import Cocoa
import OSLog

private let logger = Logger(subsystem: "com.psenger.copy-to-clipboard", category: "main")

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerServiceIfNeeded()
    }

    private func registerServiceIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "hasRegistered") else { return }
        let task = Process()
        task.launchPath = "/System/Library/CoreServices/pbs"
        task.arguments = ["-update"]
        try? task.run()
        task.waitUntilExit()
        defaults.set(true, forKey: "hasRegistered")
        logger.debug("NSService registered via pbs -update")
    }

    @MainActor @objc func copyFileContents(_ pboard: NSPasteboard,
                                userData: String,
                                error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let urls = pboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              urls.count == 1 else {
            logger.error("Expected exactly one file URL from pasteboard")
            return
        }
        ClipboardService().copy(fileAt: urls[0])
    }
}
