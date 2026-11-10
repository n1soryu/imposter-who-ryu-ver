#!/bin/sh
# Builds an UNSIGNED Imposter.ipa for a GitHub release.
# It's unsigned on purpose: a signed IPA would carry your personal Team ID and the UDIDs of your
# devices (inside embedded.mobileprovision). Whoever installs it re-signs it with their own free
# Apple ID using AltStore, SideStore or Sideloadly (see docs/INSTALL.md).
# Usage: scripts/make-ipa.sh   -- writes .build/ipa/Imposter-<version>.ipa
set -eu
cd "$(dirname "$0")/.."

: "${DEVELOPER_DIR:=/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

# Builds the committed Imposter.xcodeproj as it is. Run scripts/build.sh first if project.yml changed.
version="$(sed -n 's/^ *MARKETING_VERSION: *//p' project.yml | head -n 1)"
derived=.build/IPADerivedData
out=.build/ipa
rm -rf "$derived" "$out"
mkdir -p "$out/Payload"

# An empty team and identity keep the personal signing in Config/Signing.local.xcconfig out of the build.
xcodebuild -project Imposter.xcodeproj -scheme Imposter -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$derived" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" DEVELOPMENT_TEAM="" \
    build | grep -E "error:|BUILD" || true

app="$derived/Build/Products/Release-iphoneos/Imposter.app"
if [ ! -d "$app" ]; then
    echo "The build failed: $app was not produced."
    exit 1
fi

cp -R "$app" "$out/Payload/"
(cd "$out" && zip -qry "Imposter-$version.ipa" Payload && rm -rf Payload)

# Refuses to continue if anything personal slipped into the package.
if unzip -l "$out/Imposter-$version.ipa" | grep -q "embedded.mobileprovision"; then
    echo "The IPA contains a provisioning profile. Remove it before publishing."
    exit 1
fi
echo "Built $out/Imposter-$version.ipa"
