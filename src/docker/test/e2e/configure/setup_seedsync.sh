#!/bin/bash

echo "Waiting for seedsync to be available on port 8800..."
./wait-for-it.sh myapp:8800 -t 120 -- echo "Seedsync app is reachable"

# Wait a moment for seedsync to fully initialize
sleep 2

echo "Setting configuration values..."
curl -sS "http://myapp:8800/server/config/set/general/debug/true" > /dev/null
curl -sS "http://myapp:8800/server/config/set/general/verbose/true" > /dev/null
curl -sS "http://myapp:8800/server/config/set/lftp/local_path/%252Fdownloads" > /dev/null
curl -sS "http://myapp:8800/server/config/set/lftp/remote_address/remote" > /dev/null
curl -sS "http://myapp:8800/server/config/set/lftp/remote_username/remoteuser" > /dev/null
curl -sS "http://myapp:8800/server/config/set/lftp/remote_password/remotepass" > /dev/null
curl -sS "http://myapp:8800/server/config/set/lftp/remote_port/1234" > /dev/null
curl -sS "http://myapp:8800/server/config/set/lftp/remote_path/%252Fhome%252Fremoteuser%252Ffiles" > /dev/null
curl -sS "http://myapp:8800/server/config/set/autoqueue/patterns_only/true" > /dev/null

echo "Sending restart command..."
curl -sS "http://myapp:8800/server/command/restart" > /dev/null

# Give seedsync time to restart
sleep 10

# Wait for port to become available again after restart
./wait-for-it.sh myapp:8800 -t 120 -- echo "Seedsync app is reachable after restart"

# Wait for seedsync to report healthy status
echo "Waiting for healthy status..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    RESPONSE=$(curl -sS --connect-timeout 5 "http://myapp:8800/server/status" 2>&1 || echo '{}')
    SERVER_UP=$(echo "${RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('server',{}).get('up', False))" 2>/dev/null || echo "False")

    if [[ "${SERVER_UP}" == "True" ]]; then
        echo "Seedsync is healthy (attempt $ATTEMPT)"
        break
    fi

    sleep 2
done

if [[ "${SERVER_UP}" != "True" ]]; then
    echo "ERROR: Seedsync did not report healthy status"
    echo "Response: ${RESPONSE}"
    exit 1
fi

echo "Done configuring SeedSync"
