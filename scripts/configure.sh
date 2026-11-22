#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BR="$ROOT/buildroot"
MODE="${1:-baseline}"
case "$MODE" in
  baseline) CFG=customiot_baseline_defconfig; OUT="$ROOT/output-baseline" ;;
  custom) CFG=customiot_qemu_defconfig; OUT="$ROOT/output" ;;
  *) echo 'Usage: scripts/configure.sh [baseline|custom]' >&2; exit 2 ;;
esac
[[ -f "$BR/Makefile" ]] || { echo 'Run scripts/setup.sh first' >&2; exit 1; }
mkdir -p "$OUT"
make -C "$BR" O="$OUT" BR2_EXTERNAL="$ROOT/external" "$CFG"
printf '\nConfigured %s: %s\n' "$MODE" "$OUT"
