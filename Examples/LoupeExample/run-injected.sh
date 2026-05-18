#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DEVICE="${LOUPE_DEVICE:-booted}"
PORT="${LOUPE_PORT:-8765}"

cd "$ROOT_DIR"

if ! xcrun simctl list devices booted | grep -q Booted; then
  FIRST_DEVICE="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { print $2; exit }')"
  xcrun simctl boot "$FIRST_DEVICE"
  DEVICE="booted"
fi

swift build

xcodebuild \
  -scheme LoupeInjector \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build >/tmp/loupe-injector-build.log

xcodebuild \
  -project Examples/LoupeExample/LoupeExample.xcodeproj \
  -scheme LoupeExample \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build >/tmp/loupe-example-build.log

export LOUPE_INJECTOR_PATH="$(
  find "$HOME/Library/Developer/Xcode/DerivedData" \
    -path '*Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector' \
    -print0 | xargs -0 ls -t | head -1
)"

APP_PATH="$(
  find "$HOME/Library/Developer/Xcode/DerivedData" \
    -path '*Debug-iphonesimulator/LoupeExample.app' \
    -print0 | xargs -0 ls -td | head -1
)"

xcrun simctl install "$DEVICE" "$APP_PATH"
xcrun simctl terminate "$DEVICE" dev.loupe.example >/dev/null 2>&1 || true

.build/debug/loupe launch \
  --device "$DEVICE" \
  --bundle-id dev.loupe.example \
  --inject \
  --env LOUPE_PORT="$PORT" >/dev/null

sleep 2

curl -sS "http://127.0.0.1:$PORT/health"
echo

SNAPSHOT_PATH="/tmp/loupe-example-snapshot.json"
LOGS_PATH="/tmp/loupe-example-logs.json"
INSPECT_PATH="/tmp/loupe-example-inspect.json"
curl -sS "http://127.0.0.1:$PORT/snapshot" > "$SNAPSHOT_PATH"
curl -sS "http://127.0.0.1:$PORT/logs" > "$LOGS_PATH"

.build/debug/loupe query "$SNAPSHOT_PATH" --test-id example.customerList
.build/debug/loupe inspect "$SNAPSHOT_PATH" --test-id example.customerList > "$INSPECT_PATH"
grep -q '"example_customers_visible"' "$LOGS_PATH"
grep -q '"screen"' "$INSPECT_PATH"
grep -q '"customers"' "$INSPECT_PATH"
