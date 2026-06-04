# Platform Runtime Handoff

Last updated: 2026-06-04.

This document captures the current in-progress state for continuing platform
runtime support work on another machine. Do not treat this as a completed
release note.

Update: repository example apps should stay import-free when injection exists.
iOS/tvOS Simulator and macOS examples now use injection paths rather than
linking `LoupeKit` into the example app. Physical-device support still requires
the target app to link and embed the dynamic `LoupeInjector` product in a
debug-only target; launch-time `DYLD_INSERT_LIBRARIES` injection is
simulator-only.
`loupe app launch --linked` now uses CoreDevice `devicectl`, so devices that are
visible only through legacy Xcode device services still need manual app launch
plus `loupe app use --host`.

## Branch And Scope

- Branch: `feature/platform-runtime-support`
- User requested no release work.
- User previously asked not to commit arbitrarily; keep the working tree
  uncommitted unless explicitly asked.
- There are unrelated/user-touched signing changes in Xcode project files.
  Do not revert them without checking with the user.

## Current Dirty Tree Highlights

Major in-progress areas:

- Runtime diagnostics:
  - `Sources/LoupeCore/Diagnostics.swift`
  - `Sources/LoupeKit/LoupeRuntime.swift`
  - `Sources/LoupeKit/LoupeServer.swift`
  - `Sources/LoupeKit/LoupeRuntimeObjects.swift` (new)
  - `Sources/LoupeCLI/DiagnosticCommands.swift`
  - `Sources/LoupeCLI/LoupeCLIUsage.swift`
  - CLI/platform tests
- Platform examples:
  - `Examples/MacLoupeExample/main.swift`
  - `Examples/MacLoupeExample/run-macos-e2e.sh`
  - `Examples/LoupeTVExample/LoupeTVExample/TVViewController.swift`
  - `Examples/LoupeTVExample/run-tvos-runtime-e2e.sh`
  - `Examples/LoupeExample/LoupeExample/ViewController.swift`
  - `Examples/LoupeExample/run-native-scenarios.sh`
- SwiftUI probe work:
  - `Sources/LoupeKit/LoupeSwiftUIProbe.swift` (new)
  - `README.md`
  - `skills/loupe/SKILL.md`

## SwiftUI Probe State

The desired shape is:

- Apps that import `LoupeKit` can use a public SwiftUI modifier:

  ```swift
  import LoupeKit
  import SwiftUI

  VStack {
      // ...
  }
  .accessibilityIdentifier("checkout.form")
  .loupeProbe("checkout.form.probe", label: "Checkout form")
  ```

- Apps that do not import `LoupeKit` should use a zero-dependency helper
  snippet that creates a tiny `UIViewRepresentable` or `NSViewRepresentable`
  with only standard accessibility identifiers.

Current implementation:

- Added `Sources/LoupeKit/LoupeSwiftUIProbe.swift`.
- It exposes `View.loupeProbe(_ id: String, label: String? = nil)`.
- The modifier uses `background` to attach a 1x1 platform probe view:
  - iOS/tvOS: `UIViewRepresentable`
  - macOS: `NSViewRepresentable`
- The platform view sets:
  - test/accessibility identifier
  - accessibility label
  - `loupe.probe=true` metadata when `LoupeKit` is linked

Important unresolved issue:

- `Examples/LoupeExample/LoupeExample/ViewController.swift` currently calls
  `.loupeProbe(...)` but does not import or link `LoupeKit` in the Xcode iOS
  app target.
- Physical-device Xcode build failed with:

  ```text
  value of type 'ModifiedContent<some View, AccessibilityAttachmentModifier>' has no member 'loupeProbe'
  ```

Chosen fixes:

1. Keep injected examples dependency-free and use local zero-dependency probe
   helpers when a SwiftUI anchor is needed.
2. Use bridge notifications for app-authored logs, metadata, reference
   evidence, and lifetime probes.
3. For physical-device debug apps, link and embed dynamic `LoupeInjector`
   instead of importing `LoupeKit` and starting `LoupeServer` from app code.

## Verification Already Completed Before SwiftUI Modifier Change

These passed before replacing the inline probe views with `.loupeProbe(...)`:

```bash
swift test
swift build --product loupe
swift build --product MacLoupeExample
git diff --check
Examples/LoupeExample/run-native-scenarios.sh
Examples/MacLoupeExample/run-macos-e2e.sh
Examples/LoupeTVExample/run-tvos-runtime-e2e.sh
scripts/verify-agent-work.sh
```

After adding `LoupeSwiftUIProbe.swift`, these passed:

```bash
swift build --product loupe --product MacLoupeExample
git diff --check
```

These have not yet been rerun after the modifier change:

```bash
swift test
Examples/LoupeExample/run-native-scenarios.sh
Examples/MacLoupeExample/run-macos-e2e.sh
Examples/LoupeTVExample/run-tvos-runtime-e2e.sh
scripts/verify-agent-work.sh
```

## Physical Device Checks

### iPhone X, iOS 16.7.16, 2026-06-04

Connected device was detected by legacy Xcode device services:

```text
Name: won의 iPhone
Hardware UDID: 8f27590f4a1b239f0f7c6d4f90090291243a213e
Model: iPhone X / iPhone10,6
iOS: 16.7.16
xcdevice: available=true
xctrace: online
```

