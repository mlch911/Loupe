#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DEVICE="${LOUPE_DEVICE:-booted}"
PORT="${LOUPE_PORT:-8765}"
BACKEND="${LOUPE_ACTION_BACKEND:-axe}"

cd "$ROOT_DIR"

if ! command -v axe >/dev/null 2>&1; then
  echo "error: runtime E2E requires axe on PATH" >&2
  echo "hint: brew install cameroncooke/axe/axe" >&2
  exit 2
fi

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

HOST="http://127.0.0.1:$PORT"
SNAPSHOT_PATH="/tmp/loupe-runtime-snapshot.json"
RECORDING_PATH="/tmp/loupe-runtime-recording.json"
SCREENSHOT_PATH="/tmp/loupe-runtime-screen.png"
RUNTIME_PATH="/tmp/loupe-runtime-state.json"

curl -sS "$HOST/health" | grep -q LoupeKit
.build/debug/loupe runtime --host "$HOST" --udid "$DEVICE" > "$RUNTIME_PATH"
grep -q '"simulatorUDID"' "$RUNTIME_PATH"
curl -sS "$HOST/snapshot" > "$SNAPSHOT_PATH"
grep -q '"uiKit"' "$SNAPSHOT_PATH"
grep -q '"accessibility"' "$SNAPSHOT_PATH"

.build/debug/loupe record-start --host "$HOST" --udid "$DEVICE" >/tmp/loupe-record-start.json

.build/debug/loupe tap \
  --host "$HOST" \
  --backend "$BACKEND" \
  --udid "$DEVICE" \
  --test-id example.customer.1

sleep 1

curl -sS "$HOST/snapshot" > "$SNAPSHOT_PATH"
.build/debug/loupe query "$SNAPSHOT_PATH" --test-id example.detail >/tmp/loupe-runtime-detail-query.json

.build/debug/loupe screenshot \
  --udid "$DEVICE" \
  --output "$SCREENSHOT_PATH"

.build/debug/loupe record-stop \
  --host "$HOST" \
  --udid "$DEVICE" \
  --output "$RECORDING_PATH"

grep -q '"events"' "$RECORDING_PATH"
grep -q '"kind" : "touch"' "$RECORDING_PATH"
grep -q '"appIdentity"' "$RECORDING_PATH"
grep -q '"simulatorUDID"' "$RECORDING_PATH"

echo "runtime E2E smoke passed"
echo "runtime: $RUNTIME_PATH"
echo "snapshot: $SNAPSHOT_PATH"
echo "recording: $RECORDING_PATH"
echo "screenshot: $SCREENSHOT_PATH"
