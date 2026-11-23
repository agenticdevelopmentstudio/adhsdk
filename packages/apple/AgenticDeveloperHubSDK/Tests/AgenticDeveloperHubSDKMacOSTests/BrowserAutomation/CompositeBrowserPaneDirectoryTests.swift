import XCTest
import WebKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A pane directory that answers `noWindow` to every open, as the Kitchen's
/// does with no project window open.
@MainActor
private final class WindowlessDirectory: BrowserPaneDirectory {
    func browserPanes() -> [BrowserPaneHandle] { [] }
    func browserPane(id: String) -> BrowserPaneHandle? { nil }
    func browserPane(besidePane paneID: String) -> BrowserPaneHandle? { nil }
    func lastUsedBrowserPane() -> BrowserPaneHandle? { nil }
    func openBrowserPane(besidePane paneID: String?, engine: BrowserEngineKind) throws -> BrowserPaneHandle {
        throw BrowserAutomationError.noWindow
    }
    func revealBrowserPane(id: String) {}
    func closeBrowserPane(id: String) {}
}

@MainActor
final class CompositeBrowserPaneDirectoryTests: XCTestCase {

    private var page: OffscreenWebView!
    private var first: FakeBrowserDirectory!
    private var second: FakeBrowserDirectory!
    private var focus: BrowserPaneFocus!
    private var composite: CompositeBrowserPaneDirectory!

    override func setUp() async throws {
        page = OffscreenWebView()
        first = FakeBrowserDirectory(pages: [:])
        second = FakeBrowserDirectory(pages: [:])
        focus = BrowserPaneFocus()
        composite = CompositeBrowserPaneDirectory([first, second], focus: focus)
    }

    private func handle(_ id: String) -> BrowserPaneHandle {
        BrowserPaneHandle(
            id: id, project: "proj", tab: "Tab \(id)",
            automation: BrowserAutomation(webView: page.webView, console: BrowserConsoleLog()), hidesImages: false)
    }

    func test_listsEveryDirectoryInOrder() {
        first.panes = [handle("A"), handle("B")]
        second.panes = [handle("C")]

        XCTAssertEqual(composite.browserPanes().map(\.id), ["A", "B", "C"])
    }

    func test_findsByIDInWhicheverDirectoryHasIt() {
        first.panes = [handle("A")]
        second.panes = [handle("C")]

        XCTAssertEqual(composite.browserPane(id: "C")?.id, "C")
        XCTAssertEqual(composite.browserPane(id: "A")?.id, "A")
        XCTAssertNil(composite.browserPane(id: "Z"))
    }

    func test_besideIsTheFirstDirectorysAnswer() {
        first.panes = [handle("A")]
        second.panes = [handle("C")]
        second.beside = ["caller": "C"]

        XCTAssertEqual(composite.browserPane(besidePane: "caller")?.id, "C", "the first has none beside it")

        first.beside = ["caller": "A"]
        XCTAssertEqual(composite.browserPane(besidePane: "caller")?.id, "A")
    }

    func test_lastUsedFallsBackToTheFirstDirectoryWithAnAnswer() {
        second.panes = [handle("C")]
        second.lastUsed = "C"

        XCTAssertEqual(composite.lastUsedBrowserPane()?.id, "C")

        first.panes = [handle("A")]
        first.lastUsed = "A"
        XCTAssertEqual(composite.lastUsedBrowserPane()?.id, "A")
    }

    func test_lastUsedIsTheFocusedPaneWhicheverDirectoryHasIt() {
        let settings = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        let pane = SafariBrowserPaneViewController(store: EphemeralPaneStateStore(), settings: settings)
        first.panes = [handle("A")]
        first.lastUsed = "A"
        second.panes = [BrowserPaneHandle(pane: pane, id: "focused", project: "p", tab: "t")]

        focus.note(pane)

        XCTAssertEqual(composite.lastUsedBrowserPane()?.id, "focused", "not the first directory's front pane")
    }

    func test_openGoesToTheFirstDirectoryWithAWindow() throws {
        let opening = CompositeBrowserPaneDirectory([WindowlessDirectory(), second], focus: focus)

        let opened = try opening.openBrowserPane(besidePane: "caller", engine: .safari)

        XCTAssertEqual(opened.id, "new-0")
        XCTAssertEqual(second.opened, ["caller"])
        XCTAssertEqual(second.openedEngines, [.safari])
    }

    func test_aRefusalOtherThanNoWindowIsTheAnswer() {
        first.openFails = true

        XCTAssertThrowsError(try composite.openBrowserPane(besidePane: nil, engine: .safari)) { error in
            XCTAssertEqual(error as? BrowserAutomationError, .openRefused)
        }
        XCTAssertEqual(second.opened, [], "a refused open is not tried again elsewhere")
    }

    func test_noDirectoryWithAWindowIsNoWindow() {
        let windowless = CompositeBrowserPaneDirectory([WindowlessDirectory(), WindowlessDirectory()], focus: focus)

        XCTAssertThrowsError(try windowless.openBrowserPane(besidePane: nil, engine: .safari)) { error in
            XCTAssertEqual(error as? BrowserAutomationError, .noWindow)
        }
    }

    func test_revealAndCloseReachEveryDirectory() {
        composite.revealBrowserPane(id: "C")
        composite.closeBrowserPane(id: "C")

        XCTAssertEqual(first.revealed, ["C"])
        XCTAssertEqual(second.revealed, ["C"])
        XCTAssertEqual(first.closed, ["C"])
        XCTAssertEqual(second.closed, ["C"])
    }
}
