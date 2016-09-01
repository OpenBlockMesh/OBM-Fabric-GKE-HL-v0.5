# Kubernetes Delete Script for Management Functions
# Date : 22-08-2016
# Version 0.1
# Author : James Buckett (james.buckett@au1.ibm.com)
# Commissioned by ANZ Bank under direction of Ben Smillie (Ben.Smillie@anz.com)

#!/bin/bash -x

clear

export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=management

echo "Deleting Deployment"
kubectl delete --namespace=management -f dep-mgt-prometheus.yml

echo "Deleting Services"
kubectl delete --namespace=management -f svc-mgt-prometheus.yml
sleep 5

echo "Deleting Namespace"
kubectl delete --namespace=management -f ns-mgt.yml

kubectl get --namespace=management services
kubectl get --namespace=management pods 
kubectl get --namespace=management replicasets

echo "Done"
