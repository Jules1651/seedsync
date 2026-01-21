#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

# Increased timeout to 120 seconds for slower CI environments
TIMEOUT=${E2E_TIMEOUT:-120}
END=$((SECONDS+TIMEOUT))
ATTEMPT=0

echo "Starting E2E test wait loop (timeout: ${TIMEOUT}s)"

while [ ${SECONDS} -lt ${END} ];
do
  ATTEMPT=$((ATTEMPT+1))
  RESPONSE=$(curl -s --connect-timeout 5 myapp:8800/server/status 2>&1)
  SERVER_UP=$(echo "${RESPONSE}" | python3 ./parse_seedsync_status.py)
  if [[ "${SERVER_UP}" == 'True' ]]; then
    break
  fi
  # Show more detail every 5 attempts
  if [[ $((ATTEMPT % 5)) -eq 0 ]]; then
    echo "E2E Test is waiting for Seedsync server (attempt ${ATTEMPT}, status: ${SERVER_UP})"
    echo "  Response: ${RESPONSE:0:200}"
  else
    echo "E2E Test is waiting for Seedsync server to come up (attempt ${ATTEMPT}, status: ${SERVER_UP})..."
  fi
  sleep 2
done


if [[ "${SERVER_UP}" == 'True' ]]; then
  echo "${green}E2E Test detected that Seedsync server is UP after ${ATTEMPT} attempts${reset}"
  npx playwright test
else
  echo "${red}=========================================${reset}"
  echo "${red}E2E Test failed to detect Seedsync server after ${TIMEOUT} seconds${reset}"
  echo "${red}=========================================${reset}"
  echo "${red}Last response: ${RESPONSE}${reset}"
  echo "${red}Parsed status: ${SERVER_UP}${reset}"
  echo ""
  echo "${red}Attempting to get more debug info...${reset}"
  echo "--- Checking if myapp port is reachable ---"
  nc -zv myapp 8800 2>&1 || echo "Port 8800 not reachable"
  echo "--- Trying direct curl to myapp ---"
  curl -v myapp:8800/server/status 2>&1 || echo "curl failed"
  exit 1
fi
