<div align="center">

# copy-to-clipboard

<img src="src/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="120" alt="copy-to-clipboard">

**A macOS Services helper that puts any text file's contents on the clipboard — right from Finder.**

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg?logo=swift)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

[Installation](#installation) • [Usage](#usage) • [How it works](#how-it-works) • [Development](#development)

</div>

---

Right-click any text file in Finder, choose **Services → Copy Contents to Clipboard**, and paste.
No app to open, no window to close. A Tink sound confirms the copy; a Basso sound means the
file was unreadable or binary.

The app handles UTF-8, UTF-16, and Windows-1252 files. It has no UI, no menu-bar icon, and no
persistent process — macOS wakes it on demand and exits it after each invocation.

## Installation

```bash
make install
```

Builds the Release app, copies it to `~/Applications`, and re-applies ad-hoc code signing.
The app registers itself with the macOS Services menu on first launch — no further setup needed.

> **Gatekeeper:** Ad-hoc signed apps are blocked on first open. Right-click the app in Finder,
> choose **Open**, and confirm once. macOS remembers the choice.

## Usage

1. Right-click any text file in Finder (`.swift`, `.py`, `.md`, `.json`, `.txt`, …)
2. Choose **Services → Copy Contents to Clipboard**
3. Paste anywhere

The service appears only for files whose UTI conforms to `public.text`. Binary files —
images, archives, executables — are silently rejected.

**Encoding support**

| File | How it's read |
|---|---|
| UTF-8 (with or without emoji) | Auto-detected |
| UTF-16 (with BOM) | Auto-detected |
| Windows-1252 / legacy Windows text | Explicit fallback after auto-detection fails |

## How it works

`copy-to-clipboard` is a launch-on-demand macOS Service. There is no persistent process.

```
Finder right-click
  └─ macOS Services framework
       └─ AppDelegate.copyFileContents(_:userData:error:)
            └─ ClipboardService.copy(fileAt:)
                 ├─ Reject non-public.text UTIs
                 ├─ String(contentsOf:usedEncoding:)           ← UTF-8 / UTF-16
                 ├─ String(contentsOf:encoding:.windowsCP1252) ← Windows fallback
                 └─ NSPasteboard.general.setString(_:forType:.string)
```

**Why `setString` and not `setData`?** Writing raw file bytes to the pasteboard causes emoji
and multi-byte Unicode to paste as garbage. Decoding the file to a Swift `String` first means
paste targets always receive Unicode regardless of the original file encoding.

## Development

```bash
git clone https://github.com/psenger/copy-to-clipboard.git
cd copy-to-clipboard
make test     # 10 tests, ~91% line coverage
make build    # Release build → build/Build/Products/Release/
```

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the full development guide, key invariants,
and architecture decisions.

## License

[MIT](./LICENSE) © 2026 Philip Senger

---

<div align="center">

**For developers who work with text files.**

[Report Bug](https://github.com/psenger/copy-to-clipboard/issues) • [Request Feature](https://github.com/psenger/copy-to-clipboard/issues) • [Contributing](./CONTRIBUTING.md)

</div>
