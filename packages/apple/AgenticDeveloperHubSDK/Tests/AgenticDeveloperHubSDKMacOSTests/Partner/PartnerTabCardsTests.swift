import XCTest
import AgenticDeveloperHubSDKCore
import AIPluginKit
@testable import AgenticDeveloperHubSDKMacOS

/// Drives real shells: each test that opens a session opens one in a temporary directory.
@MainActor
final class PartnerTabCardsTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!
    private var settings: SettingsStore!
    private var registry: PartnerSessionRegistry!
    private var controller: PartnerController!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerTabCardsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
        settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                 secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        registry = PartnerSessionRegistry(store: store, environment: { [:] }, detector: ManualSessionEventDetector())
        let notifier = PartnerNotifier(store: store, settings: settings, post: { _, _ in })
        controller = PartnerController(
            store: store, sessions: registry, notifier: notifier,
            paths: PartnerPaths(home: directory, token: "kitchen-test"), endpoint: { nil },
            findClaude: { "/bin/true" },
            makeProcess: { configuration, _ in FakePartnerProcess(configuration: configuration) },
            settings: settings, pid: 4242, isPIDAlive: { _ in false })
    }

    override func tearDown() async throws {
        _ = registry.closeAll()
        controller = nil
        registry = nil
        store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func waitUntil(_ timeout: TimeInterval = 3, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    private func review(_ state: PartnerReviewState, sessionID: String?, summary: String? = nil) -> PartnerReview {
        PartnerReview(
            id: "repo:abc1234", repoID: "repo", repoPath: "/tmp/none", repoName: "demo", sha: "abc1234", parent: "p",
            branch: "feature", subject: "s", author: "Ann", committedAt: Date(), state: state, sessionID: sessionID,
            summary: summary)
    }

    func testASessionCardSaysClaudeItsTitleDirectoryAndRunningSymbol() {
        let session = registry.open(directory: directory.path, title: "review abc1234", firstCommand: nil)
        let source = SessionCardSource(session: session) { _ in nil }
        let pane = TabPaneViewController(edge: .left, tabID: session.id)
        XCTAssertEqual(source.tabPaneAgentName(pane), "Claude")
        XCTAssertEqual(source.tabPaneSessionName(pane), "review abc1234")
        XCTAssertEqual(source.tabPaneWorkingDirectory(pane), URL(fileURLWithPath: directory.path))
        XCTAssertEqual(source.tabPaneStatusSymbols(pane).map(\.symbolName), ["circle.fill"])
        XCTAssertEqual(source.tabPaneStatusSymbols(pane).map(\.accessibilityLabel), ["Running"])
        XCTAssertNil(source.tabPaneBranch(pane))
        XCTAssertEqual(source.tabPaneSummary(pane), "Running")
    }

    func testASessionCardForAReviewShowsItsBranchStateAndFirstSummaryLine() {
        let session = registry.open(directory: directory.path, title: "t", firstCommand: nil)
        session.reviewID = "repo:abc1234"
        let owned = review(.done, sessionID: session.id.uuidString, summary: "Fixed one finding.\nSecond line.")
        let source = SessionCardSource(session: session) { $0 == owned.id ? owned : nil }
        let pane = TabPaneViewController(edge: .left, tabID: session.id)
        XCTAssertEqual(source.tabPaneBranch(pane), "feature")
        XCTAssertEqual(source.tabPaneSummary(pane), "review done · Fixed one finding.")
    }

    func testAReviewOwnedByAnotherSessionIsNotThisSessionsSummary() {
        let session = registry.open(directory: directory.path, title: "t", firstCommand: nil)
        session.reviewID = "repo:abc1234"
        let other = review(.running, sessionID: "someone-else")
        let source = SessionCardSource(session: session) { _ in other }
        let pane = TabPaneViewController(edge: .left, tabID: session.id)
        XCTAssertNil(source.tabPaneBranch(pane))
        XCTAssertEqual(source.tabPaneSummary(pane), "Running")
    }

    func testThePartnerCardSaysPartnerAndItsState() {
        let source = PartnerCardSource(controller: controller)
        let pane = TabPaneViewController(edge: .left, tabID: UUID())
        XCTAssertEqual(source.tabPaneAgentName(pane), "Partner")
        XCTAssertEqual(source.tabPaneSessionName(pane), "Stopped")
        XCTAssertEqual(source.tabPaneModelName(pane), "Claude Code default")
        XCTAssertNil(source.tabPaneBranch(pane))
        XCTAssertEqual(source.tabPaneWorkingDirectory(pane), controller.paths.directory)
    }

    func testTheModelNameIsTheChosenConfigurationAndModel() {
        let id = UUID()
        let configuration = AIProviderConfiguration(
            id: id, name: "Work Claude", pluginIdentifier: PartnerModelChoice.claudeLocalPluginIdentifier,
            templateId: "claude-local")
        XCTAssertEqual(
            PartnerCardSource.modelName(
                provider: id.uuidString, configurations: [configuration], model: { _ in "opus" }),
            "Work Claude · opus")
        XCTAssertEqual(
            PartnerCardSource.modelName(provider: id.uuidString, configurations: [configuration], model: { _ in "" }),
            "Work Claude")
        XCTAssertEqual(PartnerCardSource.modelName(provider: "", configurations: [configuration], model: { _ in "x" }),
                       "Claude Code default")
    }

    func testClosingASessionRemovesItsTabAndSelectsThePartner() async {
        let split = PartnerSplitViewController(controller: controller)
        split.loadViewIfNeeded()
        let session = registry.open(directory: directory.path, title: "t", firstCommand: nil)
        await waitUntil { split.tabbed.tabs(on: .left).count == 2 }
        XCTAssertEqual(split.tabbed.tabs(on: .left).map(\.id), [split.partnerTabID, session.id])
        split.select(sessionID: session.id)
        XCTAssertEqual(split.tabbed.selectedTabID(on: .left), session.id)

        registry.close(id: session.id)
        await waitUntil { split.tabbed.tabs(on: .left).count == 1 }
        XCTAssertEqual(split.tabbed.tabs(on: .left).map(\.id), [split.partnerTabID])
        XCTAssertEqual(split.tabbed.selectedTabID(on: .left), split.partnerTabID)
    }

    func testThePartnerTabCannotClose() {
        let split = PartnerSplitViewController(controller: controller)
        split.loadViewIfNeeded()
        split.multiTabbedViewController(split.tabbed, didRequestCloseTab: split.partnerTabID, on: .left)
        XCTAssertEqual(split.cards[split.partnerTabID]?.card.showsCloseButton, false)
        XCTAssertEqual(split.tabbed.tabs(on: .left).map(\.id), [split.partnerTabID])
    }

    func testThePartnerTabShowsPartnerAndNotificationsPanesThatCannotClose() throws {
        let split = PartnerSplitViewController(controller: controller)
        split.loadViewIfNeeded()
        let panes = try XCTUnwrap(split.partnerPanes)
        panes.loadViewIfNeeded()
        XCTAssertEqual(panes.splitViewItems.map(\.viewController),
                       [panes.partnerPane, panes.notificationsPane])
        panes.notificationsPane.loadViewIfNeeded()
        XCTAssertTrue(split.attention.view.isDescendant(of: panes.notificationsPane.view))
        for pane in [panes.partnerPane, panes.notificationsPane] {
            XCTAssertFalse(split.canClose(pane))
            split.paneDidRequestClose(pane)
        }
        XCTAssertEqual(panes.splitViewItems.count, 2)
    }

    func testArrangeModeMovesNotificationsAroundThePartnerPaneAndRemembersWhere() throws {
        let split = PartnerSplitViewController(controller: controller)
        split.loadViewIfNeeded()
        let panes = try XCTUnwrap(split.partnerPanes)
        panes.loadViewIfNeeded()
        let partner = panes.partnerPane, notifications = panes.notificationsPane

        // Notifications starts on the right, so it cannot move right and the Partner pane cannot move left.
        XCTAssertFalse(panes.availableMoveDirections(for: notifications).contains(.right))
        XCTAssertFalse(panes.availableMoveDirections(for: partner).contains(.left))
        XCTAssertFalse(panes.move(notifications, .right))

        XCTAssertTrue(panes.move(notifications, .below))
        XCTAssertFalse(panes.splitView.isVertical)
        XCTAssertEqual(panes.splitViewItems.map(\.viewController), [partner, notifications])
        XCTAssertEqual(settings.get(UserSettings.partnerNotificationsSide), "below")

        // The Partner pane moving right puts Notifications on its left, first in the split.
        XCTAssertTrue(panes.move(partner, .right))
        XCTAssertTrue(panes.splitView.isVertical)
        XCTAssertEqual(panes.splitViewItems.map(\.viewController), [notifications, partner])
        XCTAssertEqual(settings.get(UserSettings.partnerNotificationsSide), "left")

        // A new window opens the way the last one was left.
        let reopened = PartnerSplitViewController(controller: controller)
        reopened.loadViewIfNeeded()
        let again = try XCTUnwrap(reopened.partnerPanes)
        again.loadViewIfNeeded()
        XCTAssertEqual(again.notificationsSide, .left)
        XCTAssertEqual(again.splitViewItems.map(\.viewController), [again.notificationsPane, again.partnerPane])
    }
}
