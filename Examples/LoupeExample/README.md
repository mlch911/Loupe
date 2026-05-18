# LoupeExample

UIKit app used to verify simulator dylib injection and Loupe-driven coordinate
actions.

The app does not link `LoupeKit`. It only defines normal UIKit views and
`accessibilityIdentifier` values. `LoupeInjector` is injected at launch time and
starts the localhost observation server.

The app includes `LaunchScreen.storyboard` so the simulator does not fall back
to the legacy 320x480 compatibility viewport.

The app intentionally includes more than a single button:

- navigation controller
- large table view with many cells
- detail screen
- pan gesture target
- UIKit component screen with labels, image views, switches, sliders, steppers,
  segmented controls, date pickers, page controls, progress/activity views,
  text input, buttons, bar buttons, scroll views, collection views, picker
  views, tab bars, alerts, and design fixtures
- mixed fixture tab controller with SwiftUI host, WebKit, keyboard-heavy form,
  nested scroll views, and selector-addressable tab items
- modal form with text input

Run:

```bash
./run-injected.sh
```

Expected result:

- the app launches on a booted simulator
- `http://127.0.0.1:8765/health` returns `LoupeKit`
- `/snapshot` contains the UIKit view hierarchy
- `loupe query ... --test-id example.customerList` returns the table node

Run the XCTest-free Loupe runtime smoke harness:

```bash
./run-runtime-e2e.sh
```

This launches the injected app, verifies richer UIKit/accessibility snapshot
fields, starts recording, performs a CLI tap through AXe, captures a screenshot,
stops recording, and verifies that touch events were recorded.

Run the AXe scenario harness:

```bash
./run-axe-scenarios.sh
```

This repeats navigation push/pop by gesture and synthetic `UIBarButtonItem`
selector nodes, verifies `wait-for-visible`, bounded `subtree`, accessibility
tree export/query, action traces, compact UIKit class identity, full
component-specific properties, mixed fixture tabs, text input, WebKit
inspection, nested scroll inspection, and the layout audit output path.

Run the legacy Loupe-driven coordinate action proof:

```bash
./run-loupe-driven-ui-test.sh
```

This launches the app with injection, fetches Loupe snapshots from the UI test,
resolves nodes by `testID`, and uses `XCUICoordinate` to scroll, tap, and drag.
