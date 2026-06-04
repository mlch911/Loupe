<p align="center">
  <img src="Docs/Assets/loupe-wordmark.svg" alt="Loupe" width="360">
</p>

Loupe gives AI agents eyes, hands, and live app context inside running
Apple-platform apps.

Use its CLI to inspect UI and accessibility state, drive host-visible input, and
verify behavior with screenshots, logs, network/state evidence, and action
traces.

Core diagnostic loops:

| Question | Loupe loop |
| --- | --- |
| What is on screen, and why did this route render? | Capture `ui snapshot`, inspect view and accessibility nodes with `ui query` or `ui node`, then compare route logs and flags. |
| Did the app receive the data it rendered? | Use `debug network` to inspect URLSession requests, status codes, response bodies, and app-authored network evidence. |
| Did runtime data or storage change correctly? | Read `debug defaults`, `debug flags`, and `debug keychain list`, then compare them before and after the flow. |
| What changed after input or a visual mode switch? | Run `act tap`, `act press`, or `act swipe` with `--trace-dir`; use `ui audit`, `ui node`, and `debug scroll` for contrast, layout, and scroll evidence. |

## Demo

<img width="1051" height="806" alt="loupe" src="https://github.com/user-attachments/assets/4a079742-996d-46ab-b5b4-7eedc618fa7e" />

<details>
<summary>Video</summary>

<video src="https://github.com/user-attachments/assets/8bdc57f4-f673-480c-b970-535cfc96012c" controls width="720"></video>

</details>

## Install

```bash
brew tap heoblitz/loupe https://github.com/heoblitz/Loupe.git
brew install loupe
```

Install the Loupe skill for agent workflows:

```bash
loupe skills install
```

## Environment

Loupe currently supports injected iOS Simulator apps plus linked LoupeKit
runtimes for macOS AppKit apps and tvOS Simulator apps. The command interface is
organized around targets and capabilities so platform support can expand without
turning every platform feature into a new top-level command.

Requirements:

- macOS 14 or later.
- Xcode with the needed iOS and tvOS Simulator runtimes installed.

Xcode and simulator versions can affect runtime injection, native HID input, and
platform-specific runtime behavior.

Loupe chooses an available localhost port for injected apps and records the
runtime. Use `--bundle-id`, `--udid`, or `loupe app use <bundle-id>` to select
the target app instead of hard-coding a host port.

## Quick Start

For agent workflows, start with this context:

```text
Use Loupe as the runtime context for this app. Inspect view and accessibility trees, collect runtime evidence, act through host-visible input when supported, and verify behavior with traces before editing code.
```

For direct CLI control:

```bash
loupe app launch --bundle-id com.example.App --device <iPhone simulator UDID>
loupe app list
loupe app use com.example.App
loupe app current
```

The public CLI keeps four stable groups. Older flat or overlapping commands are
not part of the supported interface:

```text
app     Launch, select, list, and query app runtimes.
ui      Capture UI evidence, inspect nodes, audit layout, and run UI probes.
act     Dispatch input and wait for UI state.
debug   Read diagnostic evidence, state, traces, and scroll profiles.
skills   Install Loupe workflow skills.
```

## How Loupe Differs From Xcode MCP Tooling

