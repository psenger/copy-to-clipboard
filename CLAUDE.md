# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
make build    # Release build → build/Build/Products/Release/copy-to-clipboard.app
make test     # Run all tests
make install  # Build and copy to ~/Applications
make dmg      # Build and create copy-to-clipboard.dmg in project root
make clean    # Remove build/
```

After `make install`, copy to `/Applications`, restart Finder, then re-register the extension:
```bash
sudo cp -R ~/Applications/copy-to-clipboard.app /Applications/
killall Finder
make register
```

`make register` runs `pluginkit -e use -i com.psenger.copy-to-clipboard.extension`. Every rebuild changes the extension's CDHash, which causes pluginkit to reset its enabled state. This must be run after each `sudo cp` during development. End users installing from a DMG enable the extension once via System Settings → Privacy & Security → Extensions → Finder instead.

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

The app has two components:

**Main app** (`src/`) — a background-only NSServices helper. macOS wakes it per invocation; it exits after each call. On macOS versions where NSServices works, right-clicking a text file in Finder shows the item in the Services submenu.

**FinderSync extension** (`extension/`) — a sandboxed app extension that adds "Copy Contents to Clipboard" **directly** to Finder's right-click context menu (not in a submenu). This is the primary mechanism on macOS 26 (Tahoe), where the NSServices approach no longer surfaces in Finder menus.

Source files:

- **`src/AppDelegate.swift`** — receives the file URL via `copyFileContents(_:userData:error:)`, runs `pbs -update` on every launch to register with Finder, delegates to `ClipboardService`.
- **`src/ClipboardService.swift`** — checks the file's UTI, decodes the file to a Swift `String`, writes it to `NSPasteboard.general`. Shared by both the main app and the extension.
- **`extension/FinderSyncExtension.swift`** — `FIFinderSync` subclass. Sets `directoryURLs = ["/"]` to monitor all of Finder, filters the menu to text files only in `menu(for:)`, calls `ClipboardService` on selection.
- **`extension/Info.plist`** — declares `com.apple.FinderSync` extension point with `FinderSyncExtension` as the principal class.
- **`extension/copy-to-clipboard-extension.entitlements`** — sandbox entitlements required for pluginkit to load the extension: `app-sandbox`, `files.user-selected.read-only`, and a temporary exception for read access to `/`.

`src/main.swift` uses explicit `NSApplication.shared` setup instead of `@NSApplicationMain` because the app has no NIB or storyboard.

## Signing requirements

The FinderSync extension **requires Apple Development signing** — pluginkit on macOS 26 refuses to load ad-hoc signed extensions regardless of location.

Setup:
1. Register a free Apple Developer account at developer.apple.com
2. In Xcode → Settings → Accounts, add your Apple ID and create an Apple Development certificate
3. In Xcode → project → Signing & Capabilities, set your team for all three targets
4. `DEVELOPMENT_TEAM` is intentionally blank in the committed `project.pbxproj` — set it in Xcode

The main app uses Automatic signing. The extension must be in `/Applications` (not `~/Applications`) for pluginkit to load it.

After install, enable the extension:
**System Settings → Privacy & Security → Extensions → Finder → Copy Contents to Clipboard ✓**

## Key invariants

**`setString`, never `setData`** — Writing raw bytes to `NSPasteboard` causes emoji and multi-byte Unicode to paste as garbage in receiving apps. Always write a decoded Swift `String`.

**`usedEncoding:` + Windows-1252 fallback** — macOS 26 tightened encoding auto-detection and no longer recognises Windows-1252 (bytes like `0xA9` for ©, `0x80` for €). `String(contentsOf:usedEncoding:)` is tried first for UTF-8 and UTF-16 (BOM-detected); if it throws, `.windowsCP1252` is tried explicitly. Do not add further fallbacks — `.isoLatin1` and `.utf16` are handled by the two steps above and are dead code if added.

**Main app: no sandbox. Extension: sandboxed.** — The main app needs arbitrary filesystem read access; do not add the App Sandbox entitlement to it. The extension must be sandboxed (pluginkit requirement) with a `temporary-exception.files.absolute-path.read-only = ["/"]` entitlement to read files outside the container.

**Extension must live in `/Applications`** — pluginkit only registers extensions from the system Applications folder. `~/Applications` is ignored.

**Menu filtering in the extension** — `menu(for:)` in `FinderSyncExtension` must check the file's UTI before returning a menu. Without this gate, the item appears for all file types including images.

**No config file** — There is no settings file and none should be added. `NSSendFileTypes = public.text` in `Info.plist` is the runtime type filter for NSServices; the FinderSync extension filters by UTI at runtime. OSLog `.debug` needs no toggle.

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
