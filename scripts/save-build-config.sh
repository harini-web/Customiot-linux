#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
make -C "$ROOT/buildroot" O="$ROOT/output" savedefconfig
printf 'Saved Buildroot config to external/configs/customiot_qemu_defconfig\n'