CoreDevice detected a related device record but could not use it:

```text
CoreDevice identifier: 0299A737-9A98-5D0A-A431-B0E98532B121
devicectl state: unavailable
pairingState: unsupported
tunnelState: unavailable
ddiServicesAvailable: false
```

Observed results:

- `xcrun devicectl device process launch --device
  0299A737-9A98-5D0A-A431-B0E98532B121 ...` failed with CoreDevice error 1011.
- `xcrun devicectl device process launch --device
  8f27590f4a1b239f0f7c6d4f90090291243a213e ...` failed because CoreDevice did
  not know the legacy UDID.
- `xcodebuild` could target the legacy UDID, but device build failed because the
  current provisioning profile does not include this device and local Xcode
  account credentials are unavailable for automatic provisioning.

Conclusion: this iPhone X is useful for proving the unsupported-device branch,
but not for a full Loupe physical-device E2E until provisioning is fixed and the
linked app is launched outside `devicectl`.

### iPhone 15 Pro, iOS 26.5, 2026-06-04

Connected device was detected:

```text
Name: 허원의 iPhone 15 pro
CoreDevice identifier: DA221F6B-B7C8-5DD5-AB36-1C59CDD720E4
Hardware UDID: 00008130-00121D312204001C
Model: iPhone 15 Pro
iOS: 26.5
Developer Mode: enabled
Transport: wired
Tunnel: connected
```

Commands run:

```bash
xcrun devicectl list devices
xcrun devicectl device info details --device DA221F6B-B7C8-5DD5-AB36-1C59CDD720E4
xcodebuild -project /tmp/loupe-device-fixture/ReadingNowApp/ReadingNowApp.xcodeproj -scheme ReadingNowApp -destination 'id=00008130-00121D312204001C' -configuration Debug -derivedDataPath /tmp/loupe-device-fixture/DerivedData build
xcrun devicectl device install app --device DA221F6B-B7C8-5DD5-AB36-1C59CDD720E4 /tmp/loupe-device-fixture/DerivedData/Build/Products/Debug-iphoneos/ReadingNowApp.app
.build/debug/loupe app launch --bundle-id dev.loupe.readingnow --device DA221F6B-B7C8-5DD5-AB36-1C59CDD720E4 --linked --host 'http://[fdc2:95e8:dd9e::1]:8765' --port 8765 --bind-host 0.0.0.0 --timeout 20
.build/debug/loupe app info --host 'http://[fdc2:95e8:dd9e::1]:8765'
.build/debug/loupe ui snapshot --host 'http://[fdc2:95e8:dd9e::1]:8765' --timeout 10 --output /tmp/loupe-device-injector-snapshot.json
.build/debug/loupe ui query /tmp/loupe-device-injector-snapshot.json --test-id readingNow.title --max-results 1
```

Observed results:

- `devicectl` sees the physical device and reports developer mode/tunnel
  available.
- `LoupeInjector` is a dynamic Swift package product and was linked, embedded,
  signed, and loaded by the debug app.
- The debug app did not import `LoupeKit` and did not call
  `LoupeServer.start()` from app code.
- `loupe app launch --linked` passed `LOUPE_PORT=8765` and
  `LOUPE_BIND_HOST=0.0.0.0` through CoreDevice and stored the runtime host.
- `loupe app info` returned a live iOS runtime with device identifier
  `DA221F6B-B7C8-5DD5-AB36-1C59CDD720E4`.
- `loupe ui snapshot` and `loupe ui query --test-id readingNow.title` succeeded;
  the queried text was `Reading Now`.

Current physical-device support conclusion:

- Injection launch is simulator-only today because Loupe uses `simctl launch`
  plus `DYLD_INSERT_LIBRARIES`.
- A debug app that links and embeds dynamic `LoupeInjector` is the intended
  device path. `LoupeInjector` depends on `LoupeKit` internally and starts
  `LoupeServer` automatically when the library loads. The current host CLI can
  launch CoreDevice-compatible devices with `--linked`, but older devices that
  are unavailable to `devicectl` need manual Xcode launch plus
  `loupe app use --host`.
- `LoupeServer` binds to `127.0.0.1` by default. Real-device local-network
  inspection needs an intentional device-reachable bind, such as
  `LOUPE_BIND_HOST=0.0.0.0`, plus Mac/device network reachability.

## Recommended Next Steps

1. Re-run the verification matrix after any further runtime or example changes:

   ```bash
   swift build --product loupe --product MacLoupeExample
   swift test
   Examples/LoupeExample/run-native-scenarios.sh
   Examples/MacLoupeExample/run-macos-e2e.sh
   Examples/LoupeTVExample/run-tvos-runtime-e2e.sh
   git diff --check
   ```

2. For real-device support, keep the separate linked-runtime path instead of
   trying to stretch simulator injection:
   - CoreDevice-compatible `devicectl` install/launch support
   - clear unsupported-device fallback for legacy Xcode-only devices
   - linked and embedded `LoupeInjector` runtime on device
   - host-to-device transport
   - device screenshots/input strategy
   - tests that distinguish simulator-only from physical-device support
