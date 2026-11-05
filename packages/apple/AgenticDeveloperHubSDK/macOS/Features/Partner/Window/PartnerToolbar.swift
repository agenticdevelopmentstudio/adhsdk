import AppKit
import Combine
import AgenticDeveloperHubSDKCore
import os

extension PartnerController.State {
    /// How the window names the state: the partner's card and the shelf's partner row.
    public var displayText: String {
        switch self {
        case .stopped: return "Stopped"
        case .starting: return "Starting…"
        case .idle: return "Idle"
        case .thinking: return "Thinking…"
        case .failed(let reason): return "Failed: \(reason)"
        }
    }

    var isRunning: Bool {
        switch self {
        case .stopped, .failed: return false
        case .starting, .idle, .thinking: return true
        }
    }
}

/// What the owner can tell the partner to do: start or stop it, restart it, start a new conversation.
///
/// One object behind both places they are offered, the toolbar's Start/Stop button and the Partner pane's
/// gear menu, so the two never disagree about what an action does or when it is available.
@MainActor
final class PartnerCommands: NSObject {

    private let controller: PartnerController
    /// The window a confirmation sheet attaches to; without one the alert runs as a modal.
    var window: () -> NSWindow? = { nil }

    init(controller: PartnerController) {
        self.controller = controller
        super.init()
    }

    /// The title and symbol for Start/Stop in `state`.
    static func startStop(for state: PartnerController.State) -> (title: String, symbol: String) {
        state.isRunning ? ("Stop", "stop.fill") : ("Start", "play.fill")
    }

    /// Whether Start/Stop does anything now, and the tooltip saying why when it does not. Start does nothing
    /// while Settings' switch is off, so it is disabled and says so instead of failing quietly.
    func startStopAvailability(for state: PartnerController.State) -> (enabled: Bool, toolTip: String) {
        let title = Self.startStop(for: state).title
        if state.isRunning || controller.settings.get(UserSettings.partnerEnabled) {
            return (state != .starting, title == "Stop" ? "Stop the partner" : "Start the partner")
        }
        return (false, "Turn on the Coding Partner in Settings to start it")
    }

    /// The Partner pane's gear-menu items, made fresh each time the menu opens. The menu does not
    /// auto-enable, so each item carries its own state.
    func menuItems() -> [NSMenuItem] {
        let state = controller.state
        let startStop = NSMenuItem(title: Self.startStop(for: state).title,
                                   action: #selector(startOrStop), keyEquivalent: "")
        startStop.isEnabled = startStopAvailability(for: state).enabled
        let restart = NSMenuItem(title: "Restart", action: #selector(restart), keyEquivalent: "")
        restart.toolTip = "Restart the partner, applying changed guidelines"
        restart.isEnabled = state.isRunning && state != .starting
        let newConversation = NSMenuItem(title: "New Conversation…", action: #selector(newConversation),
                                         keyEquivalent: "")
        newConversation.isEnabled = state.isRunning && state != .starting
        let items = [startStop, restart, newConversation]
        for item in items { item.target = self }
        return items
    }

    @objc func startOrStop() {
        let controller = controller
        Task { @MainActor in
            if controller.state.isRunning { await controller.stop() } else { await controller.start() }
        }
    }

    @objc func restart() {
        let controller = controller
        Task { @MainActor in await controller.restart(guidelinesChanged: true) }
    }

    /// A new conversation discards the partner's current one, so it asks first, as a sheet.
    @objc func newConversation() {
        let alert = NSAlert()
        alert.messageText = "Start a new conversation?"
        alert.informativeText = "The partner forgets this conversation."
        alert.addButton(withTitle: "New Conversation")
        alert.addButton(withTitle: "Cancel")
        let controller = controller
        let confirm: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .alertFirstButtonReturn else { return }
            Task { @MainActor in
                do { try await controller.startNewSession() } catch {
                    PartnerToolbar.logger.error("Starting a new session failed: \(error.localizedDescription)")
                    NSSound.beep()
                }
            }
        }
        if let window = window() {
            alert.beginSheetModal(for: window, completionHandler: confirm)
        } else {
            confirm(alert.runModal())
        }
    }
}

/// The Coding Partner window's toolbar: a labelled Start/Stop button. Notifications is a fixed tab, so there is
/// no inspector to toggle. Everything else the partner can be told to do is in the Partner pane's gear
/// menu, where a Projects window pane keeps its own actions; its state and queue are on its tab card.
///
/// Held by the window controller for the window's life: a toolbar keeps its delegate weakly.
@MainActor
public final class PartnerToolbar: NSObject, NSToolbarDelegate {

    enum ItemID {
        static let startStop = NSToolbarItem.Identifier("partner.toolbar.startStop")
    }

    private let controller: PartnerController
    private let commands: PartnerCommands
    /// Internal for tests.
    let startStopButton = NSButton()
    private var subscriptions: Set<AnyCancellable> = []

    init(controller: PartnerController, commands: PartnerCommands) {
        self.controller = controller
        self.commands = commands
        super.init()
        startStopButton.bezelStyle = .toolbar
        startStopButton.imagePosition = .imageLeading
        startStopButton.target = commands
        startStopButton.action = #selector(PartnerCommands.startOrStop)
        startStopButton.setAccessibilityIdentifier("partner.toolbar.startStop")

        controller.$state
            .sink { [weak self] state in MainActor.assumeIsolated { self?.refresh(state: state) } }
            .store(in: &subscriptions)
        controller.settings.changes
            .receive(on: DispatchQueue.main)
            .filter { $0 == UserSettings.partnerEnabled.name }
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.refresh(state: self.controller.state)
                }
            }
            .store(in: &subscriptions)
    }

    public func install(in window: NSWindow) {
        let toolbar = NSToolbar(identifier: "partner.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .unified
    }

    /// `state` is passed in: `$state` publishes before the property changes.
    private func refresh(state: PartnerController.State) {
        let (title, symbol) = PartnerCommands.startStop(for: state)
        startStopButton.title = title
        startStopButton.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        let availability = commands.startStopAvailability(for: state)
        startStopButton.isEnabled = availability.enabled
        startStopButton.toolTip = availability.toolTip
        startStopButton.sizeToFit()
    }

    // MARK: - NSToolbarDelegate

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, ItemID.startStop]
    }

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard itemIdentifier == ItemID.startStop else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = "Start/Stop"
        item.view = startStopButton
        return item
    }
}

extension PartnerToolbar: Loggable {
    public static nonisolated let logger = makeLogger()
}
