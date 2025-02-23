# How to deploy the project

This tutorial will guide you through the deployment of the project using docker and kubernetes.

## Build the docker image

This will build the docker image with the lambda function and the serverless framework installed. 

```bash
./scripts/build_docker.sh
```

## Run the docker container

This will run the docker container with the lambda function and the serverless framework installed.

```bash
docker run -p 3001:8080 <image_id>
```

## Test docker image locally

This will test the lambda function locally using the docker container.

```bash
./scripts/test_lambda.sh
```

## Deploy kubernetes cluster

This will deploy the kubernetes cluster with the lambda function and push the docker image inside the cluster.

```bash
./scripts/deploy.sh
```

## Test kubernetes cluster

This will test the lambda function deployed in the kubernetes cluster.

```bash
./scripts/invoke_lambda.sh
```

## Deploy monitoring

This will deploy the monitoring stack with fluentd, prometheus and grafana.

```bash
./scripts/deploy_monitoring.sh
```
**Becareful, Kubernetes cluster must be deployed before running this script !**
