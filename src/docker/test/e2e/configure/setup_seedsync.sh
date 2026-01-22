#!/bin/bash
# Force rebuild: 2026-01-22-v6

echo "Waiting for seedsync to be available on port 8800..."
./wait-for-it.sh myapp:8800 -t 120 -- echo "Seedsync app is reachable (before configuring)"

# Wait a moment for seedsync to fully initialize
sleep 2

# Check initial status
echo "=== Initial status before configuration ==="
curl -sS "http://myapp:8800/server/status" || echo "Failed to get status"
echo ""

echo "=== Setting configuration values ==="
curl -sS "http://myapp:8800/server/config/set/general/debug/true"; echo
curl -sS "http://myapp:8800/server/config/set/general/verbose/true"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/local_path/%252Fdownloads"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_address/remote"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_username/remoteuser"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_password/remotepass"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_port/1234"; echo
curl -sS "http://myapp:8800/server/config/set/lftp/remote_path/%252Fhome%252Fremoteuser%252Ffiles"; echo
curl -sS "http://myapp:8800/server/config/set/autoqueue/patterns_only/true"; echo

# Check status after config (should still be down, but config should be set)
echo "=== Status after configuration (before restart) ==="
curl -sS "http://myapp:8800/server/status" || echo "Failed to get status"
echo ""

# Verify config was set - show ALL config values to check for <replace me>
echo "=== Full config (checking for <replace me> values) ==="
curl -sS "http://myapp:8800/server/config/get" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for section, values in d.items():
    for key, val in values.items():
        marker = ' <-- INCOMPLETE!' if val == '<replace me>' else ''
        print(f'{section}.{key} = {val}{marker}')
" 2>/dev/null || echo "Failed to parse config"

echo "=== Sending restart command ==="
curl -sS "http://myapp:8800/server/command/restart"; echo

# Give seedsync time to save config, shutdown old server, and begin restarting
# The restart involves: persist config, terminate webapp, join threads, exit process
echo "Waiting for seedsync to restart (sleeping 10s)..."
sleep 10

# Wait for port to become available again after restart
echo "=== Waiting for port 8800 after restart ==="
./wait-for-it.sh myapp:8800 -t 120 -- echo "Seedsync app is reachable (after restart)"

# Now wait for seedsync to actually report healthy status
echo "Waiting for seedsync to report healthy status..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    RESPONSE=$(curl -sS --connect-timeout 5 "http://myapp:8800/server/status" 2>&1 || echo '{}')
    SERVER_UP=$(echo "${RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('server',{}).get('up', False))" 2>/dev/null || echo "False")
    ERROR_MSG=$(echo "${RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('server',{}).get('error_msg', 'none'))" 2>/dev/null || echo "parse error")

    if [[ "${SERVER_UP}" == "True" ]]; then
        echo "Seedsync reports healthy status after $ATTEMPT attempts"
        break
    fi

    echo "Waiting for healthy status (attempt $ATTEMPT/$MAX_ATTEMPTS, up=$SERVER_UP, error=$ERROR_MSG)..."
    sleep 2
done

if [[ "${SERVER_UP}" != "True" ]]; then
    echo "ERROR: Seedsync did not report healthy status after configuration"
    echo "Last response: ${RESPONSE}"

    # Show full config after restart to see what values are still <replace me>
    echo "=== Config after restart (checking for incomplete values) ==="
    curl -sS "http://myapp:8800/server/config/get" | python3 -c "
import sys, json
d = json.load(sys.stdin)
incomplete = []
for section, values in d.items():
    for key, val in values.items():
        if val == '<replace me>':
            incomplete.append(f'{section}.{key}')
        print(f'{section}.{key} = {val}')
if incomplete:
    print(f'INCOMPLETE VALUES: {incomplete}')
else:
    print('All config values are set (no <replace me> found)')
" 2>/dev/null || echo "Failed to parse config"

    echo "Config may not have been applied correctly. Failing the configure step."

    # Try to get seedsync log from myapp container for debugging
    echo "=== Attempting to fetch seedsync log from myapp ==="
    curl -sS "http://myapp:8800/server/log/get" 2>/dev/null || echo "Log endpoint not available"

    exit 1
fi

echo
echo "Done configuring SeedSync app - server is up and healthy"
