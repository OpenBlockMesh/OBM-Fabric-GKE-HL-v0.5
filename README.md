**DRAFT**

# The Open Block Mesh Project

The objective of this project is to run Hyperledger under the control of Kubernetes to provide Production-Grade Container Orchestration for Hyperledger containers.

* [Kubernetes](https://github.com/kubernetes/kubernetes)
* [Hyperledger](https://github.com/hyperledger)

This work was commissioned by ANZ Bank which is a member of the Hyperledger Project under the direction of 
* [Ben Smillie](https://github.com/benksmillie) (Ben.Smillie@anz.com)
* Technical Manager - Emerging Technology
* [ANZ Bank](http://www.anz.com)

The goal of this project is to provide a rapid platform to stand up a Hyperledger peer fabric for development purposes under the control of Kubernetes.

The standup of the entire platform should take about six minutes and the tear down about one minute. 

A majority of the time taken to stand up the fabric is GKE assigning external IP addresses.



## Assumptions

This project assumes Kubernetes to be at version 1.3 or later.

This project assumes the hosting environment is Google Container Engine and Google Compute Engine.

All of the work detailed should be performed on a system with the correct version of gcloud and kubectl and has access to GKE and GCE.

As the Hyperledger project currently only supports build from source, this project built two images from source on 26 August 2016.

See : https://github.com/hyperledger/fabric/issues/2336

These images are currently stored on [Docker Hub](https://hub.docker.com/u/jamesbuckett/) under : 
* `jamesbuckett/fabric-peer`
* `jamesbuckett/fabric-baseimage`

The metadate label : version: `08262016` is used to version these images.

These images are used in this project to build the fabric and run the chain code.



## Technical End State Objectives

The fabric will be installed into a `hyperledger` namespace to provide soft multi-tenancy and isolation.

![Overview](https://github.com/OpenBlockMesh/OBM-Fabric/blob/master/obm-overview.png)

Four Validating Peers are built so a single failure can be tolerated in the Fabric.

These Validating Peers are shown as Kubernetes Pods in the diagram above.

They are identified as : `vp0 (root node), vp1, vp2 and vp3`

This fabric uses pbft (Practical Byzantine Fault Tolerance) protocol.   

Four Non Validating Peers are built.

They are identified as : `nvp0, nvp1, nvp2 and nvp3`

These Non Validating Peers are shown as Kubernetes Pods in the diagram above.

Four Validating Peer Kubernetes Services and four Non Validating Peer Kubernetes Services are installed.

These services are identified by a `svc` prefix.

They are : 
* `svc-hl-vp0 - vp0 hyperledger kubernetes service`
* `svc-hl-vp1 - vp1 hyperledger  kubernetes service` 
* `svc-hl-vp2 - vp2 hyperledger  kubernetes service`
* `svc-hl-vp3 - vp3 hyperledger  kubernetes service`
* `svc-hl-nvp0 - nvp0 hyperledger  kubernetes service`
* `svc-hl-nvp1 - nvp1 hyperledger  kubernetes service`
* `svc-hl-nvp2 - nvp2 hyperledger  kubernetes service`
* `svc-hl-nvp3 - nvp3 hyperledger  kubernetes service`
* `svc-hl-nvp-lb - nvp loadbalancer hyperledger  kubernetes service`

The Non Validating Peer loadbalancer service (svc-hl-nvp-lb) provides a way to interact with the fabric via a loadbalancer instead of directly interacting with any of the peer/non-peers in the fabric.

The Kubernetes Services provide stable service address for the Validating and Non Validating Peer Kubernetes Deployments running behind them.

The following lables have been used in this project :
* `version: "08262016"`
* `environment: development`
* `provider: gke` 

This project uses `kind: Deployment` Replica Sets to support upgrades moving forward. 

The metadata label : version: `08262016` is to support future upgrades.



## Files Provided

Hyperledger Namespace Manifest File :
* `ns-hl.yml` - hyperledger namespace definition

Kubernetes Services Manifest Files : 
* `svc-hl-vp.yml` - Validating Peers Kubernetes Service definition
* `svc-hl-nvp.yml` - Non Validating Peers Kubernetes Service definition 
* `svc-hl-nvp-lb.yml` - Non Validating Peers Kubernetes Loadbalancer Service definition

Kubernetes Deployment Manifest Files : 
* `dep-hl-vp0.yml` - vp0 Kubernetes Deployment definition
* `dep-hl-vp1-3.yml`  - vp1-vp3 Kubernetes Deployment definition
* `dep-hl-nvp.yml`  - nvp Kubernetes Deployment definition

Install/Delete scripts : 
* `hl-install.sh` - Hyperledger create fabric
* `hl-delete.sh` - Hyperledger tear down fabric

CORE_VM_ENDPOINT call back IP update script:
* `svc-hosts.sh` - core-vm-endpoint is not part of the Kubernetes DNS and needs to know the call back IP of the fabric.



## Kubernete Cluster Setup

This guide is build using 
* GKE [Google Container Engine](https://cloud.google.com/container-engine) 
* GCE [Google Compute Engine](https://cloud.google.com/compute/)



## Kubernete Project Quotas
Request the following additional quotas:

* Up to 30 In-use IP addresses


### Container Fabric Setup

Sign in to Google Cloud Platform

Create a Project
* `hyperledger`

Setup a GKE (Google Container Engine) cluster with four nodes 

Under the Compute tab..Container Engine
* Create a Container Cluster.
* Give your cluster a meaniful name such as : `hyperledger-cluster`
* Type in a Description : `Development hyperledger cluster`
* Select a zone geographically close to your location to ensure low network latency.
* The default machine type of 1vCPU  and 3.75 GB RAM is sufficient for initial development.
* Consider larger systems if you encounter resource constraints.
* Select `4` under Size, this equates to 4 VM instances.
* One VM Instance (node) for each Validating Peer.

If you have the gcloud already setup you can use the CLI to provision the container cluster with :

`gcloud container clusters create gce-asia-east1 --scopes cloud-platform --zone asia-east1-b --num-nodes 4`

Click on the cluster.

Select Connect to the cluster to get access details.
Copy the value it should be similar to this : 
* `gcloud container clusters get-credentials hyperledger-cluster --zone asia-east1-a --project hyperledger-xxxxxx`

Install gcloud on the linux system you wish to access your cluster from.
* `wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-122.0.0-linux-x86_64.tar.gz`
* `sudo apt-get -y install python`
* `tar -zxvf google-cloud-sdk-122.0.0-linux-x86_64.tar.gz`
* `cd google-cloud-sdk`
* .`/install.sh`

Logout and login for profile changes to take effect.

Setup gcloud : 
* `gcloud auth login`
* Enter the verification code
* `gcloud components install kubectl`
* `gcloud container clusters get-credentials hyperledger-cluster --zone asia-east1-a --project hyperledger-xxxxxx`

Once kubectl is installed use this command to get a list of your nodes `kubectl get nodes`

```
kubectl get nodes
root@ubuntu-1gb-sgp1-01:~/hl/08172016# kubectl get nodes
NAME                                           STATUS    AGE
gke-openblockmesh-default-pool-03a5bc45-6ol7   Ready     24d
gke-openblockmesh-default-pool-03a5bc45-e8qs   Ready     24d
gke-openblockmesh-default-pool-03a5bc45-k4xl   Ready     24d
gke-openblockmesh-default-pool-03a5bc45-n8vc   Ready     24d
```

Label each node to ensure each validating peer runs on a separate node and can tolerate a hardware failure in the fabric.

One Lable on each separate node :
* `node=node-vp0`
* `node=node-vp1`
* `node=node-vp2`
* `node=node-vp3`

Using each node from the kubectl get nodes command above label the nodes on your cluster.

Sample output from kubectl label nodes command.

```
kubectl label nodes gke-openblockmesh-default-pool-03a5bc45-6ol7 node=node-vp0
kubectl label nodes gke-openblockmesh-default-pool-03a5bc45-e8qs node=node-vp1
kubectl label nodes gke-openblockmesh-default-pool-03a5bc45-k4xl node=node-vp2
kubectl label nodes gke-openblockmesh-default-pool-03a5bc45-n8vc node=node-vp3
```

Acces your Kubernetes UI by running these commands

* `kubectl cluster-info` - Get the UI URL
* `kubectl config view` - username and password for UI near the bottom

Note the following values you will need them later for the svc-hosts.sh script :
* project name
* zone 



### CORE_VM_ENDPOINT Setup

Setup a single GCE (Google Compute Engine) instance to run the chain code

This is the CORE_VM_ENDPOINT instance

Under the Compute tab..Compute Engine

* Create Instance
* Instance Name : `core-vm-endpoint`
* Select the same zone as selected above for the hyperledger-cluster cluster.
* The default machine type of 1vCPU  and 3.75 GB RAM is sufficient for initial development.
* Boot Disk :  Ubuntu 16.04 LTS
* Boot Disk Type : Standard Persistent disk
* Size : 20 GB

Install docker on the GCE instance :

Connect to the GCE instance via 
* `gcloud compute --project "hyperledger-xxxxxx" ssh --zone "asia-east1-a" "core-vm-endpoint"`

Due to the following problems with Docker Version 1.12.1, we have to install Docker Version  1.11.
Link : https://github.com/hyperledger/fabric/issues/2044

Use this site for instructions to setup Docker on Ubuntu : 
* https://docs.docker.com/engine/installation/linux/ubuntulinux/

```
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
```

`vi /etc/apt/sources.list.d/docker.list`

```
deb https://apt.dockerproject.org/repo ubuntu-xenial main
```

```
sudo apt-get update
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y
shutdown -r 0
sudo apt-get install docker-engine=1.11.2-0~xenial
sudo apt-mark hold docker-engine
systemctl stop docker
```

Edit the docker unit file to start the docker service with : 
* `ExecStart=/usr/bin/docker daemon --api-cors-header="*" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock`

vi /lib/systemd/system/docker.service
```
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
# ExecStart=/usr/bin/docker daemon -H fd://
ExecStart=/usr/bin/docker daemon --api-cors-header="*" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

[Install]
WantedBy=multi-user.target
```


Start docker on the GCE instance with :

```
`systemctl daemon-reload`
`systemctl start docker.service`
```

Check the status of the Docker Service via systemctl status docker.service
```
root@core-vm-endpoint:~# systemctl status docker.service
● docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2016-08-18 00:55:49 UTC; 4 days ago
     Docs: https://docs.docker.com
 Main PID: 11657 (docker)
    Tasks: 16
   Memory: 19.2M
      CPU: 1min 46.791s
   CGroup: /system.slice/docker.service
           ├─11657 /usr/bin/docker daemon --api-cors-header=* -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
           └─11664 docker-containerd -l /var/run/docker/libcontainerd/docker-containerd.sock --runtime docker-runc --start-timeout 2m

Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.574499941Z" level=info msg="Firewalld running: false"
Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.651978002Z" level=info msg="Default bridge (docker0) is assigned with an
Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.681118710Z" level=warning msg="Your kernel does not support swap memory
Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.682049565Z" level=info msg="Loading containers: start."
Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.682312028Z" level=info msg="Loading containers: done."
Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.682523376Z" level=info msg="Daemon has completed initialization"
Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.682713355Z" level=info msg="Docker daemon" commit=b9f10c9 graphdriver=au
Aug 18 00:55:49 core-vm-endpoint systemd[1]: Started Docker Application Container Engine.
Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.694195634Z" level=info msg="API listen on /var/run/docker.sock"
Aug 18 00:55:49 core-vm-endpoint docker[11657]: time="2016-08-18T00:55:49.694439049Z" level=info msg="API listen on [::]:2375"
```

If you have trouble starting the Docker process you may have to run `sudo usermod -aG docker $(whoami)`


Pull the required images for the chaincode to execute on CORE_VM_ENDPOINT 
```
docker pull jamesbuckett/fabric-baseimage:08262016
docker tag jamesbuckett/fabric-baseimage:08262016 hyperledger/fabric-baseimage:latest
```

Check the images are present via docker images : 
```
root@core-vm-endpoint:~# docker images
REPOSITORY                      TAG                 IMAGE ID            CREATED             SIZE
hyperledger/fabric-baseimage    latest              44cb1e400202        3 days ago          1.688 GB
jamesbuckett/fabric-baseimage   08262016            44cb1e400202        3 days ago          1.688 GB
```

This GCE instance becomes the CORE_VM_ENDPOINT to execute chaincode.

Record the Private IP Address of your GCE instance to use with the CORE_VM_ENDPOINT environmental variable.

Use the `ip a` command to get the IP Address of the `ens4` interface.

Once you have cloned the project in the next section update  the CORE_VM_ENDPOINT value pair with the GCE Instance IP address in the following files.
* `dep-hl-nvp.yml`
* `dep-hl-vp0.yml`
* `dep-hl-vp1-3.yml`

Sample sed command replace x.x.x.x with your GCE address.
```
sed -i 's|value.*2375"|value: "http://x.x.x.x:2375"|g' *yml
```

Replace this value in the yml files.
```
          - name: CORE_VM_ENDPOINT
            value: "http://x.x.x.x:2375"
```

Place your `ens4` interface value in the x.x.x.x in each file.



## Installation

Go to the system running gcloud and kubectl and clone the OBM-Fabric project.

```
git clone https://github.com/OpenBlockMesh/OBM-Fabric.git
cd OBM-Fabric
chmod +x hl-install.sh hl-delete.sh svc-hosts.sh
```

Edit the `svc-hosts.sh` and update with your "your_project" and "your_zone" details

vi svc-hosts.sh
```
gcloud compute --project "your_project" ssh --zone "your_zone" "core-vm-endpoint" "sed -i -e 's|.*svc-.*||g' /etc/hosts"
gcloud compute --project "your_project" copy-files --zone "your_zone" /tmp/svc-hosts core-vm-endpoint:.
gcloud compute --project "your_project" ssh --zone "your_zone" "core-vm-endpoint" "cat svc-hosts >>/etc/hosts"
```



### hl-install.sh

Run `hl-install.sh` to create the hyperledger fabric.

Watch the fabric being built with this command : 
* watch kubectl get --namespace=hyperledger ns,pods,ds,rs,rc,svc

Sample output from `hl-install.sh`

```
root@ubuntu-1gb-sgp1-01:~/hl/08172016# ./hl-install.sh
Create hyperleder namespace
namespace "hyperledger" created
Installing Fabric Services
The long wait is for GKE to assign EXTERNAL-IP
service "svc-hl-vp0" created
service "svc-hl-vp1" created
service "svc-hl-vp2" created
service "svc-hl-vp3" created
service "svc-hl-nvp0" created
service "svc-hl-nvp1" created
service "svc-hl-nvp2" created
service "svc-hl-nvp3" created
service "svc-hl-nvp-lb" created
NAME            CLUSTER-IP     EXTERNAL-IP       PORT(S)                                  AGE
svc-hl-nvp-lb   10.3.244.123   104.199.188.89    30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
svc-hl-nvp0     10.3.244.203   <pending>         30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
svc-hl-nvp1     10.3.249.144   <pending>         30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
svc-hl-nvp2     10.3.246.125   <pending>         30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
svc-hl-nvp3     10.3.246.26    104.199.164.176   30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
svc-hl-vp0      10.3.241.243   104.199.191.194   30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
svc-hl-vp1      10.3.240.112   <pending>         30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
svc-hl-vp2      10.3.245.164   104.199.152.44    30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
svc-hl-vp3      10.3.247.65    <pending>         30303/TCP,30304/TCP,31315/TCP,5000/TCP   5m
Installing Validating Peer 0
deployment "dep-pod-hl-vp0" created
NAME            CLUSTER-IP     EXTERNAL-IP       PORT(S)                                  AGE
svc-hl-nvp-lb   10.3.244.123   104.199.188.89    30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
svc-hl-nvp0     10.3.244.203   <pending>         30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
svc-hl-nvp1     10.3.249.144   <pending>         30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
svc-hl-nvp2     10.3.246.125   130.211.253.150   30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
svc-hl-nvp3     10.3.246.26    104.199.164.176   30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
svc-hl-vp0      10.3.241.243   104.199.191.194   30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
svc-hl-vp1      10.3.240.112   104.199.200.222   30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
svc-hl-vp2      10.3.245.164   104.199.152.44    30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
svc-hl-vp3      10.3.247.65    104.199.189.218   30303/TCP,30304/TCP,31315/TCP,5000/TCP   7m
NAME                              READY     STATUS    RESTARTS   AGE
dep-pod-hl-vp0-4067437311-4l02f   1/1       Running   0          2m
NAME                        DESIRED   CURRENT   AGE
dep-pod-hl-vp0-4067437311   1         1         2m
Installing Validating Peers VP1-VP3
deployment "dep-pod-hl-vp1" created
deployment "dep-pod-hl-vp2" created
deployment "dep-pod-hl-vp3" created
NAME            CLUSTER-IP     EXTERNAL-IP       PORT(S)                                  AGE
svc-hl-nvp-lb   10.3.244.123   104.199.188.89    30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
svc-hl-nvp0     10.3.244.203   <pending>         30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
svc-hl-nvp1     10.3.249.144   104.199.175.195   30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
svc-hl-nvp2     10.3.246.125   130.211.253.150   30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
svc-hl-nvp3     10.3.246.26    104.199.164.176   30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
svc-hl-vp0      10.3.241.243   104.199.191.194   30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
svc-hl-vp1      10.3.240.112   104.199.200.222   30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
svc-hl-vp2      10.3.245.164   104.199.152.44    30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
svc-hl-vp3      10.3.247.65    104.199.189.218   30303/TCP,30304/TCP,31315/TCP,5000/TCP   8m
NAME                              READY     STATUS    RESTARTS   AGE
dep-pod-hl-vp0-4067437311-4l02f   1/1       Running   0          3m
dep-pod-hl-vp1-3787478630-zffen   0/1       Running   0          1m
dep-pod-hl-vp2-3052950555-2cu9b   0/1       Running   0          1m
dep-pod-hl-vp3-4017968160-0j2id   0/1       Running   0          1m
NAME                        DESIRED   CURRENT   AGE
dep-pod-hl-vp0-4067437311   1         1         3m
dep-pod-hl-vp1-3787478630   1         1         1m
dep-pod-hl-vp2-3052950555   1         1         1m
dep-pod-hl-vp3-4017968160   1         1         1m
Installing Non Validating Peers NVP0-NVP3
deployment "dep-pod-hl-nvp0" created
deployment "dep-pod-hl-nvp1" created
deployment "dep-pod-hl-nvp2" created
deployment "dep-pod-hl-nvp3" created
NAME            CLUSTER-IP     EXTERNAL-IP       PORT(S)                                  AGE
svc-hl-nvp-lb   10.3.244.123   104.199.188.89    30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
svc-hl-nvp0     10.3.244.203   107.167.184.115   30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
svc-hl-nvp1     10.3.249.144   104.199.175.195   30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
svc-hl-nvp2     10.3.246.125   130.211.253.150   30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
svc-hl-nvp3     10.3.246.26    104.199.164.176   30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
svc-hl-vp0      10.3.241.243   104.199.191.194   30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
svc-hl-vp1      10.3.240.112   104.199.200.222   30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
svc-hl-vp2      10.3.245.164   104.199.152.44    30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
svc-hl-vp3      10.3.247.65    104.199.189.218   30303/TCP,30304/TCP,31315/TCP,5000/TCP   9m
NAME                               READY     STATUS    RESTARTS   AGE
dep-pod-hl-nvp0-2692831627-5icp2   0/1       Running   0          1m
dep-pod-hl-nvp1-1913018177-0prl0   0/1       Running   0          1m
dep-pod-hl-nvp2-3149682503-uygb5   0/1       Running   0          1m
dep-pod-hl-nvp3-92362573-9uh2d     0/1       Running   0          1m
dep-pod-hl-vp0-4067437311-4l02f    1/1       Running   0          4m
dep-pod-hl-vp1-3787478630-zffen    1/1       Running   0          2m
dep-pod-hl-vp2-3052950555-2cu9b    1/1       Running   0          2m
dep-pod-hl-vp3-4017968160-0j2id    1/1       Running   0          2m
NAME                         DESIRED   CURRENT   AGE
dep-pod-hl-nvp0-2692831627   1         1         1m
dep-pod-hl-nvp1-1913018177   1         1         1m
dep-pod-hl-nvp2-3149682503   1         1         1m
dep-pod-hl-nvp3-92362573     1         1         1m
dep-pod-hl-vp0-4067437311    1         1         4m
dep-pod-hl-vp1-3787478630    1         1         2m
dep-pod-hl-vp2-3052950555    1         1         2m
dep-pod-hl-vp3-4017968160    1         1         2m
svc-hosts                                                                                                       100%  518     0.5KB/s   00:00
Done
```



### hl-delete.sh

Run `hl-delete.sh` to tear down the fabric.

Sample output from `hl-delete.sh`

```
Deleting Non-Validating Peers NVP0-NVP3
deployment "dep-pod-hl-nvp0" deleted
deployment "dep-pod-hl-nvp1" deleted
deployment "dep-pod-hl-nvp2" deleted
deployment "dep-pod-hl-nvp3" deleted
Deleting Validating Peers VP1-VP3
deployment "dep-pod-hl-vp1" deleted
deployment "dep-pod-hl-vp2" deleted
deployment "dep-pod-hl-vp3" deleted
Deleting Validating Peer 0
deployment "dep-pod-hl-vp0" deleted
Deleting Services
service "svc-hl-vp0" deleted
service "svc-hl-vp1" deleted
service "svc-hl-vp2" deleted
service "svc-hl-vp3" deleted
service "svc-hl-nvp0" deleted
service "svc-hl-nvp1" deleted
service "svc-hl-nvp2" deleted
service "svc-hl-nvp3" deleted
service "svc-hl-nvp-lb" deleted
Deleting hyperleger namespace
namespace "hyperledger" deleted
Done
```


Change to `hyperledger` namespace
```
export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=hyperledger
```

## Verify Operation

Obtain the name of a running pod
```
kubectl get pods
```

Exec into the pod (use a pod name from kubectl get pods) 
```
kubectl exec -it dep-pod-hl-vp0-<xxxxx> bash
```

Execute Set Chain Code Example
```
peer chaincode deploy -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Function":"init", "Args": ["a","100", "b", "200"]}'
```

It may take up to a minute for the chain code containers to start on `core-vm-endpoint'

You can check that the chaincode containers are running by `docker ps -a` on the `core-vm-endpoint`

Execute Query Chain Code Example
```
peer chaincode query -n a5389f7dfb9efae379900a41db1503fea2199fe400272b61ac5fe7bd0c6b97cf10ce3aa8dd00cd7626ce02f18accc7e5f2059dae6eb0786838042958352b89fb  -c '{"Function": "query", "Args": ["a"]}'
```

Sample Output

```
23:20:03.785 [main] chaincodeInvokeOrQuery -> INFO 001 Successfully queried transaction: chaincodeSpec:<type:GOLANG chaincodeID:<name:"a5389f7dfb9efae379900a41db1503fea2199fe400272b61ac5fe7bd0c6b97cf10ce3aa8dd00cd7626ce02f18accc7e5f2059dae6eb0786838042958352b89fb" > ctorMsg:<function:"query" args:"a" > >
100
23:20:03.786 [main] main -> INFO 002 Exiting.....
```



## Monitoring

Included in this pattern is a [Prometheus](https://github.com/prometheus) template to monitor the Hyperledger application.

The files provided are : 
* `mgt-install.sh` - Deployment script for Management Pattern
* `mgt-delete.sh` - Tear down script for Management Pattern
* `ns-mgt.yml` - Management Pattern Namespace
* `dep-mgt-prometheus.yml` - Prometheus deployment manifest
* `svc-mgt-prometheus.yml` - Prometheus service definition

Make `mgt-install.sh` and `mgt-delete.sh` executable.

* `chmod +x mgt-install.sh`
* `chmod +x mgt-delete.sh`

To install run `mgt-install.sh` and to uninstall run `mgt-delete.sh`.

```
Create management namespace
namespace "management" created
Installing Management Services
service "svc-mgt-prometheus" created
NAME                 CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
svc-mgt-prometheus   10.119.245.212   <pending>     9090/TCP   6s
Installing Prometheus
deployment "prometheus" created
configmap "prometheus-config" created
NAME                 CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
svc-mgt-prometheus   10.119.245.212   <pending>     9090/TCP   17s
NAME                          READY     STATUS              RESTARTS   AGE
prometheus-1813641350-gzr21   0/1       ContainerCreating   0          12s
NAME                    DESIRED   CURRENT   AGE
prometheus-1813641350   1         1         12s
Done

```

Once deployed use `kubectl get --namespace=management ns,pods,ds,rs,rc,svc' to determine the status of the components.

```
root@ibm-ubuntu-1gb-sgp1-01:~/mgt# kubectl get --namespace=management ns,pods,ds,rs,rc,svc
NAME                          STATUS           AGE
default                       Active           6d
hyperledger                   Active           1d
kube-system                   Active           6d
management                    Active           6m
NAME                          READY            STATUS              RESTARTS   AGE
prometheus-1813641350-gzr21   0/1              ContainerCreating   0          6m
NAME                          DESIRED          CURRENT             AGE
prometheus-1813641350         1                1                   6m
NAME                          CLUSTER-IP       EXTERNAL-IP         PORT(S)    AGE
svc-mgt-prometheus            10.119.245.212   X.X.X.X      9090/TCP   6m

```

The UI for Prometheus can be accessed on the EXTERNAL-IP  of the `http://<EXTERNAL-IP >:9090`

One you log in you can use the following search expressions :

How much memory are the hyperledger containers in the hyperledger namespace using

* `sum(container_memory_usage_bytes{kubernetes_namespace="hyperledger"})`

API server reports its overall request count.

* `sum(rate(apiserver_request_count[1m]))`

Credit to this [article](https://coreos.com/blog/monitoring-kubernetes-with-prometheus.html
) for the Prometheus content.


## Miscellaneous  

Miscellaneous useful alias commands.

`alias kube-hl='kubectl get --namespace=hyperledger ns,pods,ds,rs,rc,svc`

`alias kube-mgt='kubectl get --namespace=management ns,pods,ds,rs,rc,svc`


Miscellaneous useful commands.

Switch context to `hyperledger` namespace.

`export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')`

`kubectl config set-context $CONTEXT --namespace=hyperledger`




## Troubleshooting 

If you experience any issues please check the hosts file on the core-vm-endpoint.

If there was a delay in assigning external IP addresses sometimes there will be "PENDING" entries in the hosts file as opposed to the correct IP entries.

Execute "kubectl get svc" to a list of the correct IP addresses to place in the /etc/hosts file



# End of Section
