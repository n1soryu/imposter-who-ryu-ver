#!/bin/sh
# Runs the ImposterKit tests. Works with full Xcode or with only the Command Line Tools,
# whose Swift Testing macro plugin isn't on the default search path.
set -eu
cd "$(dirname "$0")/../ImposterKit"

plugin_dir="$(xcode-select -p)/usr/lib/swift/host/plugins/testing"
if [ -d "$plugin_dir" ]; then
    exec swift test -Xswiftc -plugin-path -Xswiftc "$plugin_dir" "$@"
fi
exec swift test "$@"
