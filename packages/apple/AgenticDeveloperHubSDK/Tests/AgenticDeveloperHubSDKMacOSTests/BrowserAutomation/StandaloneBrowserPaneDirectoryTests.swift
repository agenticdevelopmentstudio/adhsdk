import XCTest
import AppKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A browser window that is never shown: its pane is real, its window is not.
@MainActor
private final class FakeBrowserWindow: StandaloneBrowserWindow {
    let browserWindowID: String
    let browserWindowTitle: String
    let pane: WebBrowserPaneViewController
    var browserWindow: NSWindow? { nil }
    var revealed = 0
    var closed = 0

    init(id: String, title: String, pane: WebBrowserPaneViewController) {
        browserWindowID = id
        browserWindowTitle = title
        self.pane = pane
    }

    func revealBrowserWindow() { revealed += 1 }
    func closeBrowserWindow() { closed += 1 }
}

@MainActor
final class StandaloneBrowserPaneDirectoryTests: XCTestCase {

    private var windows: [FakeBrowserWindow] = []
    private var opened: [BrowserEngineKind] = []
    private var opensNothing = false
    private var focus: BrowserPaneFocus!
    private var directory: StandaloneBrowserPaneDirectory!

    override func setUp() async throws {
        windows = []
        opened = []
        opensNothing = false
        focus = BrowserPaneFocus()
        directory = StandaloneBrowserPaneDirectory(
            windows: { [unowned self] in windows },
            open: { [unowned self] engine in
                opened.append(engine)
                guard !opensNothing else { return nil }
                let window = makeWindow("opened-\(opened.count)")
                windows.append(window)
                return window
            },
            focus: focus)
    }

    private func makeSettings() -> SettingsStore {
        UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
    }

    private func makeWindow(_ id: String, access: BrowserAgentAccess = .full) -> FakeBrowserWindow {
        let settings = makeSettings()
        settings.set(access, for: UserSettings.browserPrivacyAgentAccess)
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        return FakeBrowserWindow(id: id, title: "Title \(id)", pane: pane)
    }

    // MARK: - Listing

    func test_listsEveryWindowNewestFirstWhenNoneIsOnScreen() {
        windows = [makeWindow("A"), makeWindow("B")]

        let panes = directory.browserPanes()

        XCTAssertEqual(panes.map(\.id), ["B", "A"])
        XCTAssertEqual(panes.map(\.tab), ["Title B", "Title A"], "a window's tab is its title")
        XCTAssertEqual(Set(panes.map(\.project)), [StandaloneBrowserPaneDirectory.projectName])
        XCTAssertEqual(panes.first?.engine, .safari)
        XCTAssertTrue(panes.first?.automation === windows[1].pane.automation, "the pane's own automation")
    }

    func test_noWindowsIsNoPanes() {
        XCTAssertEqual(directory.browserPanes().map(\.id), [])
        XCTAssertNil(directory.lastUsedBrowserPane())
        XCTAssertNil(directory.browserPane(besidePane: "anything"))
    }

    func test_aHiddenPaneIsNotListedFoundOrDefault() {
        windows = [makeWindow("shown"), makeWindow("secret", access: .hidden)]

        XCTAssertEqual(directory.browserPanes().map(\.id), ["shown"])
        XCTAssertNil(directory.browserPane(id: "secret"))
        XCTAssertEqual(directory.browserPane(besidePane: "secret")?.id, "shown")
        XCTAssertEqual(directory.lastUsedBrowserPane()?.id, "shown")
    }

    // MARK: - Finding

    func test_findsAPaneByItsWindowID() {
        windows = [makeWindow("A"), makeWindow("B")]

        XCTAssertEqual(directory.browserPane(id: "A")?.tab, "Title A")
        XCTAssertNil(directory.browserPane(id: "C"))
    }

    func test_besideTheCallersOwnBrowserIsThatBrowser() {
        windows = [makeWindow("A"), makeWindow("B")]

        XCTAssertEqual(directory.browserPane(besidePane: "A")?.id, "A")
    }

    func test_besideAnyOtherPaneFallsBackToTheFrontBrowser() {
        windows = [makeWindow("A"), makeWindow("B")]

        XCTAssertEqual(directory.browserPane(besidePane: UUID().uuidString)?.id, "B")
    }

    func test_lastUsedIsTheFocusedPaneElseTheFrontOne() {
        windows = [makeWindow("A"), makeWindow("B")]
        XCTAssertEqual(directory.lastUsedBrowserPane()?.id, "B", "nothing focused: the front one")

        focus.note(windows[0].pane)

        XCTAssertEqual(directory.lastUsedBrowserPane()?.id, "A")
    }

    // MARK: - Opening, revealing, closing

    func test_openingOpensANewWindowOnTheEngineAsked() throws {
        windows = [makeWindow("A")]

        let handle = try directory.openBrowserPane(besidePane: "A", engine: .safari)

        XCTAssertEqual(opened, [.safari])
        XCTAssertEqual(handle.id, "opened-1")
        XCTAssertEqual(directory.browserPanes().count, 2)
    }

    func test_aWindowThatDoesNotOpenIsARefusal() {
        opensNothing = true

        XCTAssertThrowsError(try directory.openBrowserPane(besidePane: nil, engine: .chrome)) { error in
            XCTAssertEqual(error as? BrowserAutomationError, .openRefused)
        }
        XCTAssertEqual(opened, [.chrome])
    }

    func test_revealAndCloseReachOnlyTheirWindow() {
        windows = [makeWindow("A"), makeWindow("B")]

        directory.revealBrowserPane(id: "A")
        directory.closeBrowserPane(id: "B")
        directory.closeBrowserPane(id: "C")

        XCTAssertEqual(windows.map(\.revealed), [1, 0])
        XCTAssertEqual(windows.map(\.closed), [0, 1])
    }

    func test_closeReachesAHiddenPanesWindow() {
        windows = [makeWindow("secret", access: .hidden)]

        directory.closeBrowserPane(id: "secret")
        directory.revealBrowserPane(id: "secret")

        XCTAssertEqual(windows[0].closed, 1, "a refused open leaves nothing behind")
        XCTAssertEqual(windows[0].revealed, 0, "a hidden pane is never put on screen")
    }
}
