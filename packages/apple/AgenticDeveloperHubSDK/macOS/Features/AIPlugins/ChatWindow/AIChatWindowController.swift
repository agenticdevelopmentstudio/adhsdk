import AppKit
import AIPluginKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

/// One AI Chat window — ``AIChatViewController`` in an ordinary, resizable window
/// with an integrated title bar. "New AI Chat…" makes a new one every time, so
/// several conversations (with different providers or models) can sit side by
/// side; ``AIChatCoordinator`` owns the set.
///
/// The title follows the chat: "<model> (<provider>) Chat", or as much of that as
/// has been chosen, or "AI Chat". The toolbar's gear, at the trailing end, shows
/// or completely hides the provider/model configuration above the transcript.
///
/// Not registered as restorable — a chat window left open at quit should not
/// reopen itself with a dead transcript at the next launch.
@MainActor
public final class AIChatWindowController: SingleWindowController, NSToolbarDelegate {

    /// The window id for the chat numbered `index`. Each open chat takes the
    /// lowest free number, so frames persist per slot rather than piling up one
    /// saved frame per chat ever opened.
    public static func windowID(index: Int) -> String { "ai-chat-\(index)" }

    private static let gearItem = NSToolbarItem.Identifier("ai-chat.configuration")

    public let index: Int
    private let content: AIChatViewController
    private let gearButton = NSButton()

    /// Called once the window has closed, so the owner can let go of it.
    public var onClose: ((AIChatWindowController) -> Void)?

    public init(pluginManager: AIPluginManager,
                toolSource: (any ChatToolSource)? = nil,
                index: Int) {
        let content = AIChatViewController(pluginManager: pluginManager, toolSource: toolSource)
        self.content = content
        self.index = index
        super.init(windowID: Self.windowID(index: index), contentViewController: content)
        self.windowTitle = AIChatViewController.title(for: content.selection)
        // No `.fullSizeContentView`: there is no sidebar to run up under the
        // title bar, and the configuration rows would sit beneath the toolbar.
        // The transparent title bar over the themed window background is what
        // makes the bar read as part of the window.
        self.windowStyleMask = [.titled, .closable, .miniaturizable, .resizable]
        self.windowSpec = WindowSpec(
            defaultSize: content.initialContentSize,
            minSize: NSSize(width: 420, height: 420),
            defaultPosition: .center,
            behavior: [.persistsFrame]
        )
        content.onSelectionChange = { [weak self] in self?.updateTitle() }
    }

    /// The transcript being driven, so automation can send/read messages the chat's
    /// own text field won't take synthetically.
    public var chatViewModel: AIChatViewModel? { content.chatViewModel }

    /// Builds the chat's view (and so its session) without showing the window, so
    /// scripting can drive a chat that was never put on screen.
    public func loadContent() {
        content.loadViewIfNeeded()
    }

    /// The provider + model the window is currently pointed at.
    public var selection: AIChatViewController.Selection? { content.selection }

    /// Whether the provider/model configuration is showing — the gear's state.
    public var isConfigurationVisible: Bool {
        get { content.isConfigurationVisible }
        set {
            content.isConfigurationVisible = newValue
            gearButton.state = newValue ? .on : .off
        }
    }

    public override func close() {
        window?.performClose(nil)
    }

    // MARK: - Window

    public override func configureWindow(_ window: NSWindow) {
        // The same integrated title bar as the Settings window: a unified toolbar
        // with no separator, the title kept so the window says which chat it is.
        let toolbar = NSToolbar(identifier: "ai-chat.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.title = AIChatViewController.title(for: content.selection)
    }

    /// A new chat opens a step down and right of the one in front, rather than
    /// exactly on top of it, so it is visibly a second window.
    public override func placeWindowWithoutSavedFrame(_ window: NSWindow) {
        let front = NSApp.orderedWindows.first {
            $0 !== window && $0.isVisible
                && ($0.windowController as? AIChatWindowController) != nil
        }
        guard let front else { return }
        let topLeft = NSPoint(x: front.frame.minX + 24, y: front.frame.maxY - 24)
        window.setFrameTopLeftPoint(topLeft)
    }

    public override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)
        onClose?(self)
    }

    private func updateTitle() {
        let title = AIChatViewController.title(for: content.selection)
        windowTitle = title
        window?.title = title
    }

    // MARK: - Toolbar

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, Self.gearItem]
    }

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, Self.gearItem]
    }

    public func toolbar(_ toolbar: NSToolbar,
                        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard itemIdentifier == Self.gearItem else { return nil }
        gearButton.image = NSImage(systemSymbolName: "gearshape",
                                   accessibilityDescription: "Configuration")
        gearButton.bezelStyle = .toolbar
        gearButton.setButtonType(.pushOnPushOff)
        gearButton.state = content.isConfigurationVisible ? .on : .off
        gearButton.target = self
        gearButton.action = #selector(toggleConfiguration(_:))
        gearButton.toolTip = "Show or hide the provider and model"
        gearButton.setAccessibilityIdentifier("ai-chat.configuration-toggle")
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = gearButton
        item.label = "Configuration"
        item.isBordered = false
        return item
    }

    @objc private func toggleConfiguration(_ sender: NSButton) {
        content.isConfigurationVisible = sender.state == .on
    }
}
