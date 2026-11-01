import AppKit
import AgenticToolkitCore
import AIPluginKit

// The Coding Partner window's tab cards and panes. The cards are the shared `TabPaneViewController`; what
// they say comes from the data sources here, and the panes in the center are the shared
// `PaneViewController` wrapping the partner's transcript, a session's terminal or a final screen.

/// A status symbol for a partner session's state.
func partnerSessionStatusSymbol(_ state: PartnerSession.State) -> TabPaneStatusSymbol {
    switch state {
    case .running: return TabPaneStatusSymbol(symbolName: "circle.fill", accessibilityLabel: "Running")
    case .idle: return TabPaneStatusSymbol(symbolName: "pause.circle", accessibilityLabel: "Idle")
    case .exited: return TabPaneStatusSymbol(symbolName: "stop.circle", accessibilityLabel: "Exited")
    }
}

/// What the partner's own card says.
@MainActor
final class PartnerCardSource: TabPaneDataSource {

    private let controller: PartnerController

    init(controller: PartnerController) {
        self.controller = controller
    }

    /// "Claude Code default" for no provider; otherwise the chosen configuration's name and its model.
    static func modelName(provider: String, configurations: [AIProviderConfiguration],
                          model: (UUID) -> String) -> String {
        let fallback = "Claude Code default"
        guard !provider.isEmpty else { return fallback }
        guard let id = UUID(uuidString: provider), let configuration = configurations.first(where: { $0.id == id })
        else { return fallback }
        let chosen = model(id)
        return chosen.isEmpty ? configuration.name : "\(configuration.name) · \(chosen)"
    }

    func tabPaneAgentName(_ pane: TabPaneViewController) -> String { "Partner" }

    func tabPaneModelName(_ pane: TabPaneViewController) -> String? {
        let settings = controller.settings
        return Self.modelName(
            provider: settings.get(UserSettings.partnerProvider),
            configurations: settings.get(UserSettings.aiProviderConfigurations),
            model: { settings.get(UserSettings.partnerModel(config: $0)) })
    }

    func tabPaneStatusSymbols(_ pane: TabPaneViewController) -> [TabPaneStatusSymbol] {
        switch controller.state {
        case .stopped: return [TabPaneStatusSymbol(symbolName: "stop.circle", accessibilityLabel: "Stopped")]
        case .starting, .thinking:
            return [TabPaneStatusSymbol(symbolName: "circle.fill", accessibilityLabel: "Running")]
        case .idle: return [TabPaneStatusSymbol(symbolName: "pause.circle", accessibilityLabel: "Idle")]
        case .failed: return [TabPaneStatusSymbol(symbolName: "exclamationmark.triangle", accessibilityLabel: "Failed")]
        }
    }

    func tabPaneSessionName(_ pane: TabPaneViewController) -> String { controller.state.displayText }

    func tabPaneWorkingDirectory(_ pane: TabPaneViewController) -> URL { controller.paths.directory }

    func tabPaneBranch(_ pane: TabPaneViewController) -> String? { nil }

    func tabPaneSummary(_ pane: TabPaneViewController) -> String? {
        PartnerToolbar.currentQueueText(store: controller.store)
    }
}

/// What a card for a session the partner opened says.
@MainActor
final class SessionCardSource: TabPaneDataSource {

    private let session: PartnerSession
    private let review: (String) -> PartnerReview?

    /// - Parameter review: looks a review up by id; an unreadable one is nil.
    init(session: PartnerSession, review: @escaping (String) -> PartnerReview?) {
        self.session = session
        self.review = review
    }

    /// The review this session is running, when it has one and it can be read. A requeued review runs again in
    /// a new session, so the earlier session still names it; only the session the review records as its own
    /// speaks for it.
    private var ownedReview: PartnerReview? {
        guard let id = session.reviewID, let found = review(id),
              found.sessionID == session.id.uuidString else { return nil }
        return found
    }

    /// The review's state and the first line of what it finished with, or the session's state.
    static func summary(state: PartnerSession.State, review: PartnerReview?) -> String {
        guard let review else { return state.rawValue.capitalized }
        let text = review.summary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        let detail = firstLine.isEmpty ? review.skipReason ?? "" : firstLine
        return detail.isEmpty ? "review \(review.state.rawValue)" : "review \(review.state.rawValue) · \(detail)"
    }

