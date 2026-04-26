# Tech Stack

## Language

- **Swift 6** — strict concurrency, `@MainActor` isolation for all AppKit/pasteboard access

## Platform

- **macOS 13 (Ventura)** minimum — uses `UTType`, `Logger`, and modern `String(contentsOf:usedEncoding:)` APIs
- **Cocoa / AppKit** — `NSPasteboard`, `NSSound`, `NSApplication`
- **UniformTypeIdentifiers** — `UTType.text` conformance check via `url.resourceValues`

## Services integration

- **NSServices** — `NSSendFileTypes = public.text` in `Info.plist`; `@MainActor @objc copyFileContents(_:userData:error:)` on `AppDelegate`; `pbs -update` on every launch to register with Finder
- **FinderSync** — `FIFinderSync` extension in `extension/`; surfaces the menu item directly in Finder's context menu on macOS 26+ where NSServices no longer appears
- **LaunchServices** — `LSBackgroundOnly = true`, `LSUIElement = true`

## Logging

- **OSLog** — `Logger(subsystem:category:)` with `.debug` for flow and `.error` for failures; no config toggle

## Testing

- **XCTest** — 11 tests, `@MainActor` class, real temp files, real `NSPasteboard.general`; no mocks
- Coverage measured via `xcodebuild -enableCodeCoverage YES`

## Build and distribution

- **Xcode 15+** with hand-crafted `project.pbxproj` (no CocoaPods, no SPM)
- **Make** — `make build`, `make test`, `make install`, `make clean`
- **Ad-hoc code signing** (`codesign --sign -`) for the main app; **Apple Development certificate** required for the FinderSync extension (pluginkit refuses ad-hoc signed extensions)

## Frontend / Backend / Database

N/A — this is a command-line-triggered native macOS helper with no network layer, no database, and no UI.
