import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKDatabase

/// The Extensions topic (the Extensions Settings Topic recipe): its columns,
/// the header's + and ↻ in place of a button bar, the Add Extension menu,
/// installing a downloaded item through the normal confirm path, and the URL
/// prompt's validation. A host over a scratch library, never the person's.
@available(macOS 15.4, *)
@MainActor
final class SafariExtensionsTopicTests: XCTestCase {

    private var root: URL!
    /// Every host a test made, so tearDown can wait for their saves: a
    /// host saves the catalog on a task of its own, and one still running
    /// when the root was removed wrote `Library/global` back, leaking it.
    private var hosts: [SafariExtensionHost] = []

    override func setUp() {
        super.setUp()
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SafariExtensionsTopicTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        for host in hosts { await host.savesFinished() }
        hosts = []
        try? FileManager.default.removeItem(at: root)
        try await super.tearDown()
    }

    // MARK: - Fixtures

    private func makeHost() -> SafariExtensionHost {
        let host = SafariExtensionHost(profile: .global, library: library)
        hosts.append(host)
        return host
    }

    /// A library over a scratch catalog, never the person's.
    private var library: SafariExtensionLibrary {
        SafariExtensionLibrary(
            catalog: LocalSafariExtensionCatalog(root: root.appendingPathComponent("Library")), scope: .global)
    }

