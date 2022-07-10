---
title: Random Installation Instructions
date: 2022-07-09 17:00 -500
categories: [linux,ubuntu,debian]
tags: [apt-get,ansible,kubectl,helm]
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

This installation has been copied directly from `Docker` themselves, you can go to their instructions [here.](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

Set up the repository

Update the `apt` package index and install packages to allow `apt` to use a repository over HTTPS:
```bash
sudo apt-get update

sudo apt-get install \
ca-certificates \
curl \
gnupg \
lsb-release
```

Add Docker’s official GPG key:
```bash
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

Use the following command to set up the repository:
```bash
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Install Docker Engine

Update the `apt` package index, and install the latest version of Docker Engine, containerd, and Docker Compose, or go to the next step to install a specific version:
```bash
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

Now add your user account to the `Docker` group
```bash
sudo chmod -aG docker $USER
```