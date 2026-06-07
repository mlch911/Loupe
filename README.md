<p align="center">
  <img src="Docs/Assets/loupe-wordmark.svg" alt="Loupe" width="360">
</p>

Loupe helps AI coding agents build and verify native app interfaces on Apple
platforms by inspecting the app that is actually running, not just the source
code or a screenshot.

Agents get live UI evidence: view and accessibility trees, screenshots, logs,
network and runtime state, input traces, design comparison, and small UI
probes.

Why use Loupe:

- **Better UI checks** with screenshots, view trees, accessibility, traces, and
  runtime state.
- **Fewer blind rebuilds** by trying small UI adjustments before source edits.
- **Smaller agent context** by keeping full snapshots on disk and sending
  focused observations instead.

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

Install the agent skill:

```bash
loupe skills install
```

## Supported Platforms

Loupe is built around the iOS Simulator workflow. It also has checked support
for macOS, tvOS Simulator, watchOS Simulator, visionOS Simulator builds, and
debug-only physical iOS device runtimes.

Simulator apps can use `--inject` without adding Loupe to the app. Physical
iOS devices need a debug-only `LoupeInjector` dependency. Do not include Loupe
in App Store release builds.

## Quick Start

Launch an iOS Simulator app with Loupe injected:

```bash
loupe app launch --bundle-id <bundle-id> --device <simulator-udid> --inject
loupe ui report --bundle-id <bundle-id> --output loupe-report
loupe ui compact loupe-report/snapshot.json
loupe ui node loupe-report/snapshot.json --test-id checkout.payButton
```

Act on the app and keep a trace:

```bash
loupe act tap --udid <simulator-udid> --test-id checkout.payButton --trace-dir /tmp/loupe-tap
loupe debug trace summary /tmp/loupe-tap
loupe debug trace diff /tmp/loupe-tap/before-snapshot.json /tmp/loupe-tap/after-snapshot.json --changed-only
```

## Agent Workflow

A compact starting prompt:

```text
Use Loupe as runtime evidence for this app. Capture a report, inspect the changed view or accessibility node after each action, compare the running UI with the intended design, and verify source changes with fresh screenshots, trees, and traces.
```

## Common Commands

```bash
# UI evidence
loupe ui report --bundle-id <bundle-id> --output loupe-report
loupe ui tree loupe-report/snapshot.json --accessibility --depth 3
loupe ui tree loupe-report/snapshot.json --view --depth 3
loupe ui node loupe-report/snapshot.json --test-id checkout.payButton

# Actions and traces
loupe act tap --udid <simulator-udid> --test-id checkout.payButton --trace-dir /tmp/loupe-tap
loupe act swipe --udid <simulator-udid> --from 220,760 --to 220,190 --trace-dir /tmp/loupe-swipe
loupe debug trace explore --bundle-id <bundle-id> --limit 5 --trace-dir /tmp/loupe-routes --output /tmp/loupe-routes.json --json

# Diagnostics
loupe debug logs --host <runtime-host> --output /tmp/loupe-logs.json
loupe debug network --host <runtime-host> --output /tmp/loupe-network.json
loupe ui audit loupe-report/snapshot.json

# Runtime UI probes
loupe ui set --udid <simulator-udid> --test-id checkout.card backgroundColor --color '#ff3366' --output mutation.json
loupe ui reflect mutation.json --source ./Sources
```

Runtime UI changes are probes, not final state. Patch source, relaunch, and
verify with a fresh report.

## Documentation

- [Goal](Docs/Goal.md)
- [Status](Docs/Status.md)
- [Test Plan](Docs/TestPlan.md)
- [Architecture Notes](Docs/LoupePlan.md)
- [Figma Comparison](Docs/FigmaComparison.md)
- [Homebrew Distribution](Docs/Homebrew.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local verification and pull request
checks.

## Inspiration

Loupe's simulator inspection and action direction is inspired by
[AXe](https://github.com/cameroncooke/AXe),
[Baguette](https://github.com/tddworks/baguette), and
[Pepper](https://github.com/skwallace36/Pepper).
