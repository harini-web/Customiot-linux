#!/usr/bin/env bash
set -euo pipefail
# Copy/paste the guest's output into benchmarks/module08/guest-runs/ or record via serial log.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/benchmarks/module08/guest-runs"
echo "Guest metrics are created inside QEMU at /var/lib/customiot/benchmarks."
echo "Run module08-guest-metrics run01, run02, run03 and module08-mqtt-batch 200."
echo "Capture terminal output or transfer guest files to benchmarks/module08/guest-runs/."
echo "Do not mistake post-login uptime for boot readiness; use CUSTOMIOT_BOOT_READY marker."
