#!/bin/bash

COLOR_OFF='\033[0m'
COLOR_BRED='\033[1;31m'
COLOR_BGREEN='\033[1;32m'

VALID_TESTS=0
FAILED_TESTS=0

set -e

PORT=3001

if [ "$1" == "-n" ]; then
  if [[ -z "$2" || ! "$2" =~ ^[0-9]+$ || "$2" -lt 1 || "$2" -gt 65535 ]]; then
    echo -e "${COLOR_BRED}Error: Please provide a valid port (between 1 and 65535).${COLOR_OFF}"
    exit 1
  fi
  PORT=$2
fi

echo -e "Invoking the lambda function on port $PORT\n"

function run_test() {
  local event_file=$1
  local expected_status=$2
  local test_name=$3

  echo "Running test: $test_name"
  RESPONSE=$(curl -d @"$event_file" http://localhost:$PORT/2015-03-31/functions/function/invocations --silent)

  echo "Checking the response"
  if echo "$RESPONSE" | grep -q "\"statusCode\": $expected_status"; then
    echo -e "${COLOR_BGREEN}Test '$test_name' executed successfully\n${COLOR_OFF}"
    VALID_TESTS=$((VALID_TESTS+1))
  else
    echo -e "${COLOR_BRED}Test '$test_name' failed\n${COLOR_OFF}"
    FAILED_TESTS=$((FAILED_TESTS+1))
  fi
}

run_test "events/event.json" 200 "Classic event"
run_test "events/event_missing_body.json" 400 "Missing body event"
run_test "events/event_no_message.json" 400 "No message event"

echo -e "\n${COLOR_BGREEN}Valid tests: $VALID_TESTS${COLOR_OFF}"
echo -e "${COLOR_BRED}Failed tests: $FAILED_TESTS${COLOR_OFF}"

if [ $FAILED_TESTS -gt 0 ]; then
  exit 1
fi
exit 0
