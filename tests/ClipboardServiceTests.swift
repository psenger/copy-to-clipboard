import XCTest
@testable import copy_to_clipboard

@MainActor
final class ClipboardServiceTests: XCTestCase {

    var tempDir: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        NSPasteboard.general.clearContents()
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Test 1: UTF-8 file

    func testUTF8FileCopiedToPasteboard() throws {
        let content = "Hello, Swift!"
        let url = tempDir.appendingPathComponent("test.swift")
        try content.write(to: url, atomically: true, encoding: .utf8)

        ClipboardService().copy(fileAt: url)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), content)
    }

    // MARK: - Test 2: UTF-8 with emoji

    func testUTF8EmojiPreservesCharacters() throws {
        let content = "Hello 👋 World 🌍"
        let url = tempDir.appendingPathComponent("emoji.swift")
        try content.write(to: url, atomically: true, encoding: .utf8)

        ClipboardService().copy(fileAt: url)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), content)
    }

    // MARK: - Test 3: Windows-1252 file

    func testWindows1252FileDecodedCorrectly() throws {
        // © in Windows-1252 is 0xA9 — invalid as UTF-8 standalone, so usedEncoding: is required
        let content = "Price: 50\u{A9}2025"
        guard let data = content.data(using: .windowsCP1252) else {
            XCTFail("Could not encode test string as Windows-1252")
            return
        }
        let url = tempDir.appendingPathComponent("price.txt")
        try data.write(to: url)

        ClipboardService().copy(fileAt: url)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), content)
    }

    // MARK: - Test 4: File does not exist

    func testMissingFileLeavespasteboardUnchanged() {
        let url = tempDir.appendingPathComponent("ghost.swift")

        ClipboardService().copy(fileAt: url)

        XCTAssertNil(NSPasteboard.general.string(forType: .string))
    }

    // MARK: - Test 5: Non-public.text UTI

    func testNonTextFileLeavespasteboardUnchanged() throws {
        // PNG header bytes — UTI public.png does not conform to public.text
        let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        let url = tempDir.appendingPathComponent("image.png")
        try Data(pngHeader).write(to: url)

        ClipboardService().copy(fileAt: url)

        XCTAssertNil(NSPasteboard.general.string(forType: .string))
    }

    // MARK: - Mixed encoding tests

    func testWindows1252EuroSignDecoded() throws {
        // € = 0x80 in Windows-1252, not representable in UTF-8 at that byte value.
        // usedEncoding: fails; Windows-1252 fallback decodes it correctly.
        let content = "Cost: \u{20AC}50"
        let data = try XCTUnwrap(content.data(using: .windowsCP1252))
        let url = tempDir.appendingPathComponent("cost.txt")
        try data.write(to: url)

        ClipboardService().copy(fileAt: url)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), content)
    }

    func testUTF16FileDecoded() throws {
        // UTF-16 with BOM — usedEncoding: detects it directly; no fallback needed.
        let content = "Hello \u{4E16}\u{754C}"   // "Hello 世界"
        let data = try XCTUnwrap(content.data(using: .utf16))
        let url = tempDir.appendingPathComponent("unicode.txt")
        try data.write(to: url)

        ClipboardService().copy(fileAt: url)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), content)
    }

    // MARK: - AppDelegate handler

    func testHandlerCopiesFileContentViaPasteboard() throws {
        let content = "// handler test"
        let fileURL = tempDir.appendingPathComponent("handler.swift")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let inputBoard = NSPasteboard(name: .init("test-input-\(UUID().uuidString)"))
        defer { inputBoard.releaseGlobally() }
        inputBoard.clearContents()
        inputBoard.writeObjects([fileURL as NSURL])

        var errorString: NSString?
        AppDelegate().copyFileContents(inputBoard, userData: "", error: &errorString)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), content)
        XCTAssertNil(errorString)
    }

    func testHandlerRejectsEmptyPasteboard() {
        let inputBoard = NSPasteboard(name: .init("test-empty-\(UUID().uuidString)"))
        defer { inputBoard.releaseGlobally() }
        inputBoard.clearContents()

        var errorString: NSString?
        AppDelegate().copyFileContents(inputBoard, userData: "", error: &errorString)

        XCTAssertNil(NSPasteboard.general.string(forType: .string))
    }

    // MARK: - Test 11: Permission-denied file

    func testPermissionDeniedFileLeavespasteboardUnchanged() throws {
        let url = tempDir.appendingPathComponent("locked.txt")
        try "content".write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: url.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path) }

        ClipboardService().copy(fileAt: url)

        XCTAssertNil(NSPasteboard.general.string(forType: .string))
    }

    func testHandlerRejectsMultipleFiles() throws {
        let url1 = tempDir.appendingPathComponent("a.swift")
        let url2 = tempDir.appendingPathComponent("b.swift")
        try "A".write(to: url1, atomically: true, encoding: .utf8)
        try "B".write(to: url2, atomically: true, encoding: .utf8)

        let inputBoard = NSPasteboard(name: .init("test-multi-\(UUID().uuidString)"))
        defer { inputBoard.releaseGlobally() }
        inputBoard.clearContents()
        inputBoard.writeObjects([url1 as NSURL, url2 as NSURL])

        var errorString: NSString?
        AppDelegate().copyFileContents(inputBoard, userData: "", error: &errorString)

        XCTAssertNil(NSPasteboard.general.string(forType: .string))
    }
}
