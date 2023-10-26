---
title: Cloudflare Tunnel Setup
date: 2023-05-17 10:00 +0200
categories: [wan,proxy,security]
tags: [cloudflare,vpn]
author: barend
---

![Cloudflare](https://download.logo.wine/logo/Cloudflare/Cloudflare-Logo.wine.png)

# Cloudflare

There are a number of benifits of using `Cloudflare's` ZTNA platform as a reverse proxy for your applications. Coming from the networking side, it eases the load balancing and failover aspect of port forwarding. So no need to worry about WAN link failures like with port forwards...

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

## Cloudflared tunnel

All you need to do is to add the key provided by `cloudflare` in the `cloudflared/.env` file with your key.
```bash
TOKEN=<cloudflared-tunnel-secret>
```
Once that is done, you can then start the tunnel. We added the `cloudflare` tunnel to the `proxy` network since all the other fontend containers are on it. This will allow us to use the `cloudflare` tunnel as a reverse proxy for the all the applications.

```bash
docker-compose up -d -f cloudflared/docker-compose.yml
```

You will see it connected to the nearest `cloudflare` datacentres
```bash
docker logs cloudflared_clouflared_1
```

All you have to do next is to continue on configuring your `cloudflare` from the `cloudflare` ZTNA dashboard.