---
title: Zabbix and Grafana Install
date: 2023-10-26 17:15 +0200
categories: [documentation,container,docker,linux]
tags: [zabbix,docker-compose,ubuntu,grafana,postgresql]
author: barend
---

<table>
  <tr>
    <td><img src="https://assets.zabbix.com/img/logo/zabbix_logo_500x131.png" width=500></td>
    <td><p style="font-size:40px;">+</p></td>
    <td><img src="https://cdn.icon-icons.com/icons2/2699/PNG/512/grafana_logo_icon_171049.png" width=500 ></td>
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

## PostgreSQL and pgAdmin

First you need to generate a complex password for your `postgres` and `pgadmin` user - run the command twice to get a different string for the second password, the below command will generate a 32 character string without special characters. 

For the `postgres` user
```bash
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
```
{: file="postgres user" }

For the `pgadmin` user
```bash
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
```
{: file="pgadmin user" }

Copy the string and replace `<super-secure-password-1>` and `<super-secure-password-2>` with the two generated strings in `postgres/.env` with the generated string.

```bash
POSTGRES_PASSWORD=jNbQYKSeVKnIAIO7aKeFRElZQWfZxkM1831BRAIqdnEQ382H7WVCDeS1RFwQayvQ # <super-secure-password-1>
PGADMIN_DEFAULT_EMAIL=user@domain.com
PGADMIN_DEFAULT_PASSWORD=Peajezj8rEOirY7T1k7ILxj3xhf8i7Sw # <super-secure-password-2>
TRAEFIK_SERVICE=pgadmin
TRAEFIK_PORT=80
TRAEFIK_URL=pgadmin.domain.com
TRAEFIK_SCHEME=http
```
{: file="postgres/.env" }

Once completed, you can then run the `container`.

```bash
docker-compose up -d -f postgres/docker-compose.yml
```

Confirm it is up by running
```bash
docker ps
```

## Zabbix

By this time, you would have created a database and a user in `PostgreSQL` by using `pgAdmin` - you can further lock it down by editing the `pg_hba.conf` file with the relevant users and ip addresses created.

Edit the `zabbix/.env` file with your own entries.

```bash
VERSION=alpine-6.4-latest
DB_SERVER_HOST=docker.postgresql.local
POSTGRES_DB=zabbix-db
POSTGRES_USER=zabbix-user
POSTGRES_PASSWORD=<super-secure-password-1>
ZBX_SERVER_HOST=zabbix-server-pgsql
TRAEFIK_SCHEME=zabbix
TRAEFIK_SERVICE=http
TRAEFIK_PORT=8080
TRAEFIK_URL=zabbix.domain.com
```
{: file="zabbix/.env" }

Once done, you can create the `container`

```bash
docker-compose up -d -f zabbix/docker-compose.yml
```

## Grafana

Edit the `grafana/.env` file with your own entries. Ignore all the hashed out entries, those will be discussed at a later stage. Change the `GF_SERVER_DOMAIN` and the `TRAEFIK_URL` to your requirement.

```bash
TZ=Africa/Johannesburg
GF_INSTALL_PLUGINS=alexanderzobnin-zabbix-app
GF_SERVER_DOMAIN=grafana.domain.com
GF_SERVER_ROOT_URL=https://grafana.domain.com
GF_PLUGIN_ALLOW_LOCAL_MODE=true
GF_PANELS_DISABLE_SANITIZE_HTML=true
GF_SECURITY_ALLOW_EMBEDDING=true
GF_DEFAULT_INSTANCE_NAME=grafana
# GF_AUTH_GENERIC_OAUTH_ENABLED=true
# GF_AUTH_GENERIC_OAUTH_NAME=Authentik
# GF_AUTH_GENERIC_OAUTH_CLIENT_ID=<oauth-client-id>
# GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=<oauth-client-secret>
# GF_AUTH_GENERIC_OAUTH_SCOPES=openid profile email groups
# GF_AUTH_GENERIC_OAUTH_EMPTY_SCOPES=false
# GF_AUTH_GENERIC_OAUTH_AUTH_URL=https://admin.auth.domain.com/application/o/authorize/
# GF_AUTH_GENERIC_OAUTH_TOKEN_URL=https://admin.auth.domain.com/application/o/token/
# GF_AUTH_GENERIC_OAUTH_API_URL=https://admin.auth.domain.com/application/o/userinfo/
# GF_AUTH_SIGNOUT_REDIRECT_URL=https://admin.auth.domain.com/application/o/grafana/end-session/
# GF_AUTH_GENERIC_OAUTH_LOGIN_ATTRIBUTE_PATH=email
# GF_AUTH_GENERIC_OAUTH_GROUPS_ATTRIBUTE_PATH=groups
# GF_AUTH_GENERIC_OAUTH_NAME_ATTRIBUTE_PATH=name
# GF_AUTH_GENERIC_OAUTH_USE_PKCE=true
# GF_AUTH_GENERIC_OAUTH_ALLOW_ASSIGN_GRAFANA_ADMIN=true
# GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH="contains(groups[*], 'Administrators') && 'GrafanaAdmin'"
TRAEFIK_SERVICE=grafana
TRAEFIK_COOKIE=grafana_lvl
TRAEFIK_PORT=3000
TRAEFIK_URL=grafana.domain.com
TRAEFIK_SCHEME=http
```
{: file="grafana/.env" }

Once done, you can create the `container`

```bash
docker-compose up -d -f grafana/docker-compose.yml
```




## Documentation

Subnets that we have created in this tutorial:

|**Subnet**|**Docker Network**|**Type**|**Currently in Use?**|**Attachable Network?**|
|:---|:---|:---|---:|---:|
|172.31.0.0/24|traefik_proxy|Internal|yes|yes|
|172.31.1.0/24|database_network|Internal|no|yes|
|172.31.2.0/24|portainer_default|External|yes|no|
|172.31.3.0/24|traefik_default|External|yes|no|
|172.31.4.0/24|crowdsec_default|External|yes|no|
|172.31.5.0/24|postgres_default|External|yes|no|

Local Aliases specified for `containers` and `services`

|**Alias**|**Docker Network**|**Service**|
|:---|:---|:---|
|docker.portainer.local|traefik_proxy|Portainer|
|docker.traefik.local|traefik_proxy|Traefik Proxy|
|docker.crowdsec.local|traefik_proxy|Crowdsec API|
|docker.bouncer.local|traefik_proxy|Crowdsec Bouncer ForwardAuth API|
|docker.whoami.local|traefik_proxy|Who Am I Web Service|
|docker.postgres.local|database_network|PostgreSQL Database|

Local IPs specified for `containers` and `services`

|**IP**|**Docker Network**|**Service**|
|:---|:---|:---|
|172.31.1.2|database_network|PostgreSQL Database|
|172.31.1.3|database_network|pgAdmin Application|
|172.31.1.4|database_network|Zabbix Server|
|172.31.1.5|database_network|Zabbix Frontend|
|172.31.1.6|database_network|Grafana Dashboarding|
