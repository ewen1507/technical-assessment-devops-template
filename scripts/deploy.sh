#!/bin/bash

# Variables
CLUSTER="lambda-cluster"
CLUSTER_REGISTRY_PORT="5005"
DOCKER_IMAGE="lambda-function"
K3D_REGISTRY="localhost:5005"
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

echo -e "\nK3D and kubectl are installed.\n"

echo "Deleting the old Kubernetes cluster..."
k3d cluster delete ${CLUSTER}

echo -e "\nCreating the Kubernetes cluster with local registry..."
k3d cluster create ${CLUSTER} \
    --registry-create lambda-registry:5000 \
    -p ${CLUSTER_REGISTRY_PORT}:5000@loadbalancer \
    -p 3001:3001@loadbalancer

echo -e "\nBuilding and pushing the Docker image..."
docker build -t ${DOCKER_IMAGE} .
docker tag ${DOCKER_IMAGE} ${K3D_REGISTRY}/${DOCKER_IMAGE}
docker push ${K3D_REGISTRY}/${DOCKER_IMAGE}

echo -e "\nDeploying the application on Kubernetes..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/services.yaml

echo -e "\nInstalling MetalLB..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml

echo -e "\nWaiting for MetalLB initialization..."
kubectl wait --namespace metallb-system --for=condition=available deployment --all --timeout=60s
kubectl apply -f k8s/metallb-config.yaml

echo -e "\nChecking the deployment..."
kubectl get pods -n ${K8S_NAMESPACE}
kubectl get services -n ${K8S_NAMESPACE}

EXTERNAL_IP=$(kubectl get service lambda-service -n ${K8S_NAMESPACE} -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

if [ -n "$EXTERNAL_IP" ]; then
    echo -e "\nAPI accessible at: http://$EXTERNAL_IP/2015-03-31/functions/function/invocations"
    exit 0
else
    echo -e "\nWarning: External IP was not assigned. Try with kubectl get service lambda-service."
    exit 1
fi