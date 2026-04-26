---
name: Logging Patterns
description: OSLog with .debug for flow and .error for failures — no config toggle, .debug stripped from release builds automatically
type: project
---

# Logging Patterns

Use Apple's unified logging (`Logger`) exclusively — no file output, no runtime toggle.

## Setup

```swift
import OSLog
private let logger = Logger(subsystem: "com.psenger.copy-to-clipboard", category: "main")
```

## Rules

- Use `.debug` for normal flow — OSLog strips `.debug` entries from release builds automatically
- Use `.error` for failures — `.error` is always persisted regardless of build type
- No `enabled` flag or config check — logging is always on in debug, always off in release for `.debug`
- Never log file contents — log file paths or metadata only
- View logs in Console.app filtered by subsystem `com.psenger.copy-to-clipboard`

## Levels

| Use case | OSLog level |
|---|---|
| Tracing / flow | `.debug` |
| Normal events | `.info` |
| Recoverable errors | `.error` |
