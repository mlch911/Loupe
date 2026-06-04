# Platform Runtime Handoff

Last updated: 2026-06-04.

This document captures the current in-progress state for continuing platform
runtime support work on another machine. Do not treat this as a completed
release note.

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

Likely fixes:

1. Add/link `LoupeKit` to the iOS Xcode example target and import it, if the
   iOS example should prove the public API.
2. Or keep the injected iOS example dependency-free and add a local
   zero-dependency fallback helper there. This better demonstrates the
   injection-only path.
3. For macOS and tvOS linked examples, keep using the `LoupeKit` public modifier.

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

## Physical Device Check

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
.build/debug/loupe app launch --bundle-id dev.loupe.example --device DA221F6B-B7C8-5DD5-AB36-1C59CDD720E4 --timeout 5
xcodebuild -project Examples/LoupeExample/LoupeExample.xcodeproj -scheme LoupeExample -destination 'id=DA221F6B-B7C8-5DD5-AB36-1C59CDD720E4' -configuration Debug build
xcodebuild -project Examples/LoupeExample/LoupeExample.xcodeproj -scheme LoupeExample -destination 'id=00008130-00121D312204001C' -configuration Debug build
```

Observed results:

- `devicectl` sees the physical device and reports developer mode/tunnel
  available.
- `loupe app launch` does not support this physical-device id. It currently
  resolves `--device` through `simctl` and failed with:

  ```text
  error: Expected exactly one booted simulator named DA221F6B-B7C8-5DD5-AB36-1C59CDD720E4, found 0. Pass --device <UDID>.
  ```

- Xcode destination needs the hardware UDID, not the CoreDevice identifier.
- Physical-device Xcode build reached compile/signing stages, then failed on
  missing `.loupeProbe(...)` as described above.

Current physical-device support conclusion:

- Injection launch is simulator-only today because Loupe uses `simctl launch`
  plus `DYLD_INSERT_LIBRARIES`.
- A linked `LoupeKit` app may be buildable for device, but the current host CLI
  does not yet have a `devicectl` launch/attach/tunnel path.
- `LoupeServer` currently binds to `127.0.0.1` inside the app runtime, so a
  real-device path will need explicit host reachability work, such as CoreDevice
  service/tunnel forwarding or an intentional device-reachable bind strategy.

## Recommended Next Steps

1. Decide whether the iOS example should prove `LoupeKit` public API or the
   zero-dependency fallback path.
2. Fix `Examples/LoupeExample/LoupeExample/ViewController.swift` accordingly.
3. Re-run:

   ```bash
   swift build --product loupe --product MacLoupeExample
   swift test
   Examples/LoupeExample/run-native-scenarios.sh
   Examples/MacLoupeExample/run-macos-e2e.sh
   Examples/LoupeTVExample/run-tvos-runtime-e2e.sh
   git diff --check
   ```

4. For real-device support, design a separate implementation path instead of
   trying to stretch simulator injection:
   - `devicectl` install/launch support
   - linked `LoupeKit` runtime on device
   - host-to-device transport
   - device screenshots/input strategy
   - tests that distinguish simulator-only from physical-device support

