# Contributing

## Prerequisites

- macOS 13 (Ventura) or later (macOS 26 Tahoe recommended for testing the FinderSync extension)
- Xcode 16 or later
- A free [Apple Developer account](https://developer.apple.com) — required to sign the FinderSync extension so pluginkit will load it

## Signing setup (required before first build)

The FinderSync extension must be signed with an Apple Development certificate. pluginkit on macOS 26 refuses to load ad-hoc signed extensions.

1. Register at [developer.apple.com](https://developer.apple.com) (free — no credit card, no annual fee)
2. Open **Xcode → Settings → Accounts**, add your Apple ID
3. Click **Manage Certificates → + → Apple Development** to create a local signing certificate
4. Open the project in Xcode, select each target (copy-to-clipboard, copy-to-clipboard-extension, copy-to-clipboardTests), go to **Signing & Capabilities**, check **Automatically manage signing**, and select your team

> `DEVELOPMENT_TEAM` is intentionally blank in the committed `project.pbxproj`. Xcode fills it in automatically once your account is linked. Do not commit your Team ID.

## Make targets

```bash
make build    # Release build → build/Build/Products/Release/copy-to-clipboard.app
make test     # Run the full test suite
make install  # build + copy app to ~/Applications
make dmg      # build + create copy-to-clipboard.dmg in the project root
make clean    # Remove build/
```

## Installing for local testing

After `make install`, two extra steps are required because pluginkit only loads extensions from `/Applications`:

```bash
sudo cp -R ~/Applications/copy-to-clipboard.app /Applications/
killall Finder
```

Then enable the extension:
**System Settings → Privacy & Security → Extensions → Finder → Copy Contents to Clipboard ✓**

Right-clicking any text file in Finder should now show **Copy Contents to Clipboard** directly in the context menu (not in a submenu).

## Running a single test

```bash
xcodebuild test -project copy-to-clipboard.xcodeproj -scheme copy-to-clipboard \
  -destination 'platform=macOS' \
  -only-testing:copy-to-clipboardTests/ClipboardServiceTests/testUTF8FileCopiedToPasteboard
```

## Viewing runtime logs

```bash
log stream --predicate 'subsystem == "com.psenger.copy-to-clipboard"' --level debug
```

## Architecture

The app has two components:

| Component | Location | Sandbox | Purpose |
|---|---|---|---|
| Main app | `src/` | No | NSServices handler (legacy/fallback) |
| FinderSync extension | `extension/` | Yes | Direct Finder right-click menu item |

Both share `ClipboardService` (`src/ClipboardService.swift`) for the actual file read and pasteboard write.

## Key invariants — read before changing anything

| Invariant | Why |
|---|---|
| `setString`, never `setData` | Raw bytes paste as garbage for emoji/Unicode |
| `usedEncoding:` + Windows-1252 fallback | macOS 26 no longer auto-detects Windows-1252 |
| Main app: no sandbox | Needs arbitrary filesystem read access |
| Extension: sandboxed + `/` read exception | pluginkit requires sandbox; exception allows reading any file |
| Extension must be in `/Applications` | pluginkit ignores `~/Applications` |
| `menu(for:)` must filter by UTI | Without the check the item appears for images, PDFs, etc. |
| No config file | Type filtering is done in code; no settings file should be added |

Full rationale in `agent-os/decisions/architecture.md`.

## Agent-OS

This project uses the [Agent-OS](./AGENT-OS.md) Spec Driven Development framework. Before implementing any feature, read `AGENT-OS.md` for the slash-command workflow and how to use `agent-os/` knowledge-base files.

## Code standards

Standards live in `agent-os/standards/`:

- **`clipboard/pasteboard.md`** — pasteboard write rules
- **`logging/patterns.md`** — OSLog usage patterns
- **`macos/services.md`** — NSServices wiring and first-launch registration

## Tests

The test suite lives in `tests/ClipboardServiceTests.swift` and covers:

- UTF-8 files (plain text, emoji)
- Windows-1252 files (`©`, `€`)
- UTF-16 files (with BOM)
- Missing files
- Non-text UTIs (e.g. PNG)
- The `AppDelegate` NSServices handler directly

Keep the suite green and coverage above 90% before opening a pull request. The remaining ~9% gap is OSLog `@autoclosure` bodies that the test runner cannot activate — do not restructure logging to close it.

## Submitting changes

1. Fork the repository
2. Create a branch: `git checkout -b my-change`
3. Make your changes and keep tests green
4. Do **not** commit your `DEVELOPMENT_TEAM` ID — Xcode sets it locally and it should remain blank in `project.pbxproj`
5. Open a pull request with a clear description of **what** changed and **why**
