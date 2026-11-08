import AppKit
import OSLog
import AIPluginKit
import AgenticDeveloperHubSDKCore

/// Owns the AI Chat windows. "New AI Chat…" opens a new ``AIChatWindowController``
/// every time — each its own conversation, with its own provider and model chosen
/// in the window. Lazy: nothing is built until a chat is asked for.
///
/// The chat is the toolkit's, end to end: the coordinator needs only the plugin
/// manager the providers live in and, optionally, the host's tools.
@MainActor
public final class AIChatCoordinator: AppFeature {

    private let pluginManager: AIPluginManager
    private let toolSource: (any ChatToolSource)?
    /// Every chat window still open, oldest first.
    public private(set) var windows: [AIChatWindowController] = []

    /// The ids this feature's actions answer to. One command, two menu items:
    /// the AI menu entry and the status-item entry are the same action, and the
    /// registry is what lets them say so instead of each holding its own copy
    /// of the closure (`dry`).
    public enum CommandID {
        public static let newChat = "aichat.action.newChat"
    }

    /// - Parameters:
    ///   - toolSource: tools every chat may call (the host's browser tools, say);
    ///     nil for plain chats.
    ///   - commandRegistry: See `ProjectsCoordinator.init` — required, so a
    ///     dropped registry is a compile error rather than a palette that
    ///     silently lost this feature.
    public init(
        pluginManager: AIPluginManager,
        toolSource: (any ChatToolSource)? = nil,
        commandRegistry registry: CommandRegistry
    ) {
        self.pluginManager = pluginManager
        self.toolSource = toolSource
        super.init()

        registry.register(AppCommand(
            id: CommandID.newChat,
            title: "New AI Chat…",
            category: "AI Chat",
            run: { [weak self] in self?.newChat() }
        ))

        self.menuContributions = [
            MenuContribution(
                slot: .ai,
                title: "New AI Chat…",
                commandID: CommandID.newChat,
                registry: registry,
                order: 30,
                key: "3"
            ),
            MenuContribution(
                slot: .statusItem(section: 1),
                title: "New AI Chat…",
                commandID: CommandID.newChat,
                registry: registry,
                order: 20
            )
        ]

        self.scriptingKeys.insert("scriptingAIChatVisible")
        self.scriptingKeys.insert("scriptingChatViewModel")
    }

    // MARK: - Public API

    /// Opens a new chat window, in front of any already open, and returns it.
    @discardableResult
    public func newChat() -> AIChatWindowController {
        let controller = makeWindow()
        controller.showWindow()
        return controller
    }

    /// Shows the chat in front (or the newest one), opening a new chat when none
    /// is open.
    public func showWindow() {
        if let existing = windowController {
            existing.showWindow()
        } else {
            newChat()
        }
    }

    /// The chat window scripting and the app's "open chat" hooks act on: the key
    /// one if a chat is key, else the newest open one.
    public var windowController: AIChatWindowController? {
        windows.first { $0.window?.isKeyWindow == true } ?? windows.last
    }

    /// The transcript of ``windowController``.
    public var viewModel: AIChatViewModel? { windowController?.chatViewModel }

    /// Idempotent — makes sure there is a chat (built, not shown) so scripting can
    /// read `viewModel` before any window has been opened.
    public func ensureWindow() {
        guard windows.isEmpty else { return }
        _ = makeWindow()
    }

    private func makeWindow() -> AIChatWindowController {
        let used = Set(windows.map(\.index))
        let index = (1...).first { !used.contains($0) } ?? windows.count + 1
        let controller = AIChatWindowController(
            pluginManager: pluginManager, toolSource: toolSource, index: index)
        controller.onClose = { [weak self] closed in
            self?.windows.removeAll { $0 === closed }
        }
        windows.append(controller)
        return controller
    }

    public override func value(forScriptingKey key: String) -> Any? {
        switch key {
        case "scriptingAIChatVisible":
            return windows.contains { $0.isVisible }
        case "scriptingChatViewModel":
            return viewModel
        default:
            return nil
        }
    }

    public override func setValue(_ value: Any?, forScriptingKey key: String) {
        switch key {
        case "scriptingAIChatVisible":
            if (value as? Bool) == true { showWindow() }
        default:
            break
        }
    }
}

extension AIChatCoordinator: Loggable {
    public static nonisolated let logger = makeLogger()
}
