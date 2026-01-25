#!/bin/bash

# exit on first error
set -e

echo "Running entrypoint"

echo "Installing SeedSync"
./expect_seedsync.exp

echo "Continuing docker CMD"
echo "$@"
# 3>&1 workaround for docker/docker#27202
exec $@ 3>&1
