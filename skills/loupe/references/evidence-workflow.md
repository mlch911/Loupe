# Evidence Workflow

## Observe

```bash
REPORT=/tmp/loupe-checkout-report
rm -rf "$REPORT"
loupe ui report --bundle-id com.example.App --output "$REPORT"
loupe ui compact "$REPORT/snapshot.json"
loupe ui screen "$REPORT/snapshot.json" --limit 80
loupe ui tree "$REPORT/snapshot.json" --accessibility --depth 3
loupe ui tree "$REPORT/snapshot.json" --view --depth 3
loupe ui node "$REPORT/snapshot.json" --test-id target.id
```

`ui report` stores screenshot, snapshot, screen-map, accessibility, compact,
audit, runtime, and summary files. Logs are in `runtime.json.logs`; newer CLI
builds may also emit `logs.json`.

Start broad, then query only the target:

```bash
loupe ui query "$REPORT/snapshot.json" --test-id target.id
loupe ui node "$REPORT/snapshot.json" --test-id target.id --node-only
loupe ui subtree "$REPORT/snapshot.json" --test-id target.container --depth 2
```

Prefer `--test-id` when available. Use `--ref` only within the same snapshot.
Use text or role flags for discovery, then switch to `testID` or `ref`.

## SwiftUI And Bridge Evidence

For SwiftUI, prefer stable accessibility surfaces over private hierarchy
assumptions. If the app imports `LoupeKit`, ask for the public
`.loupeProbe(...)` modifier on complex regions that need durable `ui node`
targets with captured bounds. If the app should not depend on `LoupeKit`, ask
for an equivalent zero-dependency `UIViewRepresentable` or
`NSViewRepresentable` helper with a local name such as `.localLoupeProbe(...)`;
it should be attached with `background` and set standard accessibility
identifiers and labels only.

On watchOS, there is no UIKit/AppKit view-tree walker. A no-import local
SwiftUI helper should measure bounds with `GeometryReader` and post
`dev.loupe.probe` / `dev.loupe.removeProbe`; injected Loupe registers those
probes into the same runtime backend used by public `Loupe.registerProbe(...)`.

For app diagnostics, use `Loupe.log("checkout_visible")` when importing
`LoupeKit`. Without that import, post the bridge notification and read logs:

```swift
NotificationCenter.default.post(
    name: Notification.Name("dev.loupe.log"),
    object: nil,
    userInfo: ["message": "checkout_visible"]
)
```

```bash
loupe debug logs --bundle-id com.example.App --output "$REPORT/logs.json"
```

Use `Notification.Name("dev.loupe.viewMetadata")` for scalar metadata on a
UIKit view or stable `testID`, then verify with `loupe ui node`.

## References And Object Diagnostics

Use `Loupe.recordReference(...)` or the `dev.loupe.reference` notification when
the task needs ownership evidence, then answer owner questions with:

```bash
loupe debug object-graph DeviceActuationService --host <runtime-host> --output /tmp/loupe-reference-graph.json
```

The graph is app-authored reference evidence, not private heap traversal. Use
`owners` to answer what points at a target, and cite `evidenceID`, `kind`,
`label`, `metadata`, and `timestamp`.

For runtime object diagnostics:

```bash
loupe debug objects classes --matching DeviceActuationService --host <runtime-host> --output /tmp/loupe-object-classes.json
loupe debug objects describe DeviceActuationService --host <runtime-host> --output /tmp/loupe-object-description.json
loupe debug leaks --alive-only --host <runtime-host> --output /tmp/loupe-leaks.json
```

`debug objects` reads Objective-C runtime class metadata. `debug leaks` reads
weak lifetime probes registered by the app with `Loupe.watchLifetime(...)`; it
is not full private heap traversal.
