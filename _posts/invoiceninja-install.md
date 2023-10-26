---
title: InvoiceNinja Installation
date: 2023-10-26 08:00 +0200
categories: [linux,ubuntu,debian,invoicing]
tags: [docker-compose,docker,invoiceninja]
author: barend
---

![InvoiceNinja](https://invoiceninja.com/wp-content/uploads/2022/12/Small-Business-Invoicing-1024x779.png)

# InvoiceNinja

## Requirements

- [**Docker** - *Docker is a set of platform as a service products that use OS-level virtualization to deliver software in packages called containers.*](#)
- [**Docker-compose** - *Compose is a tool for defining and running multi-container Docker applications.*](#)
- [**Traefik** - *Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy.* ](/posts/docker-traefik-crowdsec)

## InvoiceNinja

To get started, clone the `InvoiceNinja` github repository.

```bash
cd docker-templates
git clone https://github.com/invoiceninja/dockerfiles.git invoiceninja
```

Edit the `invoiceninja/env` file and change it accordingly

```env
SERVICE=invoice
COOKIE=invoice_lvl
PORT=80
URL=invoice.domain.com
SCHEME=http
APP_URL=https://invoice.domain.com
APP_KEY=<your-generated-key> # docker run --rm -it invoiceninja/invoiceninja php artisan key:generate --show
APP_DEBUG=0
REQUIRE_HTTPS=true
PHANTOMJS_PDF_GENERATION=false
PDF_GENERATOR=snappdf
TRUSTED_PROXIES=*
QUEUE_CONNECTION=database
DB_HOST=mysql-database-server
DB_PORT=3306
DB_DATABASE=ninja-db
DB_USERNAME=ninja-user
DB_PASSWORD=<super-secure-password-1>
IN_USER_EMAIL=user@domain.com
IN_PASSWORD=<super-secure-password-2>
MAIL_MAILER=smtp
MAIL_HOST=smtp.domain.com
MAIL_PORT=587
MAIL_USERNAME=noreply@domain.com
MAIL_PASSWORD=<super-secure-password-3>
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS='invoice@domain.com'
MAIL_FROM_NAME='Corp Invoicing'
```
{: file="invoiceninja/env" }

You need to modify permissions to the relevant folders for `InvoiceNinja` to work correctly

```bash
chmod 755 invoiceninja/docker/app/public
sudo chown -R 1500:1500 invoiceninja/docker/app
```

Once all is done, we will essentially change the whole `docker-compose` file to our own liking.

```yaml
version: '3.7'

services:
  server:
    image: nginx
    restart: always
    env_file: env
    volumes:
      - ./config/nginx/in-vhost.conf:/etc/nginx/conf.d/in-vhost.conf:ro
      - ./docker/app/public:/var/www/app/public:ro
    depends_on:
      - app
    ports:
      - "8181:80"
    networks:
      - invoiceninja
      - proxy
    extra_hosts:
      - "in5.localhost:192.168.0.124"
    labels:
      - com.centurylinklabs.watchtower.enable=true
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.${SERVICE}.entrypoints=https
      - traefik.http.routers.${SERVICE}.rule=Host(`${URL}`)
      - traefik.http.services.${SERVICE}-service.loadbalancer.server.port=${PORT}
      - traefik.http.services.${SERVICE}-service.loadbalancer.server.scheme=${SCHEME}
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie=true
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie.httponly=true
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie.secure=true
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie.samesite=strict
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie.name=${COOKIE}
      - traefik.http.routers.${SERVICE}.tls=true
      - traefik.http.routers.${SERVICE}.middlewares=public-chain@file

  app:
    image: invoiceninja/invoiceninja:5
    env_file: env
    restart: always
    volumes:
      - ./config/hosts:/etc/hosts:ro
      - ./docker/app/public:/var/www/app/public:rw,delegated
      - ./docker/app/storage:/var/www/app/storage:rw,delegated
      - ./config/php/php.ini:/usr/local/etc/php/php.ini
      - ./config/php/php-cli.ini:/usr/local/etc/php/php-cli.ini
    networks:
      - invoiceninja
    extra_hosts:
      - "in5.localhost:192.168.0.124"
    labels:
      - com.centurylinklabs.watchtower.enable=true

networks:
  invoiceninja:
  proxy:
    external: true
```