    /// The records as the catalog holds them once `host`'s saves are in.
    private func savedRecords(of host: SafariExtensionHost) async throws -> [SafariExtensionRecord] {
        await host.savesFinished()
        return try await library.records()
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
        XCTAssertEqual(panel.descriptor.title, "Extensions")
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
        host.confirmInstall = { preview, kind, _, _, _ in
            asked.append(preview.displayName ?? "")
            XCTAssertEqual(kind, .new)
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

    // MARK: - Install paths (final review C-I3, C-I4, C-M4, C-M5)

    /// A public key in the manifest gives the extension Chrome's id for it.
    private static let sharedKey = Data((0..<32).map { UInt8($0) }).base64EncodedString()

    private func makeFolder(_ name: String, extensionName: String, key: String? = nil) throws -> URL {
        let folder = root.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var manifest: [String: Any] = ["manifest_version": 3, "name": extensionName, "version": "1.0"]
        if let key { manifest["key"] = key }
        try JSONSerialization.data(withJSONObject: manifest)
            .write(to: folder.appendingPathComponent("manifest.json"))
        return folder
    }

    /// `folder` as a zip, the way a CRX's payload is one; `ditto` keeps links.
    private func zip(_ folder: URL) throws -> Data {
        let file = root.appendingPathComponent("\(UUID().uuidString).zip")
        let ditto = Process()
        ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        ditto.arguments = ["-c", "-k", folder.path, file.path]
        try ditto.run()
        ditto.waitUntilExit()
        XCTAssertEqual(ditto.terminationStatus, 0)
        return try Data(contentsOf: file)
    }

    /// A store package holding a symbolic link is refused before the
    /// confirmation, as the downloaded and URL paths already were.
    func test_storePackageWithSymbolicLinkIsRefused() async throws {
        let host = makeHost()
        let folder = try makeFolder("StoreLinked", extensionName: "S")
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
            _ = try await host.install(
                crx: try zip(folder), id: "abcdefghijklmnopabcdefghijklmnop", presentingOn: nil)
            XCTFail("a store package with a symbolic link installed")
        } catch SafariExtensionHost.Failure.symbolicLink(_, let link) {
            XCTAssertEqual(link, "data.txt")
        }
        XCTAssertFalse(asked)
        XCTAssertTrue(host.extensions().isEmpty)
    }

    /// Files whose manifest key matches an installed store extension are a
    /// replacement: always confirmed as one, naming the installed extension,
    /// even when they ask for nothing new, and a local extension once
    /// installed, so the store's update check leaves them alone.
    func test_keyedTakeoverIsConfirmedAsAReplacement() async throws {
        let host = makeHost()
        let keyed = try XCTUnwrap(WebStoreExtension.id(ofKey: Self.sharedKey))
        let store = try makeFolder("Store", extensionName: "Trusted", key: Self.sharedKey)
        /// What the confirmation was asked and will answer, in a box the
        /// sendable closure can share with the test.
        @MainActor final class Confirmations {
            var kinds: [SafariExtensionHost.InstallKind] = []
            var answer = true
        }
        let confirmations = Confirmations()
        host.confirmInstall = { _, kind, _, _, _ in
            confirmations.kinds.append(kind)
            return confirmations.answer
        }
        let storeInstalled = try await host.install(crx: try zip(store), id: keyed, presentingOn: nil)
        XCTAssertTrue(storeInstalled)
        XCTAssertEqual(host.extensions().map(\.isFromWebStore), [true])

        let impostor = try makeFolder("Impostor", extensionName: "Impostor", key: Self.sharedKey)
        confirmations.answer = false
        let declined = try await host.installDownloaded(at: impostor)
        XCTAssertFalse(declined)
        XCTAssertEqual(confirmations.kinds, [.new, .replacement("Trusted")])
        XCTAssertEqual(host.extensions().map(\.name), ["Trusted"], "declining keeps the installed one")
        XCTAssertEqual(host.extensions().map(\.isFromWebStore), [true])

        confirmations.answer = true
        let replaced = try await host.installDownloaded(at: impostor)
        XCTAssertTrue(replaced)
        XCTAssertEqual(confirmations.kinds.last, .replacement("Trusted"))
        XCTAssertEqual(host.extensions().map(\.id), [keyed])
        XCTAssertEqual(host.extensions().map(\.name), ["Impostor"])
        XCTAssertEqual(host.extensions().map(\.isFromWebStore), [false])
    }

    /// A replacement is not handed the private browsing and file access the
    /// installed extension was allowed: the Replace sheet never asks about
    /// either.
    func test_keyedTakeoverDoesNotInheritPrivateOrFileAccess() async throws {
        let host = makeHost()
        let keyed = try XCTUnwrap(WebStoreExtension.id(ofKey: Self.sharedKey))
        let store = try makeFolder("Store", extensionName: "Trusted", key: Self.sharedKey)
        host.confirmInstall = { _, _, _, _, _ in true }
        let storeInstalled = try await host.install(crx: try zip(store), id: keyed, presentingOn: nil)
        XCTAssertTrue(storeInstalled)
        try host.setPrivateAccess(keyed, true)
        try host.setFileAccess(keyed, true)
        XCTAssertEqual(host.details(of: keyed)?.allowsPrivateBrowsing, true)
        XCTAssertEqual(host.details(of: keyed)?.allowsFileAccess, true)

        let impostor = try makeFolder("Impostor", extensionName: "Impostor", key: Self.sharedKey)
        let replaced = try await host.installDownloaded(at: impostor)
        XCTAssertTrue(replaced)
        let details = try XCTUnwrap(host.details(of: keyed))
        XCTAssertEqual(details.name, "Impostor")
        XCTAssertFalse(details.allowsPrivateBrowsing)
        XCTAssertFalse(details.allowsFileAccess)
        let records = try await savedRecords(of: host)
        let saved = try XCTUnwrap(records.first { $0.id == keyed })
        XCTAssertNotEqual(saved.allowsPrivateBrowsing, true)
        XCTAssertNotEqual(saved.allowsFileAccess, true)
    }

    /// A keyed install over an extension set to "On specific sites" is
    /// granted those sites again, so it runs where its details page says it
    /// does rather than nowhere.
    func test_keyedReplacementKeepsGrantsInStepWithSpecificSites() async throws {
        let host = makeHost()
        let keyed = try XCTUnwrap(WebStoreExtension.id(ofKey: Self.sharedKey))
        let first = try makeFolder("First", extensionName: "Sideloaded", key: Self.sharedKey)
        host.confirmInstall = { _, _, _, _, _ in true }
        let installed = try await host.installDownloaded(at: first)
        XCTAssertTrue(installed)
        let site = "*://*.github.com/*"
        try host.setSiteAccess(keyed, .specificSites, sites: [site])

        let update = try makeFolder("Update", extensionName: "Sideloaded 1.1", key: Self.sharedKey)
        let replaced = try await host.installDownloaded(at: update)
        XCTAssertTrue(replaced)
        let details = try XCTUnwrap(host.details(of: keyed))
        XCTAssertEqual(details.siteAccess, .specificSites)
        XCTAssertEqual(details.sites, [site])
        let records = try await savedRecords(of: host)
        let saved = try XCTUnwrap(records.first { $0.id == keyed })
        XCTAssertEqual(saved.grantedOrigins, [site])
    }

    /// The link check fails closed: a folder that is itself a link, or is not
    /// there to read, is reported rather than passed.
    func test_symbolicLinkCheckFailsClosed() throws {
        let folder = try makeFolder("Real", extensionName: "R")
        XCTAssertNil(SafariExtensionLibrary.symbolicLink(in: folder))
        let link = root.appendingPathComponent("Linked")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: folder)
        XCTAssertEqual(SafariExtensionLibrary.symbolicLink(in: link), ".")
        XCTAssertEqual(SafariExtensionLibrary.symbolicLink(in: root.appendingPathComponent("Missing")), ".")
    }

    /// A download larger than its limit is refused, not read into memory.
    func test_downloadIsCapped() async throws {
        let file = root.appendingPathComponent("big.crx")
        try Data(repeating: 0x50, count: 4096).write(to: file)
        do {
            _ = try await SafariExtensionLibrary.download(from: file, limit: 1024)
            XCTFail("a download over its limit was read")
        } catch WebStoreExtension.Failure.download(let detail) {
            XCTAssertTrue(detail.contains("larger than"), detail)
        }
        let small = try await SafariExtensionLibrary.download(from: file, limit: 8192)
        XCTAssertEqual(small.count, 4096)
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
        // No instruction line in the alert; the help says what URL… takes
        // (final review C-M6).
        XCTAssertEqual(prompt.alert.informativeText, "")
        XCTAssertFalse(prompt.okButton.isEnabled)
        prompt.setText("https://x/y.crx")
        XCTAssertTrue(prompt.okButton.isEnabled)
        prompt.setText("hello")
        XCTAssertFalse(prompt.okButton.isEnabled)
    }
}
