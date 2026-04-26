# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
make build    # Release build → build/Build/Products/Release/copy-to-clipboard.app
make test     # Run all tests
make install  # Build and copy to ~/Applications
make clean    # Remove build/
```

Run a single test:
```bash
xcodebuild test -project copy-to-clipboard.xcodeproj -scheme copy-to-clipboard \
  -destination 'platform=macOS' \
  -only-testing:copy-to-clipboardTests/ClipboardServiceTests/testUTF8FileCopiedToPasteboard
```

View logs at runtime:
```bash
log stream --predicate 'subsystem == "com.psenger.copy-to-clipboard"' --level debug
```

## Architecture

This is a **launch-on-demand macOS Services helper** — no UI, no menu-bar icon, no persistent process. macOS wakes it per invocation via the NSServices mechanism and it exits after each call.

Two source files do all the work:

- **`src/AppDelegate.swift`** — receives the file URL from the Services framework via `copyFileContents(_:userData:error:)`, runs `pbs -update` on first launch to register with Finder, then delegates to `ClipboardService`.
- **`src/ClipboardService.swift`** — checks the file's UTI, decodes the file to a Swift `String`, writes it to `NSPasteboard.general`.

The NSServices entry point is wired in `src/Info.plist` under `NSServices`. The `NSMessage` key (`copyFileContents`) must match the `@objc` method name on `AppDelegate`. The `NSSendFileTypes = public.text` key is the sole type gate — it controls which files show the menu item in Finder.

`src/main.swift` uses explicit `NSApplication.shared` setup instead of `@NSApplicationMain` because the app has no NIB or storyboard.

## Key invariants

**`setString`, never `setData`** — Writing raw bytes to `NSPasteboard` causes emoji and multi-byte Unicode to paste as garbage in receiving apps. Always write a decoded Swift `String`.

**`usedEncoding:` + Windows-1252 fallback** — macOS 26 tightened encoding auto-detection and no longer recognises Windows-1252 (bytes like `0xA9` for ©, `0x80` for €). `String(contentsOf:usedEncoding:)` is tried first for UTF-8 and UTF-16 (BOM-detected); if it throws, `.windowsCP1252` is tried explicitly. Do not add further fallbacks — `.isoLatin1` and `.utf16` are handled by the two steps above and are dead code if added.

**No sandbox** — The app needs arbitrary filesystem read access. Do not enable the App Sandbox entitlement; it will break on any file outside the container.

**No config file** — There is no settings file and none should be added. `NSSendFileTypes = public.text` in `Info.plist` is the runtime type filter; OSLog `.debug` needs no toggle.

**Ad-hoc signing only** — `CODE_SIGN_IDENTITY = "-"`. No Apple Developer account or provisioning profile. Users must right-click → Open once to clear Gatekeeper on first launch.

## Tests

Tests live in `tests/ClipboardServiceTests.swift`. The suite is `@MainActor` throughout because `ClipboardService.copy(fileAt:)` is `@MainActor`. Each test clears `NSPasteboard.general` in `setUp` and writes real temp files — no mocks.

Coverage is ~91%. The remaining gap is OSLog `@autoclosure` bodies that the test runner never activates (`.debug` level is off in the test process). Do not restructure logging to chase that coverage.

The `AppDelegate` handler is tested directly by writing file URLs to a named `NSPasteboard` and calling `copyFileContents(_:userData:error:)`.

## Agent-OS

This project uses **Agent-OS**, a Spec Driven Development framework for AI-assisted development. It is installed and active.

Agent-OS slash commands (available in Claude Code):

| Command | Purpose |
|---|---|
| `/agent-os:discover-standards` | Extract coding patterns from the codebase into documented standards |
| `/agent-os:index-standards` | Regenerate `agent-os/standards/index.yml` descriptions |
| `/agent-os:inject-standards` | Load relevant standards into context before making changes |
| `/agent-os:plan-product` | Plan a new feature against existing architecture decisions |
| `/agent-os:shape-spec` | Shape a feature spec before implementation |

Before making non-trivial changes, run `/agent-os:inject-standards` to load the relevant standards into context.

## Standards and decisions

- `agent-os/decisions/architecture.md` — full rationale for every architectural choice
- `agent-os/standards/index.yml` — index of all standards
- `agent-os/standards/clipboard/pasteboard.md` — pasteboard write rules
- `agent-os/standards/logging/patterns.md` — OSLog usage
- `agent-os/standards/macos/services.md` — NSServices wiring and first-launch registration
