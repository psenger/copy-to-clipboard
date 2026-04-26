---
name: Logging Patterns
description: Always-on OSLog at .debug level — no config toggle, stripped from release builds automatically
type: project
---

# Logging Patterns

Use Apple's unified logging (`Logger`) exclusively — no file output, no runtime toggle.

## Setup

```swift
import OSLog
private let logger = Logger(subsystem: "com.yourapp.copy-to-clipboard", category: "main")
```

## Rules

- Log at `.debug` level everywhere — OSLog strips `.debug` from release builds automatically
- No `enabled` flag or config check — logging is always on in debug, always off in release
- Never log file contents — log file paths or metadata only
- View logs in Console.app filtered by subsystem `com.yourapp.copy-to-clipboard`

## Levels

| Use case | OSLog level |
|---|---|
| Tracing / flow | `.debug` |
| Normal events | `.info` |
| Recoverable errors | `.error` |
