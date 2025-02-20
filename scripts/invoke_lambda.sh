#!/bin/bash

# Configuration
SERVICE_NAME="lambda-service"
NAMESPACE="default"
PORT=80
EVENT_FILE="events/event.json"

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')

EXPOSED_PORT=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')

if [[ ! -f "$EVENT_FILE" ]]; then
    echo "Error: Event file '$EVENT_FILE' not found!"
    exit 1
fi

echo "Sending request with classic event"
RESPONSE=$(curl -s -d "@events/event.json" -H "Content-Type: application/json" "http://$NODE_IP:$EXPOSED_PORT/2015-03-31/functions/function/invocations")

echo "$RESPONSE"

if echo "$RESPONSE" | grep -q '"statusCode": 200'; then
    echo "Test succeeded!"
else
    echo "Test failed!"
fi

echo -e "\nSending request with missing body event"
RESPONSE=$(curl -s -d "@events/event_missing_body.json" -H "Content-Type: application/json" "http://$NODE_IP:$EXPOSED_PORT/2015-03-31/functions/function/invocations")

echo "$RESPONSE"

if echo "$RESPONSE" | grep -q '"statusCode": 500'; then
    echo "Test succeeded!"
else
    echo "Test failed!"
fi

echo -e "\nSending request with no message event"
RESPONSE=$(curl -s -d "@events/event_no_message.json" -H "Content-Type: application/json" "http://$NODE_IP:$EXPOSED_PORT/2015-03-31/functions/function/invocations")

echo "$RESPONSE"

if echo "$RESPONSE" | grep -q '"statusCode": 400'; then
    echo "Test succeeded!"
else
    echo "Test failed!"
fi