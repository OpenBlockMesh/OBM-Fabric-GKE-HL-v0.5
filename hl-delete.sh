# Kubernetes Delete Script to delete a Hyperledger Fabric
# Date : 22-08-2016
# Version 0.1
# Author : James Buckett (james.buckett@au1.ibm.com)
# Commissioned by ANZ Bank under direction of Ben Smillie (Ben.Smillie@anz.com)

#!/bin/bash -x

clear

echo "Deleting Non-Validating Peers NVP0-NVP3"
kubectl  delete -f  dep-hl-nvp.yml

echo "Deleting Validating Peers VP1-VP3"
kubectl  delete -f  dep-hl-vp1-3.yml

echo "Deleting Validating Peer 0"
kubectl delete -f dep-hl-vp0.yml

echo "Deleting Services"
kubectl delete -f svc-hl-vp.yml
sleep 5
kubectl delete -f svc-hl-nvp.yml
sleep 5
kubectl delete -f svc-hl-nvp-lb.yml

echo "Deleting hyperleger namespace"
kubectl delete -f ns-hl.yml

kubectl get services
kubectl get pods 
kubectl get replicasets

echo "Done"