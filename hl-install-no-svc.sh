#!/bin/bash -x

# Script to install the fabric and leave the Kubernetes Services in place if already existing.

clear

export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=hyperledger

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

echo "Installing Non Validating Peers NVP0-VP3"
kubectl create -f dep-hl-nvp.yml
sleep 60
kubectl get services
kubectl get pods 
kubectl get replicasets

echo "Done"
