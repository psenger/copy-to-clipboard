---
name: Clipboard / Pasteboard
description: NSPasteboard write pattern — decode with usedEncoding to handle emoji, UTF-8, and Windows files
type: project
---

# Clipboard / Pasteboard

Always write a decoded Swift `String` to the pasteboard — never raw `Data`.
Use `usedEncoding:` to handle UTF-8 (with/without BOM), Windows-1252, and UTF-16 files correctly.

## Pattern

```swift
// Detect encoding and decode to String
var detectedEncoding: String.Encoding = .utf8
let content = try String(contentsOf: fileURL, usedEncoding: &detectedEncoding)

// Write to pasteboard
let pb = NSPasteboard.general
pb.clearContents()
pb.setString(content, forType: .string)
```

## Rules

- Use `usedEncoding:` — do NOT hardcode `.utf8` (breaks Windows-1252 and UTF-16 files)
- Use `setString(_:forType: .string)` — do NOT use `setData(_:forType:)` with raw bytes
- Call `clearContents()` before writing (always overwrite)
- If decoding throws, play `Basso` sound, log, and abort — do not fall back to a lossy encoding

## Why

Emoji and multi-byte Unicode require two things to work correctly:
1. `usedEncoding:` detects the actual encoding (UTF-8, Windows-1252, etc.) rather than assuming
2. `setString` writes a Swift `String` (Unicode) to the pasteboard — raw `Data` bytes paste as encoded garbage
