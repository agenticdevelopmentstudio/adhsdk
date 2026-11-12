import XCTest
@testable import AgenticDeveloperHubSDKLanguage
@testable import AgenticDeveloperHubSDKMacOS

/// The File Browser's own behaviour, as against following an editor
/// (`SelectionSyncTests`): a root row is always open and shows no disclosure
/// triangle, the filter shows matches with their ancestors and gives the tree
/// back when cleared, and Return and Option-Return open in the current tab and
/// a new one.
@MainActor
final class FileTreeBrowsingTests: XCTestCase {

    private struct Fixture {
        let controller: FileTreeOutlineViewController
        let manager: FileTreeManager
        let subNode: FileTreeNode
        let nestedURL: URL
        let siblingURL: URL
    }

    /// A one-root browser over `root/sub/nested.swift` and `root/other.txt`,
    /// with every level already read, so nothing the tests do waits on the
    /// manager's async disk read. Paths are the ones the directory reads
    /// handed back, for the reason `SelectionSyncTests` gives.
    private func makeFixture() throws -> Fixture {
        let created = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileTreeBrowsingTests-\(UUID().uuidString)")
        let subdirectory = created.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: subdirectory, withIntermediateDirectories: true)
        try "// nested".write(to: subdirectory.appendingPathComponent("nested.swift"),
                             atomically: true,
                             encoding: .utf8)
        try "other".write(to: created.appendingPathComponent("other.txt"), atomically: true, encoding: .utf8)
        addTeardownBlock { try? FileManager.default.removeItem(at: created) }
        let directory = URL(fileURLWithPath: try XCTUnwrap(
            created.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath
        ))

        let rootNode = FileTreeNode(url: directory, isDirectory: true, loadChildren: true)
        let subNode = try XCTUnwrap(rootNode.children?.first { $0.name == "sub" })
        let siblingURL = try XCTUnwrap(rootNode.children?.first { $0.name == "other.txt" }).url
        subNode.children = FileTreeNode.loadChildren(for: subNode.url)
        let nestedURL = try XCTUnwrap(subNode.children?.first).url

        let manager = FileTreeManager(
            repoRootURL: directory,
            packageURL: directory.appendingPathComponent(".build"),
            config: .default
        )
        let roots = FileBrowserRootsModel()
        roots.managers = [manager]

        let controller = FileTreeOutlineViewController(
            roots: roots,
            directories: FileBrowserDirectories(primary: directory),
            selection: FileBrowserSelection(),
            restoration: FileBrowserRestorationState(),
            documentStore: TextDocumentStore()
        )
        controller.loadViewIfNeeded()
        // The pump-then-set order is `SelectionSyncTests`' fixture's, for the
        // reason it documents: the manager's initial `nil` lands a turn late.
        pumpRunLoop()
        manager.rootNode = rootNode
        pumpRunLoop()

        return Fixture(
            controller: controller,
            manager: manager,
            subNode: subNode,
            nestedURL: nestedURL,
            siblingURL: siblingURL
        )
    }

    private func pumpRunLoop() {
        for _ in 0..<10 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }
    }

    // MARK: - Root rows

    func testARootShowsADisclosureTriangleAndStartsOpen() throws {
        let fixture = try makeFixture()

        XCTAssertTrue(fixture.controller.showsOutlineCellForTesting(fixture.manager),
                      "Option-clicking a root's triangle closes the whole tree")
        XCTAssertTrue(fixture.controller.isExpandedForTesting(fixture.manager))
        XCTAssertTrue(fixture.controller.showsOutlineCellForTesting(fixture.subNode),
                      "a folder below the root keeps its triangle")
    }

    func testCollapsingEverythingLeavesTheRootOpen() throws {
        let fixture = try makeFixture()

        fixture.controller.collapseAllForTesting()

        XCTAssertTrue(fixture.controller.isExpandedForTesting(fixture.manager))
    }

    // MARK: - Filter

    func testTheFilterShowsMatchesWithTheirAncestorsAndHidesTheRest() throws {
        let fixture = try makeFixture()

        fixture.controller.setFilter("NEST")

        let drawn = fixture.controller.drawnPathsForTesting
        XCTAssertTrue(drawn.contains(fixture.nestedURL.path), "the match, case-insensitively")
        XCTAssertTrue(drawn.contains(fixture.subNode.url.path), "its ancestor, opened to show it")
        XCTAssertFalse(drawn.contains(fixture.siblingURL.path), "a name without the query is hidden")
    }

    func testClearingTheFilterGivesTheTreeBack() throws {
        let fixture = try makeFixture()
        fixture.controller.setFilter("nest")

        fixture.controller.setFilter("")

        let drawn = fixture.controller.drawnPathsForTesting
        XCTAssertTrue(drawn.contains(fixture.siblingURL.path))
        XCTAssertFalse(fixture.controller.isExpandedForTesting(fixture.subNode),
                       "a folder only the filter opened closes again")
    }

    // MARK: - Return and Option-Return

    func testReturnOpensTheSelectedFileInTheCurrentTab() throws {
        let fixture = try makeFixture()
        var received: [(URL, DocumentDestination)] = []
        fixture.controller.onOpenRequest = { received.append(($0, $1)) }
        fixture.controller.reveal(fixture.nestedURL)
        XCTAssertTrue(received.isEmpty, "selecting a row opens nothing")

        fixture.controller.activateSelectedRow(inNewTab: false)

        XCTAssertEqual(received.map(\.0), [fixture.nestedURL])
        XCTAssertEqual(received.map(\.1), [.current])
    }

    func testOptionReturnOpensTheSelectedFileInANewTab() throws {
        let fixture = try makeFixture()
        var received: [(URL, DocumentDestination)] = []
        fixture.controller.onOpenRequest = { received.append(($0, $1)) }
        fixture.controller.reveal(fixture.nestedURL)

        fixture.controller.activateSelectedRow(inNewTab: true)

        XCTAssertEqual(received.map(\.0), [fixture.nestedURL])
        XCTAssertEqual(received.map(\.1), [.newTab])
    }
}
