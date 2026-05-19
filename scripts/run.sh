#!/bin/bash
# Build Roomiez, install on whichever iPhone simulator is convenient,
# and launch it. Used after every code change.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/Roomiez/Roomiez.xcodeproj"
SCHEME="Roomiez"

# Prefer an already-booted iPhone; otherwise iPhone 17; otherwise the first
# available iPhone.
pick_device() {
    local booted
    booted="$(xcrun simctl list devices booted -j \
        | /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
for rt, devs in data["devices"].items():
    for d in devs:
        if d.get("state") == "Booted" and "iPhone" in d.get("name", ""):
            print(d["udid"]); sys.exit(0)
')"
    if [[ -n "$booted" ]]; then echo "$booted"; return; fi

    xcrun simctl list devices available -j \
        | /usr/bin/python3 -c '
import json, sys
data = json.load(sys.stdin)
preferred = ["iPhone 17", "iPhone 17 Pro", "iPhone 16", "iPhone 15"]
flat = [(d["name"], d["udid"]) for rt, ds in data["devices"].items() for d in ds]
for name in preferred:
    for n, u in flat:
        if n == name:
            print(u); sys.exit(0)
for n, u in flat:
    if "iPhone" in n:
        print(u); sys.exit(0)
'
}

SIM_UDID="$(pick_device)"
SIM_NAME="$(xcrun simctl list devices -j | /usr/bin/python3 -c "
import json, sys
data = json.load(sys.stdin)
for rt, ds in data['devices'].items():
    for d in ds:
        if d['udid'] == '${SIM_UDID}':
            print(d['name']); sys.exit(0)
")"

echo "▸ Target sim: $SIM_NAME ($SIM_UDID)"

# Build.
echo "▸ Building $SCHEME…"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$SIM_UDID" \
    -configuration Debug \
    -derivedDataPath "$ROOT/.build/derived" \
    build -quiet
echo "  ✓ Build succeeded"

APP_PATH="$ROOT/.build/derived/Build/Products/Debug-iphonesimulator/${SCHEME}.app"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")"

# Boot + open the simulator UI.
xcrun simctl bootstatus "$SIM_UDID" -b > /dev/null 2>&1 || \
    xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID"

# Reinstall + launch.
xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install   "$SIM_UDID" "$APP_PATH"
xcrun simctl launch    "$SIM_UDID" "$BUNDLE_ID" > /dev/null

echo "▸ Launched $BUNDLE_ID on $SIM_NAME"
