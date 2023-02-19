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
sudo yum install epel-release -y
```

Install Certbot, DNS extension and Nano
```bash
sudo yum install certbot certbot-dns-cloudflare nano -y
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

Create the bash script for the certbot renewal and file copy

```bash
sudo nano filesync.sh
```

Copy in the below script, replace the certificate name accordingly

```bash
#!/bin/bash

# path to the source file
src_file="/etc/letsencrypt/live/sga.<domain.com>/fullchain.pem"

# path to the destination file
dst_file="/opt/server.crt"

# log file
log_file="/var/log/copy_server_crt.log"

# run the certbot renew command
certbot renew

# check the exit status of the certbot renew command
if [ $? -eq 0 ]; then
  # certbot renew was successful, compare the source and destination files
  cmp --silent "$src_file" "$dst_file"

  # check the exit status of the cmp command
  if [ $? -eq 0 ]; then
    # the files are the same
    echo "`date`: files are the same, no copy needed" >> "$log_file"
  else
    # the files are different, copy the source file to the destination file
    cp "$src_file" "$dst_file"
    if [ $? -eq 0 ]; then
      # copy was successful
      echo "`date`: copy successful" >> "$log_file"
      # reload Nginx
      systemctl reload nginx
    else
      # copy failed
      echo "`date`: copy failed" >> "$log_file"
    fi
  fi
else
  # certbot renew failed
  echo "`date`: certbot renew failed" >> "$log_file"
fi
```


Create crontab -e

```bash
sudo crontab -e
```

Press “i” for insert and populate the below

```bash
0 0 * * * /bin/bash /home/nutanix/filesync.sh 2>&1
```

Press “Esc” and the type in below and press enter

```bash
:wq
```

Backup default certificate files
```bash
sudo cp /opt/server.crt /opt/server.crt.bak
sudo cp /opt/server.key /opt/server.key.bak
```

Copy the key to the SGA location

```bash
sudo cp /etc/letsencrypt/live/sga.<domain.com>/privkey.pem /opt/server.key
```

Run the script to confirm all is working.

```bash
sudo ./filesync.sh
```

Check Status
```bash
sudo systemctl status nginx
```

If all is well, do one final test by rebooting the SGA
```bash
sudo reboot now
```
