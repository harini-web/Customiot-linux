#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/benchmarks"
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  for mode in baseline custom; do
    case "$mode" in baseline) OUT="$ROOT/output-baseline";;custom) OUT="$ROOT/output";;esac
    printf '=== %s ===\n' "$mode"
    for f in "$OUT/images/bzImage" "$OUT/images/rootfs.ext2"; do
      if [[ -f "$f" ]]; then stat -c '%n: %s bytes' "$f"; sha256sum "$f"; fi
    done
    if [[ -f "$OUT/.config" ]]; then grep -c '^BR2_PACKAGE_.*=y$' "$OUT/.config" || true; fi
  done
} | tee "$ROOT/benchmarks/host-metrics.txt"
