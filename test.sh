#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
frameworks=/Library/Developer/CommandLineTools/Library/Developer/Frameworks

if [ "$(xcode-select -p)" = /Library/Developer/CommandLineTools ] && [ -d "$frameworks/Testing.framework" ]; then
    exec swift test --enable-swift-testing --disable-xctest \
        -Xswiftc -F -Xswiftc "$frameworks" \
        -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays \
        -Xlinker -F -Xlinker "$frameworks" \
        -Xlinker -rpath -Xlinker "$frameworks"
fi

exec swift test
