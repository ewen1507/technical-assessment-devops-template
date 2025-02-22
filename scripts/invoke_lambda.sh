#!/bin/bash

set -e

# Configuration
SERVICE_NAME="lambda-service"
NAMESPACE="default"
PORT=80
EVENT_FILE="events/event.json"

# Var to store the number of valid tests
VALID_TESTS=0

# Var to store the number of failed tests
FAILED_TESTS=0

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
    VALID_TESTS=$((VALID_TESTS+1))
    echo "Test succeeded!"
else
    FAILED_TESTS=$((FAILED_TESTS+1))
    echo "Test failed!"
fi

echo -e "\nSending request with missing body event"
RESPONSE=$(curl -s -d "@events/event_missing_body.json" -H "Content-Type: application/json" "http://$NODE_IP:$EXPOSED_PORT/2015-03-31/functions/function/invocations")

echo "$RESPONSE"

if echo "$RESPONSE" | grep -q '"statusCode": 400'; then
    VALID_TESTS=$((VALID_TESTS+1))
    echo "Test succeeded!"
else
    FAILED_TESTS=$((FAILED_TESTS+1))
    echo "Test failed!"
fi

echo -e "\nSending request with no message event"
RESPONSE=$(curl -s -d "@events/event_no_message.json" -H "Content-Type: application/json" "http://$NODE_IP:$EXPOSED_PORT/2015-03-31/functions/function/invocations")

echo "$RESPONSE"

if echo "$RESPONSE" | grep -q '"statusCode": 400'; then
    VALID_TESTS=$((VALID_TESTS+1))
    echo "Test succeeded!"
else
    FAILED_TESTS=$((FAILED_TESTS+1))
    echo "Test failed!"
fi

echo -e "\n${COLOR_BGREEN}Valid tests: $VALID_TESTS${COLOR_OFF}"
echo -e "${COLOR_BRED}Failed tests: $FAILED_TESTS${COLOR_OFF}"

if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
fi
exit 0