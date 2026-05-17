# Loupe Agent Guide

This repository is a SwiftPM/Xcode prototype for Loupe, an iOS Simulator
inspection and action harness.

Use this file as a map, not as a full manual. Keep deeper project state in
`Docs/Status.md` and product direction in `Docs/LoupePlan.md`.

## Current Shape

- `Sources/LoupeCore`: snapshot models, compact observations, queries, simctl
  helpers, injector path resolution.
- `Sources/LoupeKit`: in-app iOS SDK and localhost observation server.
- `Sources/LoupeInjection`: simulator-only injected library that starts
  `LoupeServer`.
- `Sources/LoupeCLI`: host CLI for fetch, compact, query, launch, doctor, and
  injector path lookup.
- `Examples/LoupeExample`: UIKit simulator app used to prove injection,
  snapshotting, and coordinate-driven UI actions.
- `skills/loupe`: draft Codex skill for Loupe workflows.

## Architecture Rules

- LoupeKit observes app state. It should not be the primary place where touch
  events are synthesized.
- User actions should be executed from the host side through XCTest/XCUITest or
  a WebDriverAgent-style runner.
- The CLI should eventually expose `tap`, `swipe`, `drag`, and `type`, but those
  commands should delegate to an action runner that consumes Loupe snapshots and
  emits real simulator UI actions.
- Keep full snapshots on disk. Send compact observations to agents by default,
  then query or inspect specific refs on demand.
- Prefer stable `testID` / `accessibilityIdentifier` selectors over text or
  geometry when test intent is known.

## Verification

Run the fast SwiftPM tests:

```bash
swift test
```

Verify simulator injection and observation:

```bash
Examples/LoupeExample/run-injected.sh
```

Verify the normal UIKit example flow:

```bash
xcodebuild \
  -project Examples/LoupeExample/LoupeExample.xcodeproj \
  -scheme LoupeExample \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  -only-testing:LoupeExampleUITests/LoupeExampleUITests/testNavigationListFormAndGestures \
  test
```

Verify Loupe snapshot to coordinate action proof:

```bash
Examples/LoupeExample/run-loupe-driven-ui-test.sh
```

## Known Boundary

`loupe tap` / `loupe swipe` / `loupe drag` / `loupe type` are not implemented
yet. The current proof lives in the example UI test: it fetches Loupe snapshots,
resolves node frames by `testID`, and executes XCUITest coordinate actions.
