#!/bin/bash
# Force rebuild: 2026-01-21-v3

echo "Waiting for seedsync to be available on port 8800..."
./wait-for-it.sh myapp:8800 -t 120 -- echo "Seedsync app is reachable (before configuring)"

echo "Setting configuration values..."
curl -sS "http://myapp:8800/server/config/set/general/debug/true"; echo
curl -sS "http://myapp:8800/server/config/set/general/verbose/true"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/local_path/%252Fdownloads"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_address/remote"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_username/remoteuser"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_password/remotepass"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_port/1234"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_path/%252Fhome%252Fremoteuser%252Ffiles"; echo
curl -sS "http://myapp:8800/server/config/set/autoqueue/patterns_only/true"; echo

echo "Sending restart command..."
curl -sS "http://myapp:8800/server/command/restart"; echo

# Give seedsync time to save config and begin restarting
echo "Waiting for seedsync to restart..."
sleep 5

# Wait for port to become available again after restart
./wait-for-it.sh myapp:8800 -t 120 -- echo "Seedsync app is reachable (after restart)"

# Now wait for seedsync to actually report healthy status
echo "Waiting for seedsync to report healthy status..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    RESPONSE=$(curl -sS --connect-timeout 5 "http://myapp:8800/server/status" 2>&1 || echo '{}')
    SERVER_UP=$(echo "${RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('server',{}).get('up', False))" 2>/dev/null || echo "False")

    if [[ "${SERVER_UP}" == "True" ]]; then
        echo "Seedsync reports healthy status after $ATTEMPT attempts"
        break
    fi

    echo "Waiting for healthy status (attempt $ATTEMPT/$MAX_ATTEMPTS, current: $SERVER_UP)..."
    sleep 2
done

if [[ "${SERVER_UP}" != "True" ]]; then
    echo "WARNING: Seedsync did not report healthy status after configuration"
    echo "Last response: ${RESPONSE}"
    echo "This may cause E2E tests to fail"
fi

echo
echo "Done configuring SeedSync app"
