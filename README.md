<p align="center">
  <img src="Docs/Assets/loupe-wordmark.svg" alt="Loupe" width="360">
</p>

Runtime UI context for LLM agents working with iOS apps.

Loupe lets LLM agents inspect, interact with, and verify UI behavior in running
iOS Simulator apps through UIKit view hierarchies and properties, accessibility
metadata, screenshots, and simulator input.

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

Loupe is for iOS Simulator apps on macOS. It does not support physical devices.

Requirements:

- macOS 14 or later.
- Xcode with iOS Simulator installed.

Xcode and simulator versions can affect runtime injection and native HID input.

Loupe chooses an available localhost port for injected apps and records the
runtime. Use `--bundle-id`, `--udid`, or `loupe use <bundle-id>` to select the
target app instead of hard-coding a host port.

## Quick Start

For agent workflows, start with this context:

```text
Use Loupe as the runtime context for this iOS app. Inspect view and accessibility trees, act through simulator input, and verify behavior with traces before editing code.
```

For direct CLI control:

```bash
loupe start --bundle-id com.example.App --device booted
loupe runtimes
loupe use com.example.App
loupe current
```

## Inspect Runtime UI

Use `capture-report` when you need a screenshot and UI structure together:

```bash
loupe capture-report --bundle-id com.example.App --output loupe-report
loupe compact loupe-report/snapshot.json
loupe screen-map loupe-report/snapshot.json --limit 80
loupe tree loupe-report/snapshot.json --accessibility --depth 3
loupe tree loupe-report/snapshot.json --view --depth 3
loupe inspect loupe-report/snapshot.json --test-id checkout.payButton
```

Use the accessibility tree for text discovery and action targets. Use the view
tree for layout, UIKit properties, style, mutation refs, and design checks. Use
`paint-stack` when a visual change appears hidden by a same-frame child or
overlay:

```bash
loupe paint-stack loupe-report/snapshot.json --point 201,319
```

## Act and Explore

```bash
loupe tap --udid <UDID> --test-id checkout.payButton --trace-dir /tmp/loupe-tap --expect-visible checkout.confirmation
loupe tap --udid <UDID> --snapshot loupe-report/snapshot.json --ref n83
loupe tap --udid <UDID> --x 201 --y 274 --width 438 --height 954
loupe swipe --udid <UDID> --from 220,760 --to 220,190 --trace-dir /tmp/loupe-swipe
loupe tap --udid <UDID> --test-id checkout.nameField
loupe type "Ada" --udid <UDID>
```

A swipe verifies scroll offset changes when Loupe can identify a scrollable
target. For quick route discovery:

```bash
loupe explore-routes --bundle-id com.example.App --limit 5 --trace-dir /tmp/loupe-routes --output /tmp/loupe-routes.json --json
```

Review action evidence:

```bash
loupe trace-summary /tmp/loupe-tap
loupe diff /tmp/loupe-tap/before-snapshot.json /tmp/loupe-tap/after-snapshot.json --changed-only
```

## Runtime UI Experiments

Runtime mutation is optional. Use it for quick design/debug experiments on
supported UIKit properties, not as the guaranteed path for every UI change.
Text, colors, alpha, hidden state, layer styling, and common control values are
usually better targets than layout-owned frame changes.

```bash
loupe mutations --udid <UDID> --test-id checkout.card
loupe set --udid <UDID> --test-id checkout.title text "Runtime title" --output mutation.json
loupe set --udid <UDID> --test-id checkout.card backgroundColor --color '#ff3366' --output mutation.json
loupe set --udid <UDID> --test-id checkout.card frame --rect 20,120,220,80 --no-animate --output mutation.json
loupe reflect mutation.json --source ./Sources
```

Runtime property mutations animate by default. Pass `--no-animate` when you need
immediate state for verification. Treat frame and constraint changes as
diagnostic probes unless the effective value confirms UIKit kept the change.

For Auto Layout:

```bash
loupe constraints --udid <UDID> --test-id checkout.card --json
loupe set-constraint --udid <UDID> --id c0x123 constant 120
loupe deactivate-constraint --udid <UDID> --id c0x123
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
[AXe](https://github.com/cameroncooke/AXe) and
[Baguette](https://github.com/tddworks/baguette).
