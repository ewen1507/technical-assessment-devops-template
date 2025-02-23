#!/bin/bash

set -e

SERVICE_NAME="lambda-service"
NAMESPACE="default"
PORT=80
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
EXPOSED_PORT=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}')

COLOR_OFF='\033[0m'
COLOR_BRED='\033[1;31m'
COLOR_BGREEN='\033[1;32m'

VALID_TESTS=0
FAILED_TESTS=0

function check_event_file() {
    if [[ ! -f "$1" ]]; then
        echo -e "${COLOR_BRED}Error: Event file '$1' not found!${COLOR_OFF}"
        exit 1
    fi
}

function run_test() {
    local event_file=$1
    local expected_status=$2
    local test_name=$3

    check_event_file "$event_file"

    echo -e "\nRunning test: $test_name"
    RESPONSE=$(curl -s -d "@$event_file" -H "Content-Type: application/json" "http://$NODE_IP:$EXPOSED_PORT/2015-03-31/functions/function/invocations")

    echo "$RESPONSE"

    if echo "$RESPONSE" | grep -q "\"statusCode\": $expected_status"; then
        echo -e "${COLOR_BGREEN}Test '$test_name' executed successfully${COLOR_OFF}"
        VALID_TESTS=$((VALID_TESTS+1))
    else
        echo -e "${COLOR_BRED}Test '$test_name' failed${COLOR_OFF}"
        FAILED_TESTS=$((FAILED_TESTS+1))
    fi
}

run_test "events/event.json" 200 "Classic event"
run_test "events/event_missing_body.json" 400 "Missing body event"
run_test "events/event_no_message.json" 400 "No message event"
run_test "events/event_empty_body.json" 400 "Empty body event"

echo -e "\n${COLOR_BGREEN}Valid tests: $VALID_TESTS${COLOR_OFF}"
echo -e "${COLOR_BRED}Failed tests: $FAILED_TESTS${COLOR_OFF}"

if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
fi
exit 0
