# LoupeExample

UIKit app used to verify simulator dylib injection and Loupe-driven coordinate
actions.

The app does not link `LoupeKit`. It only defines normal UIKit views and
`accessibilityIdentifier` values. `LoupeInjector` is injected at launch time and
starts the localhost observation server.

The app intentionally includes more than a single button:

- navigation controller
- large table view with many cells
- detail screen
- pan gesture target
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

Run the Loupe-driven coordinate action proof:

```bash
./run-loupe-driven-ui-test.sh
```

This launches the app with injection, fetches Loupe snapshots from the UI test,
resolves nodes by `testID`, and uses `XCUICoordinate` to scroll, tap, and drag.
