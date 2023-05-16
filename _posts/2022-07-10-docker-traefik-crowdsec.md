---
title: Docker with Traefik and Crowdsec
date: 2022-07-10 10:00 +0200
categories: [docker,docker-compose,ips,reverse-proxy]
tags: [docker,docker-compose,security,reverse-proxy]
author: barend
---

![Docker](https://logos-world.net/wp-content/uploads/2021/02/Docker-Logo-2015-2017.png)

# Docker

## Requirements

- [**Docker** - *Docker is a set of platform as a service products that use OS-level virtualization to deliver software in packages called containers.*](/posts/random-installations/#docker-and-docker-compose)
- [**Docker-compose** - *Compose is a tool for defining and running multi-container Docker applications.*](/posts/random-installations/#docker-and-docker-compose)

## The repo

I have saved all my `docker` files and `templates` in [Github](https://github.com)

To use my `templates`, you can clone my `repo` as follows
```bash
git clone https://github.com/barendbotes/docker-templates.git
```

Change directory into the `repo`
```bash
cd docker-templates
```
> All references to files will be in this directory. 
{: .prompt-info}

## Traefik

At first we will create a `network` which will be shared between the `services` that need to utilize the `Traefik` reverse proxy
```bash
docker network create --attachable proxy
```

We need to create and then modify the rights to `traefik/data/acme.json`, this is needed as `traefik` will fail to create and store `certificates` as your basic access rights are too open
```bash
touch traefik/data/acme.json
chmod 600 traefik/data/acme.json
```

Next you will need to modify the `traefik/docker-compose.yml` file with your own requirements.
```yaml
version: '3.5'

services:
  traefik:
    image: traefik:latest
# ...
    environment:
      - CF_API_EMAIL=user@example.com
      - CF_API_KEY=your-secure-api-key
# ...
    labels:
# ...
      - "traefik.http.routers.traefik.rule=Host(`traefik-dashboard.example.com`)"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=USER:PASSWORD_HASH"
# ...
      - "traefik.http.routers.traefik-secure.rule=Host(`traefik-dashboard.example.com`)"
# ...
      - "traefik.http.routers.traefik-secure.tls.certresolver=cloudflare" # We are using cloudflare as our Let's Encrypt validation
      - "traefik.http.routers.traefik-secure.tls.domains[0].main=example.com"
      - "traefik.http.routers.traefik-secure.tls.domains[0].sans=*.example.com"
      - "traefik.http.routers.traefik-secure.tls.domains[1].main=domain.com"
      - "traefik.http.routers.traefik-secure.tls.domains[1].sans=*.domain.com"
# ...
```

To generate a `username` and `password` hash, use the below `command`
```bash
echo $(htpasswd -nb "<USER>" "<PASSWORD>") | sed -e s/\\$/\\$\\$/g
```

There are other `config` files that you can modify to your liking, `traefik/data/config.yml` - this is a `dynamic` config file for `traefik`. You can find out more about advanced configuration in the `traefik` [docs](https://doc.traefik.io/traefik/routing/overview/) site.

You need to modify the `traefik` system file with your own required `config`. If you want to see if your DNS provider is support, you can find that [here](https://doc.traefik.io/traefik/https/acme/#dnschallenge). Otherwise, you would need to configure a different [challenge](https://doc.traefik.io/traefik/https/acme/#tlschallenge) to get `Let's Encrypt` certificates.

`traefik/data/traefik.yml`
```yaml
# ...
certificatesResolvers:
  cloudflare:
    acme:
      email: user@example.com
      storage: acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
# ...
```

We are now ready to deploy `traefik`
```bash
docker-compose up -d -f traefik/docker-compose.yml
```

See if the `contianer` is up
```bash
docker ps
```

You will see something similar to the below
```bash
9712753440a5c   traefik:latest                              "/entrypoint.sh trae…"   About an hour ago   Up 1 minutes             0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp   traefik_traefik_1
```

Check the `logs` to see whether there are any issues
```bash
docker logs traefik_traefik_1
```

You should see
```bash
time="2022-07-10T09:34:58Z" level=info msg="Configuration loaded from file: /traefik.yml"
```

You can now navigate to your `traefik` dashboard by going to `https://traefik-dashboard.example.com` and logging in with your `username` and `password` that you created for the `traefik/docker-compose.yml` label `- "traefik.http.middlewares.traefik-auth.basicauth.users=USER:PASSWORD_HASH"`

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
      - proxy
    restart: unless-stopped
```

Once uncommented, you need to the uncomment the `bouncer` `middleware` in the `traefik` `system` file `traefik/data/traefik.yml`
```yaml
entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"
    http:
     middlewares:
       - crowdsec-bouncer@file
```

Once everything has been updated and modified, you can now `upgrade` the `containers` with the new config
```bash
docker-compose up -d -f traefik/docker-compose.yml --force-recreate
docker-compose up -d -f crowdsec/docker-compose.yml --force-recreate
```

To confirm that `crowdsec` and `traefik` is working together, we will do a quick test

First you modify the `whoami` `.env` file `whoami/.env` with your required details

```env
URL=whoami.domain.com
PORT=80
COOKIE=whoami_lvl
SERVICE=whoami
```

Then you deploy the `container`
```bash
docker-compose up -d -f whoami/docker-compose.yml
```

Now navigate to `https://whoami.example.com` and confirm that you have a valid `certificate` from `Let's Encrypt`
> Remember to point your `whoami.example.com` DNS to your `docker` instance 
{: .prompt-tip}

Test the `crowdsec` `bouncer` by adding your IP to the ban list
```bash
docker exec crowdsec_crowdsec_1 cscli decisions add --ip my-ip-address
```

Confirm that you received a 'Forbidden' message when navigating to `https://whoami.example.com`

Remove your ban
```bash
docker exec crowdsec_crowdsec_1 cscli decisions delete --ip my-ip-address
```

> If you receiving and error when trying to `exec` into the `container`, remember to check the `container` name by running `docker ps` and looking for your `container`
{: .prompt-tip}

If all went well, you have just installed a reverse proxy with automatic certificate renewals and a collaborative IPS(Intrusion Prevention System) solution