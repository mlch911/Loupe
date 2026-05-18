# Loupe Agent Guide

This repository is a SwiftPM/Xcode prototype for Loupe, an iOS Simulator
inspection and action harness.

Use this file as a map, not as a full manual. Keep deeper project state in
`Docs/Status.md` and product direction in `Docs/LoupePlan.md`.

## Current Shape

- `Sources/LoupeCore`: snapshot models, accessibility tree models, compact
  observations, queries, inspection, layout audit, simctl helpers, injector path
  resolution.
- `Sources/LoupeKit`: in-app iOS SDK and localhost observation server.
- `Sources/LoupeInjection`: simulator-only injected library that starts
  `LoupeServer`.
- `Sources/LoupeCLI`: host CLI for fetch, compact, query, inspect, audit,
  launch, doctor, runtime actions, recording, replay, and injector path lookup.
- `Examples/LoupeExample`: UIKit simulator app used to prove injection,
  snapshotting, and coordinate resolution for UI actions.
- `skills/loupe`: draft Codex skill for Loupe workflows.

## Architecture Rules

- LoupeKit observes app state. It should not be the primary place where touch
  events are synthesized.
- Runtime E2E should be driven by the Loupe CLI or a host runner, not by
  `xcodebuild test`, XCTest cases, or a test bundle as the public harness.
- User actions should be executed from the host side by a simulator action
  backend that consumes Loupe snapshots and emits real simulator UI input.
- Use the view tree for UI/layout/style validation. Use the accessibility tree
  first for movement and input; selector actions should only fall back to view
  frames when no accessibility match exists.
- The CLI should eventually expose `tap`, `swipe`, `drag`, and `type`, but those
  commands currently delegate low-level HID dispatch to AXe until a native Loupe
  HID backend exists.
- Keep full snapshots on disk. Send compact observations to agents by default,
  then query or inspect specific refs on demand.
- Prefer stable `testID` / `accessibilityIdentifier` selectors over text or
  geometry when test intent is known.

## Verification

Run the fast SwiftPM tests. Core unit tests use Swift Testing (`import Testing`,
`@Test`, `#expect`, `#require`), not XCTest:

```bash
swift test
```

Verify simulator injection and observation:

```bash
Examples/LoupeExample/run-injected.sh
```

Verify AXe-backed runtime navigation, accessibility tree export/query, UIKit
component inspection, and layout audit:

```bash
Examples/LoupeExample/run-axe-scenarios.sh
```

Verify the legacy UIKit XCTest example flow:

```bash
xcodebuild \
  -project Examples/LoupeExample/LoupeExample.xcodeproj \
  -scheme LoupeExample \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  -only-testing:LoupeExampleUITests/LoupeExampleUITests/testNavigationListFormAndGestures \
  test
```

Verify the legacy Loupe snapshot to coordinate action proof:

```bash
Examples/LoupeExample/run-loupe-driven-ui-test.sh
```

## Known Boundary

`loupe tap` / `loupe swipe` / `loupe drag` / `loupe type` exist as runtime
commands. They depend on AXe for HID dispatch for now. `loupe pinch` keeps the
intended API shape, but AXe does not support pinch yet. The current UI test
remains a legacy proof only.
