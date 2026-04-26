# Contributing

## Prerequisites

- macOS 13 (Ventura) or later
- Xcode 15 or later

## Building and testing

```bash
make build    # Release build
make test     # Run all tests
make clean    # Remove build artefacts
```

Or directly with xcodebuild:

```bash
xcodebuild -project copy-to-clipboard.xcodeproj \
           -scheme copy-to-clipboard \
           -configuration Debug build

xcodebuild test -project copy-to-clipboard.xcodeproj \
           -scheme copy-to-clipboard \
           -destination 'platform=macOS'
```

## Agent-OS

This project uses the [Agent-OS](./AGENT-OS.md) Spec Driven Development framework. Before implementing any feature, read `AGENT-OS.md` for the slash-command workflow and how to use `agent-os/` knowledge-base files.

## Read the architecture doc first

`agent-os/decisions/architecture.md` contains the key decisions and their rationale. The most important invariants are:

| Invariant | Why |
|---|---|
| `setString`, never `setData` | Raw bytes paste as garbage for emoji/Unicode |
| `usedEncoding:` + Windows-1252 fallback | macOS 26 no longer auto-detects Windows-1252 |
| No sandbox | The app needs arbitrary filesystem read access |
| No config file | `NSSendFileTypes = public.text` is the sole type gate |
| No persistent process | `LSBackgroundOnly` + launch-on-demand via NSServices |

## Code standards

Coding standards live in `agent-os/standards/`. The highlights:

- **`clipboard/pasteboard.md`** — pasteboard write rules
- **`logging/patterns.md`** — always-on OSLog `.debug`; no config toggle
- **`macos/services.md`** — NSServices wiring, first-launch `pbs -update`

## Tests

The test suite lives in `tests/ClipboardServiceTests.swift` and covers:

- UTF-8 files (plain and with emoji)
- Windows-1252 files (`©` and `€`)
- UTF-16 files (with BOM)
- Missing files
- Non-text UTIs (e.g. PNG)
- The `AppDelegate` NSServices handler directly

Keep the suite green and coverage above 90 % before submitting a pull request. The remaining ~9 % is OSLog `@autoclosure` bodies that the test runner cannot activate.

## Submitting changes

1. Fork the repository
2. Create a branch: `git checkout -b my-change`
3. Make your changes, keep tests green
4. Open a pull request with a clear description of **what** changed and **why**
