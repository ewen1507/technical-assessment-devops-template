#!/bin/bash

set -e

docker build -t lambda-function .

echo "Lambda function docker image built successfully."

# Vérification du mode détaché et du port
if [ "$1" == "-n" ]; then
  if [[ -z "$2" || ! "$2" =~ ^[0-9]+$ || "$2" -lt 1 || "$2" -gt 65535 ]]; then
    echo "Error: Invalid port number. Give a valid port number between 1 and 65535."
    exit 1
  fi

  echo "Running the lambda function in detached mode on port $2"
  docker run -d -p "$2":8080 lambda-function
fi
