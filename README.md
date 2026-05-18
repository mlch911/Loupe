# Loupe

Loupe is an iOS Simulator inspection harness for giving runners and agents compact, structured screen context.

The package is split into four layers:

- `LoupeCore`: Codable snapshot models, compact observations, selector queries, and `simctl` helpers.
- `LoupeKit`: embedded iOS observation SDK for view snapshots, custom metadata, and localhost transport.
- `LoupeInjector`: simulator-only dynamic library for app-side observation without linking the SDK.
- `loupe`: macOS CLI for fetching, compacting, querying, and launching apps.

Loupe intentionally avoids app-internal private `UIEvent` injection. The target E2E path is runtime-driven: the CLI should launch, observe, and act on an iOS Simulator app without requiring `xcodebuild test`, XCTest cases, or a test bundle as the public harness.

Loupe keeps two inspection surfaces:

- view tree: UIKit object, layout, style, sibling, and parent/child validation
- accessibility tree: selector-driven movement and input, using accessibility
  activation points when they are valid

The first runtime action backend delegates low-level simulator input to AXe.
Loupe owns snapshot capture, selector resolution, SDK communication, recording,
and replay shape; a native Loupe HID backend can replace the AXe dependency
later.

See `Docs/Status.md` for the current verified capabilities, limitations, and
the planned action-runner path.
See `Docs/Goal.md` for the runtime E2E goal contract.

## LoupeKit

Add stable IDs and custom metadata in an app that links `LoupeKit`:

```swift
import LoupeKit

button.testID("checkout.payButton")
button.testProperty("screen", "checkout")
button.testProperty("variant", "primary")
```

Start the local observation server:

```swift
let server = LoupeServer()
try server.start()
```

The default endpoints are:

```text
GET http://127.0.0.1:8765/health
GET http://127.0.0.1:8765/snapshot
GET http://127.0.0.1:8765/observation
GET http://127.0.0.1:8765/accessibility
GET http://127.0.0.1:8765/inspect?testID=checkout.payButton
GET http://127.0.0.1:8765/subtree?testID=checkout.form&depth=3
GET http://127.0.0.1:8765/audit
GET http://127.0.0.1:8765/logs
GET http://127.0.0.1:8765/runtime
GET http://127.0.0.1:8765/recording/start
GET http://127.0.0.1:8765/recording/stop
GET http://127.0.0.1:8765/recording
```

## Simulator Injection

For simulator-only dylib injection, install Loupe through Homebrew and launch the app with automatic injector discovery. The Homebrew formula depends on AXe for runtime actions:

```bash
brew install loupe

loupe launch \
  --bundle-id dev.loupe.example \
  --inject
```

To inspect the path Loupe will inject:

```bash
loupe injector-path
loupe doctor
```

For local development, build `LoupeInjector` and launch the app with an explicit path:

```bash
loupe launch \
  --bundle-id dev.loupe.example \
  --dylib /absolute/path/LoupeInjector.framework/LoupeInjector
```

`LoupeInjector` starts `LoupeServer` inside the app process. This path is for simulator PoCs and legacy apps. Real-device support should use the embedded `LoupeKit` path.

## CLI

```bash
loupe fetch http://127.0.0.1:8765/observation
loupe compact snapshot.json
loupe query snapshot.json --test-id checkout.payButton
loupe accessibility snapshot.json
loupe query snapshot.json --tree accessibility --test-id checkout.payButton
loupe inspect snapshot.json --test-id checkout.payButton
loupe subtree snapshot.json --test-id checkout.form --depth 3
loupe audit snapshot.json
loupe wait-for-visible --test-id checkout.payButton --timeout 5
loupe query snapshot.json --text "Pay now"
loupe query snapshot.json --role button
loupe tap --test-id checkout.payButton --udid booted --trace-dir /tmp/loupe-trace
loupe swipe --from 220,760 --to 220,190 --udid booted --width 438 --height 954
loupe type "Ada" --udid booted
loupe screenshot --udid booted --output screen.png
loupe record-start
loupe record-stop --output flow.json
loupe replay flow.json --udid booted --width 438 --height 954
```

## Example

`Examples/LoupeExample` contains a UIKit app that does not link `LoupeKit`. It
is used to verify simulator injection, snapshotting, normal UI flows, and the
current legacy Loupe snapshot to coordinate-action proof.

```bash
Examples/LoupeExample/run-injected.sh
```

The script builds the example app and `LoupeInjector`, installs the app on a
booted simulator, launches it with injection, fetches `/snapshot`, and queries a
visible table node.

To verify the legacy proof that Loupe snapshot frames can drive real simulator
interactions via XCUITest coordinates:

```bash
Examples/LoupeExample/run-loupe-driven-ui-test.sh
```

`loupe tap`, `loupe swipe`, `loupe drag`, and `loupe type` now exist as runtime
commands. They currently require AXe on `PATH` for low-level simulator HID
dispatch. `loupe pinch` parses the intended API shape, but AXe does not support
pinch yet.

To verify the XCTest-free runtime smoke path:

```bash
Examples/LoupeExample/run-runtime-e2e.sh
```

To repeat the AXe-backed navigation, UIKit component inspection, subtree,
waiting, action trace, and layout audit scenarios:

```bash
Examples/LoupeExample/run-axe-scenarios.sh
```
