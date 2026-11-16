import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The Extensions topic (the Extensions Settings Topic recipe): its columns,
/// the header's + and ↻ in place of a button bar, the Add Extension menu,
/// installing a downloaded item through the normal confirm path, and the URL
/// prompt's validation. A host over a scratch library, never the person's.
@available(macOS 15.4, *)
@MainActor
final class SafariExtensionsTopicTests: XCTestCase {

    private var root: URL!

    override func setUp() {
        super.setUp()
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SafariExtensionsTopicTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    // MARK: - Fixtures

    private func makeHost() -> SafariExtensionHost {
        SafariExtensionHost(
            profile: .global, library: SafariExtensionLibrary(root: root.appendingPathComponent("Library")))
    }

    private func makePanel(_ host: SafariExtensionHost) -> SafariExtensionsTopicPanel {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        let panel = SafariExtensionsTopicPanel(
            host: host, destination: { nil }, binding: BrowserSettingsBinding(settings: settings, scope: .global))
        _ = panel.view
        return panel
    }

    private func buttons(in view: NSView) -> [NSButton] {
        view.subviews.flatMap { subview -> [NSButton] in
            (subview as? NSButton).map { [$0] } ?? [] + buttons(in: subview)
        }
    }

    // MARK: - Table

    /// extensions-topic-002.
    func test_columnsOrder() throws {
        let panel = makePanel(makeHost())
        let table = try XCTUnwrap(panel.table)
        XCTAssertEqual(panel.title, "Extensions")
        XCTAssertEqual(table.tableView.tableColumns.map(\.identifier.rawValue),
                       ["on", "icon", "name", "version", "description", "gear"])
        XCTAssertEqual(table.tableView.tableColumns.first?.title, "")
        // Only Description takes up a change of width.
        let flexible = table.tableView.tableColumns.filter { $0.resizingMask.contains(.autoresizingMask) }
        XCTAssertEqual(flexible.map(\.identifier.rawValue), ["description"])
    }

    /// extensions-topic-004, extensions-topic-008.
    func test_noSourceColumnNoBottomBar() throws {
        let panel = makePanel(makeHost())
        let table = try XCTUnwrap(panel.table)
        XCTAssertNil(table.tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("source")))
        XCTAssertTrue(table.addButton.isHidden)
        XCTAssertTrue(table.removeButton.isHidden)
        let removed = ["Add…", "Options", "Details…", "Get Extensions…", "Check for Updates Now", "Refresh"]
        let titles = buttons(in: panel.view).map(\.title)
        for title in removed {
            XCTAssertFalse(titles.contains(title), title)
        }
    }

    /// extensions-topic-009.
    func test_headerButtonsHaveTooltips() throws {
        let panel = makePanel(makeHost())
        let header = try XCTUnwrap(panel.table?.tableView.headerView)
        let add = try XCTUnwrap(panel.addButton)
        let refresh = try XCTUnwrap(panel.refreshButton)
        XCTAssertEqual(add.toolTip, "Add Extension")
        XCTAssertEqual(refresh.toolTip, "Refresh and Check for Updates")
        XCTAssertEqual(add.accessibilityLabel(), "Add Extension")
        XCTAssertEqual(refresh.accessibilityLabel(), "Refresh and Check for Updates")
        XCTAssertTrue(add.isDescendant(of: header))
        XCTAssertTrue(refresh.isDescendant(of: header))
        // The header stays while the list is empty, so + is reachable.
        XCTAssertFalse(header.isHidden)
    }

    // MARK: - Add Extension

    /// extensions-topic-010, with no app extension on the Mac.
    func test_addMenuItems() {
        let panel = makePanel(makeHost())
        let menu = panel.addMenu([])
        XCTAssertEqual(menu.title, "Add Extension")
        XCTAssertEqual(menu.items.prefix(4).map(\.title),
                       ["Chrome Web Store…", "Apple App Store…", "Downloaded…", "URL…"])
        XCTAssertEqual(menu.items.count, 4)
    }