    func tabPaneAgentName(_ pane: TabPaneViewController) -> String { "Claude" }
    func tabPaneModelName(_ pane: TabPaneViewController) -> String? { nil }
    func tabPaneStatusSymbols(_ pane: TabPaneViewController) -> [TabPaneStatusSymbol] {
        [partnerSessionStatusSymbol(session.state)]
    }
    func tabPaneSessionName(_ pane: TabPaneViewController) -> String { session.title }
    func tabPaneWorkingDirectory(_ pane: TabPaneViewController) -> URL {
        URL(fileURLWithPath: session.directory)
    }
    func tabPaneBranch(_ pane: TabPaneViewController) -> String? {
        guard let branch = ownedReview?.branch, !branch.isEmpty else { return nil }
        return branch
    }
    func tabPaneSummary(_ pane: TabPaneViewController) -> String? {
        Self.summary(state: session.state, review: ownedReview)
    }
}

/// The shared pane with a fixed title, wrapping the content it is given. Zoom and minimize are not offered.
@MainActor
final class PartnerPaneViewController: PaneViewController {

    let paneTitle: String
    /// The session this pane shows, when it shows one; closing the pane closes the session.
    let sessionID: UUID?
    private let content: NSViewController
    /// False for a pane that cannot be closed (the partner, the Notifications pane): it shows no × at all.
    let showsCloseButton: Bool

    init(title: String, content: NSViewController, sessionID: UUID? = nil, showsCloseButton: Bool = true) {
        paneTitle = title
        self.showsCloseButton = showsCloseButton
        self.content = content
        self.sessionID = sessionID
        super.init(stateStore: EphemeralPaneStateStore())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func makeContentViewController() -> NSViewController? { content }
    override var fallbackTitle: String { paneTitle }
    override var paneAccessibilityIdentifier: String { "partner.pane" }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleBar.controls.minimizeButton.isHidden = true
        titleBar.controls.zoomButton.isHidden = true
        titleBar.controls.closeButton.isHidden = !showsCloseButton
    }
}

/// Hosts the partner's `ChatView`. Made once and kept, since its view model is the partner chat session's one
/// subscriber.
@MainActor
final class PartnerChatViewController: NSViewController {

    let chatView: ChatView

    /// - Parameter route: where the composer's text goes. The window routes it to the partner, wrapped when a
    ///   discussion is in progress.
    init(controller: PartnerController, route: @escaping @MainActor (String) -> Void) {
        let initial: [ChatMessage]
        do { initial = try controller.store.transcript(limit: 200) } catch {
            Self.logger.error("Loading the partner transcript failed: \(error.localizedDescription)")
            initial = []
        }
        let session = PartnerComposerSession(base: controller.chatSession, route: route)
        chatView = ChatView(viewModel: AIChatViewModel(session: session, initial: initial))
        chatView.bubbleStyle = .speaker
        chatView.setAccessibilityIdentifier("partner.transcript")
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() { view = chatView }
}

extension PartnerChatViewController: Loggable {
    static nonisolated let logger = makeLogger()
}

/// A closed session's final screen, read-only.
@MainActor
final class PartnerFinalScreenViewController: NSViewController {

    private let text: String

    init(record: PartnerStore.SessionRecord) {
        text = record.finalScreen ?? "This session closed without a final screen."
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let scroll = NSTextView.scrollableTextView()
        scroll.setAccessibilityIdentifier("partner.finalScreen")
        if let textView = scroll.documentView as? NSTextView {
            textView.isEditable = false
            textView.isSelectable = true
            textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            textView.textContainerInset = NSSize(width: 8, height: 8)
            textView.string = text
        }
        view = scroll
    }
}

/// The partner chat session as the composer sees it: events and interrupt are the session's own,
/// `close` is the controller's, and only `send` goes through the window, which may wrap the text before it
/// reaches the partner.
private final class PartnerComposerSession: ChatSession, @unchecked Sendable {
    private let base: PartnerChatSession
    private let route: @MainActor (String) -> Void

    init(base: PartnerChatSession, route: @escaping @MainActor (String) -> Void) {
        self.base = base
        self.route = route
    }

    func events() -> AsyncStream<ChatEvent> { base.events() }
    func send(_ text: String) {
        let route = route
        Task { @MainActor in route(text) }
    }
    func interrupt() { base.interrupt() }
    /// The controller owns the session; a view going away does not end it.
    func close() {}
}
