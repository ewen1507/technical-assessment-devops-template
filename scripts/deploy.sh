#!/bin/bash

# Variables
CLUSTER="lambda-cluster"
CLUSTER_REGISTRY_PORT="5005"
DOCKER_IMAGE="lambda-function"
K3D_REGISTRY="localhost:5005"
K8S_NAMESPACE="default"

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