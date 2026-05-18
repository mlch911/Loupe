#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DEVICE_NAME="${LOUPE_DEVICE_NAME:-iPhone 17 Pro}"
PORT="${LOUPE_PORT:-8765}"

cd "$ROOT_DIR"

swift build

xcodebuild \
  -scheme LoupeInjector \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  build >/tmp/loupe-injector-build.log

xcodebuild \
  -project Examples/LoupeExample/LoupeExample.xcodeproj \
  -scheme LoupeExample \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
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

xcrun simctl boot "$DEVICE_NAME" >/dev/null 2>&1 || true
xcrun simctl install booted "$APP_PATH"
xcrun simctl terminate booted dev.loupe.example >/dev/null 2>&1 || true

.build/debug/loupe launch \
  --device booted \
  --bundle-id dev.loupe.example \
  --inject \
  --env LOUPE_PORT="$PORT" >/dev/null

sleep 2

LOUPE_PORT="$PORT" xcodebuild \
  -project Examples/LoupeExample/LoupeExample.xcodeproj \
  -scheme LoupeExample \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -configuration Debug \
  -only-testing:LoupeExampleUITests/LoupeExampleUITests/testLoupeDrivenCoordinateActionsAgainstInjectedApp \
  test
