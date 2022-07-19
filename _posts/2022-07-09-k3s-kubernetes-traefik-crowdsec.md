---
title: Automated k3s with crowdsec and traefik
date: 2022-07-09 19:00 +0200
categories: [k3s,ips,reverse-proxy]
tags: [kubernetes,security,reverse-proxy]
author: barend
---

![Kubernetes](https://www.drupal.org/files/project-images/Kubernetes.png)

# Kubernetes

## Requirements

- [**Ansible** - *Ansible is an agentless automation tool that can manage an entire fleet of machines and other devices.*](/posts/random-installations/#ansible)
- [**Kubectl** - *The Kubernetes command-line tool, `kubectl`, allows you to run commands against Kubernetes clusters.*](/posts/random-installations/#kubectl)
- [**Helm** - *Helm is the package manager for Kubernetes.*](/posts/random-installations/#helm)
- [**SSH Key** - *Key based authentication is more secure and convenient than traditional password authentication.*](/posts/random-installations/#ssh-keys)


## K3s Ansible Install

### Preparation
First you will need to clone `the repo`, I am using [TechnoTim's](https://github.com/techno-tim) `repo`, so please give it a ⭐ as well. These steps are basically the same as TechnoTim, so rather give him the kudo's.

```bash
git clone https://github.com/techno-tim/k3s-ansible
```

Second create a new directory based on the `sample` directory within the `inventory` directory:

```bash
cd k3s-ansible
cp -R inventory/sample inventory/my-cluster
```

Third, edit `inventory/my-cluster/hosts.ini` to match your k3s IPs

For example:

```ini
[master]
192.168.30.38
192.168.30.39
192.168.30.40

[node]
192.168.30.41
192.168.30.42

[k3s_cluster:children]
master
node
```

If multiple hosts are in the master group, the playbook will automatically set up k3s in [HA mode with etcd](https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/).

This requires at least k3s version `1.19.1` however the version is configurable by using the `k3s_version` variable.

If needed, you can also edit `inventory/my-cluster/group_vars/all.yml` to match your environment.

It’s best to start using these args, and optionally include `traefik` if you want it installed with `k3s` however I would recommend installing it later ith `helm`

```yaml
extra_server_args: "--no-deploy servicelb --no-deploy traefik"
extra_agent_args: ""
```

### Create Cluster

Start provisioning of the cluster using the following command:

```bash
ansible-playbook site.yml -i inventory/my-cluster/hosts.ini
```

After deployment control plane will be accessible via virtual ip-address which is defined in `inventory/group_vars/all.yml` as `apiserver_endpoint`

## Kubernetes cluster management

### Kubectl copy

Depending on your `kubectl` install, you might need to create the `.kube` folder first:

```bash
ls -la | grep .kube
```
You should see something similar to 
```bash
username username 4096 Jul  9 10:23 .kube
```

If not, then run the below
```bash
mkdir ~/.kube
```

To manage the cluster from your computer, you would need to copy over the `kubectl` `config`:

```bash
scp -i .ssh/id_rsa user@server_node_ip:~/.kube/config ~/.kube/config
```

### Testing your k3s cluster

Be sure you can ping your VIP defined in `inventory/my-cluster/group_vars/all.yml` as `apiserver_endpoint`
```bash
cd
ping 192.168.30.222
```

Getting the nodes
```bash
kubectl get nodes
```

## Traefik installation

Add `traefik` helm repo and update
```bash
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
```

Clone the `repo` from github for all the `configuration` files
```bash
git clone https://github.com/barendbotes/kubernetes-templates.git
```

Change directory into the cloned `repo`
```bash
cd kubernetes-templates
```

This `traefik` setup will also have a dynamic `file` configuration, so edit `traefik/traefik-config.yml` to your liking for any services outside of `kubernetes` that you would like to be behind the `traefik` proxy.

```yaml
    http:
      routers:
        webserver:
          entryPoints:
            - "websecure"
          rule: "Host(`webserver.example.com`)"
          tls: {}
          service: webserver
          middlewares:
            - secured
        webserver1:
          entryPoints:
            - "websecure"
          rule: "Host(`webserver1.example.com`)"
          tls: {}
          service: webserver1
          middlewares:
            - secured

      services:
        webserver:
          loadBalancer:
            servers:
              - url: "https://192.168.80.1"
            sticky:
              cookie:
                name: webserver_lvl
                secure: true
                httpOnly: true
                SameSite: strict
        webserver1:
          loadBalancer:
            servers:
              - url: "https://192.168.80.2"
            sticky:
              cookie:
                name: webserver1_lvl
                secure: true
                httpOnly: true
                SameSite: strict
```

Apply the `traefik-config.yml` configuration
```bash
kubectl create namespace traefik
kubectl apply -f traefik/traefik-config.yml
```
> I have found that there is an issue with serving the `Traefik` dashboard with the `Crowdsec` ForwardAuth (Could be related to the BasicAuth middleware for `Traefik` dashboard). However, we will only allow `Traefik` dashboard internally so, I am not too worried about having `Crowdsec` enabled for it.
{.is-warning}

> We will not be applying the `ForwardAuth` `crowdsec` middleware at a global config level, we will apply it to each `service` via the `middleware` file or `middlewares` defined in the deployment below
{.is.info}

We have a few `middlewares` to configure, this will be the same as the file config, however, these will be used for our Kubernetes `workloads`.
```
kubectl apply -f templates/middleware.yml
```

Update the `traefik/traefik-values.yml` `helm` chart values with your details
Keeping in mind to change the values relevant to you.
```yaml
  - --certificatesresolvers.cloudflare.acme.email=email@example.com
  - --entrypoints.websecure.http.tls.domains[0].main=example.com
  - --entrypoints.websecure.http.tls.domains[0].sans=*.example.com
```

> With the `Cloudflare` API token you need to use either `CF_API_KEY` or `CF_DNS_API_TOKEN`, the differences between the two matter. If you are using a `Global API` token in `Cloudflare` from your account then use `CF_API_KEY`, however, if you created an `API token` and selected the domain for which the `API token` as access to, then use `CF_DNS_API_TOKEN`
{.is-warning}
```yaml
  - name: CF_API_KEY
    valueFrom:
      secretKeyRef:
        key: apiKey
        name: cloudflare-credentials
```

Update your `LoadBalancerIP`
```yaml
  spec:
    # externalTrafficPolicy: Cluster
    loadBalancerIP: "192.168.80.254"
```

Since we are using `Cloudflare` for our `Let's Encrypt` certificates and `DNS` confirmation, we need to create a secret for `Cloudflare` using `traefik/cloudflare-credentials.yml`
Add your email and API key.
```yaml
stringData:
  email: email@example.com
  apiKey: super-secure-api-key
```

Create the `Cloudflare` credentials `secret`
```bash
kubectl apply -f traefik/cloudflare-credentials.yml
```

Install `traefik` with the chart values
```bash
helm install traefik traefik/traefik -n traefik -f traefik/traefik-values.yml
```

Check all pds and services associated to `traefik`
```bash
kubectl get all -n traefik
```

Confirm successful deployment of `traefik`
```bash
kubectl -n traefik logs $(kubectl -n traefik get pods --selector "app.kubernetes.io/name=traefik" --output=name)
```
It should be `level=info msg="Configuration loaded from flags."`

### Traefik dashboard

To expose the `traefik` dashboard, we need to create a `secret` for the `basic auth` user account
Generate the `base64` key that represents your user account. Be sure to replace `$username` and `$password` with your required details
```bash
htpasswd -nb $username $password | openssl base64
```
This should output a string like this `dGVjaG5vOiRhcHIxJFRnVVJ0N2E1JFpoTFFGeDRLMk8uYVNaVWNueG41eTAKCg==`
Use this string to populate the `secret` we are going to create in `traefik/traefik-dashboard-secret.yml`
```yaml
data:
  users: |2
    dGVjaG5vOiRhcHIxJFRnVVJ0N2E1JFpoTFFGeDRLMk8uYVNaVWNueG41eTAKCg==
```

Apply the `traefik` dashboard `basic auth` credentials `secret`
```bash
kubectl apply -f traefik/traefik-dashboard-secret.yml
```

Next update the `traefik/traefik-dashboard-ingressroute.yml` with your dashboard fqdn
```yaml
  routes:
    - kind: Rule
      match: Host(`traefik-dashboard.example.com`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))
```

Create the `ingressRoute`
```bash
kubectl apply -f traefik/traefik-dashboard-ingressroute.yml
```

Navigate to `https://traefik-dashboard.example.com/dashboard/`

> The trailing `/` after `dashboard` is very import, so please ensure that you enter the full address `https://traefik-dashboard.example.com/dashboard/`
{.is-warning}

## CrowdSec installation

First install the `helm` chart
```bash
helm repo add crowdsec https://crowdsecurity.github.io/helm-charts
helm repo update
```

Edit the `crowdsec/crowdsec-values.yml` and replace the `ENROLL_KEY` value with the one obtained from app.crowdsec.net, if you do not have an account uncomment the `DISABLE_ONLINE_API` `env`
```yaml
  env:
    - name: ENROLL_KEY
      value: "your-crowdsec-online-key"
    - name: ENROLL_INSTANCE_NAME
      value: "kubernetes-cluster"
    - name: ENROLL_TAGS
      value: "k3s rancher prod"
    # If it's a test, we don't want to share signals with CrowdSec so disable the Online API.
    #- name: DISABLE_ONLINE_API
    #  value: "true"
```

Install `crowdsec` using the `helm` chart values
```bash
helm install crowdsec crowdsec/crowdsec -f crowdsec/crowdsec-values.yml -n crowdsec --create-namespace
```

Generate a `bouncer` `API token` in the `crowdsec-lapi` deployment
```bash
kubectl exec -n crowdsec $(kubectl -n crowdsec get pods --selector "type=lapi" --output=name) -- cscli bouncers add traefik-bouncer
```
You will receive the `bouncer` token like below
```bash
Api key for 'traefik-bouncer':

  882882ac8acdf60dacc008dd3de68cf0

Please keep this key since you will not be able to retrieve it!
```

Populate the `API token` in the `crowdsec/traefik-bouncer.yml` file
```yaml
bouncer:
  crowdsec_bouncer_api_key: 882882ac8acdf60dacc008dd3de68cf0
  crowdsec_agent_host: "crowdsec-service.crowdsec.svc.cluster.local:8080"
```

Deploy the bouncer in the `traefik` namespace
```bash
helm install -n traefik traefik-bouncer crowdsec/crowdsec-traefik-bouncer -f crowdsec/traefik-bouncer.yml
```

Update the `traefik/traefik-values.yml` file and uncomment the `traefik-bouncer` `middleware`.
```yaml
   - --entrypoints.websecure.http.middlewares=traefik-traefik-bouncer@kubernetescrd
```
Upgrade `traefik` with the chart values
```bash
helm upgrade traefik traefik/traefik -n traefik -f traefik/traefik-values.yml
```

## Final tests

To confirm that everything works, we will deploy a whoami container that will be proxied via `traefik`

First we will modify `whoami/whoami.yml` and populate `match: Host(whoami.domain.com)` with your own domain
```yaml
  routes:
    - kind: Rule
      match: Host(`whoami.domain.com`)
```

Then we will `deploy` the application
```bash
kubectl apply -f whoami/whoami.yml
```

Now test the `whoami` application by navigating to `https://whoami.domain.com`

> Remember to add the `whoami.domain.com` record to your DNS or add it in your `hosts` file.
{: .prompt-tip}

This page should give you information about your connection details. Now go check the logs of the `traefik-bouncer` application and the `crowdsec-lapi` application. You should see your IP listed in the logs.

Block your IP in the `traefik-bouncer`
```bash
kubectl exec -n crowdsec $(kubectl -n crowdsec get pods --selector "type=lapi" --output=name) -- cscli decision add --ip your-device-ip-address
```

Now access the `whoami` application again, you should see a `Forbidden` page.

Delete your IP from the `decision` list
```bash
kubectl exec -n crowdsec $(kubectl -n crowdsec get pods --selector "type=lapi" --output=name) -- cscli decision delete --ip your-device-ip-address
```
