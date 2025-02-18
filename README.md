# DevOps Technical Assessment

The goal of this technical assessment is to package a small Python function as an AWS Lambda and deploy it in a local Kubernetes cluster. The assessment covers several points:
- Development of the AWS Lambda entrypoint in Python to be invoked as an AWS Lambda function or via an HTTP request.
- Automatic deployment of the function in a local Kubernetes cluster with application monitoring.
- Configuration of Continuous Integration workflows using GitHub Actions to automate testing, packaging, and deployment.
- Code organization between source, test, Continuous Integration (CI) workflows, and Kubernetes manifest files.

There is no single correct answer to this technical assessment. You are free to use any tools to build your solution.

The goal is to cover all aspects of the technical assessment. If you have questions or feel stuck, contact vorteX-io.

## Create a Repository from This Template

Recommended configuration:
- Windows 10/11 machine with [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/install) (WSL) feature enabled.
- VSCode editor installed on Windows and running on WSL (referred to as the 'local' machine in the following instructions).
- Git installed on WSL.
- Docker installed on WSL. We strongly advise against using the Windows version of Docker.

The development environment can be reproduced with the [Devcontainer](https://code.visualstudio.com/docs/devcontainers/containers) feature of VSCode based on `.devcontainer/devcontainer.json`.

The project uses [Poetry](https://python-poetry.org/) as the Python dependency manager, and the dependencies are declared in `pyproject.toml`.

1. Follow [Creating a repository from a template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) to create your own repository.
2. Clone the newly created repository on the WSL local machine.
3. In VSCode, select "Dev Containers: Open in container" to automatically initialize the development environment with Python, Docker in Docker, and other necessary tools.

## 🎯 Organize the Code

You are responsible for organizing your code directories clearly and explicitly (source and test files, CI/CD workflow, etc.).

## 🎯 Set Up the CI/CD

Throughout the assessment, design a step-by-step CI/CD workflow using GitHub Actions to automatically:
- Build the Docker image of the lambda function
- Check coding rules with ruff (already included in the base workflow)
- Test and measure test coverage with pytest and pytest-cov (already included in the base workflow)
- Invoke the lambda function locally using `curl` and check its response as an integration test
- Provision the local Kubernetes cluster and deploy the lambda function
- ...

The CI/CD is initialized with a minimal workflow implementing the check of coding rules and the testing of the lambda function.

## 🎯 Develop the Lambda Function Entrypoint

The Python source directory is `lambda_app`.
Fill the lambda entry point `lambda_handler` to process the string message received as input and send back the processed message.
The `events` directory contains sample event files that can be received by the lambda function.
You are also responsible for developing the corresponding unit tests (we advise using `pytest`).

## 🎯 Check Coding Rules and Test the Lambda Function

Coding rules are checked with `ruff` (coding rules are set in `pyproject.toml`).
Unit testing is run by `pytest` and code coverage with `pytest-cov`.

```bash
ruff check .
pytest --cov-report term-missing --cov=lambda_app python/test/dir
```

You are responsible for developing Python code with the highest possible test coverage score and the lowest possible coding rule errors/warnings.

## 🎯 Build the Application
Fill the `Dockerfile` to package your lambda function using the base image `public.ecr.aws/lambda/python:3.12`.

Write a bash command to build the image from the `Dockerfile`.

```bash
...
```

## 🎯 Check the Local Invocation of the Application

### With curl

Using the Docker image and the small bash script below, check that the lambda function can be invoked locally using `curl` with the event files from `events`.

```bash
docker run -p 3001:8080 ${DOCKER_IMAGE}:latest

curl -d @events/event.json  http://localhost:3001/2015-03-31/functions/function/invocations
```

Propose a solution to automate the check of the `curl` response in the CI.

## 🎯 Deploy Your Application in a Local Kubernetes Cluster

Set up a local Kubernetes cluster using [k3d](https://k3d.io/v5.7.4/) (k3d and kubectl CLI are already installed by the devcontainer configuration).

Deploy your lambda application in the cluster.

**Hints**
1. You can create a local Kubernetes cluster with the following command:
```
k3d cluster create ${CLUSTER} \
    --registry-create ${CLUSTER}:${CLUSTER_REGISTRY_PORT} \ # Create a Docker registry inside the cluster
    -p 5432:5432@loadbalancer # Expose a port outside the cluster (e.g. the Lambda port)
```

2. You can push a Docker image from WSL to the internal cluster registry:
```
docker tag ${DOCKER_IMAGE} localhost:${CLUSTER_REGISTRY_PORT}/${DOCKER_IMAGE} && docker push localhost:${CLUSTER_REGISTRY_PORT}/${DOCKER_IMAGE}
```

Write a small bash script to invoke the lambda function deployed in the cluster using `curl` with the event files from `events`.
```bash
...
```

## 🎯 Automate Kubernetes Cluster and Application Deployment

Propose a solution to automate the cluster provisioning locally and the deployment of the lambda application.

## 🎯 Monitor Your Application

Propose a solution to monitor the deployed lambda application: logs and execution metrics. Include this as part of the automatic deployment.
