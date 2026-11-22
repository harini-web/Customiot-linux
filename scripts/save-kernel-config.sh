#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
make -C "$ROOT/buildroot" O="$ROOT/output" linux-update-defconfig
printf 'Saved Linux config to external/board/customiot/linux.config\n'
