# Loupe Status

Last verified: 2026-05-17.

## Goal

Loupe is intended to become a Playwright-like harness for iOS Simulator apps:

1. Launch an app with observation enabled.
2. Capture a structured app-side view tree with stable selectors and custom
   metadata.
3. Give agents compact screen context instead of the entire tree.
4. Resolve specific nodes on demand.
5. Execute real simulator interactions such as tap, scroll, drag, swipe, and
   type.
6. Record enough traces, screenshots, snapshots, and logs to make failures
   reproducible.

Figma API integration is intentionally out of scope for the current phase. The
near-term visual goal is to support screenshot, layout, and style assertions
against known expectations or baselines.

## Harness Engineering Principles

The project direction follows the OpenAI harness engineering guidance from
`https://openai.com/index/harness-engineering/`:

- Build an environment where agents can inspect, act, and validate with normal
  engineering tools.
- Keep repository knowledge as the system of record. `AGENTS.md` should be a
  map, with deeper details stored in focused docs.
- Make the application legible to agents with stable structure, selectors,
  observations, traces, and mechanical feedback.
- Enforce boundaries and invariants in code and tests instead of relying only on
  prose instructions.
- Prefer short feedback loops that reproduce failures, apply changes, and verify
  outcomes.

For Loupe, this means the SDK captures high-quality app context, the host owns
actions and traces, and the CLI exposes small deterministic tools that agents can
compose.

## Verified

- SwiftPM package builds and tests pass.
- `LoupeKit` can expose `/health`, `/snapshot`, and `/observation` over
  localhost.
- `LoupeInjector` can be built as a simulator-only injected library.
- `loupe launch --inject` can launch the example app with
  `DYLD_INSERT_LIBRARIES` through `simctl`.
- `loupe query` can resolve nodes from a full snapshot by `testID`, text, role,
  or ref.
- `Examples/LoupeExample/run-injected.sh` verifies injection, health, snapshot,
  and query.
- The example app now includes navigation, a large table view, a detail screen,
  a pan gesture target, and a modal form.
- `testNavigationListFormAndGestures` verifies normal XCUITest navigation,
  table scrolling, form input, and gesture behavior.
- `run-loupe-driven-ui-test.sh` verifies the key proof: fetch Loupe snapshot,
  find nodes by `testID`, convert view frames to window coordinates, and execute
  XCUITest tap/drag actions against those coordinates.

## Current Limitation

Loupe does not yet expose CLI action commands. There is no production
implementation for:

```bash
loupe tap --test-id example.customer.24
loupe swipe --test-id example.customerList --direction up
loupe drag --test-id example.gestureCard --from 0.2,0.5 --to 0.85,0.5
loupe type --test-id example.form.name "Ada"
```

The current action proof is intentionally implemented in
`Examples/LoupeExample/LoupeExampleUITests/LoupeExampleUITests.swift` using
`XCUIApplication`, `XCUICoordinate`, and snapshots fetched from Loupe.

## Action Strategy

Do not make app-internal `UIEvent` synthesis the main strategy. It is fragile on
iOS, depends on private behavior, and does not match how user-visible simulator
interactions are normally driven.

The desired structure is:

```text
loupe CLI
  -> action runner process or XCTest bundle
    -> fetch Loupe snapshot
    -> resolve node by ref/testID/text/role
    -> compute screen/window coordinate
    -> execute XCUITest/WebDriverAgent-style action
    -> capture after snapshot, screenshot, and action log
```

This keeps observation and action separated:

- `LoupeKit` / `LoupeInjector`: app-side observation and metadata.
- `LoupeCore`: selectors, refs, geometry, query, compact context.
- `LoupeActionRunner` future target: real simulator input through XCTest or a
  WebDriverAgent-style bridge.
- `loupe` CLI: stable public commands and trace output.

## Next Work

1. Add a `LoupeActionRunner` target or example runner that can be launched by
   the CLI.
2. Productize the UI-test proof into host commands for tap, swipe, drag, and
   type.
3. Define action traces: before snapshot, target query result, before screenshot,
   action payload, after snapshot, after screenshot, and logs.
4. Add `inspect(ref)`, `subtree(ref, depth)`, and better selector scoring.
5. Add screenshot capture and baseline diff helpers.
6. Add layout/style assertions for design QA without requiring Figma API yet.
7. Improve installation flow: Homebrew formula should package the CLI and
   injector, and the Codex skill should discover that Homebrew path.

## Verified Commands

```bash
swift test
```

```bash
Examples/LoupeExample/run-injected.sh
```

```bash
xcodebuild \
  -project Examples/LoupeExample/LoupeExample.xcodeproj \
  -scheme LoupeExample \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug \
  -only-testing:LoupeExampleUITests/LoupeExampleUITests/testNavigationListFormAndGestures \
  test
```

```bash
Examples/LoupeExample/run-loupe-driven-ui-test.sh
```
