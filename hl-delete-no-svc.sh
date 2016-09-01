#!/bin/bash -x

# Script to delete the fabric and leave the Kubernetes Services in place if already existing.

clear

export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=hyperledger

echo "Deleting Non Validating Peers NVP1-NVP3"
kubectl  delete -f  dep-hl-nvp.yml

echo "Deleting-Validating Peers VP1-VP3"
kubectl  delete -f  dep-hl-vp1-3.yml

echo "Deleting Validating Peer 0"
kubectl delete -f dep-hl-vp0.yml

kubectl get services
kubectl get pods 
kubectl get replicasets

echo "Done"
