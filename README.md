# Loupe

Loupe is an iOS Simulator inspection harness for giving runners and agents compact, structured screen context.

The package is split into four layers:

- `LoupeCore`: Codable snapshot models, compact observations, selector queries, and `simctl` helpers.
- `LoupeKit`: embedded iOS observation SDK for view snapshots, custom metadata, and localhost transport.
- `LoupeInjector`: simulator-only dynamic library for app-side observation without linking the SDK.
- `loupe`: macOS CLI for fetching, compacting, querying, and launching apps.

Loupe intentionally avoids private `UIEvent` injection. App interaction should be driven by XCTest/XCUITest or a WebDriverAgent-style runner, while Loupe provides richer app-side context.

See `Docs/Status.md` for the current verified capabilities, limitations, and
the planned action-runner path.

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
```

## Simulator Injection

For simulator-only dylib injection, install Loupe through Homebrew and launch the app with automatic injector discovery:

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
loupe query snapshot.json --text "Pay now"
loupe query snapshot.json --role button
```

## Example

`Examples/LoupeExample` contains a UIKit app that does not link `LoupeKit`. It
is used to verify simulator injection, snapshotting, normal UI flows, and the
current Loupe snapshot to coordinate-action proof.

```bash
Examples/LoupeExample/run-injected.sh
```

The script builds the example app and `LoupeInjector`, installs the app on a
booted simulator, launches it with injection, fetches `/snapshot`, and queries a
visible table node.

To verify that Loupe snapshot frames can drive real simulator interactions via
XCUITest coordinates:

```bash
Examples/LoupeExample/run-loupe-driven-ui-test.sh
```

`loupe tap`, `loupe swipe`, `loupe drag`, and `loupe type` are not implemented
yet. The example UI test is the current proof that the architecture works.
