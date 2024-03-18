---
title: Full Docker Security Stack
date: 2022-07-08 00:00 +0200
categories: [documentation,linux,security]
tags: [graylog,wazuh,misp,opensearch,syslog]
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

## Requirements

- [**Docker** - *Docker is a set of platform as a service products that use OS-level virtualization to deliver software in packages called containers.*](/posts/random-installations/#docker-and-docker-compose)

## Docker Swarm Setup



