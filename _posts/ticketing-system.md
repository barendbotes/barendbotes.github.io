---
title: Zammad Ticketing System
date: 2023-02-19 13:30 +0200
categories: [docker,docker-compose,zammad,ticketing]
tags: [zammad,ticketing,msp]
author: barend
---

![Zammad](https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Logo-zammad.svg/1280px-Logo-zammad.svg.png)

# Zammad on Docker

```bash
version: '3.5'
networks:
  zammad:
  proxy:
    external: true

services:
  zammad-backup:
    command: ["zammad-backup"]
    depends_on:
      - zammad-railsserver
      - zammad-postgresql
    entrypoint: /usr/local/bin/backup.sh
    environment:
      - BACKUP_SLEEP=86400
      - HOLD_DAYS=10
      - POSTGRESQL_USER=${POSTGRES_USER}
      - POSTGRESQL_PASSWORD=${POSTGRES_PASS}
    image: ${IMAGE_REPO}:zammad-postgresql${VERSION}
    restart: ${RESTART}
    volumes:
      - zammad-backup:/var/tmp/zammad
      - zammad-data:/opt/zammad
      - zammad-backup-var:/var/lib/postgresql/data
    networks:
      - zammad

  zammad-elasticsearch:
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    image: ${IMAGE_REPO}:zammad-elasticsearch${VERSION}
    restart: ${RESTART}
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    networks:
      - zammad
      - proxy

  zammad-init:
    command: ["zammad-init"]
    depends_on:
      - zammad-postgresql
    environment:
      - MEMCACHE_SERVERS=${MEMCACHE_SERVERS}
      - POSTGRESQL_USER=${POSTGRES_USER}
      - POSTGRESQL_PASS=${POSTGRES_PASS}
      - REDIS_URL=${REDIS_URL}
    image: ${IMAGE_REPO}:zammad${VERSION}
    restart: on-failure
    volumes:
      - zammad-data:/opt/zammad
    networks:
      - zammad

  zammad-memcached:
    command: memcached -m 256M
    image: memcached:1.6.10-alpine
    restart: ${RESTART}
    networks:
      - zammad

  zammad-nginx:
    command: ["zammad-nginx"]
    expose:
      - "8080"
    depends_on:
      - zammad-railsserver
    image: ${IMAGE_REPO}:zammad${VERSION}
    restart: ${RESTART}
    environment:
      - NGINX_SERVER_SCHEME=https
    volumes:
      - zammad-data:/opt/zammad
    networks:
      - zammad
      - proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=proxy
      - traefik.http.routers.${SERVICE}.entrypoints=https
      - traefik.http.routers.${SERVICE}.rule=Host(`${URL}`)
      - traefik.http.services.${SERVICE}-service.loadbalancer.passhostheader=true
      - traefik.http.services.${SERVICE}-service.loadbalancer.server.port=${PORT}
      - traefik.http.services.${SERVICE}-service.loadbalancer.server.scheme=${SCHEME}
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie=true
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie.httponly=true
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie.secure=true
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie.samesite=strict
      - traefik.http.services.${SERVICE}-service.loadbalancer.sticky.cookie.name=${COOKIE}
      - traefik.http.routers.${SERVICE}.tls=true
      - traefik.http.routers.${SERVICE}.middlewares=secured@file

  zammad-postgresql:
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASS}
    image: ${IMAGE_REPO}:zammad-postgresql${VERSION}
    restart: ${RESTART}
    volumes:
      - postgresql-data:/var/lib/postgresql/data
    networks:
      - zammad
      - proxy

  zammad-railsserver:
    command: ["zammad-railsserver"]
    depends_on:
      - zammad-memcached
      - zammad-postgresql
      - zammad-redis
    environment:
      - MEMCACHE_SERVERS=${MEMCACHE_SERVERS}
      - REDIS_URL=${REDIS_URL}
    image: ${IMAGE_REPO}:zammad${VERSION}
    restart: ${RESTART}
    volumes:
      - zammad-data:/opt/zammad
    networks:
      - zammad

  zammad-redis:
    image: redis:6.2.5-alpine
    restart: ${RESTART}
    volumes:
      - zammad-redis:/data
    networks:
      - zammad

  zammad-scheduler:
    command: ["zammad-scheduler"]
    depends_on:
      - zammad-memcached
      - zammad-railsserver
      - zammad-redis
    environment:
      - MEMCACHE_SERVERS=${MEMCACHE_SERVERS}
      - REDIS_URL=${REDIS_URL}
    image: ${IMAGE_REPO}:zammad${VERSION}
    restart: ${RESTART}
    volumes:
      - zammad-data:/opt/zammad
    networks:
      - zammad

  zammad-websocket:
    command: ["zammad-websocket"]
    depends_on:
      - zammad-memcached
      - zammad-railsserver
      - zammad-redis
    environment:
      - MEMCACHE_SERVERS=${MEMCACHE_SERVERS}
      - REDIS_URL=${REDIS_URL}
    image: ${IMAGE_REPO}:zammad${VERSION}
    restart: ${RESTART}
    volumes:
      - zammad-data:/opt/zammad
    networks:
      - zammad

volumes:
  elasticsearch-data:
    driver: local
  postgresql-data:
    driver: local
  zammad-backup:
    driver: local
  zammad-data:
    driver: local
  zammad-redis:
    driver: local
  zammad-backup-var:
    driver: local
```

.env file

```bash
IMAGE_REPO=zammad/zammad-docker-compose
MEMCACHE_SERVERS=zammad-memcached:11211
POSTGRES_PASS=SecurePassword123
POSTGRES_USER=zammad
REDIS_URL=redis://zammad-redis:6379
RESTART=always
VERSION=-5.1.0-4
SERVICE=zammad
COOKIE=zammad_lvl
URL=tickets.company.com
PORT=8080
SCHEME=http

```