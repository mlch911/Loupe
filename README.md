<p align="center">
  <img src="Docs/Assets/loupe-wordmark.svg" alt="Loupe" width="360">
</p>

A CLI that gives agents runtime UI context through small primitives and
skill-driven workflows.

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

Loupe currently targets iOS Simulator apps on macOS. The command interface is
organized around targets and capabilities so macOS, tvOS, and other backends can
be added without turning every platform feature into a new top-level command.

Requirements:

- macOS 14 or later.
- Xcode with iOS Simulator installed.

Xcode and simulator versions can affect runtime injection and native HID input.

Loupe chooses an available localhost port for injected apps and records the
runtime. Use `--bundle-id`, `--udid`, or `loupe target use <bundle-id>` to
select the target app instead of hard-coding a host port.

## Quick Start

For agent workflows, start with this context:

```text
Use Loupe as the runtime context for this iOS app. Inspect view and accessibility trees, act through simulator input, and verify behavior with traces before editing code.
```

For direct CLI control:

```bash
loupe runtime start --bundle-id com.example.App --device <iPhone simulator UDID>
loupe target list
loupe target use com.example.App
loupe target current
```

Existing flat commands such as `loupe start`, `loupe tap`, and `loupe tree`
remain as compatibility aliases. New workflows should prefer the grouped
interface:

```text
target   Select the current runtime target.
runtime  Start, list, select, and query injected runtimes.
observe  Capture screenshots, trees, maps, and raw runtime data.
inspect  Query or inspect nodes and paint stacks.
act      Dispatch input and wait for UI state.
ui       Audit, mutate, and compare UI structure.
  trace    Explore, summarize, and diff action traces.
debug   Read logs, network events, and reference evidence.
state   Inspect defaults, flags, and keychain metadata.
env     Change runtime environment such as appearance.
perf    Run lightweight runtime performance probes.
skills   Install Loupe workflow skills.
```

## Inspect Runtime UI

Use `observe capture` when you need a screenshot and UI structure together:

```bash
loupe observe capture --bundle-id com.example.App --output loupe-report
loupe observe compact loupe-report/snapshot.json
loupe observe screen loupe-report/snapshot.json --limit 80
loupe observe tree loupe-report/snapshot.json --accessibility --depth 3
loupe observe tree loupe-report/snapshot.json --view --depth 3
loupe inspect node loupe-report/snapshot.json --test-id checkout.payButton
```

Use the accessibility tree for text discovery and action targets. Use the view
tree for layout, UIKit properties, style, mutation refs, and design checks. Use
`inspect paint` when a visual change appears hidden by a same-frame child or
overlay:

```bash
loupe inspect paint loupe-report/snapshot.json --point 201,319
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
loupe trace explore --bundle-id com.example.App --limit 5 --trace-dir /tmp/loupe-routes --output /tmp/loupe-routes.json --json
```

Review action evidence:

```bash
loupe trace summary /tmp/loupe-tap
loupe trace diff /tmp/loupe-tap/before-snapshot.json /tmp/loupe-tap/after-snapshot.json --changed-only
```

## Debug Runtime State

Keep higher-level diagnosis in skills, but compose it from a small command
surface. For an empty list, gather UI state, app logs, network evidence, and
feature flags:

```bash
loupe observe fetch /snapshot --host <runtime-host> --output /tmp/loupe-snapshot.json
loupe debug network --host <runtime-host> --output /tmp/loupe-network.json
loupe debug console --host <runtime-host> --output /tmp/loupe-logs.json
loupe inspect query /tmp/loupe-snapshot.json --test-id customers.list
loupe state flags get new-nav --host <runtime-host>
```

For visual, responder, storage, and regression checks:

```bash
loupe env appearance dark --host <runtime-host>
loupe ui audit /tmp/loupe-snapshot.json --json
loupe ui hit-test --point 201,437 --host <runtime-host>
loupe ui responder-chain --test-id login.button --host <runtime-host>
loupe state keychain list --host <runtime-host>
loupe state flags set new-nav --bool false --host <runtime-host>
```

For scroll investigation:

```bash
loupe perf scroll --from 220,760 --to 220,190 --udid <UDID> --host <runtime-host> --trace-dir /tmp/loupe-scroll --output /tmp/loupe-scroll.json
loupe trace summary /tmp/loupe-scroll
```

`debug network` records app-authored network events, so apps should call
`Loupe.recordNetwork(...)` or post the `dev.loupe.network` bridge notification
where automatic URL loading interception is not available. `debug refs` is
currently registry/log evidence, not a full heap reference graph. `perf scroll`
records elapsed time and trace-based scroll offset deltas; frame-level hitch
classification still requires deeper instrumentation.

## Runtime UI Experiments

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
[Pepper](https://github.com/skwallace36/Pepper). Pepper is especially useful as
a reference for the kinds of diagnosis questions agents should be able to
answer, such as empty-list network debugging, dark-mode contrast checks,
responder-chain failures, scroll performance hitches, storage audits, and
feature-flag regression checks. Loupe keeps those workflows skill-driven and
builds the CLI around stable observe, act, inspect, UI, trace, and runtime
primitives.
