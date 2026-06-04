# Actions And Mutations

## Act

```bash
TRACE=/tmp/loupe-checkout-trace
rm -rf "$TRACE"
loupe act tap --test-id checkout.payButton --host <runtime-host> --udid <sim-udid> --trace-dir "$TRACE"
loupe act tap --snapshot "$REPORT/snapshot.json" --ref n21 --udid <sim-udid>
loupe act tap --x 201 --y 274 --udid <sim-udid> --width 438 --height 954
loupe act swipe --from 219,760 --to 219,190 --host <runtime-host> --udid <sim-udid> --width 438 --height 954 --trace-dir "$TRACE"
loupe act press select --host <runtime-host> --udid <tvos-sim-udid> --trace-dir "$TRACE"
loupe debug scroll --test-id feed.list --delta 0,80 --host <runtime-host> --output /tmp/loupe-scroll-profile.json
loupe debug trace summary "$TRACE"
loupe debug trace diff "$TRACE/before-snapshot.json" "$TRACE/after-snapshot.json" --changed-only
```

Also use `act drag`, `act type`, `act press`, and `debug trace explore` when
needed. Treat scroll with no offset or visible-frame change as failed unless
`--no-verify-scroll` is intentional. Use `debug scroll --delta` or `--to-offset`
for linked runtimes that can expose scroll state but do not have host HID scroll
input.

Preserve failed trace paths until summarized or handed back. Remove successful
trace dirs unless a later diff/audit needs them. Action traces use
`before-snapshot.json`/`after-snapshot.json`; `ui set-many --trace-dir` uses
`prev-snapshot.json`/`next-snapshot.json`.

## Mutate

Mutations are developer-only probes. Prefer stable `testID`; use `ref` only
within the same observed screen.

```bash
loupe ui mutations --host <runtime-host> --test-id target.view
loupe ui set --host <runtime-host> --test-id target.view alpha 0.5 --no-animate
loupe ui set-many --host <runtime-host> --file /tmp/mutations.json --trace-dir /tmp/loupe-mutation-trace
loupe act wait value --host <runtime-host> --test-id target.view alpha 0.5
loupe ui reflect --host <runtime-host> --test-id target.view
```

Use `--no-animate` when verification needs immediate state. Treat frame and Auto
Layout mutations as probes until `loupe ui node` confirms the effective state.

## Design QA

For Figma, screenshot, or visual-reference work, capture a report, inspect
anchors, run audit, then act and diff:

```bash
loupe ui audit "$REPORT/snapshot.json"
loupe ui compare-design "$REPORT/snapshot.json" /path/to/design.json --limit 20
```

Reject wrong screen size, duplicated simulator chrome, scrolling fixed chrome,
wrong scroll axis, bad key text/frame/color/corner metadata, untraceable routes,
or unintended app state.

For `compare-design`, match by `testID`, then role plus text, then geometry.
