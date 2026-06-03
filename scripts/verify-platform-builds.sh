#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-Release}"
MACOS_DESTINATION='generic/platform=macOS'
IOS_SIMULATOR_DESTINATION='generic/platform=iOS Simulator'
TVOS_DESTINATION='generic/platform=tvOS'
TVOS_SIMULATOR_TRIPLE="${TVOS_SIMULATOR_TRIPLE:-arm64-apple-tvos-simulator}"

cd "$ROOT_DIR"

run_step() {
  local name="$1"
  shift
  echo "==> $name"
  "$@"
}

build_scheme() {
  local scheme="$1"
  local destination="$2"
  local slug

  slug="$(printf '%s-%s-%s' "$scheme" "$destination" "$CONFIGURATION" | tr -c '[:alnum:]' '-')"

  xcodebuild \
    -scheme "$scheme" \
    -destination "$destination" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "/tmp/loupe-platform-builds/$slug" \
    build
}

destination_available() {
  local platform="$1"
  local output="$2"

  awk '
    /Available destinations/ { in_available = 1; next }
    /Ineligible destinations/ { in_available = 0 }
    in_available { print }
  ' <<<"$output" | grep -q "platform:${platform},"
}

print_ineligible_destination() {
  local platform="$1"
  local output="$2"

  awk -v platform="platform:${platform}," '
    /Ineligible destinations/ { in_ineligible = 1; next }
    in_ineligible && index($0, platform) { print }
  ' <<<"$output"
}

require_destination() {
  local scheme="$1"
  local platform="$2"
  local output

  if ! output="$(xcodebuild -showdestinations -scheme "$scheme" 2>&1)"; then
    echo "$output" >&2
    echo "error: could not inspect Xcode destinations for $scheme" >&2
    exit 1
  fi

  if destination_available "$platform" "$output"; then
    return 0
  fi

  echo "error: $platform destination is unavailable for $scheme." >&2
  print_ineligible_destination "$platform" "$output" >&2
  exit 1
}

build_tvos_cross_target() {
  local target="$1"
  local build_path="$2"
  local sdk

  sdk="$(xcrun --sdk appletvsimulator --show-sdk-path)"
  swift build \
    --build-path "$build_path" \
    --triple "$TVOS_SIMULATOR_TRIPLE" \
    --sdk "$sdk" \
    --target "$target"
}

build_tvos_cross_product() {
  local product="$1"
  local build_path="$2"
  local sdk

  sdk="$(xcrun --sdk appletvsimulator --show-sdk-path)"
  swift build \
    --build-path "$build_path" \
    --triple "$TVOS_SIMULATOR_TRIPLE" \
    --sdk "$sdk" \
    --product "$product"
}

can_build_tvos_with_xcode() {
  local scheme="$1"
  local output

  output="$(xcodebuild -showdestinations -scheme "$scheme" 2>&1 || true)"
  destination_available tvOS "$output"
}

run_step "release CLI build" swift build --configuration release --disable-sandbox --product loupe

run_step "macOS LoupeKit build" build_scheme LoupeKit "$MACOS_DESTINATION"
run_step "macOS LoupeInjector build" build_scheme LoupeInjector "$MACOS_DESTINATION"

run_step "iOS Simulator LoupeKit build" build_scheme LoupeKit "$IOS_SIMULATOR_DESTINATION"
run_step "iOS Simulator LoupeInjector build" build_scheme LoupeInjector "$IOS_SIMULATOR_DESTINATION"

if can_build_tvos_with_xcode LoupeKit && can_build_tvos_with_xcode LoupeInjector; then
  run_step "tvOS LoupeKit build" build_scheme LoupeKit "$TVOS_DESTINATION"
  run_step "tvOS LoupeInjector build" build_scheme LoupeInjector "$TVOS_DESTINATION"
else
  echo "==> tvOS Xcode destinations unavailable; using AppleTVSimulator SwiftPM cross-build"
  run_step "tvOS LoupeKit cross-build" build_tvos_cross_target LoupeKit /tmp/loupe-platform-tvos-kit
  run_step "tvOS LoupeInjection cross-build" build_tvos_cross_target LoupeInjection /tmp/loupe-platform-tvos-injection
  run_step "tvOS LoupeInjector cross-build" build_tvos_cross_product LoupeInjector /tmp/loupe-platform-tvos-injector
fi

echo "platform build verification passed"
