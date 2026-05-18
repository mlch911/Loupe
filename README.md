# Loupe

Runtime E2E inspection and action harness for iOS Simulator apps.

## Install

```bash
brew tap heoblitz/loupe
brew install loupe
```

The Homebrew formula installs AXe as a dependency for runtime actions.

## Launch

```bash
loupe doctor
loupe injector-path

loupe launch \
  --bundle-id dev.loupe.example \
  --device booted \
  --inject
```

For multiple simulators or apps, give each app a port and pass the matching host:

```bash
LOUPE_PORT=8876 loupe launch --bundle-id dev.loupe.example --device <UDID> --inject
loupe runtime --host http://127.0.0.1:8876 --udid <UDID>
```

## Inspect

```bash
loupe fetch http://127.0.0.1:8765/snapshot --output snapshot.json
loupe compact snapshot.json
loupe query snapshot.json --test-id checkout.payButton
loupe query snapshot.json --tree accessibility --test-id checkout.payButton
loupe accessibility snapshot.json
loupe inspect snapshot.json --test-id checkout.payButton
loupe subtree snapshot.json --test-id checkout.form --depth 3
loupe audit snapshot.json
loupe wait-for-visible --host http://127.0.0.1:8765 --test-id checkout.payButton --timeout 5
```

## Act

```bash
loupe tap --host http://127.0.0.1:8765 --udid booted --test-id checkout.payButton
loupe tap --udid booted --x 201 --y 274
loupe swipe --udid booted --from 220,760 --to 220,190 --width 438 --height 954
loupe drag --udid booted --from 4,430 --to 390,430 --duration 0.8
loupe type "Ada" --udid booted
loupe screenshot --udid booted --output screen.png
```

## Record

```bash
loupe record-start checkout-flow --host http://127.0.0.1:8765
loupe record-stop --host http://127.0.0.1:8765 --output checkout-flow.json

loupe replay checkout-flow.json \
  --host http://127.0.0.1:8765 \
  --udid booted \
  --width 438 \
  --height 954
```

Use `--udid <UDID>` on `runtime`, `logs`, `record-start`, `record-stop`, and
`recording` when you want Loupe to verify that the host belongs to the expected
simulator.

## Verify

```bash
swift test
Examples/LoupeExample/run-injected.sh
Examples/LoupeExample/run-runtime-e2e.sh
Examples/LoupeExample/run-axe-scenarios.sh
Examples/LoupeExample/run-loupe-driven-ui-test.sh
```

Current status and design notes live in `Docs/Status.md`, `Docs/TestPlan.md`,
`Docs/RuntimeCommunication.md`, and `Docs/Homebrew.md`.
