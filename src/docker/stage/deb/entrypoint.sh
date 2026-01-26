#!/bin/bash

# exit on first error
set -e

echo "=== ENTRYPOINT DEBUG ==="
echo "Running entrypoint"

echo "=== Checking init binary ==="
ls -la /sbin/init /lib/systemd/systemd 2>&1 || true

echo "=== Checking cgroups ==="
mount | grep cgroup || true
cat /proc/self/cgroup 2>&1 || true
ls -la /sys/fs/cgroup/ 2>&1 || true

echo "=== Installing SeedSync ==="
./expect_seedsync.exp

echo "=== Checking seedsync installation ==="
ls -la /usr/lib/seedsync/ 2>&1 || true
ls -la /lib/systemd/system/seedsync.service 2>&1 || true
cat /lib/systemd/system/seedsync.service 2>&1 || true

echo "=== Checking systemd service enablement ==="
ls -la /etc/systemd/system/multi-user.target.wants/ 2>&1 || true

echo "=== Continuing docker CMD ==="
echo "$@"
exec "$@"
