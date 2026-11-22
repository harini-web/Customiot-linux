#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-baseline}"
case "$MODE" in baseline) IMAGES="$ROOT/output-baseline/images";;custom) IMAGES="$ROOT/output/images";;*) echo 'Usage: scripts/run-qemu.sh [baseline|custom]' >&2; exit 2;;esac
[[ -f "$IMAGES/bzImage" && -f "$IMAGES/rootfs.ext2" ]] || { echo "Build first: scripts/build.sh $MODE" >&2; exit 1; }
exec qemu-system-x86_64 \
  -M pc -m 512M -smp 2 -nographic -no-reboot \
  -kernel "$IMAGES/bzImage" \
  -drive "file=$IMAGES/rootfs.ext2,if=virtio,format=raw,snapshot=on" \
  -append 'rootwait root=/dev/vda ro console=ttyS0' \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0
