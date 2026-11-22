#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-baseline}"
case "$MODE" in baseline) OUT="$ROOT/output-baseline";;custom) OUT="$ROOT/output";;*) echo 'Usage: scripts/build.sh [baseline|custom]' >&2; exit 2;;esac
[[ -f "$OUT/.config" ]] || { echo "Run scripts/configure.sh $MODE first" >&2; exit 1; }
make -C "$ROOT/buildroot" O="$OUT" -j"$(nproc)" all
