import XCTest
@testable import AgenticDeveloperHubSDKLanguage

final class BundledTextMateResourcesTests: XCTestCase {

    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("bundled-textmate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// A bundle on disk shaped as an app's: `Contents/Info.plist` and
    /// `Contents/Resources/`, with the TextMate folder holding `files`.
    private func makeBundle(named name: String, textMateFiles files: [String]?) throws -> Bundle {
        let bundleURL = root.appendingPathComponent("\(name).bundle", isDirectory: true)
        let contents = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": "com.example.\(name)",
            "CFBundleName": name,
            "CFBundlePackageType": "BNDL"
        ]
        let plist = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try plist.write(to: contents.appendingPathComponent("Info.plist"))
        if let files {
            let folder = resources.appendingPathComponent(BundledTextMateResources.folderName, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for file in files {
                try Data("{}".utf8).write(to: folder.appendingPathComponent(file))
            }
        }
        return try XCTUnwrap(Bundle(url: bundleURL))
    }

    func testABundleWithoutTheFolderAnswersNil() throws {
        let bundle = try makeBundle(named: "Bare", textMateFiles: nil)
        XCTAssertNil(BundledTextMateResources.load(from: bundle))
    }

    func testAFolderMissingARequiredFileAnswersNil() throws {
        let bundle = try makeBundle(named: "Partial", textMateFiles: ["highlighter.js", "onig.wasm"])
        XCTAssertNil(BundledTextMateResources.load(from: bundle))
    }

    func testTheFixtureFolderLoads() throws {
        let bundle = try makeBundle(named: "Full", textMateFiles: TextMateResources.requiredFiles)
        let resources = try XCTUnwrap(BundledTextMateResources.load(from: bundle))
        XCTAssertEqual(
            resources.directory.resolvingSymlinksInPath().standardizedFileURL,
            bundle.resourceURL?.appendingPathComponent("TextMate", isDirectory: true)
                .resolvingSymlinksInPath().standardizedFileURL)
    }
}
