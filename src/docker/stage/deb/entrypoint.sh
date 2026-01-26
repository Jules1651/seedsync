#!/bin/bash

# exit on first error for installation
set -e

echo "=== ENTRYPOINT ==="
echo "Running entrypoint"

echo "=== Installing SeedSync ==="
./expect_seedsync.exp

echo "=== Checking seedsync installation ==="
ls -la /usr/lib/seedsync/ 2>&1 || true

# Create directories for seedsync
mkdir -p /home/user/.seedsync/log

echo "=== Starting SeedSync directly (no systemd) ==="
# Run seedsync in a restart loop (it exits when restart is requested)
set +e
while true; do
    echo "Starting seedsync..."
    /usr/lib/seedsync/seedsync --logdir /home/user/.seedsync/log -c /home/user/.seedsync
    EXIT_CODE=$?
    echo "Seedsync exited with code $EXIT_CODE"
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Restarting seedsync in 2 seconds..."
        sleep 2
    else
        echo "Seedsync exited cleanly, restarting..."
        sleep 1
    fi
done
