#!/bin/sh
# Regenerates Imposter.xcodeproj from project.yml (so new files are picked up) and builds the app.
# Usage: scripts/build.sh [simulator]   -- default builds for a generic iPhone without signing.
set -eu
cd "$(dirname "$0")/.."

: "${DEVELOPER_DIR:=/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

xcodegen generate --quiet

if [ "${1:-}" = "simulator" ]; then
    destination='generic/platform=iOS Simulator'
else
    destination='generic/platform=iOS'
fi

xcodebuild -project Imposter.xcodeproj -scheme Imposter \
    -destination "$destination" \
    -derivedDataPath .build/DerivedData \
    CODE_SIGNING_ALLOWED=NO \
    build | grep -E "error:|warning:|BUILD" | grep -v appintents || true
