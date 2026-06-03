# Loupe Goal

Loupe is a runtime diagnostic and E2E harness for Apple-platform apps.

The project goal is:

1. Launch an app with Loupe observation injected or linked.
2. Capture a high-fidelity UIKit and accessibility tree from inside the app.
3. Let the CLI resolve stable selectors from that tree.
4. Execute simulator-visible input through runtime commands, without XCTest as
   the public harness.
5. Let the injected SDK and CLI communicate through localhost for snapshots,
   on-demand inspection, layout audits, logs, and app-authored diagnostic
   events.
6. Let developers patch supported view properties at runtime so UI diagnosis,
   verification, and design iteration can happen from the CLI without
   rebuilding the app.
7. Keep reproducible traces and smoke harnesses in the repository as the source
   of truth.

Current implementation stance:

- Loupe owns app-side observation, selector resolution, runtime logs,
  app-authored diagnostic evidence, on-demand inspection, allowlisted runtime
  property mutation, initial layout audit checks, screenshots, and CLI UX.
- Low-level tap, drag, swipe, and type dispatch uses Loupe's native host-side
  HID backend.
