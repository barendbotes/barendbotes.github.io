---
title: Random Configuration Files
date: 2022-07-10 10:00 +0200
categories: [configuration,linux,files]
tags: [hosting,code,docs]
author: barend
---

# Welcome!

This page serves as a repository for guides on a bunch of random configuration files


## CloudFlare Bulk Delete DNS

You need to had jq installed

```bash
sudo apt install jq -y
```

First create bash script cloudflare-delete-all-records.sh

```bash
nano cloudflare-delete-all-records.sh
```

Bash content

```bash
#!/bin/bash

TOKEN="xxxxxxxxxxxxxxxxx"
ZONE_ID=xxxxxxxxxxxxxxxxx

# EMAIL=me@gmail.com
# KEY=11111111111111111111111111
# Replace with
#     -H "X-Auth-Email: ${EMAIL}" \
#     -H "X-Auth-Key: ${KEY}" \
# for old API keys


curl -s -X GET https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?per_page=500 \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" | jq .result[].id |  tr -d '"' | (
  while read id; do
    curl -s -X DELETE https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${id} \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json"
  done
  )
```

Make it executable

```bash
chmod x+ cloudflare-delete-all-records.sh
```

And then run it

```bash
./cloudflare-delete-all-records.sh
```

## Certbot Ubuntu Certificate Requests 90 Day

Install Certbot

```bash
sudo apt install python3-certbot-dns-cloudflare
```

Create folders for credential file

```bash
mkdir -p ~/.secrets/certbot
```

Create and edit credential file

```bash
nano ~/.secrets/certbot/cloudflare.ini
```

Credential file contents

```bash
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = <your-email-address>
dns_cloudflare_api_key = <your-api-key>
```

Secure the file

```bash
chmod 600 ~/.secrets/certbot/cloudflare.ini
```

Create a certificate

```bash
sudo certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
    --preferred-challenges dns-01 \
    -d <certificate.domain.com>
```

## OpenSSL Certificate conversion

Convert from PEM/CERT to PFX using OpenSSL

```bash
openssl pkcs12 -inkey privkey.pem -in fullchain.pem -export -out cert1.pfx
```

## Docker ConfigMap

Mapping config in portainer to path in docker container. compose file must use version 3.3 or higher.

```bash

    configs:
      - source: config.file
        target: /path/in/container/config.file
        uid: '0'
        gid: '0'
        mode: 292
configs:
  config.file:
    external: true
```


## Setting up Ubuntu after installation

### Configuring updates and automatic updates

Update package manager

```bash
sudo apt-get update
```

Upgrade packages

```bash
sudo apt-get upgrade
```

Reconfigure unattended-upgrades

```bash
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Verify unattended upgrades configuration file in your text editor of choice

```bash
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```

To disable automatic reboots by the automatic upgrades configuration edit the following file

```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

and uncomment the following line by removing the leading slashes

```bash
//Unattended-Upgrade::Automatic-Reboot "false";
```

### Set Timezone

Set timezone on Ubuntu

Show timezones

```bash
sudo timedatectl list-timezones
```

Choose the correct timezone for your location, in my case, I am in South Africa.

```bash
sudo timedatectl set-timezone Africa/Johannesburg
```

## Install Docker and Docker-compose

First check for updates

```bash
sudo apt-get update
```

Install docker and docker-compose

```bash
sudo apt-get install docker && sudo apt-get install docker-compose -y
```

Add the current user to the docker group to run docker commands without sudo

```bash
sudo usermod -aG docker $USER
```

## Install Portainer

Create the docker-compose file for the portainer config

```bash
nano docker-compose.yml
```

Add the following compose configuration

```bash
version: '3.3'
services:
  portainer:
    image: portainer/portainer-ce:latest
    ports:
      - "9443:9443"
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
volumes:
  portainer_data:
```

spin up portainer container

```bash
docker-compose up -d
```

Portainer will now be accessible via the web interface https://serveraddress:9443

## OpenSSL Self-signed CA and Certificate Generation

### Creating the Certificate Authority's Certificate and Keys

Generate a private key for the CA:

```bash
openssl genrsa 2048 > ca-key.pem
```

Generate the X509 certificate for the CA:

```bash
openssl req -new -x509 -nodes -days 365000 \
   -key ca-key.pem \
   -out ca-cert.pem
```

