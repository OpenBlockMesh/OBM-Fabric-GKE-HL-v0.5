# Kubernetes Install Script to create a Hyperledger Fabric
# Date : 27-07-2016
# Version 0.1
# Author : James Buckett (james.buckett@au1.ibm.com)
# Commissioned by ANZ Bank under direction of Ben Smillie (Ben.Smillie@anz.com)

#!/bin/bash -x

clear

echo "Create hyperleder namespace"
kubectl create -f ns-hl.yml
sleep 5

export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=hyperledger

echo "Installing Fabric Services"
echo "The long wait is for GKE to assign EXTERNAL-IP"
kubectl create -f svc-hl-vp.yml
sleep 5
kubectl create -f svc-hl-nvp.yml
sleep 5
kubectl create -f svc-hl-nvp-lb.yml
sleep 300
kubectl get services

echo "Installing Validating Peer 0"
kubectl create -f dep-hl-vp0.yml
sleep 120
kubectl get services
kubectl get pods 
kubectl get replicasets

echo "Installing Validating Peers VP1-VP3"
kubectl create -f dep-hl-vp1-3.yml
sleep 60
kubectl get services
kubectl get pods 
kubectl get replicasets

echo "Installing Non Validating Peers NVP0-NVP3"
kubectl create -f dep-hl-nvp.yml
sleep 60
kubectl get services
kubectl get pods 
kubectl get replicasets

./svc-hosts.sh

echo "Done"
