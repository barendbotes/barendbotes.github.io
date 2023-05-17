---
title: Docker PostgreSQL Setup
date: 2023-05-17 14:00 +0200
categories: [documentation,linux,docker]
tags: [hosting,docker,sql,postgresql]
author: barend
---

![PostgreSQL](https://1000logos.net/wp-content/uploads/2020/08/PostgreSQL-Logo.png)

# PostgreSQL

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
> All references to files will be from this directory. 
{: .prompt-info}

## Postgres

At first we will create a `network` which will be shared between the `services` that need to utilize `PostgreSQL` as a database server
```bash
docker network create --attachable backend_postgres
```

Next you will need to modify the `postgres/.env` file with your own complex password.
```bash
POSTGRES_PASSWORD=<complex-sql-password> # tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32  ; echo
```

You can use `tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32  ; echo` to generate a 32 character alphanumeric string.

After that one change, you can then run the new PostgreSQL database container.
```bash
docker-compose up -d -f postgres/docker-compose.yml
```

You can look at the container logs to see if it is up by running:
```bash
docker logs postgres-postgres-1
```

It will show you that it is ready to connect.

## PGAdmin

Now, I am not a database administrator or a fundi, so I will be using pgadmin to manage the postgres databases.

To set up pgadmin, we will first modify `pgadmin/.env` file

```bash
PGADMIN_DEFAULT_EMAIL=user@domain.com # Your email address to access the WebUI
PGADMIN_DEFAULT_PASSWORD=<complex-password-for-webui> # tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16  ; echo
SERVICE=pgadmin
COOKIE=pgadmin_lvl
PORT=80
URL=pgadmin.domain.com # Your FQDN which should match your domain in your traefik configuration.
SCHEME=http
```

Once you have modified the `pgadmin/.env` file, you can then spin up the pgadmin container
```bash
docker-compose up -d -f pgadmin/docker-compose.yml
```

You can access the WebUI by going to `pgadmin.domain.com` in your browser and logging in with the email address and password that you created in the `pgadmin/.env` file.

After you logged in, you can add a PostgreSQL server using `postgres` username and the password configured in the `postgres/.env` file.

> Congratulations, you have successfully set up PostgreSQL and PGAdmin docker containers.
{: .prompt-tip}