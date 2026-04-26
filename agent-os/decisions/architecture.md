# Architecture Decisions

## copy-to-clipboard — macOS Swift app

| Decision | Choice | Rationale |
|---|---|---|
| App type | Launch-on-demand helper, no UI | NSServices wakes it per invocation; no persistent process needed |
| Sandbox | Disabled | Needs arbitrary filesystem read; ineligible for App Store anyway |
| Distribution | Direct / local only | No Apple Developer account; ad-hoc sign, right-click → Open once |
| Code signing | Ad-hoc (`codesign --sign -`) | Personal tool, no notarization required |
| Minimum macOS | 13 (Ventura) | Modern `UTType`, `Logger` APIs; single-user machine |
| Config file | None | Eliminated to reduce complexity; no runtime type filtering needed |
| File type gate | `NSSendFileTypes = public.text` | Covers all developer text files; single source of truth |
| File reading | `String(contentsOf:usedEncoding:)` | Handles UTF-8, Windows-1252, UTF-16; do NOT hardcode `.utf8` |
| Pasteboard write | `setString(_:forType: .string)` | Never use `setData` — causes emoji/Unicode corruption |
| Size limit | None | Source code files are never large enough to matter |
| Menu label | "Copy Contents to Clipboard" | Verb-first, descriptive |
| Success sound | `NSSound(named: "Tink")` | Standard macOS action confirmation |
| Failure sound | `NSSound(named: "Basso")` | Standard macOS error sound |
| Logging | Always-on OSLog `.debug` | Stripped from release builds automatically; no toggle needed |
| First launch | `UserDefaults` flag → `pbs -update` | Registers NSService with Finder on first run |
| Project files | `AppDelegate.swift`, `ClipboardService.swift`, `Info.plist` | Two Swift files; no other targets |

## Key non-obvious choices

**No config file** — An earlier design had `~/.config/copy-to-clipboard/settings.json` for `allowedTypes` and logging config. Dropped entirely: `NSSendFileTypes = public.text` is the sole type gate, OSLog `.debug` needs no toggle, and eliminating the file removes a class of parse/missing-file error handling.

**`usedEncoding:` not `.utf8`** — Windows text files use Windows-1252. Hardcoding `.utf8` silently fails on those files. `usedEncoding:` handles all common encodings; once decoded to a Swift `String`, encoding is irrelevant at the pasteboard layer.

**`setString` not `setData`** — The original bug: writing raw file bytes to `NSPasteboard` instead of a decoded `String`. UTF-8 bytes for emoji (`0xF0 0x9F...`) pasted as literal encoded characters. `setString` writes Unicode; paste targets render it correctly regardless of their own encoding.

## Test cases (ClipboardService)

1. UTF-8 file — reads and copies, Tink plays
2. UTF-8 file with emoji — no mangled characters on paste
3. Windows-1252 file — `usedEncoding:` detects it, copies correctly
4. Unreadable encoding — throws, Basso plays, pasteboard unchanged
5. File does not exist — throws, Basso plays
6. Non-`public.text` UTI — rejected before read, Basso plays
