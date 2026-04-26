import Cocoa
import FinderSync
import OSLog

private let logger = Logger(subsystem: "com.psenger.copy-to-clipboard", category: "findersync")

class FinderSyncExtension: FIFinderSync {
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems,
              let url = FIFinderSyncController.default().selectedItemURLs()?.first,
              isTextFile(url) else { return nil }
        let menu = NSMenu(title: "")
        let item = NSMenuItem(
            title: "Copy Contents to Clipboard",
            action: #selector(copyContents(_:)),
            keyEquivalent: ""
        )
        item.target = self
        menu.addItem(item)
        return menu
    }

    private func isTextFile(_ url: URL) -> Bool {
        if let values = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let type = values.contentType {
            return type.conforms(to: .text)
        }
        let textExtensions: Set<String> = [
            "txt", "md", "markdown", "swift", "py", "js", "ts",
            "json", "xml", "html", "htm", "css", "sh", "yaml", "yml",
            "rb", "java", "c", "cpp", "h", "go", "rs", "toml", "ini", "conf", "log"
        ]
        return textExtensions.contains(url.pathExtension.lowercased())
    }

    @objc func copyContents(_ sender: AnyObject?) {
        guard let url = FIFinderSyncController.default().selectedItemURLs()?.first else { return }
        Task { @MainActor in
            ClipboardService().copy(fileAt: url)
        }
    }
}