### Creating the Server's Certificate and Keys

Generate the private key and certificate request:

```bash
openssl req -newkey rsa:2048 -nodes -days 365000 \
   -keyout server-key.pem \
   -out server-req.pem
```

Generate the X509 certificate for the server:

```bash
openssl x509 -req -days 365000 -set_serial 01 \
   -in server-req.pem \
   -out server-cert.pem \
   -CA ca-cert.pem \
   -CAkey ca-key.pem
```

### Creating the Client's Certificate and Keys

Generate the private key and certificate request:

```bash
openssl req -newkey rsa:2048 -nodes -days 365000 \
   -keyout client-key.pem \
   -out client-req.pem
```

Generate the X509 certificate for the client:

```bash
openssl x509 -req -days 365000 -set_serial 01 \
   -in client-req.pem \
   -out client-cert.pem \
   -CA ca-cert.pem \
   -CAkey ca-key.pem
```

### Verifying the Certificates

Verify the server certificate:

```bash
openssl verify -CAfile ca-cert.pem \
   ca-cert.pem \
   server-cert.pem
```

Verify the client certificate:

```bash
openssl verify -CAfile ca-cert.pem \
   ca-cert.pem \
   client-cert.pem
```

Microsoft Server Certificate Request [Windows Server Microsoft Docs](https://docs.microsoft.com/en-US/troubleshoot/windows-server/identity/enable-ldap-over-ssl-3rd-certification-authority#create-the-certificate-request)

## Nutanix Cloud-init custom config

When creating an Ubuntu VM on Nutanix, you can use a custom script to configure the VM when it gets created.

1.  Create VM according to preference, RAM, CPU etc.
2.  When attaching a Disk, select “Clone fromm image” and select ubuntu-20.04-server-cloudimg-amd64.img or ubuntu-22.04-server-cloudimg-amd64.img
3.  Size the disk according to what size you need for the linux VM.
4.  Attached interfaces and select UEFI boot.
5.  Select your Timezone and then choose the “Cloud-inint (Linux)” option under Guest Customization.
6.  Choose custom script and use the below format

***Replace ${HOSTNAME} with the hostname that you want the VM to have and replace "corp.domain.com" with your existing local domain or whatever domain you want - or leave it out.***

Generate secure password: ***Replace ${PASSWORD} with your plaintext password***

```bash
python3 -c 'import crypt; print(crypt.crypt("${PASSWORD}", crypt.mksalt(crypt.METHOD_SHA512)))'
```

```bash
#cloud-config

hostname: ${HOSTNAME}
fqdn: ${HOSTNAME}.corp.domain.com
timezone: Africa/Johannesburg
growpart:
  mode: auto
  devices: ["/"]
  ignore_growroot_disabled: false
manage_etc_hosts: true
preserve_hostname: false
resize_rootfs: true
package_update: true
package_upgrade: true
# Packages can be installed by uncommenting the below and adding apt-get packages
#packages:
# - docker
# - docker-compose
users:
  - name: localadmin
    gecos: Local Administrator
    primary_group: localadmin
    passwd: "$6$YMlMXEEPDxSp/mo8$pB.4CGxhB/jODvVVHKLdbD/U7bprQh.PchZI2dOufcj1NGkuUfbRHSxgQT3OsnfjPGjkmQXSeyz1KvUQuthcJ0"
    shell: /bin/bash
    lock-passwd: false
    ssh_pwauth: false
    chpasswd: { expire: False }
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: localadmin,sudo
    ssh_authorized_keys:
      - ssh-rsa AAAAB....... localadmin
```


### Static IP

Create the config file to disable the cloud assigned network config

```bash
sudo touch /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

Append `network: {config: disabled}` to the end of that file

```bash
sudo -- bash -c 'echo "network: {config: disabled}" >> /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
```

Save it and edit the `netplan` config file 

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

Network Settings

```bash
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      addresses:
        - 192.168.1.111/24
      nameservers:
        search: [corp.domain.com]
        addresses: [192.168.1.1]
      routes:
        - to: default
          via: 192.168.1.1
```

Then apply the network configuration

```bash
sudo netplan apply
```

## Apache Guacamole Branding

First download the branding file from [here](https://github.com/Zer0CoolX/guacamole-customize-loginscreen-extension)

Install 7zip so that you can extract the .jar file.

Edit the JAR file according to your specifications.

On your WSL/Linux machine, install fastjar

```bash
sudo apt install fastjar
```

Navigate into the root of your extracted file

Run the following to compress and convert it to a JAR file

```bash
jar cMf ../branding.jar *
```

copy the branding.jar file into your gaucamole home extensions folder

```bash
scp -i C:\Users\${USER}\.ssh\id_rsa .\branding.jar localadmin@192.168.1.2:/data/guacamole/home/extensions/branding.jar
```

## Show listening ports (Linux)

To show listening ports, run the following command.

```bash
sudo netstat -tulpn | grep LISTEN
```

If the above does not work, then you can use the following:

```bash
sudo lsof -i -P -n | grep LISTEN
```

## Ubuntu built-in firewall UFW

Let us run through a scenario where we want to allow http, https from anywhere and ssh only from a jumpbox IP address 10.200.90.2

```bash
sudo ufw status
```

You will see that it is inactive

Let us set the default rules

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Now let us allow http and https from anywhere

```bash
sudo ufw allow http
sudo ufw allow https
```

Add the ssh protocol from only 192.168.1.2

```bash
sudo ufw allow from 192.168.1.2 to any port 22
```

Enable the firewall

```bash
sudo ufw enable
```

### Basic commands and rules

First we need to specify the default incoming and outgoing rules

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow certain port and both protocols from any address

```bash
sudo ufw allow 6000
```

Allow port range

```bash
sudo ufw allow 6000-6007
```

Allow a certain port and protocol from any address

```bash
sudo ufw allow 6000/tcp
sudo ufw allow 6000/udp
```

Allow any port form a certain IP address

```bash
sudo ufw allow from 192.168.1.1
```

Allow any port from a subnet

```bash
sudo ufw allow from 192.168.1.0/24
```

Allow from certain IP to a certain port

```bash
sudo ufw allow from 192.168.1.1 to any port 22
```

Allow from a subnet to a certain port

```bash
sudo ufw allow from 192.168.1.0/24 to any port 22
```

Allow from any to an app

```bash
sudo ufw allow http
```

Allow from certain IP to app

```bash
sudo ufw allow from 192.168.1.1 to any app http
```

### Create an application

We are now going to create an application, so if you have multiple port associated to one application, you can create it instead of allowing each port.

Create and edit the file

```bash
sudo nano /etc/ufw/applications.d/zabbix
```

Add the protocols

```bash
[zabbix-server]
title=Zabbix Server
description=Zabbix is an open-source software tool to monitor IT infrastructure such as networks, servers, virtual machines, and cloud services. Zabbix collects and displays basic metrics
ports=10050/tcp

[zabbix-agent]
title=Zabbix Agent
description=Zabbix is an open-source software tool to monitor IT infrastructure such as networks, servers, virtual machines, and cloud services. Zabbix collects and displays basic metrics
ports=10051/tcp
```

Let us first list a few basic commands

show known app list

```bash
sudo ufw app list
```

One being the status of ufw

```bash
sudo ufw status
```

Enable the firewall

```bash
sudo ufw enable
```

Disable the firewall

```bash
sudo ufw disable
```

Reset the firewall

```bash
sudo ufw reset
```

Show numbered ufw rules

```bash
sudo ufw status numbered
```

Delete a numbered rule

```bash
sudo ufw delete 2
```

Delete a rule by port

```bash
sudo ufw delete allow 80
```

Delete a rule by app

```bash
sudo ufw delete allow http
```

## NFS Drive on Docker

To create a NFS share as a persistent drive on docker, we need to first mount the NFS share and manually create the folder (drive name) to which the docker container will map.

```bash
sudo mount :/nfs_share /mnt
```

Create a new folder in the Nutanix files container storage share, replace ${VOLUME} with your desired drive name

```bash
cd /mnt
sudo mkdir ${VOLUME}
cd ~
sudo umount /mnt
```

Once the folder has been created, we can now include a NFS share into our docker-compose file as persistent storage.

```bash
### SAMPLE ###
version: '3.8'

services:
  nginx:
    image: nginx
    volumes:
      - ${VOLUME}:/etc/nginx


...

volumes:
  ${VOLUME}:
    driver_opts:
      type: "nfs"
      o: "addr=,rw,noatime,tcp,nfsvers=4,nolock,soft"
      device: ":/nfs_share"
...
### SAMPLE ##
```

## NinjaOne install on Ubuntu

Generate site installer for the desired site. Copy the installer Download link and download the package.

```bash
wget -O ninja-installer.deb <link>
```

Run the installer 

```bash
sudo dpkg -i ninja-installer.deb
```

Check for files

```bash
ls /opt/NinjaRMMAgent/programfiles
```

Users should see NinjaRMM program files such as `*ninjarmm-linagent*`

Check that the service is up and running

```bash
sudo systemctl status ninjarmm-agent.service
```

## FortiGate IPsec with OSPF routing

### HUB FortiGate

Setup the IPsec Phase 1 and Phase 2 interface. Substitute `${WAN}` and `${TUNNEL}` with the names you need

```bash
config vpn ipsec phase1-interface
    edit "${TUNNEL}"
        set type dynamic
        set interface "${WAN}"
        set peertype any
        set net-device enable
        set proposal aes128-sha256 aes256-sha256 3des-sha256 aes128-sha1 aes256-sha1 3des-sha1
        set add-route disable
        set dpd on-idle
        set auto-discovery-sender enable
        set psksecret sample
        set dpd-retryinterval 5
    next
end
config vpn ipsec phase2-interface
    edit "${TUNNEL}"
        set phase1name "${TUNNEL}"
        set proposal aes128-sha1 aes256-sha1 3des-sha1 aes128-sha256 aes256-sha256 3des-sha256
    next
end
```

Next we set up the IPsec interface IP, this is your “overlay” network

```bash
config system interface
    edit "${TUNNEL}"
        set ip 172.31.252.254 255.255.255.255
        set remote-ip 172.31.252.253 255.255.255.0
    next
end
```

Now we configure the OSPF router

```bash
config router ospf
    set router-id 1.1.1.1
    config area
        edit 0.0.0.0
        next
    end
    config network
        edit 1
            set prefix 172.31.252.0 255.255.255.0
        next
        edit 2
            set prefix 10.201.0.0 255.255.0.0
        next
    end
end
```

### Spoke FortiGate

Configure the phase 1 and phase 2 interfaces, replace `${HUB_IP}` with your HUB IP

```bash
config vpn ipsec phase1-interface
    edit "${TUNNEL}"
        set interface "${WAN}"
        set peertype any
        set net-device enable
        set proposal aes128-sha256 aes256-sha256 aes128-sha1 aes256-sha1
        set add-route disable
        set dpd on-idle
        set auto-discovery-receiver enable
        set remote-gw ${HUB_IP}
        set psksecret sample 
        set dpd-retryinterval 5
    next   
end
config vpn ipsec phase2-interface
    edit "${TUNNEL}"
        set phase1name "${TUNNEL}"
        set proposal aes128-sha1 aes256-sha1 aes128-sha256 aes256-sha256 aes128gcm aes256gcm chacha20poly1305
        set auto-negotiate enable
    next 
end
```

Set the IPSec interface IP

```bash
config system interface
    edit "${TUNNEL}"
        set ip 172.31.252.1 255.255.255.255
        set remote-ip 172.31.252.254 255.255.255.0
    next   
end
```

Now configure the OSPF router

```bash
config router ospf
    set router-id 3.3.3.3
    config area
        edit 0.0.0.0
        next
    end
    config network
        edit 1
            set prefix 172.31.252.0 255.255.255.0
        next
        edit 2
            set prefix 172.21.254.0 255.255.255.0
        next
    end
end
```

### Filtering inbound OSPF advertised routes

To filter inbound routes, you first need to create an access-list

```bash
config router access-list
    edit "block_in"
        config rule
            edit 1
                set action deny
                set prefix 10.200.0.0 255.255.0.0
            next
        end
    next
end
```

and then you add it in your OSPF router

```bash
config router ospf

    set distribute-list-in "block_in"
end
```

### Helpful commands

First of all, best place to find various IPsec designs is to go to [FortiOS Administration guide](https://docs.fortinet.com/document/fortigate/7.2.2/administration-guide)

Get all your OSPF neighbours

```bash
get router info ospf neighbor
```

Get all the OSPF advertised routes

```bash
get router info routing-table ospf
```

## HYCU Backup on Physical Windows

Open powershell on physical machine that needs to be backed up and run the following

```bash
get-executionpolicy
set-executionpolicy RemoteSigned
```

Once you have set the execution policy, we then need to enable WinRM

```bash
winrm quickconfig
```

After that, you should then be able to backup the machine.

> The physical machine would need access to the backup datastore as well

## DNS Entry for Cloudflare Proxy

When using the cloudflare proxy, if you need your onprem DNS to resolve for the cloudflare proxy, you then need to create the CNAME record on your DNS and point it to `{your-fqdn}.cdn.cloudflare.net`

## Nutanix Guest Tools

Installing Nutanix Guest Tools on Linux manually is done by attaching the NGT Disk to the Linux machine.

Once attached to the linux machine, you can confirm that it is there by running the following command.

```bash
blkid -L NUTANIX_TOOLS
```

You should receive a response similar to the below

```bash
/dev/sr0
```

This means that is where the disk is located. We now need to mount the disk

```bash
sudo mount /dev/sr0 /mnt
```

Once it is mounted, we then need to run the installation

```bash
sudo python3 /mnt/installer/linux/install_ngt.py
```

Then unmount it

```bash
sudo umount /mnt
```

> You are all done now
{.is-success}

### SNMP testing

You need to have snmp installed.

```bash
sudo apt install snmp -y
```

Once you have snmp installed, you can then run your snmp commands. The below SNMP command queries 10.10.10.10 using the `private` community with the System Name OID, this OID is shared on ALL snmp devices.

```bash
snmpwalk -v2c -c private 10.10.10.10 1.3.6.1.2.1.1.5
```

You can run the same OID, using snmp v3 with the below command

```bash
snmpwalk -v3  -l authPriv -u snmp-user -a SHA -A "auth-pass"  -x AES -X "private-pass" 10.10.10.10 1.3.6.1.2.1.1.5
```

### Docker PostgreSQL pg_hba.conf

Exec into the PostgreSQL container and edit the `pg_hba.conf` file

```conf

vi var/lib/postgresql/data/pg_hba.conf
```

Make the changes according to the format below and save the config file.

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   postgres        postgres                                trust
host    all             postgres        172.16.0.0/12           md5
host    n8n-db          n8n-user        172.16.0.0/24           md5

```
{: file="var/lib/postgresql/data/pg_hba.conf" }

Press `esc` and then type the below to `write` and `quit`

```bash
:wq
```

Next we want to log into `psql` and reload the `pg_hba.conf` configuration

```bash
psql -U postgres
```

Reload the config

```bash
SELECT pg_reload_conf();
```

Then exit

```bash
exit
```

## dotfiles with starship

```bash
sudo nano ~/install_starship.sh
```

```bash
#!/bin/bash

# Function to install fontconfig if not installed
install_fontconfig() {
    if ! dpkg -l fontconfig &>/dev/null; then
        echo "Installing fontconfig..."
        sudo apt update
        sudo apt install -y fontconfig
    fi
}

# Function to install unzip if not installed
install_unzip() {
    if ! command -v unzip &>/dev/null; then
        echo "Installing unzip..."
        sudo apt update
        sudo apt install -y unzip
    fi
}

# Function to install Nerd Font
install_nerd_font() {
    font_name=$1
    echo "Installing $font_name..."
    # Download and install the chosen Nerd Font
    curl -fLo "$font_name.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$font_name.zip
    unzip -o "$font_name.zip" -d ~/.fonts
    rm "$font_name.zip"
    # Refresh font cache
    fc-cache -fv ~/.fonts
}

# Function to install Starship.rs
install_starship() {
    echo "Installing Starship.rs..."
    sh -c "$(curl -fsSL https://starship.rs/install.sh)"
    # Append 'eval "$(starship init bash)"' to ~/.bashrc
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    # Check if ~/.config directory exists, if not, create it
    if [ ! -d ~/.config ]; then
        mkdir -p ~/.config
    fi
    # Set default preset to gruvbox-rainbow
    starship preset gruvbox-rainbow -o ~/.config/starship.toml
    # Modify Starship configuration
    sed -i 's/\$username\$hostname\\/\$username\\\n\$hostname\\/' ~/.config/starship.toml
    echo -e "\n[hostname]" >> ~/.config/starship.toml
    echo "ssh_only = false" >> ~/.config/starship.toml
    echo 'style = "bg:color_orange fg:color_fg0"' >> ~/.config/starship.toml
    echo 'format = "[@ \$hostname ](\$style)"' >> ~/.config/starship.toml
    echo "disabled = false" >> ~/.config/starship.toml
}

# Main script
echo "Select a Nerd Font to install:"
options=("FiraCode" "JetBrainsMono" "Hack" "Quit")
select opt in "${options[@]}"; do
    case $opt in
        "FiraCode")
            install_fontconfig
            install_unzip
            install_nerd_font "FiraCode"
            install_starship
            break
            ;;
        "JetBrainsMono")
            install_fontconfig
            install_unzip
            install_nerd_font "JetBrainsMono"
            install_starship
            break
            ;;
        "Hack")
            install_fontconfig
            install_unzip
            install_nerd_font "Hack"
            install_starship
            break
            ;;
        "Quit")
            echo "Quitting..."
            exit 0
            ;;
        *) echo "Invalid option";;
    esac
done

```
{: file="~/install_starship.sh" }

```bash
chmod +x insatll_starship.sh
```

```bash
./install_starship.sh
```

Here is the updated starship.toml config that I use:

```bash
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[](color_orange)\
$os\
$username\
$hostname\
[](bg:color_yellow fg:color_orange)\
$directory\
[](fg:color_yellow bg:color_aqua)\
$git_branch\
$git_status\
[](fg:color_aqua bg:color_blue)\
$c\
$rust\
$golang\
$nodejs\
$php\
$java\
$kotlin\
$haskell\
$python\
[](fg:color_blue bg:color_bg3)\
$docker_context\
[](fg:color_bg3 bg:color_bg1)\
$time\
[ ](fg:color_bg1)\
$line_break$character"""

palette = 'gruvbox_dark'

[palettes.gruvbox_dark]
color_fg0 = '#fbf1c7'
color_bg1 = '#005f60'
color_bg3 = '#008083'
color_blue = '#65bbbc'
color_aqua = '#faab36'
color_green = '#98971a'
color_orange = '#fd5901'
color_purple = '#b16286'
color_red = '#cc241d'
color_yellow = '#f78104'

[os]
disabled = false
style = "bg:color_orange fg:color_fg0"

[os.symbols]
Windows = "󰍲"
Ubuntu = "󰕈"
SUSE = ""
Raspbian = "󰐿"
Mint = "󰣭"
Macos = "󰀵"
Manjaro = ""
Linux = "󰌽"
Gentoo = "󰣨"
Fedora = "󰣛"
Alpine = ""
Amazon = ""
Android = ""
Arch = "󰣇"
Artix = "󰣇"
CentOS = ""
Debian = "󰣚"
Redhat = "󱄛"
RedHatEnterprise = "󱄛"

[username]
show_always = true
style_user = "bg:color_orange fg:color_fg0"
style_root = "bg:color_orange fg:color_fg0"
format = '[ $user ]($style)'

[hostname]
ssh_only = false
style = "bg:color_orange fg:color_fg0"
format = '[@ $hostname ]($style)'
disabled = false

[directory]
style = "fg:color_fg0 bg:color_yellow"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = "󰝚 "
"Pictures" = " "
"Developer" = "󰲋 "

[git_branch]
symbol = ""
style = "bg:color_aqua"
format = '[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)'

[git_status]
style = "bg:color_aqua"
format = '[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)'

[nodejs]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[c]
symbol = " "
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[rust]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[golang]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[php]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[java]
symbol = " "
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[kotlin]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[haskell]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[python]
symbol = ""
style = "bg:color_blue"
format = '[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)'

[docker_context]
symbol = ""
style = "bg:color_bg3"
format = '[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:color_bg1"
format = '[[  $time ](fg:color_fg0 bg:color_bg1)]($style)'

[line_break]
disabled = false

[character]
disabled = false
success_symbol = '[](bold fg:color_green)'
error_symbol = '[](bold fg:color_red)'
vimcmd_symbol = '[](bold fg:color_green)'
vimcmd_replace_one_symbol = '[](bold fg:color_purple)'
vimcmd_replace_symbol = '[](bold fg:color_purple)'
vimcmd_visual_symbol = '[](bold fg:color_yellow)'
```
{: file="~/.config/starship.toml" }
