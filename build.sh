#!/usr/bin/env bash

set -euo pipefail
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

MOD_DIR=$(mktemp -d -t openmw-special-XXXXXX)

function cleanup {      
  rm -rf "$MOD_DIR"
  echo "Deleted temp working directory $MOD_DIR"
}
trap cleanup EXIT

tree "${DIR}"
cd "${DIR}"
git config --global safe.directory "${DIR}"
VERSION=$(git rev-parse --short HEAD)

cd "${DIR}/esp-generator"
cargo run --release "${MOD_DIR}/special.esp"

cd "${DIR}/omwscripts"
cp -r l10n "${MOD_DIR}"
cp -r special.omwscripts "${MOD_DIR}"
cyan build
mkdir -p "${MOD_DIR}/scripts/special"
cp scripts/special/*.lua "${MOD_DIR}/scripts/special"

cd "${MOD_DIR}"
tree "${MOD_DIR}"
rm -f "${DIR}/special-${VERSION}.zip"
zip -r "${DIR}/special-${VERSION}.zip" .