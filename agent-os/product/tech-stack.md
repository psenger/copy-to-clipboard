# Tech Stack

## Language

- **Swift 6** — strict concurrency, `@MainActor` isolation for all AppKit/pasteboard access

## Platform

- **macOS 13 (Ventura)** minimum — uses `UTType`, `Logger`, and modern `String(contentsOf:usedEncoding:)` APIs
- **Cocoa / AppKit** — `NSPasteboard`, `NSSound`, `NSApplication`
- **UniformTypeIdentifiers** — `UTType.text` conformance check via `url.resourceValues`

## Services integration

- **NSServices** — `NSSendFileTypes = public.text` in `Info.plist`; `@objc copyFileContents(_:userData:error:)` on `AppDelegate`
- **LaunchServices** — `LSBackgroundOnly = true`, `LSUIElement = true`; `pbs -update` on first launch to register with Finder

## Logging

- **OSLog** — `Logger(subsystem:category:)` with always-on `.debug` level; no config toggle

## Testing

- **XCTest** — 11 tests, `@MainActor` class, real temp files, real `NSPasteboard.general`; no mocks
- Coverage measured via `xcodebuild -enableCodeCoverage YES`

## Build and distribution

- **Xcode 15+** with hand-crafted `project.pbxproj` (no CocoaPods, no SPM)
- **Make** — `make build`, `make test`, `make install`, `make clean`
- **Ad-hoc code signing** (`codesign --sign -`) — no Apple Developer account or provisioning profile

## Frontend / Backend / Database

N/A — this is a command-line-triggered native macOS helper with no network layer, no database, and no UI.
