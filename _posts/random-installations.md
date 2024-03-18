---
title: Random Installation Instructions
date: 2022-07-09 17:00 +0200
categories: [linux,ubuntu,debian]
tags: [apt-get,ansible,kubectl,helm]
author: barend
---

# Welcome!

This page serves as a repository for guides on a bunch of random installs

## Ansible

Installation of ansible is very easy, all you need is just to update and install
```bash
sudo apt update
sudo apt install ansible
```
---
## Kubectl

Update the `apt` package index and install packages needed to use the Kubernetes `apt` repository:
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
```

Download the Google Cloud public signing key:
```bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```

Add the Kubernetes `apt` repository:
```bash
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Update `apt` package index with the new repository and install `kubectl`:
```bash
sudo apt-get update
sudo apt-get install -y kubectl
```
---
## Helm

Helm Installation
Helm now has an installer script that will automatically grab the latest version of Helm and install it locally.

You can fetch that script, and then execute it locally. It's well documented so that you can read through it and understand what it is doing before you run it.
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
---
## SSH Keys

The chances are that you already have an SSH key pair on your Ubuntu client machine. If you generate a new key pair, the old one will be overwritten. To check whether the key files exist, run the following ls command
```bash
ls -l ~/.ssh/id_*.pub
```
If the command returns something like No such file or directory, or no matches found, it means that the user does not have SSH keys, and you can proceed with the next step and generate SSH key pair. Otherwise, if you have an SSH key pair, you can either the existing ones or backup up the old keys and generate a new pair.

To generate a new 4096 bits SSH key pair with your email address as a comment, run:
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@domain.com"
```

You will be prompted to specify the file name:
```bash
Enter file in which to save the key `(/home/yourusername/.ssh/id_rsa)`:
```

The default location and file name should be fine for most users. Press `Enter` to accept and continue.

Next, you’ll be asked to type a secure passphrase. A passphrase adds an extra layer of security. If you set a passphrase, you’ll be prompted to enter it each time you use the key to login to the remote machine.

If you don’t want to set a passphrase, press `Enter`.
```bash
Enter passphrase (empty for no passphrase):`
```

To verify your new SSH key pair is generated, type:
```bash
ls ~/.ssh/id_*
```

You should then see something like this
```bash
/home/yourusername/.ssh/id_rsa /home/yourusername/.ssh/id_rsa.pub
```

Now that you have an SSH key pair, the next step is to copy the public key to the remote server you want to manage.

The easiest and the recommended way to copy the public key to the server is to use the ssh-copy-id tool. On your local machine type:
```bash
ssh-copy-id remote_username@server_ip_address
```

You will be prompted to enter the remote user password:
```bash
remote_username@server_ip_address's password:
```

Once the user is authenticated, the public key `~/.ssh/id_rsa.pub` will be appended to the remote user `~/.ssh/authorized_keys` file, and the connection will be closed.
```bash
Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'username@server_ip_address'"
and check to make sure that only the key(s) you wanted were added.
```

If by some reason the `ssh-copy-id` utility is not available on your local computer, use the following command to copy the public key:
```bash
cat ~/.ssh/id_rsa.pub | ssh remote_username@server_ip_address "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

After completing the steps above, you should be able to log in to the remote server without being prompted for a password.

To test it, try to login to your server via SSH:
```bash
ssh remote_username@server_ip_address
```

If you haven’t set a passphrase for the private key, you will be logged in immediately. Otherwise, you will be prompted to enter the passphrase.

---
## Docker and Docker-compose

I followed the [Docker](https://docs.docker.com/engine/install/ubuntu/#installation-methods) guide, so you can either follow the link or just copy and paste the below for `Ubuntu`.

Uninstall all the old and previous versions of `Docker` and `Container.io` etc.

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

Add the official `Docker` repository and the `GPG` keys

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

The repositories:

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

Now install the latest version of `Docker`

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Now add your user account to the `Docker` group
```bash
sudo usermod -aG docker $USER
```

## Keepalived

Keepalived provides frameworks for both load balancing and high availability. The load balancing framework relies on the well-known and widely used Linux Virtual Server (IPVS) kernel module, which provides Layer 4 load balancing.

Keepalived is quite simple to install, we will just run:

```bash
sudo apt install keepalived -y
```

Once installed, you would want to create the config file on each server.

```bash
sudo nano /etc/keepalived/keepalived.conf
```

You can use the following template, but modify for each server

```yaml
vrrp_instance VI_1 {
        state MASTER
        interface eth0 # Enter in correct interface name
        virtual_router_id 10 # Unique to each VRRP instance
        priority 25 # Higher number means higher priority
        advert_int 1
        lb_kind DR
        unicast_src_ip 10.200.40.23 # Local server IP
        unicast_peer{ # Enter in each other server IP
                10.200.40.19 
                10.200.40.20
                10.200.40.18
        }
        authentication {
                auth_type PASS
                auth_pass $PASSWORD
        }
        virtual_ipaddress {
                10.200.40.231/24 # VRRP IP address
        }
}
```

Enable the keepalived service and start it.

```bash
sudo systemctl enable keepalived
sudo systemctl start keepalived
```

## GlusterFS Installation

Ensure hostname resolution across nodes, below we have 3 nodes; node1 - 10.10.10.1, node2 - 10.10.10.2, node3 - 10.10.10.3

```bash
##node1
echo '10.10.10.2 node2' | sudo tee -a /etc/hosts
echo '10.10.10.3 node3' | sudo tee -a /etc/hosts

##node2
echo '10.10.10.1 node1' | sudo tee -a /etc/hosts
echo '10.10.10.3 node3' | sudo tee -a /etc/hosts

##node3
echo '10.10.10.1 node1' | sudo tee -a /etc/hosts
echo '10.10.10.2 node2' | sudo tee -a /etc/hosts
```

Create folder for GlusterFS

```bash
sudo mkdir /gluster
sudo mkdir /gluster/${VOLUME_NAME}
sudo mkdir /mnt/${VOLUME_NAME}
```

Install GlusterFS Server

```bash
sudo apt install glusterfs-server -y
sudo systemctl start glusterd
sudo systemctl enable glusterd
```

Peer nodes from master node, node1

```bash
sudo gluster peer probe node2
sudo gluster peer probe node3
```

Check the status

```bash
sudo gluster peer status
```

Create the Gluster volume and start it

```bash
sudo gluster volume create ${VOLUME_NAME} replica 3 node1:/gluster/${VOLUME_NAME} node2:/gluster/${VOLUME_NAME} node3:/gluster/${VOLUME_NAME} force
sudo gluster volume start ${VOLUME_NAME}
sudo gluster volume info
sudo gluster pool list
```

Enable mount at start up of server

```bash
echo 'localhost:/${VOLUME_NAME} /mnt/${VOLUME_NAME} glusterfs defaults,_netdev,noauto,x-systemd.automount 0 0' | sudo tee -a /etc/fstab
```

Mount volume

```bash
sudo mount -a
```