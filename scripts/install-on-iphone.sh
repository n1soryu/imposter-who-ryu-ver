#!/bin/sh
# Builds a release copy of the app and installs it on a connected iPhone.
# Run this again every 7 days: free Apple ID signing expires after a week. Your players, rules and packs are kept.
# Usage: scripts/install-on-iphone.sh [device-name-or-udid]
set -eu
cd "$(dirname "$0")/.."

if [ ! -f Config/Signing.local.xcconfig ]; then
    echo "No signing set up yet. Run scripts/setup-signing.sh first (see docs/INSTALL.md)."
    exit 1
fi

# Finds connected physical iPhones. devicectl and xcodebuild use different IDs, so read both.
devices_json="$(mktemp)"
trap 'rm -f "$devices_json"' EXIT
xcrun devicectl list devices --json-output "$devices_json" >/dev/null 2>&1 || true
ids="$(python3 -I - "$devices_json" "${1:-}" <<'PY'
import json, sys
path, wanted = sys.argv[1], sys.argv[2]
try:
    devices = json.load(open(path))["result"]["devices"]
except (OSError, KeyError, ValueError):
    devices = []
for device in devices:
    hardware = device.get("hardwareProperties", {})
    name = device.get("deviceProperties", {}).get("name", "")
    if hardware.get("reality") != "physical" or hardware.get("deviceType") != "iPhone":
        continue
    if wanted and wanted not in (name, device.get("identifier"), hardware.get("udid")):
        continue
    print(device["identifier"], hardware.get("udid", ""), name)
    break
PY
)"
if [ -z "$ids" ]; then
    echo "No iPhone found. Plug it in with a cable, unlock it, and tap Trust if asked."
    exit 1
fi
core_id="$(echo "$ids" | cut -d' ' -f1)"
udid="$(echo "$ids" | cut -d' ' -f2)"
device="$(echo "$ids" | cut -d' ' -f3-)"
echo "Installing on $device"

xcodegen generate --quiet
xcodebuild -project Imposter.xcodeproj -scheme Imposter -configuration Release \
    -destination "platform=iOS,id=$udid" \
    -derivedDataPath .build/DeviceBuild \
    -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
    build | grep -E "error:|BUILD" || true

app=.build/DeviceBuild/Build/Products/Release-iphoneos/Imposter.app
if [ ! -d "$app" ]; then
    echo "The build failed. Open Imposter.xcodeproj in Xcode to see why (Signing & Capabilities usually explains it)."
    exit 1
fi

xcrun devicectl device install app --device "$core_id" "$app"
echo "Installed. If the app won't open, trust your Apple ID on the iPhone: Settings > General > VPN & Device Management."
