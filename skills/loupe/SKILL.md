# Loupe

Use this skill when working with iOS Simulator UI automation, view-tree inspection, compact screen context, or Loupe injection.

## Tooling Assumptions

Prefer the Homebrew installation:

```bash
brew install loupe
```

The Homebrew package installs:

- `loupe` CLI on `PATH`
- `LoupeInjector.framework/LoupeInjector` under Homebrew `libexec`

Do not hard-code DerivedData injector paths. Resolve the injector through Loupe:

```bash
loupe injector-path
```

## Build And Inject Workflow

For an app that has already been built with `xcodebuild`, install and launch it on the simulator through Loupe:

```bash
xcrun simctl install booted /path/to/App.app
loupe launch --bundle-id com.example.App --inject
```

`loupe launch --inject` resolves the Homebrew injector path and sets `SIMCTL_CHILD_DYLD_INSERT_LIBRARIES` before calling `xcrun simctl launch`.

If a nonstandard injector is needed, use:

```bash
loupe launch --bundle-id com.example.App --dylib /absolute/path/LoupeInjector.framework/LoupeInjector
```

## Observation

After launch, fetch context from the in-app Loupe server:

```bash
loupe fetch http://127.0.0.1:8765/observation
loupe fetch http://127.0.0.1:8765/snapshot --output /tmp/loupe-snapshot.json
loupe query /tmp/loupe-snapshot.json --test-id checkout.payButton
```

Use compact observation for LLM context. Keep full snapshots in files and query them by `testID`, text, role, or ref.

## Actions

Loupe CLI action commands are planned but not implemented yet. Do not assume
`loupe tap`, `loupe swipe`, `loupe drag`, or `loupe type` exist.

For now, use an XCTest/XCUITest runner to execute real simulator actions. The
reference proof is:

```bash
Examples/LoupeExample/run-loupe-driven-ui-test.sh
```

That test fetches Loupe snapshots, resolves node frames, and uses
`XCUICoordinate` for tap and drag actions.

## Debugging

Run:

```bash
loupe doctor
```

If injection does not start the server:

- Confirm the app is running in iOS Simulator, not a real device.
- Confirm `loupe injector-path` prints an executable path.
- Relaunch the app with `loupe launch --bundle-id <id> --inject`.
- Check `http://127.0.0.1:8765/health`.
