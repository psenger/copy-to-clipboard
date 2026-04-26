import Cocoa
import OSLog
import UniformTypeIdentifiers

private let logger = Logger(subsystem: "com.psenger.copy-to-clipboard", category: "clipboard")

struct ClipboardService {

    @MainActor
    func copy(fileAt url: URL) {
        guard conformsToPublicText(url) else {
            logger.error("File does not conform to public.text: \(url.lastPathComponent, privacy: .public)")
            NSSound(named: "Basso")?.play()
            return
        }
        do {
            let content = try decode(url)
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(content, forType: .string)
            NSSound(named: "Tink")?.play()
            logger.debug("Copied to pasteboard")
        } catch {
            logger.error("Failed to read file: \(error.localizedDescription, privacy: .public)")
            NSSound(named: "Basso")?.play()
        }
    }

    // macOS 26 tightened usedEncoding: detection — no longer auto-detects Windows-1252.
    // UTF-8 and UTF-16 (with BOM) are handled by usedEncoding:; Windows-1252 needs explicit fallback.
    private func decode(_ url: URL) throws -> String {
        var usedEncoding: String.Encoding = .utf8
        if let content = try? String(contentsOf: url, usedEncoding: &usedEncoding) {
            return content
        }
        if let content = try? String(contentsOf: url, encoding: .windowsCP1252) {
            return content
        }
        throw CocoaError(.fileReadCorruptFile)
    }

    private func conformsToPublicText(_ url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.contentTypeKey]),
              let type = values.contentType else { return false }
        return type.conforms(to: .text)
    }
}
