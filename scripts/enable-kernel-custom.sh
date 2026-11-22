#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="$ROOT/buildroot/board/qemu/x86_64/linux.config"
DEST="$ROOT/external/board/customiot/linux.config"
[[ -f "$BASE" ]] || { echo 'Run scripts/setup.sh first' >&2; exit 1; }
if [[ ! -f "$DEST" ]]; then cp "$BASE" "$DEST"; fi
sed -i 's|BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="board/qemu/x86_64/linux.config"|BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE="$(BR2_EXTERNAL_CUSTOMIOT_PATH)/board/customiot/linux.config"|' "$ROOT/external/configs/customiot_qemu_defconfig"
echo 'Kernel config prepared. Re-run scripts/configure.sh custom, then use:'
echo 'make -C buildroot O="$PWD/output" linux-menuconfig'
echo 'scripts/save-kernel-config.sh'
