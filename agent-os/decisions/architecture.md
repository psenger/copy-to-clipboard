# Architecture Decisions

## copy-to-clipboard — macOS Swift app

| Decision | Choice | Rationale |
|---|---|---|
| App type | Launch-on-demand helper, no UI | NSServices wakes it per invocation; no persistent process needed |
| Main app sandbox | Disabled | Needs arbitrary filesystem read access |
| Extension sandbox | Enabled + `/` read exception | pluginkit requires app sandbox on all extensions |
| Main app signing | Ad-hoc (`codesign --sign -`) | Personal tool; right-click → Open once clears Gatekeeper |
| Extension signing | Apple Development certificate | pluginkit refuses ad-hoc signed extensions on macOS 26+ |
| Distribution | Direct / local only | Free Apple Developer account required for extension signing; no App Store |
| Minimum macOS | 13 (Ventura) | Modern `UTType`, `Logger` APIs; single-user machine |
| Config file | None | Eliminated to reduce complexity; no runtime type filtering needed |
| File type gate | `NSSendFileTypes = public.text` (NSServices) + UTI check in `menu(for:)` (FinderSync) | Covers all developer text files; each mechanism has its own gate |
| File reading | `String(contentsOf:usedEncoding:)` + Windows-1252 fallback | Handles UTF-8, UTF-16 (BOM), and Windows-1252; do NOT hardcode `.utf8` |
| Pasteboard write | `setString(_:forType: .string)` | Never use `setData` — causes emoji/Unicode corruption |
| Size limit | None | Source code files are never large enough to matter |
| Menu label | "Copy Contents to Clipboard" | Verb-first, descriptive |
| Success sound | `NSSound(named: "Tink")` | Standard macOS action confirmation |
| Failure sound | `NSSound(named: "Basso")` | Standard macOS error sound |
| Logging | OSLog `.debug` (flow), `.error` (failures) | `.debug` stripped from release builds automatically; `.error` always persisted |
| NSServices registration | `pbs -update` on every launch (unconditional) | Launch-on-demand cost is negligible; simpler than a `UserDefaults` flag |
| Project files | `src/` (main app), `extension/` (FinderSync), shared `ClipboardService.swift` | Two targets sharing one service class |

## Key non-obvious choices

**No config file** — An earlier design had `~/.config/copy-to-clipboard/settings.json` for `allowedTypes` and logging config. Dropped entirely: `NSSendFileTypes = public.text` is the sole type gate, OSLog `.debug` needs no toggle, and eliminating the file removes a class of parse/missing-file error handling.

**`usedEncoding:` + Windows-1252 fallback** — `String(contentsOf:usedEncoding:)` auto-detects UTF-8 and UTF-16 (BOM). macOS 26 tightened encoding detection and no longer auto-detects Windows-1252; bytes like `0xA9` (©) and `0x80` (€) throw instead of being guessed. An explicit `.windowsCP1252` retry handles these files. Do not add further fallbacks — `.isoLatin1` and raw `.utf16` are covered by the two steps above.

**`setString` not `setData`** — The original bug: writing raw file bytes to `NSPasteboard` instead of a decoded `String`. UTF-8 bytes for emoji (`0xF0 0x9F...`) pasted as literal encoded characters. `setString` writes Unicode; paste targets render it correctly regardless of their own encoding.

**FinderSync extension** — On macOS 26 (Tahoe), NSServices entries no longer appear in Finder's right-click context menu. A `FIFinderSync` extension is the only way to surface a direct menu item. The extension must be in `/Applications` (pluginkit ignores `~/Applications`), signed with an Apple Development certificate (pluginkit refuses ad-hoc), and sandboxed with a `temporary-exception.files.absolute-path.read-only = ["/"]` entitlement so it can read files outside the container. Both mechanisms are shipped together so older macOS versions continue to work via NSServices.

## Test cases (ClipboardService)

1. UTF-8 file — reads and copies, Tink plays
2. UTF-8 file with emoji — no mangled characters on paste
3. Windows-1252 file — `usedEncoding:` detects it, copies correctly
4. Unreadable encoding — throws, Basso plays, pasteboard unchanged
5. File does not exist — throws, Basso plays
6. Non-`public.text` UTI — rejected before read, Basso plays