[Apple's Xcode MCP bridge](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode)
and tools such as [XcodeBuildMCP](https://www.xcodebuildmcp.com/docs) help
agents operate the Apple development toolchain: discover projects, build, test,
launch, manage simulators, inspect build output, and access Xcode or Apple
documentation context.

Loupe sits inside the running app. It captures runtime UI structure, framework
properties, accessibility state, screenshots, logs, URLSession network evidence,
defaults/flags/keychain metadata, reference evidence, and action traces. Use
Xcode tooling to build and launch the app; use Loupe to answer what is actually
on screen, what runtime state the app exposed, what changed after an action, and
why a visible behavior failed.

## Inspect Runtime UI

Use `ui report` when you need a screenshot and UI structure together:

```bash
loupe ui report --bundle-id com.example.App --output loupe-report
loupe ui compact loupe-report/snapshot.json
loupe ui screen loupe-report/snapshot.json --limit 80
loupe ui tree loupe-report/snapshot.json --accessibility --depth 3
loupe ui tree loupe-report/snapshot.json --view --depth 3
loupe ui node loupe-report/snapshot.json --test-id checkout.payButton
```

Use the accessibility tree for text discovery and action targets. Use the view
tree for layout, UIKit properties, style, mutation refs, and design checks. Use
`ui paint` when a visual change appears hidden by a same-frame child or
overlay:

For SwiftUI, prefer stable accessibility identifiers and explicit probe anchors
for regions that agents must inspect as durable `ui node` targets. When the app
can import `LoupeKit`, use the public modifier:

```swift
import LoupeKit
import SwiftUI

VStack {
    // ...
}
.accessibilityIdentifier("checkout.form")
.loupeProbe("checkout.form.probe", label: "Checkout form")
```

If the app should not depend on `LoupeKit`, use the same idea with a
zero-dependency helper. Loupe injection will capture the platform view because
it only relies on standard accessibility identifiers:

```swift
import SwiftUI

extension View {
    func loupeProbe(_ id: String, label: String? = nil) -> some View {
        background(LoupeProbeView(id: id, label: label).frame(width: 1, height: 1))
    }
}

#if canImport(UIKit)
import UIKit

private struct LoupeProbeView: UIViewRepresentable {
    let id: String
    let label: String?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.accessibilityIdentifier = id
        view.isAccessibilityElement = true
        view.accessibilityLabel = label ?? id
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#elseif canImport(AppKit)
import AppKit

private struct LoupeProbeView: NSViewRepresentable {
    let id: String
    let label: String?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.identifier = NSUserInterfaceItemIdentifier(id)
        view.setAccessibilityElement(true)
        view.setAccessibilityLabel(label ?? id)
        view.setAccessibilityRole(.group)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
```

```bash
loupe ui paint loupe-report/snapshot.json --point 201,319
```

## Act and Explore

```bash
loupe act tap --udid <UDID> --test-id checkout.payButton --trace-dir /tmp/loupe-tap --expect-visible checkout.confirmation
loupe act tap --udid <UDID> --snapshot loupe-report/snapshot.json --ref n83
loupe act tap --udid <UDID> --x 201 --y 274 --width 438 --height 954
loupe act swipe --udid <UDID> --from 220,760 --to 220,190 --trace-dir /tmp/loupe-swipe
loupe act tap --udid <UDID> --test-id checkout.nameField
loupe act type "Ada" --udid <UDID>
```

A swipe verifies scroll offset changes when Loupe can identify a scrollable
target. For quick route discovery:

```bash
loupe debug trace explore --bundle-id com.example.App --limit 5 --trace-dir /tmp/loupe-routes --output /tmp/loupe-routes.json --json
```

Review action evidence:

```bash
loupe debug trace summary /tmp/loupe-tap
loupe debug trace diff /tmp/loupe-tap/before-snapshot.json /tmp/loupe-tap/after-snapshot.json --changed-only
```

## Debug Runtime State

Keep higher-level diagnosis in skills, but compose it from a small command
surface. For an empty list, gather UI state, app logs, network evidence, and
feature flags:

```bash
loupe ui snapshot --host <runtime-host> --output /tmp/loupe-snapshot.json
loupe debug network --host <runtime-host> --output /tmp/loupe-network.json
loupe debug logs --host <runtime-host> --output /tmp/loupe-logs.json
loupe ui query /tmp/loupe-snapshot.json --test-id customers.list
loupe debug flags get new-nav --host <runtime-host>
```

For visual, responder, storage, and regression checks:

```bash
loupe ui appearance dark --host <runtime-host>
loupe ui audit /tmp/loupe-snapshot.json --json
loupe ui hit-test --point 201,437 --host <runtime-host>
loupe ui responder-chain --test-id login.button --host <runtime-host>
loupe debug keychain list --host <runtime-host>
loupe debug flags set new-nav --bool false --host <runtime-host>
```

For scroll investigation:

```bash
loupe debug scroll --from 220,760 --to 220,190 --udid <UDID> --host <runtime-host> --trace-dir /tmp/loupe-scroll --output /tmp/loupe-scroll.json
loupe debug trace summary /tmp/loupe-scroll
```

`debug network` records URLSession requests captured through LoupeKit's
URLProtocol hook, plus app-authored events from `Loupe.recordNetwork(...)` or
the `dev.loupe.network` bridge notification when explicit evidence is needed.
`debug refs` records app-authored ownership evidence through
`Loupe.recordReference(...)` or the `dev.loupe.reference` bridge notification;
`debug object-graph <target>` summarizes those records into `owners`, `nodes`,
and `edges`. Graph `edges` and `owners` include the original `evidenceID`,
`kind`, `label`, `metadata`, and
`timestamp` so a leak/debug answer can point back to the exact app-authored
record. `debug heap --target` uses the same app-authored evidence summary; it
is not private heap traversal.
`debug objects classes` and `debug objects describe` read Objective-C runtime
class metadata for development builds. `debug leaks` reads weak lifetime probes
registered by the app through `Loupe.watchLifetime(...)`; use it to verify
expected deallocation points without claiming full heap traversal.
`debug scroll` records elapsed time and scroll offset deltas;
frame-level hitch classification still requires deeper instrumentation.

## Runtime Diagnostic Experiments

Runtime mutation is optional. Use it for quick design/debug experiments on
supported UIKit properties, not as the guaranteed path for every UI change.
Text, colors, alpha, hidden state, layer styling, and common control values are
usually better targets than layout-owned frame changes.

```bash
loupe ui mutations --udid <UDID> --test-id checkout.card
loupe ui set --udid <UDID> --test-id checkout.title text "Runtime title" --output mutation.json
loupe ui set --udid <UDID> --test-id checkout.card backgroundColor --color '#ff3366' --output mutation.json
loupe ui set --udid <UDID> --test-id checkout.card frame --rect 20,120,220,80 --no-animate --output mutation.json
loupe ui reflect mutation.json --source ./Sources
```

Runtime property mutations animate by default. Pass `--no-animate` when you need
immediate state for verification. Treat frame and constraint changes as
diagnostic probes unless the effective value confirms UIKit kept the change.

For Auto Layout:

```bash
loupe ui constraints --udid <UDID> --test-id checkout.card --json
loupe ui set-constraint --udid <UDID> --id c0x123 constant 120
loupe ui deactivate-constraint --udid <UDID> --id c0x123
```

Loupe reports requested and effective values so layout-owned changes are visible
instead of silently accepted.

## Documentation

- [Goal](Docs/Goal.md)
- [Status](Docs/Status.md)
- [Test Plan](Docs/TestPlan.md)
- [Runtime Communication](Docs/RuntimeCommunication.md)
- [Architecture Notes](Docs/LoupePlan.md)
- [Figma Comparison](Docs/FigmaComparison.md)
- [Homebrew Distribution](Docs/Homebrew.md)
- [Development Homebrew Overlay](Docs/DevHomebrewOverlay.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local verification and pull request
checks.

## Inspiration

Loupe's simulator inspection and action direction is inspired by
[AXe](https://github.com/cameroncooke/AXe),
[Baguette](https://github.com/tddworks/baguette), and
[Pepper](https://github.com/skwallace36/Pepper).

<details>
<summary>Special thanks to Pepper</summary>

Loupe started with a UI-focused runtime inspection and interaction direction.
Pepper was especially helpful in shaping how Loupe expands that workflow into
debug diagnostics such as network evidence, runtime state, storage, traces, and
platform-specific examples.

</details>
