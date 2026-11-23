import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The catalog's files, on a scratch root, never the person's.
final class LocalSafariExtensionCatalogTests: XCTestCase {

    private var root: URL!
    private var catalog: LocalSafariExtensionCatalog!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalSafariExtensionCatalogTests-\(UUID().uuidString)", isDirectory: true)
        catalog = LocalSafariExtensionCatalog(root: root.appendingPathComponent("Catalog", isDirectory: true))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// An unpacked extension staged outside the catalog, as a download is.
    private func stage(_ id: String, version: String = "1.0") throws -> URL {
        let folder = root.appendingPathComponent("Staging", isDirectory: true)
            .appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(#"{"name":"\#(id)","version":"\#(version)","manifest_version":3}"#.utf8)
            .write(to: folder.appendingPathComponent("manifest.json"))
        return folder
    }

    private func manifest(of id: String, scope: SafariExtensionScope) throws -> String {
        try String(
            contentsOf: catalog.directory(of: id, scope: scope).appendingPathComponent("manifest.json"),
            encoding: .utf8)
    }

    // MARK: - Records

    func test_recordsRoundTripPerScope() async throws {
        let jar = UUID()
        var first = SafariExtensionRecord(
            id: "aaaa", isFromWebStore: true, grantedPermissions: ["storage"], grantedOrigins: ["*://*.example.com/*"])
        first.siteAccess = .specificSites
        first.sites = ["*://*.example.com/*"]
        first.isPinned = false
        let second = SafariExtensionRecord(
            id: "com.example.app.Extension", isEnabled: false, isFromWebStore: false,
            appSource: .init(appexPath: "/Applications/Example.app/Contents/PlugIns/E.appex",
                             version: "2.1", appName: "Example"))

        try await catalog.save([first, second], scope: .global)
        try await catalog.save([second], scope: .jar(jar))

        let global = try await catalog.records(scope: .global)
        XCTAssertEqual(global, [first, second], "every field, in install order")
        let jarRecords = try await catalog.records(scope: .jar(jar))
        XCTAssertEqual(jarRecords, [second], "a jar keeps its own list")
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: catalog.root.appendingPathComponent("global/extensions.json").path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: catalog.root.appendingPathComponent("\(jar.uuidString)/extensions.json").path))
    }

    func test_noRecordsYetIsAnEmptyList() async throws {
        let records = try await catalog.records(scope: .jar(UUID()))
        XCTAssertEqual(records, [])
    }

    func test_recordsThatDoNotDecodeAreAnErrorNotEmpty() async throws {
        let file = catalog.recordsFile(of: .global)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: file)
        do {
            _ = try await catalog.records(scope: .global)
            XCTFail("unreadable records read as a list")
        } catch is DecodingError {}
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "not json", "nothing overwrote them")
    }

    // MARK: - Install

    func test_installMovesTheStagedDirectoryIntoPlace() async throws {
        let staged = try stage("abcd")
        let installed = try await catalog.install(stagedAt: staged, scope: .global)

        XCTAssertEqual(installed, catalog.directory(of: "abcd", scope: .global))
        XCTAssertFalse(FileManager.default.fileExists(atPath: staged.path), "moved, not copied")
        XCTAssertTrue(try manifest(of: "abcd", scope: .global).contains(#""version":"1.0""#))
        let records = try await catalog.records(scope: .global)
        XCTAssertEqual(records, [], "the records are the caller's to save")
    }

    func test_installReplacesTheInstalledCopy() async throws {
        try await catalog.install(stagedAt: try stage("abcd"), scope: .global)
        let leftover = catalog.directory(of: "abcd", scope: .global).appendingPathComponent("old.js")
        try Data("old".utf8).write(to: leftover)

        try await catalog.install(stagedAt: try stage("abcd", version: "2.0"), scope: .global)

        XCTAssertTrue(try manifest(of: "abcd", scope: .global).contains(#""version":"2.0""#))
        XCTAssertFalse(FileManager.default.fileExists(atPath: leftover.path), "nothing of the old copy is left")
    }

    func test_installGoesIntoItsScopeOnly() async throws {
        let jar = UUID()
        try await catalog.install(stagedAt: try stage("abcd"), scope: .jar(jar))
        XCTAssertTrue(FileManager.default.fileExists(atPath: catalog.directory(of: "abcd", scope: .jar(jar)).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: catalog.directory(of: "abcd", scope: .global).path))
    }

    // MARK: - Remove

    func test_removeLeavesOtherIDs() async throws {
        try await catalog.install(stagedAt: try stage("keep"), scope: .global)
        try await catalog.install(stagedAt: try stage("drop"), scope: .global)
        try await catalog.save(
            [SafariExtensionRecord(id: "keep", isFromWebStore: true),
             SafariExtensionRecord(id: "drop", isFromWebStore: true)],
            scope: .global)

        try await catalog.remove(id: "drop", scope: .global)

        XCTAssertFalse(FileManager.default.fileExists(atPath: catalog.directory(of: "drop", scope: .global).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: catalog.directory(of: "keep", scope: .global).path))
        let records = try await catalog.records(scope: .global)
        XCTAssertEqual(records.map(\.id), ["keep"])
    }

    func test_removingWhatIsNotThereIsNotAnError() async throws {
        try await catalog.remove(id: "never", scope: .global)
        let records = try await catalog.records(scope: .global)
        XCTAssertEqual(records, [])
    }

    // MARK: - Changes

    func test_eachWriteAnnouncesItsScope() async throws {
        let jar = UUID()
        let changes = catalog.changes
        let collected = Task { () -> [SafariExtensionScope] in
            var seen: [SafariExtensionScope] = []
            for await scope in changes {
                seen.append(scope)
                if seen.count == 3 { break }
            }
            return seen
        }
        try await catalog.save([], scope: .global)
        try await catalog.install(stagedAt: try stage("abcd"), scope: .jar(jar))
        try await catalog.remove(id: "abcd", scope: .jar(jar))
        _ = try await catalog.records(scope: .global)

        let seen = await collected.value
        XCTAssertEqual(seen, [.global, .jar(jar), .jar(jar)])
    }

    // MARK: - Scope

    func test_scopeFolderNamesRoundTrip() {
        let jar = UUID()
        XCTAssertEqual(SafariExtensionScope.global.folderName, "global")
        XCTAssertEqual(SafariExtensionScope.jar(jar).folderName, jar.uuidString)
        XCTAssertEqual(SafariExtensionScope(folderName: "global"), .global)
        XCTAssertEqual(SafariExtensionScope(folderName: jar.uuidString), .jar(jar))
        XCTAssertNil(SafariExtensionScope(folderName: "Staging"))
    }
}
