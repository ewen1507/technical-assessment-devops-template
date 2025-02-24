#!/bin/bash

set -e

if ! command -v helm &> /dev/null
then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "Helm already installed."
fi

kubectl get namespace monitoring >/dev/null 2>&1 || kubectl create namespace monitoring


if kubectl get configmap fluentd-config -n monitoring > /dev/null 2>&1; then
  echo "ConfigMap fluentd-config already exists, skipping creation."
else
  kubectl create configmap fluentd-config --from-file=conf/fluent.conf -n monitoring
fi


echo "Deploying Prometheus..."
kubectl apply -f k8s/prometheus/prometheus-service.yaml
kubectl apply -f k8s/prometheus/prometheus-deployment.yaml
kubectl apply -f k8s/prometheus/prometheus-config.yaml

echo "Deploying Fluentd..."
kubectl apply -f k8s/fluentd/fluentd-daemonset.yaml
kubectl apply -f k8s/fluentd/fluentd-rbac.yaml
kubectl apply -f k8s/fluentd/fluentd-configmap.yaml
kubectl apply -f k8s/fluentd/fluentd-service.yaml

echo "Deploying Elasticsearch..."
kubectl apply -f k8s/elasticsearch/elasticsearch-service.yaml
kubectl apply -f k8s/elasticsearch/elasticsearch-deployment.yaml

helm repo add grafana https://grafana.github.io/helm-charts

echo "Deploying Grafana..."
helm upgrade --install grafana grafana/grafana --namespace monitoring

echo "Waiting for Grafana to be ready..."
until kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath="{.items[0].status.phase}" | grep -q "Running"; do
  echo "Grafana is not ready yet, waiting..."
  sleep 5
done

kubectl port-forward svc/grafana 3000:80 -n monitoring &

PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana Password: $PASSWORD"

echo "Verifying the deployment..."
kubectl get pods -n monitoring
kubectl get svc -n monitoring

echo "Access Grafana at http://localhost:3000"
echo "Default credentials: admin/$PASSWORD"
echo "Deployed monitoring stack successfully."