    /// extensions-topic-016.
    func test_downloadedRejectsUnsupported() async throws {
        let host = makeHost()
        let file = root.appendingPathComponent("foo.txt")
        try Data("not an extension".utf8).write(to: file)
        do {
            _ = try await host.installDownloaded(at: file)
            XCTFail("foo.txt installed")
        } catch SafariExtensionHost.Failure.unsupportedDownload(let url) {
            XCTAssertEqual(url.lastPathComponent, "foo.txt")
        }
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: root.appendingPathComponent("Library/Staging").path))
        XCTAssertTrue(host.extensions().isEmpty)
    }

    /// extensions-topic-014, extensions-topic-017: an unpacked folder reaches
    /// the confirmation, and declining it installs nothing.
    func test_downloadedAcceptsUnpackedFolder() async throws {
        let host = makeHost()
        let folder = root.appendingPathComponent("Unpacked", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(#"{"manifest_version":3,"name":"T","version":"1.0"}"#.utf8)
            .write(to: folder.appendingPathComponent("manifest.json"))
        var asked: [String] = []
        host.confirmInstall = { preview, isUpdate, _, _, _ in
            asked.append(preview.displayName ?? "")
            XCTAssertFalse(isUpdate)
            return false
        }
        let installed = try await host.installDownloaded(at: folder)
        XCTAssertFalse(installed)
        XCTAssertEqual(asked, ["T"])
        XCTAssertTrue(host.extensions().isEmpty)
    }

    /// A folder holding a symbolic link (here, one out of the folder) is
    /// refused before the confirmation, and nothing stays staged.
    func test_downloadedRefusesSymbolicLinks() async throws {
        let host = makeHost()
        let folder = root.appendingPathComponent("Linked", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(#"{"manifest_version":3,"name":"L","version":"1.0"}"#.utf8)
            .write(to: folder.appendingPathComponent("manifest.json"))
        let outside = root.appendingPathComponent("secret.txt")
        try Data("private".utf8).write(to: outside)
        try FileManager.default.createSymbolicLink(
            at: folder.appendingPathComponent("data.txt"), withDestinationURL: outside)
        var asked = false
        host.confirmInstall = { _, _, _, _, _ in
            asked = true
            return true
        }
        do {
            _ = try await host.installDownloaded(at: folder)
            XCTFail("a folder with a symbolic link installed")
        } catch SafariExtensionHost.Failure.symbolicLink(let url, let link) {
            XCTAssertEqual(url.lastPathComponent, "Linked")
            XCTAssertEqual(link, "data.txt")
        }
        XCTAssertFalse(asked)
        let staging = root.appendingPathComponent("Library/Staging")
        let left = (try? FileManager.default.contentsOfDirectory(atPath: staging.path)) ?? []
        XCTAssertEqual(left, [])
        XCTAssertTrue(host.extensions().isEmpty)
    }

    // MARK: - URL…

    /// extensions-topic-019 to extensions-topic-021.
    func test_urlPromptValidation() {
        XCTAssertTrue(ExtensionURLPromptController.isValid("abcdefghijklmnopabcdefghijklmnop"))
        XCTAssertTrue(ExtensionURLPromptController.isValid("https://x/y.crx"))
        XCTAssertTrue(ExtensionURLPromptController.isValid(
            "https://chromewebstore.google.com/detail/json-formatter/abcdefghijklmnopabcdefghijklmnop"))
        XCTAssertFalse(ExtensionURLPromptController.isValid("hello"))
        XCTAssertFalse(ExtensionURLPromptController.isValid("ftp://x/y.crx"))
        XCTAssertFalse(ExtensionURLPromptController.isValid("   "))
        let prompt = ExtensionURLPromptController(accessibilityPrefix: "test")
        XCTAssertFalse(prompt.okButton.isEnabled)
        prompt.setText("https://x/y.crx")
        XCTAssertTrue(prompt.okButton.isEnabled)
        prompt.setText("hello")
        XCTAssertFalse(prompt.okButton.isEnabled)
    }
}
