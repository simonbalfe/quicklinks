#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
swift build -c release
mkdir -p "$HOME/.local/bin"
install -m 755 .build/release/quicklinks "$HOME/.local/bin/quicklinks"
echo "installed $HOME/.local/bin/quicklinks"
