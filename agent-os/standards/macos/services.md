---
name: macOS Services Wiring
description: NSServices Info.plist registration, first-launch pbs -update, and handler pattern
type: project
---

# macOS Services Wiring

Menu item registered via `NSServices` in `Info.plist`.
Do NOT use a Finder Sync Extension.

## Info.plist entry

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

## First launch registration

On first launch (detected via `UserDefaults` flag `hasRegistered`), run `pbs -update` to register
the service with Finder, then set the flag and quit.

```swift
if !UserDefaults.standard.bool(forKey: "hasRegistered") {
    let task = Process()
    task.launchPath = "/System/Library/CoreServices/pbs"
    task.arguments = ["-update"]
    task.launch()
    task.waitUntilExit()
    UserDefaults.standard.set(true, forKey: "hasRegistered")
}
```

## Rules

- `NSSendFileTypes = public.text` — menu appears for all text files; handler is the sole gatekeeper
- Single-file selection only — reject if `urls.count != 1`
- No `allowedTypes` config — `public.text` UTI conformance is the only type filter
- Ad-hoc signed only (`codesign --sign -`) — right-click → Open once to clear Gatekeeper

## Handler signature

```swift
@objc func copyFileContents(_ pboard: NSPasteboard,
                             userData: String,
                             error: AutoreleasingUnsafeMutablePointer<NSString?>) {
    guard let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL],
          urls.count == 1 else { return }
    ClipboardService().copy(fileAt: urls[0])
}
```
