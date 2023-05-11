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

## Frame SGA Certificate Automation

***Replace "domain.com" with your own domain. Keep in mind that the "sga" child domain can be anything you want.***

Install epel-release

```bash
sudo yum install epel-release
```

Install Certbot and DNS extension

```bash
sudo yum install certbot certbot-dns-cloudflare -y
```

Install Nano text editor

```bash
sudo yum install nano -y
```

Create secret and permissions as per [Certbot Work Docs](/posts/random-configurations/#certbot-ubuntu-certificate-requests-90-day)

Create certificate

```bash
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini -d *.sga.domain.com
```

Create the bash script for the certbot renewal and file copy

```bash
sudo nano filesync.sh
```

Copy in the below script, replace the certificate name accordingly

```bash
#!/bin/bash

# path to the source file
src_file="/etc/letsencrypt/live/sga.domain.com/fullchain.pem"
src_file_key="/etc/letsencrypt/live/sga.domain.com/privkey.pem"

# path to the destination file
dst_file="/opt/server.crt"
dst_file_key="/opt/server.key"

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
    cp "$src_file_key" "$dst_file_key"
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

Make the filesync script executable

```bash
sudo chmod +x filesync.sh
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
sudo cp /opt/frame/etc/dhparam.pem /opt/frame/etc/dhparam.pem.bak
```

Copy the newly created certificate files to the correct directory

```bash
sudo cp /etc/letsencrypt/live/sga.domain.com/fullchain.pem /opt/server.crt
sudo cp /etc/letsencrypt/live/sga.domain.com/privkey.pem /opt/server.key
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