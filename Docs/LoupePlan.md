# Loupe Plan

## Goals

Build an iOS Simulator harness that supports:

- functional E2E flows
- view-tree and property observation
- custom app metadata
- screenshot-based visual QA
- rule-based layout/style QA

Figma API integration is intentionally out of scope for now.

## Architecture

```text
Host runner
  - starts simulator/app
  - stores full snapshots
  - sends compact observations to the LLM
  - executes actions through XCTest/XCUITest
  - stores screenshots, diffs, logs, and traces

LoupeKit
  - captures UIWindowScene/UIWindow/UIView tree
  - exposes custom metadata
  - serves snapshots over localhost transport

LoupeInjector
  - simulator-only dynamic library
  - starts LoupeServer from a dylib constructor path
  - works for basic observation without linking LoupeKit into the app

Homebrew install
  - installs loupe CLI into bin
  - installs LoupeInjector.framework into libexec
  - lets loupe launch --inject resolve the injector path automatically

LoupeCore
  - Codable full snapshot
  - compact observation
  - selector queries
  - ref-based action targets
```

## Action Boundary

Loupe should not rely on app-internal private `UIEvent` synthesis as the primary
interaction mechanism. The app-side SDK and injector observe state. Host-side
XCTest/XCUITest or a WebDriverAgent-style runner should execute interactions.

The target flow is:

```text
loupe tap --test-id checkout.payButton
  -> fetch /snapshot
  -> resolve node frame
  -> execute XCUITest coordinate tap
  -> store trace artifacts
```

The current proof for this flow lives in the example UI test and
`Examples/LoupeExample/run-loupe-driven-ui-test.sh`.

## Observation Policy

Do not put the whole tree into LLM context by default.

Default observation:

- screen size, scale, interface style
- visible texts, capped
- visible interactive elements, capped
- per-snapshot `ref` values

Implemented host-side query primitives:

- `testID`
- `text`
- `role`
- `ref`

Later on-demand tools:

- `inspect(ref)`
- `search(query)`
- `subtree(ref, depth)`
- `screenshotCrop(rect)`

## Validation Types

Functional E2E:

```swift
tap(ref)
type(ref, text)
swipe(ref, direction)
waitForVisible(testID)
```

Visual QA:

```swift
expectScreen("checkout.default").toMatchBaseline(threshold: 0.01)
```

Layout/style QA:

```swift
expect("checkout.payButton").toHaveFrame(height: 52)
expect("checkout.payButton").toHaveStyle(cornerRadius: 12)
expect("checkout.payButton").toBeBelow("checkout.password", spacing: 16)
```

## Next Implementation Steps

1. Add an XCTest/WebDriverAgent-style action runner that the CLI can drive.
2. Add CLI commands for `tap`, `swipe`, `drag`, and `type`.
3. Add trace artifacts for every action: before/after snapshots, screenshots,
   target resolution, and logs.
4. Add screenshot capture and baseline diff storage.
5. Add richer selector scoring and `inspect(ref)`.
6. Add layout/style assertion primitives.
7. Add a generated Codex skill/package release flow.
