# Runtime Modes

## Simulator Injection

Simulator apps do not need a Loupe dependency:

```bash
xcrun simctl install booted /path/to/App.app
loupe app launch --bundle-id com.example.App --inject
```

`loupe app launch` injects by default for iOS/tvOS Simulator apps when no other
mode is selected. Use `loupe injector-path` when debugging injector resolution.

## Physical Device

Real-device `DYLD_INSERT_LIBRARIES` launch injection is not available. For iOS
physical-device debug builds, add the dynamic Swift package product
`LoupeInjector` to the Debug app target:

- Link `LoupeInjector`.
- Embed & Sign `LoupeInjector.framework`.
- Keep `LD_RUNPATH_SEARCH_PATHS` including `@executable_path/Frameworks`.
- Exclude Loupe from App Store release builds.

`LoupeInjector` depends on `LoupeKit` internally. The app should not call
`LoupeServer.start()` for this path. `LoupeInjectionBootstrap` runs when the
dynamic library loads, calls `LoupeInjectorStart`, activates the bridge, and
starts `LoupeServer` using `LOUPE_PORT` and `LOUPE_BIND_HOST`.

```bash
loupe app launch \
  --bundle-id com.example.DeviceApp \
  --device <physical-device-id> \
  --linked \
  --host http://<device-ip>:8765 \
  --port 8765 \
  --bind-host 0.0.0.0

loupe app use --host http://<device-ip>:8765
```

Use `--bind-host 0.0.0.0` only for debug builds that need Mac-to-device
reachability. Keep linked apps on `127.0.0.1` otherwise.

## Runtime Selection

Observation commands can use `--bundle-id` or `--host`. Simulator action
commands do not accept `--bundle-id`; run:

```bash
loupe app use <bundle-id> --udid <sim-udid>
```

or pass:

```bash
--host <runtime-host> --udid <sim-udid>
```

If multiple simulators are booted, do not use `--udid booted`; use the UDID from
`loupe app current` or `loupe app list`.

For physical-device linked runtimes, use `ui` and `debug` commands with `--host`
or the selected current runtime. Native HID `act swipe`, `act drag`, `act type`,
and simulator `press` remain simulator-only. Use
`act tap --backend runtime --host <runtime-host>` only where runtime activation
is supported.

## Troubleshooting

If `loupe app launch --linked` fails on an older iOS device, CoreDevice may not
support it. Launch the LoupeInjector-linked debug app manually from Xcode, then
select it with:

```bash
loupe app use --host <runtime-host>
```

If a physical-device app exits immediately, verify the embedded framework and
runpath:

```bash
find /path/to/App.app -maxdepth 4 -type f | rg 'LoupeInjector|Frameworks'
otool -L /path/to/App.app/AppBinary | rg 'LoupeInjector|@rpath'
```

The expected bundle includes:

```text
App.app/Frameworks/LoupeInjector.framework/LoupeInjector
```
