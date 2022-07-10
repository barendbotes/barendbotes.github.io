---
title: Random Configuration Files
date: 2022-07-08 18:56 -500
categories: [configuration,linux,files]
tags: [hosting,code,docs]
---

# Welcome!

This page serves as a repository for guides on a bunch of random configuration files

## Cloud-init

There might be other better ways of achieving the same results, however, I found that this is the easiest and most consistent for me. I always use the `.img` file from ubuntu, and not the `.iso`. Click [here](https://cloud-images.ubuntu.com/releases/22.04/release/) for Ubuntu 22.04 amd64 release.

First we need to get our encrypted password
```bash
python3 -c 'import crypt; print(crypt.crypt("my-super-secure-password", crypt.mksalt(crypt.METHOD_SHA512)))'
```

You should get an output like this
```bash
$6$KlrsQOhlTJHCVpc0$eGL6M/noKoEvPxVYTkdLXW6C6dE.lTXk15I53svCNJUYG3VUk/aBv.aIPX/0xi3hU3/l/YZQty3rallWTljde/
```
### Config file

This is the cloud-init config file that I use, replace `${HOSTNAME}`, `${FQDN}` and the `timezone` with your own details. Here is a list of [Timezones](https://www.php.net/manual/en/timezones.php)
```yaml
#cloud-config

hostname: ${HOSTNAME}
fqdn: ${FQDN}
timezone: Africa/Johannesburg
# This automatically grows your rootfs when you change the disk size on your VM
growpart:
  mode: auto
  devices: ["/"]
  ignore_growroot_disabled: false
# This adds your hostname and fqdn into the hosts file
manage_etc_hosts: true
preserve_hostname: false
resize_rootfs: true
# Updates and Upgrades packages
package_update: true
package_upgrade: true
# Packages can be installed by uncommenting the below and adding apt-get packages
#packages:
# - docker
# - docker-compose
users:
  - name: username
    gecos: User Name
    primary_group: username
    # encrypted password that we generated
    passwd: "$6$KlrsQOhlTJHCVpc0$eGL6M/noKoEvPxVYTkdLXW6C6dE.lTXk15I53svCNJUYG3VUk/aBv.aIPX/0xi3hU3/l/YZQty3rallWTljde/"
    shell: /bin/bash
    lock-passwd: false
    ssh_pwauth: false
    chpasswd: { expire: False }
    # passwordless sudo
    # sudo: ALL=(ALL) NOPASSWD:ALL
    groups: [username, sudo]
    ssh_authorized_keys:
      - ssh-rsa AAA... #generated ssh key
```

### Static IP

Create the `config` file to disable the cloud assigned `netplan` config
```bash
sudo touch /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

Append `network: {config: disabled}` to the end of that file
```bash
sudo -- bash -c 'echo "network: {config: disabled}" >> /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
```

Save it and edit the `netplan` config file `/etc/netplan/50-cloud-init.yaml`
```bash
sudo nano etc/netplan/50-cloud-init.yaml
```

Network `config` file
```yaml
network:
    version: 2
    renderer: networkd
    ethernets:
        eth0:
            addresses:
                - 192.168.1.10/24
            nameservers:
                search: [domain.local, domain2.local]
                addresses: [192.168.1.1]
            routes:
                - to: default
                  via: 192.168.1.1
```

Apply the `netplan` config file
```bash
sudo netplan apply
```

> You should now be able to access your linux VM from the new static IP 
{: .prompt-info}