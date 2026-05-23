#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PORT="${LOUPE_PORT:-}"

cd "$ROOT_DIR"

booted_udid() {
  xcrun simctl list devices booted --json | ruby -rjson -e '
    devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
    booted = devices.find { |device| device["state"] == "Booted" }
    puts booted && booted["udid"]
  '
}

DEVICE="${LOUPE_DEVICE:-$(booted_udid)}"
if [[ -z "$DEVICE" ]]; then
  FIRST_DEVICE="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { print $2; exit }')"
  xcrun simctl boot "$FIRST_DEVICE"
  DEVICE="$FIRST_DEVICE"
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

LAUNCH_ARGUMENTS=(
  --device "$DEVICE"
  --bundle-id dev.loupe.example
  --inject
)
if [[ -n "$PORT" ]]; then
  LAUNCH_ARGUMENTS+=(--env "LOUPE_PORT=$PORT")
fi
LAUNCH_OUTPUT="$(.build/debug/loupe launch "${LAUNCH_ARGUMENTS[@]}")"
HOST="$(awk '/^loupe host: / { print $3 }' <<<"$LAUNCH_OUTPUT" | tail -1)"
if [[ -z "$HOST" ]]; then
  echo "error: loupe launch did not report a runtime host" >&2
  echo "$LAUNCH_OUTPUT" >&2
  exit 1
fi

sleep 2

curl -sS "$HOST/health"
echo

SNAPSHOT_PATH="/tmp/loupe-example-snapshot.json"
LOGS_PATH="/tmp/loupe-example-logs.json"
INSPECT_PATH="/tmp/loupe-example-inspect.json"
curl -sS "$HOST/snapshot" > "$SNAPSHOT_PATH"
.build/debug/loupe logs --host "$HOST" --output "$LOGS_PATH" >/dev/null

.build/debug/loupe query "$SNAPSHOT_PATH" --test-id example.customerList
.build/debug/loupe inspect "$SNAPSHOT_PATH" --test-id example.customerList > "$INSPECT_PATH"
ruby -rjson -e '
  logs = JSON.parse(File.read(ARGV.fetch(0)))
  log = logs.find { |entry| entry["message"] == "example_customers_visible" }
  abort "missing example_customers_visible log" unless log
  screen = log.dig("metadata", "screen", "value")
  abort "expected log screen=customers, got #{screen.inspect}" unless screen == "customers"
  background_log = logs.find { |entry| entry["message"] == "example_customers_background_visible" }
  abort "missing background example_customers_background_visible log" unless background_log
  background_screen = background_log.dig("metadata", "screen", "value")
  background_origin = background_log.dig("metadata", "origin", "value")
  abort "expected background log screen=customers, got #{background_screen.inspect}" unless background_screen == "customers"
  abort "expected background log origin=background, got #{background_origin.inspect}" unless background_origin == "background"
  inspection = JSON.parse(File.read(ARGV.fetch(1)))
  custom = inspection.fetch("node").fetch("custom")
  abort "expected inspect screen=customers" unless custom.dig("screen", "value") == "customers"
  abort "expected inspect fixture=true" unless custom.dig("fixture", "value") == true
' "$LOGS_PATH" "$INSPECT_PATH"
