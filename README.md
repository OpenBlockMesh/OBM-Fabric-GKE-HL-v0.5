# OBM-Fabric

**DRAFT**

The objective of this code is to run Hyperledger under the control of Kubernetes to provide Production-Grade Container Orchestration for Hyperledger containers.

[Kubernetes] (https://github.com/kubernetes/kubernetes)
[Hyperledger] (https://github.com/hyperledger)

This code assumes Kubernetes v1.3 or later.

Four Validating Peers are built so a single failure can be tolerated in the Fabric.

This code will create four Validating Peer Kubernetes Services and four Validating Peer Kubernetes Deployements.

The Validating Peer Services provide stable service address for the Validating Peer Kubernetes Deployments running behind them.

All of the work detailed should be performed on a system with the correct version of kubectl and has access to GKE and GCE.

**Kubernete Cluster Setup**

This guide is build using **GKE** [Google Container Engine](https://cloud.google.com/container-engine) and **GCE** [Google Compute Engine](https://cloud.google.com/compute/)

Setup a GKE (Google Container Engine) cluster with three nodes 
Setup a single GCE (Google Compute Engine) instance to run the chain code

**CORE_VM_ENDPOINT Setup** 

Install docker on the GCE instance 

Start docker on the GCE instance with 

```
sudo docker daemon --api-cors-header="*" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock 
```

This GCE instance becomes the CORE_VM_ENDPOINT 

Record the IP Address of the GCE instance to use with the CORE_VM_ENDPOINT environmental variable

Update the CORE_VM_ENDPOINT_IP value with the GCE Instance IP address.

**Validating Peer Kubernetes Service Setup**

vi svc-hl-vp.yml

```
apiVersion: v1        
kind: Service

metadata:
  # Hyperledger Validating Peer Service Definition 
  name: svc-hl-vp0

spec:
  type: LoadBalancer

  ports:
    # 30303: Peer service listening port
  - name: peer-service
    port: 30303
    targetPort: 30303

    # 30304: CLI process use it for callbacks from chain code
  - name: cli-callback 
    port: 30304
    targetPort: 30304

    # 31315: Event service on validating node
  - name: event-service 
    port: 31315
    targetPort: 31315
    protocol: TCP

    # 5000: REST service listening port
  - name: rest-service 
    port: 5000
    targetPort: 5000
    protocol: TCP

  # Like the selector in the replication controller,
  # but this time it identifies the set of Hyperledger 
  # pods to load balance traffic to.
  selector:
    app: hl-vp0
--- 
apiVersion: v1
kind: Service

metadata:
  # Hyperledger Validating Peer Service Definition 
  name: svc-hl-vp1

spec:
  type: LoadBalancer

  ports:
    # 30303: Peer service listening port
  - name: peer-service
    port: 30303
    targetPort: 30303

    # 30304: CLI process use it for callbacks from chain code
  - name: cli-callback 
    port: 30304
    targetPort: 30304

    # 31315: Event service on validating node
  - name: event-service 
    port: 31315
    targetPort: 31315
    protocol: TCP

    # 5000: REST service listening port
  - name: rest-service 
    port: 5000
    targetPort: 5000
    protocol: TCP

  # Like the selector in the replication controller,
  # but this time it identifies the set of Hyperledger 
  # pods to load balance traffic to.
  selector:
    app: hl-vp1
--- 
apiVersion: v1
kind: Service

metadata:
  # Hyperledger Validating Peer Service Definition 
  name: svc-hl-vp2

spec:
  type: LoadBalancer

  ports:
    # 30303: Peer service listening port
  - name: peer-service
    port: 30303
    targetPort: 30303

    # 30304: CLI process use it for callbacks from chain code
  - name: cli-callback 
    port: 30304
    targetPort: 30304

    # 31315: Event service on validating node
  - name: event-service 
    port: 31315
    targetPort: 31315
    protocol: TCP

    # 5000: REST service listening port
  - name: rest-service 
    port: 5000
    targetPort: 5000
    protocol: TCP

  # Like the selector in the replication controller,
  # but this time it identifies the set of Hyperledger 
  # pods to load balance traffic to.
  selector:
    app: hl-vp2
--- 
apiVersion: v1
kind: Service

metadata:
  # Hyperledger Validating Peer Service Definition 
  name: svc-hl-vp3

spec:
  type: LoadBalancer

  ports:
    # 30303: Peer service listening port
  - name: peer-service
    port: 30303
    targetPort: 30303

    # 30304: CLI process use it for callbacks from chain code
  - name: cli-callback 
    port: 30304
    targetPort: 30304

    # 31315: Event service on validating node
  - name: event-service 
    port: 31315
    targetPort: 31315
    protocol: TCP

    # 5000: REST service listening port
  - name: rest-service 
    port: 5000
    targetPort: 5000
    protocol: TCP

  # Like the selector in the replication controller,
  # but this time it identifies the set of Hyperledger 
  # pods to load balance traffic to.
  selector:
    app: hl-vp3
```

Create the svc-hl-vp.yml via

```
kubectl create -f svc-hl-vp.yml
```

Verify the services have been created successfully and have EXTERNAL-IP addresses assigned.

```
kubectl get services
```

Sample Output

```
NAME                              CLUSTER-IP      EXTERNAL-IP       PORT(S)                                  AGE
kubernetes                        10.95.240.1     <none>            443/TCP                                  23d
svc-hl-vp0                        10.95.246.228   104.199.163.244   30303/TCP,30304/TCP,31315/TCP,5000/TCP   2h
svc-hl-vp1                        10.95.249.13    104.199.163.121   30303/TCP,30304/TCP,31315/TCP,5000/TCP   2h
svc-hl-vp2                        10.95.252.221   104.199.152.169   30303/TCP,30304/TCP,31315/TCP,5000/TCP   2h
svc-hl-vp3                        10.95.251.18    104.199.150.197   30303/TCP,30304/TCP,31315/TCP,5000/TCP   2h
```

**Validating Peer Kubernetes Deployment Setup**

The Validating Peer Deployements are time sensitive in startup and the VP0 has to be started first and given time to settle.

vi dep-hl-vp0.yml

```
apiVersion: extensions/v1beta1
kind: Deployment
#
# Create Service
# kubectl create -f hl-vp.yml
#
# Delete Service
# kubectl delete -f hl-vp.yml
#
metadata:
  name: dep-pod-hl-vp0
  labels:
    # Label of this Deployment Pod
    app: hl-vp0
    
# Replica Specifications
spec:
  # One copy of the fabric in case of consistency issues
  replicas: 1
  selector:
    matchLabels:
      app: hl-vp0
  template:
    metadata:
      labels:
        app: hl-vp0
        
    # Container Specifications
    spec:         
      containers:
      - name: vp0
        
        # Fabric Peer docker image for Hyperledger Project
        # https://github.com/hyperledger/fabric
        image: hyperledger/fabric-peer:latest

        # Readiness Check
        # Due to size of Hyperledger images allow some time for image download
        # The readiness probe will not be called until 5 seconds after the all containers in the pod are created. 
        # The readiness probe must respond within the 1 second timeout.
        readinessProbe:
          httpGet:
            # Ready Check via REST interface to /chain 
            path: "/chain"
            port: 5000
          initialDelaySeconds: 60
          timeoutSeconds: 5
        
        # Start as peer node
        command:
          - "peer"
        args:
          - "node"
          - "start"
        
        # Environment
        env:
          # Set this validating node as root - vp0
          - name: CORE_PEER_ID
            value: "vp0"
          - name: CORE_PEER_ADDRESSAUTODETECT
            value: "false"
          # Service name for the VP0  
          - name: CORE_PEER_ADDRESS
            value: "svc-hl-vp0.default.svc.cluster.local:30303"            
          - name: CORE_PEER_NETWORKID
            value: "dev"
          - name: CORE_LOGGING_LEVEL
            # value: "debug"
            value: chaincode=debug:vm=debug:main=info
            # Enablenable pbft consensus
          - name: CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN
            value: "pbft"
          - name: CORE_PBFT_GENERAL_MODE
            value: "batch"
          - name: CORE_PBFT_GENERAL__BATCHSIZE
            value: "2"           
            # Four nodes minimum for pbft protocol
          - name: CORE_PBFT_GENERAL_N
            value: "4"
          - name: CORE_PBFT_GENERAL_TIMEOUT_REQUEST
            value: "10s"
          - name: CORE_CHAINCODE_STARTUPTIMEOUT
            value: "10000"
          - name: CORE_CHAINCODE_DEPLOYTIMEOUT
            value: "120000"
            # Location for Chain Code Docker Engine
            # Change this value to match your environment
          - name: CORE_VM_ENDPOINT
            value: "http://<CORE_VM_ENDPOINT_IP>:2375"
        
        # Health Check
        livenessProbe:
          httpGet:
            # Health Check via REST interface to /chain 
            path: "/chain"
            port: 5000
          initialDelaySeconds: 30
          timeoutSeconds: 1
        
        # Communication Ports
        ports:
          # Peer service listening port
           - containerPort: 30303
          # CLI process use it for callbacks from chain code
           - containerPort: 30304
          # Event service on validating node
           - containerPort: 31315
          # REST service listening port
           - containerPort: 5000
```

Create the dep-hl-vp0.yml via

```
kubectl create -f dep-hl-vp0.yml
```

Wait 60 seconds for processing to complete

**Create Validating Peer Nodes 1 - 3**

vi hl-vp-v1-3.yml

```
apiVersion: extensions/v1beta1
kind: Deployment

metadata:
  name: dep-pod-hl-vp1
  labels:
    # Label of this Deployment Pod
    app: hl-vp1
    
# Replica Specifications
spec:
  # One copy of the fabric in case of consistency issues
  replicas: 1
  selector:
    matchLabels:
      app: hl-vp1
  template:
    metadata:
      labels:
        app: hl-vp1
        
    # Container Specifications
    spec:         
      containers:
      - name: vp1
        
        # Fabric Peer docker image for Hyperledger Project
        # https://github.com/hyperledger/fabric
        image: hyperledger/fabric-peer:latest
        
        # Readiness Check
        # Due to size of Hyperledger images allow some time for image download
        # The readiness probe will not be called until 5 seconds after the all containers in the pod are created. 
        # The readiness probe must respond within the 1 second timeout.
        readinessProbe:
          httpGet:
            # Ready Check via REST interface to /chain 
            path: "/chain"
            port: 5000
          initialDelaySeconds: 60
          timeoutSeconds: 5
        
        # Start as peer node
        command:
          - "peer"
        args:
          - "node"
          - "start"
        
        # Environment
        env:
          # Set this validating node as root - vp1
          - name: CORE_PEER_ID
            value: "vp1"
          # Root Node Service Location
          - name: CORE_PEER_DISCOVERY_ROOTNODE
            value: "svc-hl-vp0.default.svc.cluster.local:30303"
          - name: CORE_PEER_ADDRESSAUTODETECT
            value: "false"
          # Service name for the vp1  
          - name: CORE_PEER_ADDRESS
            value: "svc-hl-vp1.default.svc.cluster.local:30303"            
          - name: CORE_PEER_NETWORKID
            value: "dev"
          - name: CORE_LOGGING_LEVEL
            # value: "debug"
            value: chaincode=debug:vm=debug:main=info
            # Enablenable pbft consensus
          - name: CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN
            value: "pbft"
          - name: CORE_PBFT_GENERAL_MODE
            value: "batch"
          - name: CORE_PBFT_GENERAL__BATCHSIZE
            value: "2"                
            # Four nodes minimum for pbft protocol
          - name: CORE_PBFT_GENERAL_N
            value: "4"
          - name: CORE_PBFT_GENERAL_TIMEOUT_REQUEST
            value: "10s"
          - name: CORE_CHAINCODE_STARTUPTIMEOUT
            value: "10000"
          - name: CORE_CHAINCODE_DEPLOYTIMEOUT
            value: "120000"
            # Location for Chain Code Docker Engine
            # Change this value to match your environment
          - name: CORE_VM_ENDPOINT
            value: "http://<CORE_VM_ENDPOINT_IP>:2375"
        
        # Health Check
        livenessProbe:
          httpGet:
            # Health Check via REST interface to /chain 
            path: "/chain"
            port: 5000
          initialDelaySeconds: 30
          timeoutSeconds: 1
        
        # Communication Ports
        ports:
          # Peer service listening port
          - containerPort: 30303
          # CLI process use it for callbacks from chain code
          - containerPort: 30304
          # Event service on validating node
          - containerPort: 31315
          # REST service listening port
          - containerPort: 5000
--- 
apiVersion: extensions/v1beta1
kind: Deployment
#
metadata:
  name: dep-pod-hl-vp2
  labels:
    # Label of this Deployment Pod
    app: hl-vp2
    
# Replica Specifications
spec:
  # One copy of the fabric in case of consistency issues
  replicas: 1
  selector:
    matchLabels:
      app: hl-vp2
  template:
    metadata:
      labels:
        app: hl-vp2
        
    # Container Specifications
    spec:         
      containers:
      - name: vp2
        
        # Fabric Peer docker image for Hyperledger Project
        # https://github.com/hyperledger/fabric
        image: hyperledger/fabric-peer:latest
        
        # Readiness Check
        # Due to size of Hyperledger images allow some time for image download
        # The readiness probe will not be called until 5 seconds after the all containers in the pod are created. 
        # The readiness probe must respond within the 1 second timeout.
        readinessProbe:
          httpGet:
            # Ready Check via REST interface to /chain 
            path: "/chain"
            port: 5000
          initialDelaySeconds: 60
          timeoutSeconds: 5        
        
        # Start as peer node
        command:
          - "peer"
        args:
          - "node"
          - "start"
        
        # Environment
        env:
          # Set this validating node as root - vp2
          - name: CORE_PEER_ID
            value: "vp2"
          # Root Node Service Location
          - name: CORE_PEER_DISCOVERY_ROOTNODE
            value: "svc-hl-vp0.default.svc.cluster.local:30303"            
          - name: CORE_PEER_ADDRESSAUTODETECT
            value: "false"
          # Service name for the vp2  
          - name: CORE_PEER_ADDRESS
            value: "svc-hl-vp2.default.svc.cluster.local:30303"            
          - name: CORE_PEER_NETWORKID
            value: "dev"
          - name: CORE_LOGGING_LEVEL
            # value: "debug"
            value: chaincode=debug:vm=debug:main=info
            # Enablenable pbft consensus
          - name: CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN
            value: "pbft"
          - name: CORE_PBFT_GENERAL_MODE
            value: "batch"
          - name: CORE_PBFT_GENERAL__BATCHSIZE
            value: "2"    
            # Four nodes minimum for pbft protocol
          - name: CORE_PBFT_GENERAL_N
            value: "4"
          - name: CORE_PBFT_GENERAL_TIMEOUT_REQUEST
            value: "10s"
          - name: CORE_CHAINCODE_STARTUPTIMEOUT
            value: "10000"
          - name: CORE_CHAINCODE_DEPLOYTIMEOUT
            value: "120000"
            # Location for Chain Code Docker Engine
            # Change this value to match your environment
          - name: CORE_VM_ENDPOINT
            value: "http://<CORE_VM_ENDPOINT_IP>:2375"
        
        # Health Check
        livenessProbe:
          httpGet:
            # Health Check via REST interface to /chain 
            path: "/chain"
            port: 5000
          initialDelaySeconds: 30
          timeoutSeconds: 1
        
        # Communication Ports
        ports:
          # Peer service listening port
          - containerPort: 30303
          # CLI process use it for callbacks from chain code
          - containerPort: 30304
          # Event service on validating node
          - containerPort: 31315
          # REST service listening port
          - containerPort: 5000
--- 
apiVersion: extensions/v1beta1
kind: Deployment

metadata:
  name: dep-pod-hl-vp3
  labels:
    # Label of this Deployment Pod
    app: hl-vp3
    
# Replica Specifications
spec:
  # One copy of the fabric in case of consistency issues
  replicas: 1
  selector:
    matchLabels:
      app: hl-vp3
  template:
    metadata:
      labels:
        app: hl-vp3
        
    # Container Specifications
    spec:         
      containers:
      - name: vp3
        
        # Fabric Peer docker image for Hyperledger Project
        # https://github.com/hyperledger/fabric
        image: hyperledger/fabric-peer:latest
        
        # Readiness Check
        # Due to size of Hyperledger images allow some time for image download
        # The readiness probe will not be called until 5 seconds after the all containers in the pod are created. 
        # The readiness probe must respond within the 1 second timeout.
        readinessProbe:
          httpGet:
            # Ready Check via REST interface to /chain 
            path: "/chain"
            port: 5000
          initialDelaySeconds: 60
          timeoutSeconds: 5        
        
        # Start as peer node
        command:
          - "peer"
        args:
          - "node"
          - "start"
        
        # Environment
        env:
          # Set this validating node as root - vp3
          - name: CORE_PEER_ID
            value: "vp3"
          # Root Node Service Location
          - name: CORE_PEER_DISCOVERY_ROOTNODE
            value: "svc-hl-vp0.default.svc.cluster.local:30303"            
          - name: CORE_PEER_ADDRESSAUTODETECT
            value: "false"
          # Service name for the vp3  
          - name: CORE_PEER_ADDRESS
            value: "svc-hl-vp3.default.svc.cluster.local:30303"            
          - name: CORE_PEER_NETWORKID
            value: "dev"
          - name: CORE_LOGGING_LEVEL
            # value: "debug"
            value: chaincode=debug:vm=debug:main=info
            # Enablenable pbft consensus
          - name: CORE_PEER_VALIDATOR_CONSENSUS_PLUGIN
            value: "pbft"
          - name: CORE_PBFT_GENERAL_MODE
            value: "batch"
          - name: CORE_PBFT_GENERAL__BATCHSIZE
            value: "2"    
            # Four nodes minimum for pbft protocol
          - name: CORE_PBFT_GENERAL_N
            value: "4"
          - name: CORE_PBFT_GENERAL_TIMEOUT_REQUEST
            value: "10s"
          - name: CORE_CHAINCODE_STARTUPTIMEOUT
            value: "10000"
          - name: CORE_CHAINCODE_DEPLOYTIMEOUT
            value: "120000"
            # Location for Chain Code Docker Engine
            # Change this value to match your environment
          - name: CORE_VM_ENDPOINT
            value: "http://<CORE_VM_ENDPOINT_IP>:2375"
        
        # Health Check
        livenessProbe:
          httpGet:
            # Health Check via REST interface to /chain 
            path: "/chain"
            port: 5000
          initialDelaySeconds: 30
          timeoutSeconds: 1
        
        # Communication Ports
        ports:
          # Peer service listening port
          - containerPort: 30303
          # CLI process use it for callbacks from chain code
          - containerPort: 30304
          # Event service on validating node
          - containerPort: 31315
          # REST service listening port
          - containerPort: 5000
```

Verify the creation of the services, pods and deployments 

```
kubectl get services, pods, deployments
```

Sample Output
```
NAME                              READY           STATUS            RESTARTS   AGE
dep-pod-hl-vp0-427017619-7cued    1/1             Running           0          45m
dep-pod-hl-vp1-2743071788-1welj   1/1             Running           0          45m
dep-pod-hl-vp2-3647599664-yihlt   1/1             Running           0          45m
dep-pod-hl-vp3-258143284-eez9b    1/1             Running           0          45m
NAME                              DESIRED         CURRENT           AGE
dep-pod-hl-vp0-427017619          1               1                 2h
dep-pod-hl-vp1-2743071788         1               1                 2h
dep-pod-hl-vp2-3647599664         1               1                 2h
dep-pod-hl-vp3-258143284          1               1                 2h
NAME                              CLUSTER-IP      EXTERNAL-IP       PORT(S)                                  AGE
kubernetes                        10.95.240.1     <none>            443/TCP                                  23d
svc-hl-vp0                        10.95.246.228   104.199.163.244   30303/TCP,30304/TCP,31315/TCP,5000/TCP   2h
svc-hl-vp1                        10.95.249.13    104.199.163.121   30303/TCP,30304/TCP,31315/TCP,5000/TCP   2h
svc-hl-vp2                        10.95.252.221   104.199.152.169   30303/TCP,30304/TCP,31315/TCP,5000/TCP   2h
svc-hl-vp3                        10.95.251.18    104.199.150.197   30303/TCP,30304/TCP,31315/TCP,5000/TCP   2h
```

**Update GCE /etc/hosts**

The GCE instance has no knowledge of the GKE internal DNS used for Service Discovery.

The hosts file on the GCE instance has to be updated to that the chain code can call back to the originating VP.

Execute this command to update the GCE instance.

vi svc-hosts.sh

```
#!/bin/bash -x

gcloud compute --project "your-project-id" ssh --zone "your-zone" "core-vm-endpoint" "sed -i -e 's|.*svc-.*||g' /etc/hosts"

kubectl get svc | awk '{print $3, $1".default.svc.cluster.local"}'|grep svc- > /tmp/svc-hosts

gcloud compute --project "your-project-id" copy-files --zone "your-zone" /tmp/svc-hosts core-vm-endpoint:.

gcloud compute --project "your-project-id" ssh --zone "your-zone" "core-vm-endpoint" "cat svc-hosts >>/etc/hosts"

```


**Verify Operation**

Obtain the name of a running pod
```
kubectl get pods
```

Exec into the pod 
```
kubectl exec -it dep-pod-hl-vp0-<xxxxx> bash
```

Execute Set Chain Code Example
```
peer chaincode deploy -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Function":"init", "Args": ["a","100", "b", "200"]}'
```

Execute Query Chain Code Example
```
a5389f7dfb9efae379900a41db1503fea2199fe400272b61ac5fe7bd0c6b97cf10ce3aa8dd00cd7626ce02f18accc7e5f2059dae6eb0786838042958352b89fb  -c '{"Function": "query", "Args": ["a"]}'
```

**End of Section**

