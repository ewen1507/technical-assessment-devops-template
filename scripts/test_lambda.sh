#!/usr/bin/bash
# Description: This scripts is used to test the lambda function locally using docker

# Some Colour Codes
COLOR_OFF='\033[0m'
COLOR_BRED='\033[1;31m'
COLOR_BGREEN='\033[1;32m'

# Var to store the number of valid tests
VALID_TESTS=0

# Var to store the number of failed tests
FAILED_TESTS=0

set -e

echo -e "Invoking the lambda function\n"

echo "Test Classic event"
RESPONSE=$(curl -d @events/event.json http://localhost:3001/2015-03-31/functions/function/invocations --silent)

echo "Checking the response"
if echo "$RESPONSE" | grep -q '"statusCode": 200'; then
  echo -e "${COLOR_BGREEN}Test Classic executed successfully\n${COLOR_OFF}"
  VALID_TESTS=$((VALID_TESTS+1))
else
  echo -e "${COLOR_BRED}Test Classic failed\n${COLOR_OFF}"
  FAILED_TESTS=$((FAILED_TESTS+1))
fi

echo "Test missing body event"
RESPONSE=$(curl -d @events/event_missing_body.json http://localhost:3001/2015-03-31/functions/function/invocations --silent)

echo "Checking the response"
if echo "$RESPONSE" | grep -q '"statusCode": 500'; then
  echo -e "${COLOR_BGREEN}Test missing body executed successfully\n${COLOR_OFF}"
  VALID_TESTS=$((VALID_TESTS+1))
else
  echo -e "${COLOR_BRED}Test missing body failed\n${COLOR_OFF}"
  FAILED_TESTS=$((FAILED_TESTS+1))
fi

echo "Test no message event"
RESPONSE=$(curl -d @events/event_no_message.json http://localhost:3001/2015-03-31/functions/function/invocations --silent)

echo "Checking the response"
if echo "$RESPONSE" | grep -q '"statusCode": 400'; then
  echo -e "${COLOR_BGREEN}Test no message executed successfully${COLOR_OFF}"
  VALID_TESTS=$((VALID_TESTS+1))
else
  echo -e "${COLOR_BRED}Test no message failed${COLOR_OFF}"
  FAILED_TESTS=$((FAILED_TESTS+1))
fi

echo -e "\n${COLOR_BGREEN}Valid tests: $VALID_TESTS${COLOR_OFF}"
echo -e "${COLOR_BRED}Failed tests: $FAILED_TESTS${COLOR_OFF}"

if [ $FAILED_TESTS -gt 0 ]; then
  exit 1
fi
exit 0