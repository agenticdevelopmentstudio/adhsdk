import AgenticDeveloperHubSDKCore
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// What a closing project window still owes the project.
///
/// Everything structural is written as it happens, so the only writes a close
/// can race are the two debounced ones — the divider thicknesses and the
/// focused leaf. A close inside the debounce is not a rare window either: the
/// natural way to finish arranging a window is to arrange it and then close it.
@MainActor
final class ComposableTabsClosePersistTests: XCTestCase {

    private var tempRoot: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("composable-close-persist-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempRoot)
        try await super.tearDown()
    }

    /// Letting go of a divider and closing the window inside the 300 ms
    /// debounce used to throw the drag away: `windowWillClose` raised
    /// `isClosing`, and the pending write either was refused by it or ran
    /// against a controller nothing held any more. The arrangement the user
    /// left on screen is not a write the app gets to drop.
    func testAWindowClosedRightAfterADragStillSavesWhereTheDividerWas() throws {
        let project = try makeProject()
        let stored = TabRecord(title: "Tab 1", root: project.layout.blueprint())
        project.persistTabs([stored], activeTabID: stored.id, enabledEdges: [.top])

        let window = ComposableTabsWindowController(project: project)
        window.showWindow(nil)
        window.window?.setContentSize(NSSize(width: 900, height: 600))
        let split = try XCTUnwrap(
            Self.firstSplitTree(under: try XCTUnwrap(window.window?.contentViewController)),
            "expected the stored tab's split tree to be installed"
        )
        // The first real layout pass is what puts the preferred thicknesses on
        // screen; until it has run, a resize is AppKit's placeholder geometry
        // and is deliberately not persisted at all.
        split.view.layoutSubtreeIfNeeded()

        // The user drags the divider to a quarter of the window and lets go.
        let total = split.splitView.bounds.width
        split.splitView.setPosition(total * 0.25, ofDividerAt: 0)
        split.view.layoutSubtreeIfNeeded()
        XCTAssertNotEqual(
            storedFractions(over: project).first.map { ($0 * 100).rounded() }, 25,
            "the write must still be pending — otherwise the close proves nothing"
        )

        window.close()

        let saved = try XCTUnwrap(storedFractions(over: project).first)
        XCTAssertEqual(saved, 0.25, accuracy: 0.03,
                       "closing the window dropped the divider the user had just placed")
    }

    /// Until a project's first reconcile has settled, the window's live tab
    /// set is the placeholder it was built with, and the divider write the
    /// first layout pass arms reaches `persistAllTabs()` like any other. A
    /// scan slower than the 300 ms debounce let it store the placeholder,
    /// which the reconcile then kept as the main checkout's tab. Held while
    /// the reconcile is pending, and dropped when the reconcile writes.
    func testADividerWriteBeforeTheFirstReconcileDoesNotLand() async throws {
        let project = try makeProject()
        XCTAssertNil(project.storedTabs(), "a first open has nothing stored")

        let window = ComposableTabsWindowController(project: project, awaitsFirstReconcile: true)
        defer { window.close() }
        window.showWindow(nil)
        window.window?.setContentSize(NSSize(width: 900, height: 600))
        let split = try XCTUnwrap(
            Self.firstSplitTree(under: try XCTUnwrap(window.window?.contentViewController)),
            "expected the placeholder tab's split tree to be installed"
        )
        split.view.layoutSubtreeIfNeeded()
        let total = split.splitView.bounds.width
        split.splitView.setPosition(total * 0.25, ofDividerAt: 0)
        split.view.layoutSubtreeIfNeeded()

        // Well past the debounce: the write has come due and been held.
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertNil(project.storedTabs(), "a divider write before the first reconcile stored the placeholder")

        // The reconcile writes, as `ProjectController` does: cancel, persist,
        // reload, settle.
        let reconciled = TabRecord(title: "main", root: project.layout.blueprint())
        window.cancelPendingTabPersist()
        project.persistTabs([reconciled], activeTabID: reconciled.id, enabledEdges: [.top])
        window.reloadTabs()
        window.reconcileDidSettle()

        try await Task.sleep(for: .milliseconds(800))
        XCTAssertEqual(
            project.storedTabs()?.tabs.map(\.title), ["main"],
            "the held divider write must not land over the reconciled tabs"
        )
    }

    /// The other outcome of the first reconcile: it found the stored tabs
    /// already right and wrote nothing. The window is then showing a saved
    /// arrangement, and a divider the user moved while the scan ran is theirs
    /// — held, not dropped, and written the moment the reconcile settles.
    func testADividerHeldForTheFirstReconcileIsWrittenWhenItSettlesUnchanged() async throws {
        let project = try makeProject()
        let stored = TabRecord(title: "main", root: project.layout.blueprint())
        project.persistTabs([stored], activeTabID: stored.id, enabledEdges: [.top])

        let window = ComposableTabsWindowController(project: project, awaitsFirstReconcile: true)
        defer { window.close() }
        window.showWindow(nil)
        window.window?.setContentSize(NSSize(width: 900, height: 600))
        let split = try XCTUnwrap(
            Self.firstSplitTree(under: try XCTUnwrap(window.window?.contentViewController)),
            "expected the stored tab's split tree to be installed"
        )
        split.view.layoutSubtreeIfNeeded()
        let total = split.splitView.bounds.width
        split.splitView.setPosition(total * 0.25, ofDividerAt: 0)
        split.view.layoutSubtreeIfNeeded()

        try await Task.sleep(for: .milliseconds(800))
        XCTAssertNotEqual(
            storedFractions(over: project).first.map { ($0 * 100).rounded() }, 25,
            "the divider write must be held while the first reconcile is pending"
        )

        window.reconcileDidSettle()

        let saved = try XCTUnwrap(storedFractions(over: project).first)
        XCTAssertEqual(saved, 0.25, accuracy: 0.03,
                       "the divider held for the first reconcile was never written")
    }

    // MARK: - Helpers

    private func makeProject() throws -> ProjectWorkspace {
        let database = try ProjectDatabase(path: tempRoot.appendingPathComponent("Test.db").path)
        let repo = GitRepo(path: tempRoot.path, name: "Test")
        try database.insert(repo)
        return ProjectWorkspace(repo: repo, database: database)
    }

    /// The sizes as the *database* holds them, read through a workspace of its
    /// own so nothing can be answered out of the live window's memory.
    private func storedFractions(over project: ProjectWorkspace) -> [Double] {
        let reloaded = ProjectWorkspace(repo: project.repo, database: project.database)
        guard let root = reloaded.initialTabs().tabs.first?.root else { return [] }
        return Self.fractions(of: root)
    }

    private static func fractions(of node: LayoutNode) -> [Double] {
        switch node.kind {
        case .leaf:
            return [node.thicknessFraction].compactMap { $0 }
        case .split(_, let first, let second):
            return fractions(of: first) + fractions(of: second)
        }
    }

    private static func firstSplitTree(under controller: NSViewController) -> ComposableTabsViewController? {
        for child in controller.children {
            if let split = child as? ComposableTabsViewController { return split }
            if let found = firstSplitTree(under: child) { return found }
        }
        return nil
    }
}
