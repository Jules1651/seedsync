#!/bin/bash

# exit on first error
set -e

echo "Running entrypoint"

echo "Installing SeedSync"
./expect_seedsync.exp

# Check if systemd is available and working
if [ -d /run/systemd/system ]; then
    echo "Systemd detected, starting via systemd"
    echo "Continuing docker CMD"
    echo "$@"
    exec $@
else
    echo "Systemd not available, running seedsync directly"
    # Create required directories as user
    sudo -u user mkdir -p /home/user/.seedsync
    sudo -u user mkdir -p /home/user/.seedsync/log

    # Run seedsync in a loop to handle restarts (since we don't have systemd to restart it)
    while true; do
        echo "Starting seedsync..."
        sudo -u user /usr/lib/seedsync/seedsync --logdir /home/user/.seedsync/log -c /home/user/.seedsync || true
        echo "Seedsync exited, restarting in 2 seconds..."
        sleep 2
    done
fi
