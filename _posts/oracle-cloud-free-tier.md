---
title: Oracle Cloud Free-Tier Signup
date: 2022-07-23 11:30 +0200
categories: [documentation,cloud,hosting,linux]
tags: [oracle,server,virtual,vm,ubuntu]
author: barend
---

![Oracle](https://images.saasworthy.com/oracleanalyticscloud_11516_logo_1606733044_fqrte.png)

# Oracle Cloud Setup

Today we are going to go through - how to setup Oracle Cloud free-tier. This will give us access to their amazing always free compute instance offering.

## Hardware resources

You get a hefty amount of resources for free, keep in mind that this is not like Google, AWS or Azure's free compute where you only get it  for 12 months, this is on their always-free tier. So as long as they do not change anything, you should be good for a while.

You get the following resources for free:

Arm-based Ampere A1 cores and 24 GB of memory usable as 1 VM or up to 4 VMs with 3,000 OCPU hours and 18,000 GB hours per month
2 Block Volumes Storage, 200 GB total. If you want a more detailed breakdown, you can click [here](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) to head to the oracle documentation

We will only focus on 1 `virtual` machine with:

- 4x vCPU
- 24GB RAM
- 200GB Storage

## Sign Up

First thing, first. We need to actually sign up to the Oracle Free Tier service. To do that, you can click [here](https://signup.oraclecloud.com/)

This will take you to the sign up page where you need to enter in your details, name, surname, email and region - also confirm that you are not a robot.

Keep in mind that there might still be availability issues in your region, I had to wait a week or so before the Ampere A1 Compute instances were available. I think it should be rolled out almost everywhere.

You will have to go through confirmation emails, most likely some marketing confirmation stuff etc. etc...

## Account Creation

After you have confirmed your email, you will be taken to the account confirmation page. Here you will enter in a password, cloud account name and your home region. 

The home region is where your compute resource will sit, so if want to use this for production, maybe put it somewhere central to your location or depending on your target market, put it in EU or America.

We use CloudFlare in any case, so it routes via their CDN when we proxy our website/webapp via CloudFlare.

## Creating VM Instance

- To create your `VM` instance, you need to go to the top left burger menu, select `Compute` and then `Instances` in the right pop-up menu. In the `Instances` view, you can create a new `instance`.
- Next, you will need to give your `instance` a name, or you can keep it as it is. This is just to identify the `instance` if you have many.
- Make sure your `Availability domain` has the `Always Free-eligible` tag in the `Placement` category.
- Next, `edit` the `Image and shape` category, choose to `Change image ` and select `Canonical Ubuntu`. It should also be `Always Free-eligible`
- Once you selected and changed the image, go `Change shape`make sure `Virtual machine` instance type is selected and select `Ampere` share series.
- Change the OCPU count to max (`4`) and the RAM to max (`24GB`) and make sure the configuration is selected.
- You can leave everything in `Networking` category default. We will get to the ports later.
- If you have not generated your own `SSH` key pair yet, you can use this `instance` setup to generate it for you. So you either save the `private key` and the `public key` for future use, or you follow my [guide](/posts/random-installations/#ssh-keys) on how to create your own `SSH` key pair and upload the pub file.
- In the `Boot volume` category, you need to `Specify a custom boot volume size` and make it `100GB`. You can also select `Use in-transit encryption` to secure your data in-transit.
- Now the magical button `Create` this should create your `instance` and boot it up.

## Accessing your Cloud Server

Once the `instance` is up and running, you can click on the `instance` name and you will be taken to the `vm` details. The only thing you need to get from the details page is the `Public IP address` and the `username`.

To access the `vm`, you need the private key in your `.ssh` directory. I know there are more ways of hosting multiple `ssh` keys etc. This is just the most simple way of doing it. The `private key` that you saved earlier, copy the key into a safe directory as a backup and then also save another copy in `~\.ssh\` in `Windows` and `~/.ssh/` in `Linux`. This is on your personal computer that you are using to access the Cloud server.

If you want to copy and paste, you can open up your terminal on `Linux` or `Command Prompt` on `Windows`.

Open up `Command Prompt` either by searching for `cmd` in the `Windows` start menu or by pressing the `windows` key and the `r` key
```cmd
mkdir ~\.ssh
cp ~\Downloads\ssh-key*.key ~\.ssh\id_rsa
```

For `Linux` you can use the below to copy it to your `ssh` directory
```bash
mkdir ~/.ssh
cp ~/Downloads/ssh-key*.key ~/.ssh/id_rsa
```

Once the keys have been copied to your `ssh` directory, you can then log into your cloud `vm` `instance`

In windows `cmd` or linux `terminal` you can use the following, make sure you replace `oracle-cloud-instance-ip` with your public IP from the `instance` details in Oracle
```
ssh ubuntu@oracle-cloud-instance-ip
```

You should now be logged into your cloud `virtual server`. :partying_face:Congratulations!

Take a breather and just think of what you have done. You have just created an account with an enterprise cloud hosting provider and successfully spun an `Ubuntu` cloud server!

## Docker installation

Before we install `docker`, we need to create another user account. We need to do this because it is not ideal to use the `ubuntu` account.

First we create the user
```bash
 sudo adduser myadminaccount
```
Enter in a password and go through the rest of the prompts either by leaving them blank or filling in the information.

Next, we need to add the user to the `sudo` group for `sudo` access
```bash
sudo usermod -aG sudo myadminaccount
```

We need to copy in the `ssh` key
```bash
sudo mkdir /home/myadminaccount/.ssh
sudo cp .ssh/authorized_keys /home/myadminaccount/.ssh/authorized_keys
sudo chown -R myadminaccount:myadminaccount /home/myadminaccount/.ssh
```

You can confirm that everything is working by switching to the `myadminaccount` account
```bash
sudo -u myadminaccount
```

Once in the newly created account, confirm that you can run sudo commands
```bash
sudo ip address
```

This should display your `vm` internal ip address.

Now confirm that your `ssh` keys work by going back to your own computer, and `ssh` using your new account name
```
ssh myadminaccount@oracle-cloud-instance-ip
```

It should log you straight in. You not want to lock the `ubuntu` account. So while logged into the `Ubuntu` cloud server with your new account run the following to disable the default `ubuntu` account
```bash
sudo passwd -l ubuntu
```

We are now all done setting up the `Ubuntu` cloud server.

## Installations to consider

- [**Docker and Docker-compose** - *How to install docker and docker-compose*](/posts/random-installations/#docker-and-docker-compose)
- [**Traefik with Crowdsec** - *How to install Traefik and Crowdsec on Docker*](/posts/docker-traefik-crowdsec/#the-repo)