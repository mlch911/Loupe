# Runtime Communication

Loupe injection starts `LoupeServer` inside the simulator app process and binds
HTTP to `127.0.0.1`. The CLI talks to that local server with `--host`; it uses
`--udid` only to validate that the contacted server belongs to the expected
simulator.

The default port is `8765`. Keep it for the single-simulator case. For multiple
simulators or multiple injected apps, launch each app with a different
`LOUPE_PORT` and pass the matching `--host` to CLI commands.

HTTPS is not required for this path. Loupe is not making the app call an
external service; the host CLI is calling the app's loopback server inside the
iOS Simulator. The server binds only to localhost.

## App To Loupe

When an app links `LoupeKit`, it can call the Swift APIs directly. When Loupe is
injected and the app does not import `LoupeKit`, app code can still send logs and
view metadata through `NotificationCenter` string names.

```swift
NotificationCenter.default.post(
    name: Notification.Name("dev.loupe.log"),
    object: nil,
    userInfo: [
        "level": "info",
        "message": "checkout_visible",
        "metadata": ["cartID": "cart-123", "itemCount": 3]
    ]
)
```

Attach metadata to a concrete UIKit view:

```swift
NotificationCenter.default.post(
    name: Notification.Name("dev.loupe.viewMetadata"),
    object: payButton,
    userInfo: [
        "metadata": ["screen": "checkout", "variant": "primary"]
    ]
)
```

Attach metadata by stable test id when the view object is inconvenient:

```swift
NotificationCenter.default.post(
    name: Notification.Name("dev.loupe.viewMetadata"),
    object: nil,
    userInfo: [
        "testID": "checkout.payButton",
        "metadata": ["screen": "checkout", "variant": "primary"]
    ]
)
```

Metadata values are intentionally scalar: `String`, `Bool`, `Int`, `Double`, and
`Float`/`NSNumber` values that map to those types.

## SwiftUI Boundary

Loupe does not synthesize a SwiftUI view tree. SwiftUI elements are valid
movement/input targets only when they are exposed through the accessibility tree.
If a SwiftUI `.accessibilityIdentifier(...)` is not visible through the runtime
accessibility tree, Loupe will not invent a selector for it from private SwiftUI
implementation views. Recording follows the same rule: SwiftUI-backed view-tree
nodes are skipped as replay selector candidates, while accessibility nodes remain
eligible.
