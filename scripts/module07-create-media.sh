#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="${1:?Usage: $0 VERSION SEQUENCE [rootfs-image]}"
SEQ="${2:?Provide increasing integer sequence}"
IMAGE="${3:-output/images/rootfs.ext2}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Version must be X.Y.Z' >&2; exit 1; }
[[ "$SEQ" =~ ^[1-9][0-9]*$ ]] || { echo 'Sequence must be positive integer' >&2; exit 1; }
[[ -f "$IMAGE" && -f secrets/update-signing-private.pem ]] || { echo 'Image or private signing key missing' >&2; exit 1; }
command -v mkfs.ext4 >/dev/null || { echo 'Install e2fsprogs' >&2; exit 1; }
mkdir -p module07-disks
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
cp "$IMAGE" "$STAGE/rootfs.img"
SIZE="$(stat -c %s "$STAGE/rootfs.img")"
HASH="$(sha256sum "$STAGE/rootfs.img" | cut -d' ' -f1)"
cat > "$STAGE/manifest.txt" <<MANIFEST
format=1
product=customiot
arch=x86_64
version=$VERSION
sequence=$SEQ
size=$SIZE
sha256=$HASH
MANIFEST
openssl dgst -sha256 -sign secrets/update-signing-private.pem -out "$STAGE/manifest.sig" "$STAGE/manifest.txt"
MEDIA='module07-disks/update-media.img'
[[ ! -e "$MEDIA" ]] || { echo "Refusing to overwrite $MEDIA while it may be in use. Delete it only after QEMU is shut down." >&2; exit 1; }
MEDIA_MB=$(( (SIZE + 1024 * 1024 * 32 + 1024 * 1024 - 1) / (1024 * 1024) ))
truncate -s "${MEDIA_MB}M" "$MEDIA"
mkfs.ext4 -q -F -L CUSTOMIOT_UPDATE -d "$STAGE" "$MEDIA"
echo "Created signed offline update media: $MEDIA"
echo "Version $VERSION, sequence $SEQ, signed hash $HASH"
