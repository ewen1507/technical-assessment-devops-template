#!/bin/bash

set -e  # Stoppe le script en cas d'erreur

# 1️⃣ Installation de Helm s'il n'est pas déjà installé
if ! command -v helm &> /dev/null
then
    echo "🔧 Installation de Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "✅ Helm est déjà installé."
fi

kubectl get namespace monitoring >/dev/null 2>&1 || kubectl create namespace monitoring


if kubectl get configmap fluentd-config -n monitoring > /dev/null 2>&1; then
  echo "🟡 ConfigMap fluentd-config already exists, skipping creation."
else
  kubectl create configmap fluentd-config --from-file=conf/fluent.conf -n monitoring
fi


echo "Déploiement de Prometheus..."
kubectl apply -f k8s/prometheus/prometheus-service.yaml
kubectl apply -f k8s/prometheus/prometheus-deployment.yaml
kubectl apply -f k8s/prometheus/prometheus-config.yaml

echo "Déploiement de Fluentd..."
kubectl apply -f k8s/fluentd/fluentd-daemonset.yaml
kubectl apply -f k8s/fluentd/fluentd-rbac.yaml
kubectl apply -f k8s/fluentd/fluentd-configmap.yaml
kubectl apply -f k8s/fluentd/fluentd-service.yaml

echo "Déploiement de Elasticsearch..."
kubectl apply -f k8s/elasticsearch/elasticsearch-service.yaml
kubectl apply -f k8s/elasticsearch/elasticsearch-deployment.yaml

helm repo add grafana https://grafana.github.io/helm-charts

echo "Déploiement de Grafana..."
helm upgrade --install grafana grafana/grafana --namespace monitoring

kubectl port-forward svc/grafana 3000:80 -n monitoring &

PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana Password: $PASSWORD"

echo "📊 Vérification des pods..."
kubectl get pods -n monitoring
kubectl get svc -n monitoring

echo "Accède à Grafana via http://localhost:3000"
echo "✅ Déploiement terminé !"
