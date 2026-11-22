#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ROOT_IMAGE="output/images/rootfs.ext2"
DISKS="module07-disks"
[[ -f "$ROOT_IMAGE" ]] || { echo "Missing $ROOT_IMAGE" >&2; exit 1; }
command -v mkfs.ext4 >/dev/null || { echo 'Install e2fsprogs' >&2; exit 1; }
mkdir -p "$DISKS"
for slot in a b; do
  image="$DISKS/root-${slot}.img"
  if [[ ! -e "$image" ]]; then
    cp -- "$ROOT_IMAGE" "$image"
    echo "Created $image"
  else
    echo "Preserved $image"
  fi
done
DATA="$DISKS/state.img"
if [[ ! -e "$DATA" ]]; then
  truncate -s 128M "$DATA"
  mkfs.ext4 -q -F -L CUSTOMIOT_DATA "$DATA"
  echo "Created $DATA"
else
  echo "Preserved persistent $DATA"
fi
printf '\nDisk images in %s (do not commit these images)\n' "$DISKS"
