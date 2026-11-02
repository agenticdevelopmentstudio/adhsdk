import XCTest
import AgenticToolkitCore
@testable import AgenticToolkitMacOS

@MainActor
final class PartnerCodeReviewJobSettingsTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerCodeReviewJobSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Settings

    func testTheReviewSettingsDefaults() {
        let settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                     secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsWindowHours), 24)
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsCrawlIntervalMinutes), 30)
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsConcurrency), 1)
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsIncludeOtherBranches), false)
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsReviewerModel), "")
        XCTAssertEqual(settings.get(UserSettings.partnerReviewsFixBranch), "partner/review-fixes")
    }

    // MARK: - Projects table

    private func makePaths() -> PartnerPaths { PartnerPaths(home: directory, token: "kitchen-test") }

    private func makeTab() -> PartnerCodeReviewJobSettingsViewController {
        let model = PartnerJobsEditorModel(store: store, guidelines: PartnerGuidelinesInstaller(paths: makePaths()))
        let tab = PartnerCodeReviewJobSettingsViewController(model: model, store: store, projects: {
            [.init(id: "a", name: "Alpha", path: "/r/alpha"), .init(id: "b", name: "Beta", path: "/r/beta"),
             .init(id: "c", name: "No Path", path: "")]
        })
        tab.loadViewIfNeeded()
        tab.reloadProjects()
        return tab
    }

    func testProjectsWithAPathAreListed() {
        let tab = makeTab()
        XCTAssertEqual(tab.listed.map(\.id), ["a", "b"])
        XCTAssertEqual(tab.projectsCard.rows.map(\.id), ["a", "b"])
    }

    func testTheReviewToggleWritesTheOptOut() throws {
        let tab = makeTab()
        XCTAssertTrue(tab.isReviewed("a"), "reviewed unless opted out")
        tab.setReviewed(false, projectID: "a")
        XCTAssertEqual(try store.reviewSetting(repoID: "a", key: "opted_out"), "1")
        XCTAssertFalse(tab.isReviewed("a"))
        XCTAssertTrue(tab.isReviewed("b"))
        tab.setReviewed(true, projectID: "a")
        XCTAssertNil(try store.reviewSetting(repoID: "a", key: "opted_out"), "opting back in deletes the row")
        XCTAssertTrue(tab.isReviewed("a"))
    }

    func testTheReviewCellShowsTheOptOut() throws {
        try store.setReviewSetting(repoID: "b", key: "opted_out", value: "1")
        let tab = makeTab()
        func isOn(_ id: String) -> Bool? {
            guard case .toggle(let isOn)? = tab.projectsCard.rows.first(where: { $0.id == id })?.cells["review"]
            else { return nil }
            return isOn
        }
        XCTAssertEqual(isOn("a"), true)
        XCTAssertEqual(isOn("b"), false)
    }

    func testTogglingTheCellWritesTheOptOut() throws {
        let tab = makeTab()
        tab.projectsCard.onToggle?("a", "review", false)
        XCTAssertEqual(try store.reviewSetting(repoID: "a", key: "opted_out"), "1")
    }

    // MARK: - Panel

    private func makeController() -> PartnerController {
        let sessions = PartnerSessionRegistry(store: store, environment: { [:] },
                                              detector: ManualSessionEventDetector())
        return PartnerController(
            store: store, sessions: sessions, notifier: PartnerNotifier(store: store), paths: makePaths(),
            endpoint: { nil })
    }

    func testThePanelListsExactlyTheFiveSubTopics() {
        let panel = PartnerSettingsPanelViewController(controller: makeController(), pluginManager: nil)
        panel.loadViewIfNeeded()
        XCTAssertEqual(panel.panels.map { $0.descriptor.title },
                       ["General", "Model", "Permissions", "Code Review Job", "Notifications"])
        XCTAssertEqual(panel.descriptor.title, "Coding Partner")
        XCTAssertEqual(panel.sidebarTitle, "Coding Partner")
    }

    func testTheCodeReviewStepsAreEditedThroughTheModel() throws {
        let tab = makeTab()
        tab.reloadSteps()
        XCTAssertEqual(tab.stepsCard.rows.count, PartnerJobDefaults.codeReviews().steps.count)
        tab.editStep(rowID: "0", column: "name", to: "renamed")
        XCTAssertEqual(try store.jobs().first { $0.id == PartnerJobDefaults.codeReviewsID }?.steps.first?.name,
                       "renamed")
        tab.editStep(rowID: "1", column: "environment", to: "terminal")
        XCTAssertEqual(try store.jobs().first { $0.id == PartnerJobDefaults.codeReviewsID }?.steps[1].environment,
                       .terminal)
    }

    func testThePermissionsToolsTableEditsTheList() {
        let settings = SettingsStore(with: InMemorySettingsStorageProvider(),
                                     secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        let tab = PartnerPermissionsSettingsViewController(settings: settings)
        tab.loadViewIfNeeded()
        let count = settings.get(UserSettings.partnerAllowedToolsList).count
        tab.addTool()
        XCTAssertEqual(settings.get(UserSettings.partnerAllowedToolsList).count, count + 1)
        tab.editTool(rowID: String(count), to: "Grep")
        XCTAssertEqual(settings.get(UserSettings.partnerAllowedToolsList).last, "Grep")
        tab.editTool(rowID: String(count), to: "  ")
        XCTAssertEqual(settings.get(UserSettings.partnerAllowedToolsList).count, count, "an empty cell removes it")
    }

    // MARK: - Partner card queue

    func testTheQueueShowsWhileReviewsAreEnabled() {
        let queue = PartnerCardSource.ReviewQueue(waiting: 2, running: 1, done: 3)
        XCTAssertEqual(PartnerCardSource.queueText(queue, reviewsEnabled: true),
                       "queue: 2 waiting · 1 running · 3 done")
        XCTAssertEqual(PartnerCardSource.queueText(.init(waiting: 0, running: 0, done: 0), reviewsEnabled: true),
                       "queue: 0 waiting · 0 running · 0 done")
    }

    func testAnEmptyQueueHidesWhileReviewsAreOff() {
        let empty = PartnerCardSource.ReviewQueue(waiting: 0, running: 0, done: 0)
        let finished = PartnerCardSource.ReviewQueue(waiting: 0, running: 0, done: 4)
        XCTAssertNil(PartnerCardSource.queueText(empty, reviewsEnabled: false))
        XCTAssertEqual(PartnerCardSource.queueText(finished, reviewsEnabled: false),
                       "queue: 0 waiting · 0 running · 4 done")
        XCTAssertNil(PartnerCardSource.queueText(nil, reviewsEnabled: true))
    }

    // MARK: - Card summary

    private func review(state: PartnerReviewState, summary: String? = nil, skip: String? = nil,
                        sessionID: String = "s1") -> PartnerReview {
        PartnerReview(id: "r", repoID: "repo", repoPath: "/p", repoName: "demo", sha: "abc", parent: "p",
                      branch: "main", subject: "s", author: "Ann", committedAt: Date(), state: state,
                      sessionID: sessionID, summary: summary, skipReason: skip)
    }

    func testASessionWithoutAReviewShowsItsState() {
        XCTAssertEqual(SessionCardSource.summary(state: .idle, review: nil), "Idle")
    }

    func testAReviewSessionShowsTheReviewsStateAndSummary() {
        XCTAssertEqual(SessionCardSource.summary(state: .running, review: review(state: .running)),
                       "review running")
        let done = review(state: .done, summary: "Fixed two.\n")
        XCTAssertEqual(SessionCardSource.summary(state: .exited, review: done), "review done · Fixed two.")
        let skipped = review(state: .skipped, skip: "dirty worktree")
        XCTAssertEqual(SessionCardSource.summary(state: .exited, review: skipped),
                       "review skipped · dirty worktree")
    }
}
