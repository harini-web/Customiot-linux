#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

IMAGES="$ROOT/output/images"

KERNEL="$IMAGES/bzImage"
ROOTFS="$IMAGES/rootfs.ext2"

UART_SOCKET="/tmp/customiot-uart-$(id -u).sock"

if [ ! -f "$KERNEL" ]; then
    echo "ERROR: Custom kernel not found"
    exit 1
fi

if [ ! -f "$ROOTFS" ]; then
    echo "ERROR: Root filesystem not found"
    exit 1
fi

rm -f "$UART_SOCKET"

echo "======================================="
echo "      CustomIoT Linux - UART Mode"
echo "======================================="
echo
echo "Kernel: $KERNEL"
echo "RootFS: $ROOTFS"
echo
echo "Serial Console: /dev/ttyS0"
echo "Sensor UART   : /dev/ttyS1"
echo "Host Socket   : $UART_SOCKET"
echo

echo "Start the virtual sensor in another terminal:"
echo
echo "python3 scripts/virtual-sensor.py $UART_SOCKET"
echo

cleanup() {
    rm -f "$UART_SOCKET"
}

trap cleanup EXIT

qemu-system-x86_64 \
    -M pc \
    -m 512M \
    -smp 2 \
    -nographic \
    -no-reboot \
    -kernel "$KERNEL" \
    -drive "file=$ROOTFS,if=virtio,format=raw,snapshot=on" \
    -append "rootwait root=/dev/vda ro console=ttyS0" \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -serial mon:stdio \
    -serial "unix:$UART_SOCKET,server=on,wait=off"
