---
title: Nutanix SGA Certificate Automation
date: 2022-07-08 18:56 +0200
categories: [automation,certificates]
tags: [letsencrypt,cloudflare,automation,nutanix]
author: barend
---

!['Nutanix'](https://download.logo.wine/logo/Nutanix/Nutanix-Logo.wine.png)

# Nutanix Frame

Since modifying your SGA install is not supported by Nutanix, you will not receive any support on this SGA instance. 

I am using a Cloudflare DNS plugin for certbot for domain confirmation. 

## Certbot Installation

Install Certbot with the DNS plugin. To look for other DNS plugins, you can look [here](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins)

Install epel-release
```bash
sudo yum install epel-release
```

Install Certbot and DNS extension
```bash
sudo yum install certbot certbot-dns-cloudflare -y
```

Create folders for credential file
```bash
mkdir ~/.secrets
mkdir ~/.secrets/certbot
```

Create and edit credential file
```bash
vi ~/.secrets/certbot/cloudflare.ini
```

Credential file contents
```ini
# Cloudflare API credentials used by Certbot
dns_cloudflare_email = <your-email-address>
dns_cloudflare_api_key = <your-api-key>
```

Secure the file
```bash
chmod 600 ~/.secrets/certbot/cloudflare.ini
```

Create secret and permissions as per Certbot Work Docs

Create certificate
```bash
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini -d sga.<domain.com> -d *.sga.<domain.com>
```

This is the same certificate that you can use for your SGA setup, you can find all the required certificates in `/etc/letsencrypt/live/sga.<domain.com>`

## SGA Setup
Install epel-release
```bash
sudo yum install epel-release
```

Create crontab -e
```bash
sudo crontab -e
```

Press “i” for insert and populate the below
```bash
15 3 * * * /usr/bin/certbot renew --quiet --post-host "/usr/sbin/service nginx reload" > /dev/null 2>&1
```
Press “Esc” and the type in below and press enter
```bash
:wq
```

Backup default certificate files
```bash
sudo cp /opt/server.crt /opt/server.crt.bak
sudo cp /opt/server.key /opt/server.key.bak
sudo cp /opt/frame/etc/dhparam.pem /opt/frame/etc/dhparam.pem.bak
```

Create Symbolic links to LetsEncrypt Certificates
```bash
sudo ln -s /etc/letsencrypt/live/sga.<domain.com>/fullchain.pem /opt/server.crt
sudo ln -s /etc/letsencrypt/live/sga.<domain.com>/privkey.pem /opt/server.key
sudo ln -s /etc/letsencrypt/ssl-dhparams.pem /opt/frame/etc/dhparam.pem
```

Check Nginx config reload
```bash
sudo nginx -t
sudo nginx -s reload
```

Finally restart the Nginx service
```bash
sudo systemctl restart nginx
```

Check Status
```bash
sudo systemctl status nginx
```

If all is well, do one final test by rebooting the SGA
```bash
sudo reboot now
```
