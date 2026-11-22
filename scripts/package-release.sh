#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DEST="$ROOT/release/customiot-0.9.0"
mkdir -p "$DEST/source" "$DEST/images" "$DEST/evidence" "$DEST/licenses"
# Explicit source allowlist; no private keys, build artifacts, or device-state disks.
for p in app external scripts tests docs README.md Makefile .gitignore; do
 if [[ -e "$p" ]]; then cp -a "$p" "$DEST/source/"; fi
done
for f in output/images/bzImage output/images/rootfs.ext2 output/images/rootfs.iso9660; do
 if [[ -f "$f" ]]; then cp --sparse=always "$f" "$DEST/images/"; fi
done
if [[ -d benchmarks ]]; then cp -a benchmarks "$DEST/evidence/"; fi
if [[ -d output/legal-info ]]; then cp -a output/legal-info "$DEST/licenses/"; fi
find "$DEST" -type f -name '*.pem' -path '*/secrets/*' -print -quit | grep -q . && { echo 'ERROR private key detected'; exit 1; } || true
( cd "$DEST" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS )
( cd "$ROOT/release" && tar -czf customiot-source-and-evidence.tar.gz customiot-0.9.0/source customiot-0.9.0/evidence customiot-0.9.0/licenses )
echo "Release staged in $DEST"
echo "Source/evidence archive in release/customiot-source-and-evidence.tar.gz"
echo 'Images remain separate to avoid inflating the source archive.'
