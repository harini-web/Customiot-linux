#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=2026.08.2
if [[ ! -d "$ROOT/buildroot/.git" ]]; then
  git clone --depth 1 --branch "$VERSION" https://github.com/buildroot/buildroot.git "$ROOT/buildroot"
fi
printf 'Buildroot pinned at: '
git -C "$ROOT/buildroot" describe --tags --always
