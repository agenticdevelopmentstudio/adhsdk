import AppKit
import Combine
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// An engine that renders nothing, for tests of the pane around it: its page
/// may live in a window of its own, and it may draw its own toolbar.
@MainActor
final class StubBrowserEngine: BrowserEngine {
    let consoleLog: BrowserConsoleLog
    let pageWindow: NSWindow?
    let providesOwnToolbar: Bool
    init(consoleLog: BrowserConsoleLog, pageWindow: NSWindow? = nil, providesOwnToolbar: Bool = true) {
        self.consoleLog = consoleLog
        self.pageWindow = pageWindow
        self.providesOwnToolbar = providesOwnToolbar
    }
    weak var delegate: BrowserEngineDelegate?
    /// The page's address; a test sets it before telling the pane it moved.
    var url: URL?
    var title: String? { nil }
    var isLoading = false
    var loadingChanges: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
    let view = NSView()
    var viewportSize: CGSize { .zero }
    var canGoBack = false
    var canGoForward = false
    var inputGate = BrowserInputGate.open
    var onInputDecision: ((BrowserInputChannel, String, Bool, Bool, String) -> Void)?
    var isActivationShieldActive: Bool { false }
    var heldLoadURL: URL? { nil }
    func load(_ url: URL) {}
    /// Every navigation call, in order: "reload", "stop", "back", "forward".
    private(set) var navigationCalls: [String] = []
    func goBack() { navigationCalls.append("back") }
    func goForward() { navigationCalls.append("forward") }
    func reload() { navigationCalls.append("reload") }
    func stopLoading() { navigationCalls.append("stop") }
    func teardown() {}
    func setActivationShieldActive(_ active: Bool) {}
    private(set) var hidesImages = false
    func setHidesImages(_ hides: Bool) { hidesImages = hides }
    private(set) var pageWordFilter: TextSubstitutionFilter?
    func setPageWordFilter(_ filter: TextSubstitutionFilter?) { pageWordFilter = filter }
    func applyCookiePolicy(acceptsCookies: Bool) {}
    func installAutomationRuntime() async throws {}
    func callAsyncFunction(
        body: String, arguments: [String: Any], world: BrowserScriptWorld
    ) async throws -> Any? { nil }
    func snapshot(cssRect: CGRect?) async throws -> CGImage { throw CancellationError() }
    func nativeClick(atViewportX viewportX: Double, viewportY: Double) async throws {}
}
