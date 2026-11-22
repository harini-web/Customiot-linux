#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
OUT=benchmarks/module10
mkdir -p "$OUT"
REPORT="$OUT/release-audit.txt"
{
 echo 'CUSTOMIOT RELEASE AUDIT'; date -u -Is
 echo; echo '[Build files]'
 for f in scripts/setup.sh scripts/configure.sh scripts/build.sh external/configs/customiot_qemu_defconfig external/board/customiot/linux.config output/images/bzImage output/images/rootfs.ext2 benchmarks/module09/ALL_BENCHMARKS.txt; do
  if [[ -f "$f" ]]; then printf '[OK] %s\n' "$f"; else printf '[MISSING] %s\n' "$f"; fi
 done
 echo; echo '[Overlay tests]'
 for f in external/board/customiot/rootfs-overlay/usr/local/bin/test-module06 external/board/customiot/rootfs-overlay/usr/local/bin/customiot-benchmark-all; do
  if [[ -f "$f" ]]; then sh -n "$f" && echo "[SYNTAX OK] $f"; else echo "[MISSING] $f"; fi
 done
 echo; echo '[Buildroot settings]'
 if [[ -f output/.config ]]; then grep -E '^(BR2_ROOTFS_OVERLAY|BR2_INIT_BUSYBOX|BR2_TARGET_ROOTFS_EXT2|BR2_TARGET_ROOTFS_ISO9660)' output/.config || true; fi
 echo; echo '[Image SHA256]'
 for f in output/images/bzImage output/images/rootfs.ext2; do [[ ! -f "$f" ]] || sha256sum "$f"; done
 echo; echo '[Git changes]'; git status --short 2>/dev/null || true
} | tee "$REPORT"
echo "Saved $REPORT"
