# OBM-Fabric

DRAFT

The objective of this code is to run Hyperledger under the control of Kubernetes to provide Production-Grade Container Orchestration for Hyperledger containers.

Cluster Setup
Setup a GKE (Google Container Engine) cluster with three nodes
Setup a GCE (Google Compute Engine) instance to run the chain code

Chain Code Setup
Install docker on the GCE instance
Run docker with sudo docker daemon --api-cors-header="*" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
This GCE instance becomes the CORE_VM_ENDPOINT
Record the IP of the GCE instance to eer into the CORE_VM_ENDPOINT environmental variable

