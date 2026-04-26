---
name: macOS Menu Mechanisms
description: NSServices (older macOS) and FinderSync extension (macOS 26+) wiring, registration, and handler patterns
type: project
---

# macOS Menu Mechanisms

Two mechanisms surface the menu item depending on macOS version:

| Mechanism | macOS version | Menu location |
|---|---|---|
| NSServices | macOS 13–25 | Services submenu |
| FinderSync extension | macOS 26+ (Tahoe) | Direct context menu (not in submenu) |

Both are built and shipped together. NSServices is the fallback; the FinderSync extension is the primary path on macOS 26+.

## NSServices: Info.plist entry

```xml
<key>NSServices</key>
<array>
  <dict>
    <key>NSMenuItem</key>
    <dict>
      <key>default</key>
      <string>Copy Contents to Clipboard</string>
    </dict>
    <key>NSMessage</key>
    <string>copyFileContents</string>
    <key>NSPortName</key>
    <string>copy-to-clipboard</string>
    <key>NSSendFileTypes</key>
    <array>
      <string>public.text</string>
    </array>
  </dict>
</array>
<key>LSUIElement</key>
<true/>
<key>LSBackgroundOnly</key>
<true/>
```

## NSServices: Registration on every launch

`pbs -update` runs unconditionally on every launch — no `UserDefaults` flag. The app is launch-on-demand so the overhead is negligible.

```swift
private func registerServiceIfNeeded() {
    let task = Process()
    task.launchPath = "/System/Library/CoreServices/pbs"
    task.arguments = ["-update"]
    try? task.run()
    task.waitUntilExit()
    logger.debug("NSService registered via pbs -update")
}
```

## NSServices: Handler signature

`@MainActor` is required because `ClipboardService.copy(fileAt:)` is `@MainActor`.

```swift
@MainActor @objc func copyFileContents(_ pboard: NSPasteboard,
                             userData: String,
                             error: AutoreleasingUnsafeMutablePointer<NSString?>) {
    guard let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL],
          urls.count == 1 else { return }
    ClipboardService().copy(fileAt: urls[0])
}
```

## FinderSync extension: key facts

- `FIFinderSync` subclass in `extension/FinderSyncExtension.swift`
- `directoryURLs = [URL(fileURLWithPath: "/")]` — monitors all of Finder
- `menu(for:)` filters by UTI (`type.conforms(to: .text)`) before returning a menu item; without this gate the item appears for images and binaries
- Extension must be in `/Applications` — pluginkit ignores `~/Applications`
- Must be signed with an Apple Development certificate — pluginkit refuses ad-hoc signed extensions

## Rules (both mechanisms)

- `NSSendFileTypes = public.text` — NSServices type filter; FinderSync filters by UTI at runtime in `menu(for:)`
- Single-file selection only — reject if `urls.count != 1`
- No config file — type filtering is entirely in code
