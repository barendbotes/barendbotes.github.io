---
title: HA Docker Swarm with Keepalived
date: 2023-02-19 13:30 +0200
categories: [docker,docker-compose,ha,keepalived]
tags: [docker,docker-compose,security,keepalived]
author: barend
---

![Docker Swarm](https://raw.githubusercontent.com/docker-library/docs/471fa6e4cb58062ccbf91afc111980f9c7004981/swarm/logo.png)

# Docker Swarm

To setup a docker swarm, we need to create 4 linux servers at a minimum. If you want more information on the docker swarm fault tolerances, you can click [here.](https://docs.docker.com/engine/swarm/admin_guide/#add-manager-nodes-for-fault-tolerance)

We will run 3 manager nodes and 1 worker node.

## Requirements

- [**Docker** - *Docker is a set of platform as a service products that use OS-level virtualization to deliver software in packages called containers.*](/posts/random-installations/#docker-and-docker-compose)
- [**Docker-compose** - *Compose is a tool for defining and running multi-container Docker applications.*](/posts/random-installations/#docker-and-docker-compose)
- [**Keepalived** - *Keepalived provides frameworks for ha and load balancing*](/posts/random-installations/#keepalived)
- [**Static IP** - *Ubuntu static IP via Netplan*](/posts/random-configurations/#static-ip)


## Update

```bash
sudo apt update -y
```

## Docker Swam

First we will create a docker swarm cluster on one of the servers

```bash
 docker swarm init --default-addr-pool 172.31.0.0/16 --default-addr-pool-mask-length 24 --advertise-addr eth0 --data-path-addr eth1
```

The reason I created an address pool and mask length is because I do not plan on running hundreds and thousands of applications and networks in the cluster, what I chose allows me to run basically 255 /24 seperate networks within in the 172.31.0.0/16 range, so network-1 will be 172.31.0.0/24, network-2 will be 172.31.1.0./24 and so on. If you are planning to scale massively, then you might want to change those parameters to something else like `--default-addr-pool 10.0.0.0/8 --default-addr-pool-mask-length 24`, this will allow you to run 65 025 /24 networks within the 10.0.0.0/8 range.

You can also mix and match. So if I want to stay within the 172.31.0.0/16 range, but I want to run more networks and I don't plan on scalling workloads, but rather running a lot of different container, then I can look at something like `--default-addr-pool 172.31.0.0/16 --default-addr-pool-mask-length 26` or even `--default-addr-pool 172.31.0.0/16 --default-addr-pool-mask-length 27`

If you do choose to run on less networks and smaller subnets, you should also remember to delete your unused networks, containers and images just as a best practice. You can do so by running:

Networks
```bash
docker network prune
```

Images
```bash
docker image prune -a
```

Volumes
```bash
docker volume prune
```

Once it is done, it will give you a command to add workers, you can ignore that for now.

To get the token for a manager node, you can run the following:

```bash
docker swarm join-token manager
```

You should see something like this:

```
To add a manager to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5bovi9l4fb63hghwqckka0ojbc2kx8pkuyyvifm9pnontupr25-exogi65du4w4ri4flobpg0ssn 192.168.1.2:2377
```

Or use the below to sepatate data plane and control plane traffic ![Docker Separate Data](https://docs.docker.com/engine/swarm/networking/#use-a-separate-interface-for-control-and-data-traffic)

```
docker swarm join \
  --token SWMTKN-1-5bovi9l4fb63hghwqckka0ojbc2kx8pkuyyvifm9pnontupr25-exogi65du4w4ri4flobpg0ssn \
  --advertise-addr eth0 \
  --data-path-addr eth1 \
  192.168.1.2:2377
```

Copy the docker swarm join command and run it on each new manager.

Confirm that you can see all your manager nodes

```bash
docker node ls
```

Once you see everything, you can add your worker node.

```bash
docker swarm join-token worker
```

You should see something like this:

```config
To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5bovi9l4fb63hghwqckka0ojbc2kx8pkuyyvifm9pnontupr25-exogi65du4w4ri4flobpg0ssn 192.168.1.2:2377
```

Copy the docker swarm join command and run it on each new worker.

Confirm that all your nodes show

```bash
docker node ls
```

There we have it, docker swarm all set up. Now we will set up keepalived so that you can access all your services from one IP address. 

## Keepalived

Follow the installation steps and modify the keepalived config file. Remember to change the interface according to your interface name and all the IPs to your relevant IPs.

```bash
sudo nano /etc/keepalived.conf
```

```yaml
vrrp_instance VI_1 {
        state MASTER
        interface eth0 # Enter in correct interface name
        virtual_router_id 10 # Unique to each VRRP instance
        priority 25 # Higher number means higher priority
        advert_int 1
        lb_kind DR
        unicast_src_ip 192.168.1.2 # Local server IP
        unicast_peer{ # Enter in each other server IP
                192.168.1.3 # Server 2
                192.168.1.4 # Server 3
        }
        authentication {
                auth_type PASS
                auth_pass $PASSWORD
        }
        virtual_ipaddress {
                10.200.40.254/24 # VRRP IP address
        }
}
```

Enable the keepalived service and start it.

```bash
sudo systemctl enable keepalived
sudo systemctl start keepalived
```

## Storage for HA

This is a topic that I will go further in to, however, these are the two choices that I will go through another day, NFS and GlusterFS.
