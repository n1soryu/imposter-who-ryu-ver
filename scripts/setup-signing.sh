#!/bin/sh
# Finds your free Personal Team in Xcode and writes Config/Signing.local.xcconfig.
# Sign in first: Xcode > Settings > Accounts > + > Apple ID.
set -eu
cd "$(dirname "$0")/.."

teams="$(defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier 2>/dev/null \
    | grep -E 'teamID' | sed -E 's/.*teamID = "?([A-Z0-9]+)"?;.*/\1/' | sort -u || true)"

if [ -z "$teams" ]; then
    echo "No teams found. In Xcode, open Settings > Accounts, add your Apple ID, then run this again."
    exit 1
fi

count=$(printf '%s\n' "$teams" | wc -l | tr -d ' ')
if [ "$count" -gt 1 ]; then
    echo "Found more than one team:"
    printf '  %s\n' $teams
    echo "Set DEVELOPMENT_TEAM in Config/Signing.local.xcconfig to the one you want."
    exit 1
fi

if [ -f Config/Signing.local.xcconfig ]; then
    echo "Config/Signing.local.xcconfig already exists, so it was left alone. Your team ID is $teams."
    exit 0
fi

cat > Config/Signing.local.xcconfig <<CONFIG
// Written by scripts/setup-signing.sh. Not committed to git.
DEVELOPMENT_TEAM = $teams
CONFIG
echo "Wrote Config/Signing.local.xcconfig with team $teams."
