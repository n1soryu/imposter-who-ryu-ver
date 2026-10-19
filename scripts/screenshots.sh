#!/bin/sh
# Builds the app for a booted simulator, then launches each debug scene and saves a screenshot.
# Usage: scripts/screenshots.sh <simulator-udid> [output-dir]
set -eu
cd "$(dirname "$0")/.."

: "${DEVELOPER_DIR:=/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

udid="$1"
out="${2:-.build/screenshots}"
mkdir -p "$out"

xcodegen generate --quiet
xcodebuild -project Imposter.xcodeproj -scheme Imposter -destination "id=$udid" \
    -derivedDataPath .build/DerivedData build | grep -E "error:|BUILD" || true
xcrun simctl install "$udid" .build/DerivedData/Build/Products/Debug-iphonesimulator/Imposter.app

for scene in home players rules deal clues discussion voting lastChance results scoreboard; do
    xcrun simctl terminate "$udid" com.n1soryu.imposter 2>/dev/null || true
    if [ "$scene" = home ]; then
        xcrun simctl launch "$udid" com.n1soryu.imposter >/dev/null
    else
        xcrun simctl launch "$udid" com.n1soryu.imposter -scene "$scene" >/dev/null
    fi
    sleep 3
    xcrun simctl io "$udid" screenshot "$out/$scene.png" >/dev/null 2>&1
    echo "$out/$scene.png"
done
