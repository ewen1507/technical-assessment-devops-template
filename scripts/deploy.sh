#!/bin/bash

# Variables
CLUSTER="lambda-cluster"
CLUSTER_REGISTRY_PORT="5005"
K8S_NAMESPACE="default"

echo "Checking if k3d and kubectl are installed..."

if ! command -v k3d &> /dev/null
then
    echo "k3d is not installed. Installing..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

if ! command -v kubectl &> /dev/null
then
    echo "kubectl is not installed. Installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

echo -e "\nK3D and kubectl are installed."

echo "Deleting the old Kubernetes cluster..."
k3d cluster delete ${CLUSTER}

echo "Creating a new Kubernetes cluster..."
k3d cluster create ${CLUSTER} \
    --registry-create lambda-registry:5000 \
    -p ${CLUSTER_REGISTRY_PORT}:5000@loadbalancer \
    -p 3001:3001@loadbalancer


echo -e "\nBuilding and pushing the Docker image..."
docker build -t lambda-function .
docker tag lambda-function localhost:5000/lambda-function
docker push localhost:5000/lambda-function

echo -e "\nDeploying the application on Kubernetes..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/services.yaml

echo -e "\nWaiting for the pod to be ready..."
while [[ $(kubectl get pods -n ${K8S_NAMESPACE} -l app=lambda-function -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo "Pod is not ready yet. Waiting..."
    sleep 5
done

# Récupérer l'IP du noeud Kubernetes (K3D)
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
if [[ -z "$NODE_IP" ]]; then
    echo "ERROR: Failed to retrieve Node IP"
    exit 1
fi

# Récupérer le NodePort du service
NODE_PORT=$(kubectl get svc lambda-service -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
if [[ -z "$NODE_PORT" ]]; then
    echo "ERROR: Failed to retrieve NodePort"
    exit 1
fi

echo -e "\nAPI available at: http://$NODE_IP:$NODE_PORT/2015-03-31/functions/function/invocations"

exit 0
