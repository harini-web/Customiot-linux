#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SLOT="${1:-A}"
case "$SLOT" in A|a) SLOT=A; DEVICE=/dev/vda;; B|b) SLOT=B; DEVICE=/dev/vdb;; *) echo 'Usage: module07-run-qemu.sh [A|B]' >&2; exit 1;; esac
for f in output/images/bzImage module07-disks/root-a.img module07-disks/root-b.img module07-disks/state.img; do
  [[ -f "$f" ]] || { echo "Missing $f" >&2; exit 1; }
done
SOCKET="/tmp/customiot-uart-$(id -u).sock"
rm -f "$SOCKET"
trap 'rm -f "$SOCKET"' EXIT
CMD=(qemu-system-x86_64 -M pc -m 512M -smp 2 -nographic -no-reboot
 -kernel output/images/bzImage
 -append "rootwait root=$DEVICE ro console=ttyS0 customiot.slot=$SLOT"
 -drive file=module07-disks/root-a.img,if=virtio,format=raw
 -drive file=module07-disks/root-b.img,if=virtio,format=raw
 -drive file=module07-disks/state.img,if=virtio,format=raw
 -netdev user,id=net0 -device virtio-net-pci,netdev=net0
 -serial mon:stdio -serial "unix:$SOCKET,server=on,wait=off")
if [[ -f module07-disks/update-media.img ]]; then
 CMD+=(-drive file=module07-disks/update-media.img,if=virtio,format=raw,readonly=on)
fi
printf 'CustomIoT Module 07 | root slot %s (%s) | UART %s\n' "$SLOT" "$DEVICE" "$SOCKET"
"${CMD[@]}"
