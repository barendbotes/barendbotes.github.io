---
title: Docker and Portainer Install
date: 2023-10-26 10:25 +0200
categories: [documentation,container,docker,linux]
tags: [portainer,docker-compose,ubuntu]
author: barend
---

<table>
  <tr>
    <td><img src="https://upload.wikimedia.org/wikipedia/commons/4/4e/Docker_%28container_engine%29_logo.svg" width=500></td>
    <td><p style="font-size:40px;">+</p></td>
    <td><img src="https://cdn.worldvectorlogo.com/logos/portainer-wordmark-1.svg" width=500 ></td>
  </tr>
 </table>


# Installation Instructions

## The repo

First thing is first, clone the repo. 

I have saved all my `docker` files and `templates` in [Github](https://github.com)

To use my `templates`, you can clone my `repo` as follows
```bash
cd ~
git clone https://github.com/barendbotes/docker-templates.git
```

Change directory into the `repo`
```bash
cd docker-templates
```
> All references to files will be from this directory. 
{: .prompt-info}

## Docker and Docker-compose

I prefer to use the built in repositories for `Docker` as Ubuntu does tend to keep them up to date and I have never had any issue running it.

```bash
sudo apt install docker docker-compose -y

```

Now add your user account to the `Docker` group
```bash
sudo usermod -aG docker $USER
```

> Remember to log out and back into your server for the group permissions to take place.
{: .prompt-info}

For future reference, we can create the required `docker` networks now. I am using 172.31.0.0/24 for the proxy network as I know I wont have more than 254 applicaitons/containers requiring proxy services and the same goes for the database network.

```
docker network create -d bridge traefik_proxy --attachable --internal --subnet 172.31.0.0/24
docker network create -d bridge database_network --attachable --internal --subnet 172.31.1.0/24
```
> Because we have created a network that is only `internal` any containers or stacks that we create with this network would need an additional network for public access - but that will be done within each `docker-compose.yml` file going forward.
{: .prompt-info}


## Portainer

Since most of the configuration is in the `github` repo, all you have to do is modify the `portainer/.env` file with your values, but that does not need to be done right now as we have not installed `traefik` or `crowdsec` yet.

This is what the `portainer/.env` file looks like, we will come back to this later
```env
TRAEFIK_URL=portainer.domain.com
TRAEFIK_PORT=9443
TRAEFIK_SCHEME=https
TRAEFIK_SERVICE=portainer
```
{: file="portainer/.env" }

Below I will talk you through the `docker-compose.yml` configuration below and what it means. This file is already in the repository, so you don't need to modify anything.
```yaml
version: '3.5'

networks:
  traefik_proxy: # <--- Referencing the docker network created earlier within the docker stack
    name: traefik_proxy
    external: true # <--- Specifying that it was created outside of the current docker stack (this docker-compose.yml file)
  default: # <--- Creating a new network for internet access for the containers
    ipam:
      driver: default
      config:
        - subnet: "172.31.2.0/24" # <--- Specifying a subnet that we controll note that it is ONE integer up from the last used subnet in the third octet. 172.31.***2***.0/24 we will continue this going forward.

volumes:
  portainer_data: # <--- Creating a docker volume for Portainer's persistent data

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer # <--- Just specifying names so that get some good habits going.
    hostname: portainer # <--- An identifiable name which gets referenced within notification services etc.
    restart: always
    networks:
      default: # <--- Attching the locally created network to the container
      traefik_proxy: # <--- Attching the externally created network to the container.
        aliases: 
          - docker.portainer.local # <--- Just creating an alias in case we want to refer to it via the "traefik_proxy" network.
    labels: # <--- Labels wont break anything being there, it helps with automated tasks and enrollment into services.
      - "com.centurylinklabs.watchtower.enable=true" # <--- Future use for automatic container updates
      - "traefik.enable=true" # <--- Enables traefik integration
      - "traefik.docker.network=traefik_proxy" # <--- Specifying what network to use
      - "traefik.http.routers.${TRAEFIK_SERVICE}.entrypoints=https" # <--- Specifying the https entry point within the traefik config
      - "traefik.http.routers.${TRAEFIK_SERVICE}.rule=Host(`${TRAEFIK_URL}`)" # <--- Rule to proxy incomming request "IF you use this DOMAIN, then route to THIS service"
      - "traefik.http.services.${TRAEFIK_SERVICE}-service.loadbalancer.passhostheader=true" # <--- Passing the URL through to the web application (Its on by default)
      - "traefik.http.services.${TRAEFIK_SERVICE}-service.loadbalancer.server.port=${TRAEFIK_PORT}" # <--- Specifying the port that the internal service uses, portainer in this case uses 9443
      - "traefik.http.services.${TRAEFIK_SERVICE}-service.loadbalancer.server.scheme=${TRAEFIK_SCHEME}" # <--- The scheme used to connect to the above port, 9443 by portainer uses https scheme
      - "traefik.http.routers.${TRAEFIK_SERVICE}.tls=true"  # <--- Specifying that we want to use TLS for certificate services
      - "traefik.http.routers.${TRAEFIK_SERVICE}.middlewares=public-chain@file"  # <--- The middleware that we want to use for this service (explained more in traefik setup)
    ports:
      - "9443:9443"  # <--- The ports used by portainer exposed on the VM interfaces
      - "8000:8000" # <--- The ports used by portainer exposed on the VM interfaces
    volumes:
      - portainer_data:/data # <--- Here we are mapping the docker volume portainer_data to the internal path of /data inside the container
      - /var/run/docker.sock:/var/run/docker.sock # <--- Used for portainer to controll docker
```
{: file="portainer/docker-compose.yml" }

Having gone through everything, you can now create the `Portainer` application
```bash
docker-compose up -d -f portainer/docker-compose.yml
```

To see if it is up and running, you can run the below:
```bash
docker ps
```

## Traefik

We need to create and then modify the rights to `traefik/data/acme.json`, this is needed as `traefik` will fail to create and store `certificates` as your basic access rights are too open
```bash
touch traefik/data/acme.json
chmod 600 traefik/data/acme.json
```

Create the `cloudflare` API key file.
```bash
mkdir traefik/.secret
```

Copy your `API` key from `Cloudflare` into the `cloudflare_token` file.
```bash
echo "api-super-secret-key" >> traefik/.secrets/cloudflare_token
```

To generate a `username` and `password` hash, use the below `command`
```bash
echo $(htpasswd -nb "<USER>" "<PASSWORD>") | sed -e s/\\$/\\$\\$/g
```

Next you will need to modify the `traefik/.env` file with your own requirements.
```yaml
TRAEFIK_DASH_URL=traefik-dashboard.domain.com
TRAEFIK_HASH=<user-password-hash> # echo $(htpasswd -nb "<USER>" "<PASSWORD>") | sed -e s/\\$/\\$\\$/g
DOMAIN_0=domain.com
DOMAIN_1=domain.org
```
{: file="traefik/.env" }

There are other `config` files that you can modify to your liking, `traefik/data/config.yml` - this is a `dynamic` config file for `traefik`. You can find out more about advanced configuration in the `traefik` [docs](https://doc.traefik.io/traefik/routing/overview/) site.

You need to modify the `traefik` system file with your own required `config`. If you want to see if your DNS provider is support, you can find that [here](https://doc.traefik.io/traefik/https/acme/#dnschallenge). Otherwise, you would need to configure a different [challenge](https://doc.traefik.io/traefik/https/acme/#tlschallenge) to get `Let's Encrypt` certificates.

```yaml
# ...
certificatesResolvers:
  cloudflare:
    acme:
      email: user@domain.com
      storage: acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
# ...
```
{: file="traefik/data/traefik.yml" }

We are now ready to deploy `traefik`
```bash
docker-compose up -d -f traefik/docker-compose.yml
```

See if the `contianer` is up
```bash
docker ps
```

## Crowdsec

You can immediately spin up the `crowdsec` container
```bash
docker-compose up -d -f crowdsec/docker-compose.yml
```

Confirm that it is running
```bash
docker ps
```

You should see
```bash
6ed2572f5c   crowdsecurity/crowdsec:latest               "/bin/sh -c '/bin/ba…"   About an hour ago   Up 28 minutes                                                                                        crowdsec_crowdsec_1
```

`Exec` into the `container` and add the `traefik-bouncer`
```bash
docker exec crowdsec_crowdsec_1 cscli bouncers add traefik-bouncer
```

You should get `traefik-bouncer` api key
```bash
Api key for 'traefik-bouncer':

  882882ac8acdf60dacc008dd3de68cf0

Please keep this key since you will not be able to retrieve it!
```

We have to add this to our `bouncer` and create the `container`, for this you need to modify the `crowdsec/docker-compose.yml` file and uncomment the `traefik-bouncer` service
```yaml
  bouncer-traefik:
    image: docker.io/fbonalair/traefik-crowdsec-bouncer:latest
    environment:
      CROWDSEC_BOUNCER_API_KEY: 882882ac8acdf60dacc008dd3de68cf0 # Insert your generated key
      CROWDSEC_AGENT_HOST: crowdsec:8080
      CROWDSEC_BOUNCER_LOG_LEVEL: 0
      GIN_MODE: release
    networks:
      default:
      traefik_proxy:
        aliases: 
          - docker.bouncer.local
    restart: unless-stopped
```
{: file="crowdsec/docker-compose.yml" }


Once everything has been updated and modified, you can now `upgrade` the `containers` with the new config
```bash
docker-compose up -d -f traefik/docker-compose.yml --force-recreate
docker-compose up -d -f crowdsec/docker-compose.yml --force-recreate
```

To confirm that `crowdsec` and `traefik` is working together, we will do a quick test

First you modify the `whoami/.env` file with your required details
```yaml
TRAEFIK_URL=whoami.domain.com
TRAEFIK_PORT=80
TRAEFIK_SCHEME=http
TRAEFIK_SERVICE=whoami
```
{: file="whoami/.env" }

Then you deploy the `container`
```bash
docker-compose up -d -f whoami/docker-compose.yml
```

Now navigate to `https://whoami.domain.com` and confirm that you have a valid `certificate` from `Let's Encrypt`
> Remember to point your `whoami.domain.com` DNS to your `docker` instance 
{: .prompt-tip}

Test the `crowdsec` `bouncer` by adding your IP to the ban list
```bash
docker exec crowdsec_crowdsec_1 cscli decisions add --ip my-ip-address
```

Confirm that you received a 'Forbidden' message when navigating to `https://whoami.domain.com`

Remove your ban
```bash
docker exec crowdsec_crowdsec_1 cscli decisions delete --ip my-ip-address
```

> If you receiving and error when trying to `exec` into the `container`, remember to check the `container` name by running `docker ps` and looking for your `container`
{: .prompt-tip}

If all went well, you have just installed a reverse proxy with automatic certificate renewals and a collaborative IPS(Intrusion Prevention System) solution

## Documentation

Subnets that we have created in this tutorial:

|**Subnet**|**Docker Network**|**Type**|**Currently in Use?**|**Attachable Network?**|
|:---|:---|:---|---:|---:|
|172.31.0.0/24|traefik_proxy|Internal|yes|yes|
|172.31.1.0/24|database_network|Internal|no|yes|
|172.31.2.0/24|portainer_default|External|yes|no|
|172.31.3.0/24|traefik_default|External|yes|no|
|172.31.4.0/24|crowdsec_default|External|yes|no|

Local Aliases specified for `containers` and `services`

|**Alias**|**Docker Network**|**Service**|
|:---|:---|:---|
|docker.portainer.local|traefik_proxy|Portainer|
|docker.traefik.local|traefik_proxy|Traefik Proxy|
|docker.crowdsec.local|traefik_proxy|Crowdsec API|
|docker.bouncer.local|traefik_proxy|Crowdsec Bouncer ForwardAuth API|
|docker.whoami.local|traefik_proxy|Who Am I Web Service|