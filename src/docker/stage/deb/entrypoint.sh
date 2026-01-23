#!/bin/bash

# exit on first error
set -e

echo "Running entrypoint"
echo "Environment variables:"
echo "  SEEDSYNC_NO_SYSTEMD=${SEEDSYNC_NO_SYSTEMD:-not set}"
echo "  SEEDSYNC_DEB=${SEEDSYNC_DEB:-not set}"
echo "  SEEDSYNC_OS=${SEEDSYNC_OS:-not set}"

echo "Installing SeedSync"
# Run install script directly (debconf value is pre-set via debconf-set-selections)
./install_seedsync.sh

# Determine if we should use systemd or run seedsync directly
# SEEDSYNC_NO_SYSTEMD=1 forces direct mode (useful for CI where systemd doesn't work)
USE_SYSTEMD=true

if [ "${SEEDSYNC_NO_SYSTEMD:-0}" = "1" ]; then
    echo "SEEDSYNC_NO_SYSTEMD=1 set, forcing direct mode"
    USE_SYSTEMD=false
elif [ ! -f /lib/systemd/systemd ]; then
    echo "Systemd binary not found, using direct mode"
    USE_SYSTEMD=false
elif [ ! -d /sys/fs/cgroup ]; then
    echo "Cgroups not mounted, systemd won't work, using direct mode"
    USE_SYSTEMD=false
fi

if [ "$USE_SYSTEMD" = "true" ]; then
    echo "Starting via systemd"
    echo "Continuing docker CMD"
    echo "$@"
    exec $@
else
    echo "Systemd not available, running seedsync directly"
    # Create required directories as user
    sudo -u user mkdir -p /home/user/.seedsync
    sudo -u user mkdir -p /home/user/.seedsync/log

    # Run seedsync in a loop to handle restarts (since we don't have systemd to restart it)
    RESTART_COUNT=0
    while true; do
        RESTART_COUNT=$((RESTART_COUNT + 1))
        echo "Starting seedsync (run #$RESTART_COUNT)..."

        # Run seedsync and capture exit code
        set +e
        sudo -u user /usr/lib/seedsync/seedsync --logdir /home/user/.seedsync/log -c /home/user/.seedsync
        EXIT_CODE=$?
        set -e

        echo "Seedsync exited with code $EXIT_CODE"

        # Exit code 0 means restart requested, any other code is an error
        if [ $EXIT_CODE -ne 0 ]; then
            echo "Seedsync exited with error, showing last 20 lines of log:"
            tail -20 /home/user/.seedsync/log/seedsync.log 2>/dev/null || echo "No log file"
        fi

        sleep 2
    done
fi
