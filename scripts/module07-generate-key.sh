#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p secrets external/board/customiot/rootfs-overlay/etc/customiot
umask 077
KEY=secrets/update-signing-private.pem
PUB=external/board/customiot/rootfs-overlay/etc/customiot/update-public.pem
if [[ -e "$KEY" ]]; then
  echo "Signing key exists: $KEY (not overwriting)" >&2
  exit 1
fi
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out "$KEY"
openssl pkey -in "$KEY" -pubout -out "$PUB"
chmod 600 "$KEY"
echo "Public verification key: $PUB"
echo 'Keep secrets/ OUT of Git and off the QEMU guest.'
