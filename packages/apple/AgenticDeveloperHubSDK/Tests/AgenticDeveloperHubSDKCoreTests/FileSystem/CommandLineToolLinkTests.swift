import XCTest
@testable import AgenticDeveloperHubSDKCore

final class CommandLineToolLinkTests: XCTestCase {

    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("CommandLineToolLinkTests-\(UUID().uuidString)", isDirectory: true)
        let app = root.appendingPathComponent("real/App", isDirectory: true)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        let tool = app.appendingPathComponent("tool")
        FileManager.default.createFile(atPath: tool.path, contents: Data("#!/bin/sh\n".utf8),
                                       attributes: [.posixPermissions: 0o755])
        // `apps` is a symlinked folder holding the app, as a symlinked
        // ~/Applications would be.
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("apps"),
                                                   withDestinationURL: root.appendingPathComponent("real"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private var bin: URL { root.appendingPathComponent("bin", isDirectory: true) }

    func testALinkToTheResolvedToolReadsAsInstalledThroughASymlinkedFolder() throws {
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: bin.appendingPathComponent("tool"),
                                                   withDestinationURL: root.appendingPathComponent("real/App/tool"))
        let link = CommandLineToolLink(name: "tool", tool: root.appendingPathComponent("apps/App/tool"),
                                       directory: bin)
        XCTAssertEqual(link.state, .installed)
    }

    func testALinkThroughTheSymlinkedFolderReadsAsInstalledForTheResolvedTool() throws {
        let throughSymlink = CommandLineToolLink(name: "tool", tool: root.appendingPathComponent("apps/App/tool"),
                                                 directory: bin)
        try throughSymlink.install()
        let resolved = CommandLineToolLink(name: "tool", tool: root.appendingPathComponent("real/App/tool"),
                                           directory: bin)
        XCTAssertEqual(resolved.state, .installed)
    }

    func testALinkToAnotherToolIsLinkedElsewhere() throws {
        let other = root.appendingPathComponent("other")
        FileManager.default.createFile(atPath: other.path, contents: Data(), attributes: [.posixPermissions: 0o755])
        try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: bin.appendingPathComponent("tool"), withDestinationURL: other)
        let link = CommandLineToolLink(name: "tool", tool: root.appendingPathComponent("apps/App/tool"),
                                       directory: bin)
        XCTAssertEqual(link.state, .linkedElsewhere(other.path))
    }

    // MARK: - helper(_:in:)

    /// A suite app's CLI in `Contents/Helpers`, beside an app whose name
    /// differs from the tool's only in case.
    func testAHelperIsFoundInContentsHelpers() throws {
        let bundle = try makeBundle(helper: "fake", executable: true)
        let link = try XCTUnwrap(CommandLineToolLink.helper("fake", in: bundle, directory: bin))
        XCTAssertEqual(link.name, "fake")
        XCTAssertEqual(link.tool.resolvingSymlinksInPath().path,
                       bundle.bundleURL.appending(path: "Contents/Helpers/fake").resolvingSymlinksInPath().path)
        XCTAssertEqual(link.directory, bin)
    }

    func testAMissingOrNonExecutableHelperIsNil() throws {
        let bundle = try makeBundle(helper: "fake", executable: false)
        XCTAssertNil(CommandLineToolLink.helper("fake", in: bundle, directory: bin))
        XCTAssertNil(CommandLineToolLink.helper("absent", in: bundle, directory: bin))
    }

    private func makeBundle(helper name: String, executable: Bool) throws -> Bundle {
        let app = root.appendingPathComponent("Fake.app", isDirectory: true)
        let helpers = app.appending(path: "Contents/Helpers", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: helpers, withIntermediateDirectories: true)
        let plist = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleIdentifier": "com.example.fake"], format: .xml, options: 0)
        try plist.write(to: app.appending(path: "Contents/Info.plist"))
        FileManager.default.createFile(atPath: helpers.appendingPathComponent(name).path,
                                       contents: Data("#!/bin/sh\n".utf8),
                                       attributes: [.posixPermissions: executable ? 0o755 : 0o644])
        return try XCTUnwrap(Bundle(url: app))
    }
}
