import AgenticDeveloperHubSDKCore
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The app-wide tab positions (`tabs.positions`) and how a
/// `MultiTabbedViewController` follows them until it is given edges of its
/// own.
@MainActor
final class TabPositionSettingTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        // Writes UserSettings.shared, which suites in the other framework share.
        await ExclusiveAccess.Resource.userSettings.acquire()
    }

    override func tearDown() async throws {
        await ExclusiveAccess.Resource.userSettings.release()
        try await super.tearDown()
    }

    private var savedSettings: UserSettings!

    override func setUp() {
        super.setUp()
        savedSettings = UserSettings.shared
        UserSettings.shared = UserSettings(with: InMemorySettingsStorageProvider())
    }

    override func tearDown() {
        UserSettings.shared = savedSettings
        super.tearDown()
    }

    private func makeContent() -> NSViewController {
        let content = NSViewController()
        content.view = NSView()
        return content
    }

    private func enabledEdges(of controller: MultiTabbedViewController) -> Set<Edge> {
        Set(Edge.allCases.filter(controller.isEdgeEnabled))
    }

    // MARK: - TabPositions

    func test_emptyStoredPositionsReadAsTop() {
        XCTAssertEqual(TabPositions([]).edges, [.top])
    }

    func test_defaultSettingIsTopAlone() {
        XCTAssertEqual(UserSettings.tabsPositions.value, TabPositions([.top]))
    }

    func test_primaryEdgeOrder() {
        XCTAssertEqual(TabPositions([.bottom, .left]).primaryEdge, .left)
        XCTAssertEqual(TabPositions([.right, .bottom]).primaryEdge, .right)
        XCTAssertEqual(TabPositions([.right, .top]).primaryEdge, .top)
    }

    func test_removingLastEdgeReturnsNil() {
        XCTAssertNil(TabPositions([.left]).setting(.left, enabled: false))
    }

    func test_settingAnEdgeAddsAndRemovesIt() {
        XCTAssertEqual(TabPositions([.left]).setting(.top, enabled: true)?.edges, [.left, .top])
        XCTAssertEqual(TabPositions([.left, .top]).setting(.left, enabled: false)?.edges, [.top])
    }

    func test_encodesInPrimaryOrderAndDecodesEmptyAsTop() throws {
        let data = try JSONEncoder().encode(TabPositions([.bottom, .right, .top]))
        XCTAssertEqual(String(data: data, encoding: .utf8), #"["top","right","bottom"]"#)
        let empty = try JSONDecoder().decode(TabPositions.self, from: Data("[]".utf8))
        XCTAssertEqual(empty.edges, [.top])
        let unknown = try JSONDecoder().decode(TabPositions.self, from: Data(#"["sideways","left"]"#.utf8))
        XCTAssertEqual(unknown.edges, [.left])
    }

    // MARK: - Following the setting

    func test_controllerFollowsGlobalUntilExplicit() {
        UserSettings.tabsPositions.value = TabPositions([.left])
        let controller = MultiTabbedViewController()
        controller.loadViewIfNeeded()
        XCTAssertTrue(controller.followsGlobalTabPositions)
        XCTAssertTrue(controller.isEdgeEnabled(.left))
        XCTAssertFalse(controller.isEdgeEnabled(.top))

        controller.setEdgeEnabled(.bottom, true)
        XCTAssertFalse(controller.followsGlobalTabPositions)
        UserSettings.tabsPositions.value = TabPositions([.right])
        // The observer delivers on the next main-queue turn; drain it.
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(enabledEdges(of: controller), [.left, .bottom])

        controller.overrideTabPositions(nil)
        XCTAssertTrue(controller.followsGlobalTabPositions)
        XCTAssertEqual(enabledEdges(of: controller), [.right])
    }

    func test_overrideWinsOverTheSetting() {
        let controller = MultiTabbedViewController()
        controller.overrideTabPositions(TabPositions([.bottom]))
        controller.loadViewIfNeeded()
        UserSettings.tabsPositions.value = TabPositions([.left])
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertFalse(controller.followsGlobalTabPositions)
        XCTAssertEqual(enabledEdges(of: controller), [.bottom])
    }

    func test_controllerPrimaryEdge() {
        let controller = MultiTabbedViewController()
        controller.overrideTabPositions(TabPositions([.right, .bottom]))
        XCTAssertEqual(controller.primaryEdge, .right)
    }

    // MARK: - Single-edge hosts

    /// multi-tabbed-051: three tabs on top, the second selected; the edges
    /// change to the left, and all three move there in order, still selected.
    func test_singleEdgeHostMovesTabsKeepingOrderAndSelection() {
        let controller = MultiTabbedViewController()
        controller.keepsTabsOnPrimaryEdge = true
        controller.loadViewIfNeeded()
        let tabs = (1...3).map { MultiTabbedViewController.Tab(title: "\($0)", viewController: makeContent()) }
        for tab in tabs { controller.addTab(tab, on: controller.primaryEdge) }
        controller.selectTab(id: tabs[1].id, on: .top)

        controller.overrideTabPositions(TabPositions([.left, .bottom]))

        XCTAssertEqual(controller.primaryEdge, .left)
        XCTAssertEqual(enabledEdges(of: controller), [.left], "a single-edge host shows only its primary edge")
        XCTAssertEqual(controller.tabs(on: .left).map(\.id), tabs.map(\.id))
        XCTAssertTrue(controller.tabs(on: .top).isEmpty)
        XCTAssertEqual(controller.selectedTabID(on: .left), tabs[1].id)
    }

    // MARK: - Top accessory

    /// multi-tabbed-052: with the tabs on the left the accessory is still the
    /// centre's top row, right of the left bar.
    func test_topAccessoryStaysTopWhenTabsOnLeft() throws {
        let controller = MultiTabbedViewController()
        controller.overrideTabPositions(TabPositions([.left]))
        controller.loadViewIfNeeded()
        controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        let content = makeContent()
        controller.addTab(.init(title: "One", viewController: content), on: .left)
        let accessory = NSView()
        accessory.translatesAutoresizingMaskIntoConstraints = false
        accessory.heightAnchor.constraint(equalToConstant: 30).isActive = true
        controller.setTopAccessory(accessory)
        controller.view.layoutSubtreeIfNeeded()

        let root = controller.view
        let accessoryFrame = root.convert(accessory.bounds, from: accessory)
        let contentFrame = root.convert(content.view.bounds, from: content.view)
        let leftBar = try XCTUnwrap(controller.tabBars[.left])
        let barFrame = root.convert(leftBar.bounds, from: leftBar)

        XCTAssertTrue(controller.topAccessory === accessory)
        XCTAssertEqual(accessoryFrame.maxY, root.bounds.maxY, accuracy: 0.5, "the accessory is at the top")
        XCTAssertEqual(contentFrame.maxY, accessoryFrame.minY, accuracy: 0.5, "the content starts under it")
        XCTAssertGreaterThanOrEqual(accessoryFrame.minX, barFrame.maxX - 0.5, "it is not inside the left bar")
        XCTAssertFalse(accessory.isDescendant(of: leftBar))
    }

    // MARK: - Project windows

    /// A project with its own Tab Bars choice can be returned to following the
    /// app-wide positions, and keeps following them once reopened (final
    /// review C-I1).
    func test_projectWindowUseGlobalSettingFollowsTheAppWidePositions() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("tab-positions-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let database = try ProjectDatabase(path: root.appendingPathComponent("Test.db").path)
        let repo = GitRepo(path: root.path, name: "Test")
        try database.insert(repo)
        let project = ProjectWorkspace(repo: repo, database: database)
        let stored = TabRecord(title: "Tab 1", root: project.layout.blueprint())
        project.persistTabs([stored], activeTabID: stored.id, enabledEdges: [.top, .left])
        UserSettings.tabsPositions.value = TabPositions([.right])

        let window = ComposableTabsWindowController(project: project)
        window.showWindow(nil)
        defer { window.close() }
        XCTAssertEqual(window.enabledTabEdgeNames, ["top", "left"], "the project's own choice wins")

        window.useGlobalTabPositions()
        XCTAssertEqual(window.enabledTabEdgeNames, ["right"])
        XCTAssertNil(try database.loadTabs(repoID: repo.id).enabledEdges, "the stored choice is cleared")

        // The static setting's live delivery is bound to the
        // `UserSettings.shared` of its first use, not the one setUp swapped
        // in, so the observer's action is run as it would be delivered.
        UserSettings.tabsPositions.value = TabPositions([.bottom])
        window.followGlobalTabPositions()
        XCTAssertEqual(window.enabledTabEdgeNames, ["bottom"], "the window follows the setting")
        XCTAssertNil(try database.loadTabs(repoID: repo.id).enabledEdges)

        window.close()
        let reopened = ComposableTabsWindowController(project: project)
        reopened.showWindow(nil)
        defer { reopened.close() }
        XCTAssertEqual(reopened.enabledTabEdgeNames, ["bottom"], "reopened, it still follows")
    }
}
