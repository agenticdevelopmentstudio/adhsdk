import AppKit
import Combine
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
    var url: URL? { nil }
    var title: String? { nil }
    var isLoading: Bool { false }
    var loadingChanges: AnyPublisher<Bool, Never> { Empty().eraseToAnyPublisher() }
    let view = NSView()
    var viewportSize: CGSize { .zero }
    var canGoBack: Bool { false }
    var canGoForward: Bool { false }
    var inputGate = BrowserInputGate.open
    var onInputDecision: ((BrowserInputChannel, String, Bool, Bool, String) -> Void)?
    var isActivationShieldActive: Bool { false }
    var heldLoadURL: URL? { nil }
    func load(_ url: URL) {}
    func goBack() {}
    func goForward() {}
    func reload() {}
    func stopLoading() {}
    func teardown() {}
    func setActivationShieldActive(_ active: Bool) {}
    func applyCookiePolicy(acceptsCookies: Bool) {}
    func installAutomationRuntime() async throws {}
    func callAsyncFunction(
        body: String, arguments: [String: Any], world: BrowserScriptWorld
    ) async throws -> Any? { nil }
    func snapshot(cssRect: CGRect?) async throws -> CGImage { throw CancellationError() }
    func nativeClick(atViewportX viewportX: Double, viewportY: Double) async throws {}
}
