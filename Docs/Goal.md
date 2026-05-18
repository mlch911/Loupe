# Loupe Goal

Loupe is a runtime E2E harness for iOS Simulator apps.

The project goal is:

1. Launch an app with Loupe observation injected or linked.
2. Capture a high-fidelity UIKit and accessibility tree from inside the app.
3. Let the CLI resolve stable selectors from that tree.
4. Execute simulator-visible input through runtime commands, without XCTest as
   the public harness.
5. Let the injected SDK and CLI communicate through localhost for snapshots,
   on-demand inspection, layout audits, logs, recording, and app-authored
   diagnostic events.
6. Record human or CLI-driven gesture flows and replay them as Loupe actions.
7. Keep reproducible traces and smoke harnesses in the repository as the source
   of truth.

Current implementation stance:

- Loupe owns app-side observation, selector resolution, runtime logs, recording,
  on-demand inspection, initial layout audit checks, screenshots, replay shape,
  and CLI UX.
- Low-level HID dispatch is currently delegated to AXe.
- Native Loupe HID dispatch is the next backend milestone.
