---
name: loupe
description: Use this skill when working with Loupe Apple-platform runtime automation, simulator injection, linked LoupeInjector runtimes, view-tree inspection, accessibility tree querying, compact screen context, or Loupe CLI-driven platform actions.
---

# Loupe

Use Loupe for Apple-platform runtime observation, diagnostics, CLI actions,
mutation probes, and design QA.

## Core Rules

- Use the installed `loupe`; resolve injector paths with `loupe injector-path`.
- Loupe talks to the app's in-process Loupe server; no separate host daemon is
  needed.
- Keep full snapshots on disk during the task. Send compact output to agents by
  default, then query or inspect specific refs on demand.
- Keep attachment mode explicit:
  - Simulator injection uses `--inject` and no app dependency.
  - Physical-device debug runtimes link and embed the dynamic `LoupeInjector`
    product. It depends on `LoupeKit` internally and starts Loupe automatically
    when loaded.
- Repository example apps should stay import-free when an injection path exists.
  Do not add `import LoupeKit` to examples just to make a simulator workflow
  pass.
- Drive runtime E2E with Loupe CLI actions, not XCTest as the public harness.
- Prefer `testID`, `ref`, or coordinates over tap-by-text.

## Reference Files

Read only the file needed for the current task:

- `references/runtime-modes.md`: simulator injection, physical-device
  `LoupeInjector` setup, runtime selection, and launch troubleshooting.
- `references/evidence-workflow.md`: reports, snapshots, queries, diagnostics,
  SwiftUI probes, bridge notifications, object graphs, and leaks.
- `references/actions-and-mutations.md`: tap/swipe/drag/type/press, trace
  verification, scroll profiling, mutations, and design QA checks.

## Default Workflow

1. Identify the attachment mode: simulator injection, linked physical device, or
   existing `--host`.
2. Capture runtime evidence with `loupe ui report` or `loupe ui snapshot`.
3. Use accessibility for discovery and action targets. Use the view tree for
   layout, style, UIKit properties, mutation refs, and visual checks.
4. Act through Loupe only when the platform supports it; preserve failed trace
   paths until summarized or handed back.
5. Verify with fresh snapshot/query/effective state, not command success alone.

## Quick Commands

```bash
loupe app launch --bundle-id com.example.App
loupe app list
loupe app use com.example.App
loupe app current

REPORT=/tmp/loupe-report
rm -rf "$REPORT"
loupe ui report --bundle-id com.example.App --output "$REPORT"
loupe ui compact "$REPORT/snapshot.json"
loupe ui query "$REPORT/snapshot.json" --test-id target.id
loupe ui node "$REPORT/snapshot.json" --test-id target.id
```

For physical-device failures, first check `references/runtime-modes.md`.
