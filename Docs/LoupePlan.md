# Loupe Architecture Notes

Loupe is an iOS Simulator harness for runtime observation, simulator-visible
input, and fast UI iteration.

## Goals

- Capture high-fidelity UIKit and accessibility state from inside the app.
- Give agents compact context by default and full snapshots on demand.
- Resolve stable selectors for inspection and action.
- Execute real simulator input without making XCTest the public harness.
- Keep screenshots, logs, diffs, and traces for reproducible failures.
- Let developers try supported UIKit mutations at runtime, verify effective
  state, and reflect successful experiments back into source.

Figma API integration is not part of the runtime architecture. Design checks use
Loupe snapshots, screenshots, screen maps, audits, and optional exported design
fixtures.

## Components

```text
loupe CLI
  - launches and injects apps
  - records runtime host mappings
  - stores snapshots, reports, screenshots, logs, and traces
  - resolves selectors and dispatches host-side simulator input

LoupeKit / LoupeInjection
  - runs inside the simulator app
  - captures view, accessibility, UIKit, layout, style, and metadata state
  - exposes localhost runtime endpoints
  - applies allowlisted UIKit mutation experiments on the app main thread

LoupeCore
  - shared models for snapshots, accessibility trees, queries, audits, diffs,
    compact observations, and design comparison
```

Homebrew installs both the CLI and `LoupeInjector.framework`; `loupe start`
resolves the injector path automatically.

## Runtime Selection

Injected apps bind to localhost. The CLI launch path chooses an available port
unless `--port` or `LOUPE_PORT` is explicitly provided. Do not build workflows
around a fixed default port.

Use stable identity first:

```bash
loupe runtimes
loupe use com.example.App
loupe current
loupe capture-report --bundle-id com.example.App --output loupe-report
```

Use `--host <runtime-host>` only when it comes from `loupe runtimes` or
`loupe current`.

## Observation Policy

Do not put the whole tree into LLM context by default.

Default agent context should come from:

- `compact`
- `tree --accessibility`
- `tree --view`
- `screen-map`
- targeted `inspect`
- `trace-summary`
- `diff --changed-only`

Use accessibility for movement/input selectors and text discovery. Use the view
tree for layout, style, UIKit properties, mutation refs, and design checks.

## Action Boundary

Loupe should not rely on app-internal `UIEvent` synthesis as the main action
strategy. App-side code observes state; host-side Loupe commands dispatch user
visible input through the simulator.

Target flow:

```text
loupe tap --test-id checkout.payButton --trace-dir /tmp/loupe-trace
  -> fetch runtime accessibility/snapshot state
  -> resolve target and coordinates
  -> dispatch native simulator input
  -> capture after state, screenshot, logs, and diff
```

`tap`, `swipe`, `drag`, and `type` are implemented. `pinch` remains planned.
Tap-by-text is intentionally not the public contract because visible text is
ambiguous; prefer `testID`, `ref`, or coordinates.

## Runtime Mutation

Mutation is a runtime experiment path, not a guarantee that UIKit will keep every
requested value. Support is allowlisted, not arbitrary Objective-C selector
execution.

```bash
loupe mutations --test-id checkout.card
loupe set --test-id checkout.title text "New title" --output /tmp/loupe-set.json
loupe set --test-id checkout.card backgroundColor --color '#ff3366'
loupe set --test-id checkout.card frame --rect 20,120,220,80 --no-animate
loupe reflect /tmp/loupe-set.json --source ./Sources
```

Supported families include view, layer, accessibility, text, control, scroll,
stack, and Auto Layout constraint properties. Text, colors, alpha, hidden state,
layer styling, and common control values are the strongest targets. Frame and
constraint edits are useful probes, but UIKit owners may restore them during a
layout pass. Mutation responses include requested and effective state so those
reversions are visible.

## Runtime UI Verification

UI implementation is considered successful only when runtime evidence supports
it. Design comparison is one optional workflow in that loop:

- screen size matches the intended simulator
- fixed chrome does not scroll with content
- scroll gestures produce meaningful content movement
- key route actions produce traceable state changes
- key elements have expected text, frame, color, corner radius, clipping, and
  hierarchy
- screenshots match the intended visual state

Use `Docs/FigmaComparison.md` for optional exported-design fixture comparison.

## Planned Work

1. Implement native HID pinch.
2. Add screenshot baseline diffing.
3. Expand layout/style assertions for spacing, typography, alignment, clipping,
   and z-order intent.
4. Improve selector scoring for ambiguous accessibility and view-tree matches.
5. Continue refining the Loupe skill with measured agent A/B loops.
