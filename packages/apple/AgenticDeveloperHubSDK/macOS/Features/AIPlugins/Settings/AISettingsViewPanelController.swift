import AppKit
import Combine
import SwiftUI
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import AIPluginKit

/// The "AI Connections" settings panel — a topic/detail split (like "Theme") with
/// one sub-panel per configured provider, each a Connection card over a Test
/// Chat card. The sidebar lists the configurations
/// (titled "Connections" and themed by the framework); selecting one shows its
/// editor in the detail, whose title is the configuration's name. A footer under
/// the list carries add (`+`, opens the provider picker) / remove (`−`).
@MainActor
open class AIPanelViewController: ComposableSettings.SettingsPanelSplitViewController {

    public let pluginManager: AIPluginManager
    private let viewModel: LLMProvidersListViewModel
    /// The +/− bar under the list; "remove" is live while a configuration is selected.
    let footer = ComposableSettings.AddRemoveFooterView(
        accessibilityPrefix: "providers.add-remove", separatorAbove: true)
    private var selectionObserver: AnyCancellable?
    /// Plugin binaries that failed to load, surfaced as a trailing panel so a bad
    /// signature / ABI mismatch isn't silently invisible until a chat send fails.
    private var loadFailures: [PluginLoadFailure] = []

    public init(pluginManager: AIPluginManager) {
        self.pluginManager = pluginManager
        self.viewModel = LLMProvidersListViewModel(pluginManager: pluginManager)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "AI Connections",
            icon: NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)
        ))
        // The sidebar lists multiple connections, so title it in plural.
        sidebarTitle = "Connections"
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Connections",
                body: "Each row is one configured way of reaching a model — a plugin "
                    + "(Claude, OpenAI, Google, or any OpenAI-compatible endpoint) plus "
                    + "the account details it needs. Add one with +, remove the selected "
                    + "one with −. Other panels that use a model choose from this list, "
                    + "so a provider configured once here is available everywhere."
            ),
            .init(
                title: "Keys and Secrets",
                body: "An API key you enter is stored in your login Keychain, never in a "
                    + "settings file or a database. Removing a provider removes its key "
                    + "along with it."
            ),
            .init(
                title: "Test Chat",
                body: "The Test Chat card under a provider's connection talks to that "
                    + "provider directly, so you can confirm the key and the endpoint "
                    + "work — and pick a model with Choose Model… — before anything "
                    + "else depends on them. Choosing a model here saves it as the "
                    + "provider's model. For a longer conversation, New AI Chat… in "
                    + "the AI menu opens a chat window. A provider whose plugin failed "
                    + "to load says so instead, and can't be used until that is resolved."
            )
        ])
    }

    /// The provider editors are SwiftUI, so their controls cannot be read off
    /// the view tree; this names what the whole panel is about.
    open override var searchKeywords: [String] {
        ["llm", "provider", "api key", "model", "claude", "openai", "google", "endpoint"]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        footer.addButton.toolTip = "Add a provider"
        footer.removeButton.toolTip = "Remove the selected provider"
        footer.onAdd = { [weak self] in self?.viewModel.onRequestAddProvider?() }
        footer.onRemove = { [weak self] in self?.removeSelected() }
        listViewController.setFooterView(footer)

        // Load the plugin binaries so dlopen failures (bad signature, ABI mismatch)
        // become visible here instead of only surfacing as a generic error when a
        // chat/summary send later fails.
        loadFailures = pluginManager.loadAllPlugins().failures

        viewModel.onRequestAddProvider = { [weak self] in
            guard let self, let window = self.view.window else { return }
            ProviderPicker.present(over: window, rows: self.viewModel.pickerRows) { [weak self] available in
                guard let self else { return }
                self.viewModel.add(available)            // sets selectedId to the new config
                self.rebuildPanels(selecting: self.viewModel.selectedId)
            }
        }

        rebuildPanels(selecting: viewModel.selectedId ?? viewModel.configurations.first?.id)

        // Enable remove (−) only when a configuration is selected.
        selectionObserver = viewModel.$selectedId.sink { [weak self] id in
            self?.footer.isRemoveEnabled = id != nil
        }
    }

    /// Rebuilds the detail panels to match the configurations list and selects
    /// `selectID`. Called on load and after any structural change (add / remove).
    ///
    /// Existing panels are REUSED by configuration id — only genuinely new
    /// configurations get a fresh panel, so an add/remove doesn't discard the
    /// in-progress edits of configurations it never touched.
    private func rebuildPanels(selecting selectID: UUID?) {
        let configs = viewModel.configurations
        let existing = Dictionary(
            panels.compactMap { ($0 as? ProviderConfigPanelViewController).map { ($0.config.id, $0) } },
            uniquingKeysWith: { first, _ in first }
        )
        var rebuilt: [any ComposableSettingsPanel] = configs.map { config in
            existing[config.id] ?? ProviderConfigPanelViewController(
                config: config,
                viewModel: viewModel,
                pluginManager: pluginManager,
                onRenamed: { [weak self] in self?.refreshRows() }
            )
        }
        if !loadFailures.isEmpty {
            rebuilt.append(PluginLoadFailuresPanel(failures: loadFailures))
        }
        setPanels(rebuilt)
        if let index = configs.firstIndex(where: { $0.id == selectID }) {
            selectPanel(at: index)
        } else if !rebuilt.isEmpty {
            selectPanel(at: 0)
        }
    }

    // MARK: - Scripted / testable selection

    /// The names of the configured providers, in sidebar order (excludes the
    /// trailing plugin-load-failures panel, which isn't a provider configuration).
    public var configurationNames: [String] {
        panels.compactMap { ($0 as? ProviderConfigPanelViewController)?.descriptor.title }
    }

    /// Selects the provider configuration with the given name (its sidebar title),
    /// driving both the list highlight and the detail editor. Enables scripted /
    /// UI-test navigation of the inner Providers list, which — being a custom
    /// themed table — doesn't reliably respond to synthetic clicks. Returns false
    /// when no configuration has that name.
    @discardableResult
    public func selectConfiguration(named name: String) -> Bool {
        guard let index = panels.firstIndex(where: { $0.descriptor.title == name }) else { return false }
        selectPanel(at: index)
        return true
    }

    /// The selected configuration's panel, or `nil` when nothing is selected.
    private var selectedProviderPanel: ProviderConfigPanelViewController? {
        guard let id = viewModel.selectedId else { return nil }
        return panels.lazy
            .compactMap { $0 as? ProviderConfigPanelViewController }
            .first { $0.config.id == id }
    }

    /// The selected configuration's Test Chat view model, so automation can
    /// drive a chat whose text field doesn't take synthetic input. Returns nil
    /// when no configuration is selected.
    @discardableResult
    public func presentChat() -> AIChatViewModel? {
        selectedProviderPanel?.chatViewModel
    }

    /// Sends a message through the selected configuration's Test Chat. Returns
    /// false when no configuration is selected.
    @discardableResult
    public func sendTestMessage(_ text: String) -> Bool {
        guard let viewModel = presentChat() else { return false }
        viewModel.sendMessage(text)
        return true
    }

    /// The selected configuration's Test Chat transcript as newline-separated
    /// `role: text` lines. Empty when nothing is selected.
    public func testChatTranscript() -> String {
        guard let viewModel = presentChat() else { return "" }
        return viewModel.messages.map { "\($0.role.scriptingLabel): \($0.text)" }.joined(separator: "\n")
    }

    /// Re-reads the sidebar row titles from the existing panels after an in-place
    /// rename, without recreating them, then keeps the selected row highlighted.
    private func refreshRows() {
        listViewController.setPanels(panels)
        if let index = viewModel.configurations.firstIndex(where: { $0.id == viewModel.selectedId }) {
            listViewController.selectPanel(at: index)
        }
    }

    // MARK: - Footer

    private func removeSelected() {
        guard let id = viewModel.selectedId,
              let config = viewModel.configurations.first(where: { $0.id == id }) else {
            RefusalFeedback.announce()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Delete “\(config.name)”?"
        alert.informativeText = "This removes the configuration and its stored settings, including any API key."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true

        let confirmDelete: () -> Void = { [weak self] in
            guard let self else { return }
            // Land on the previous row (or the first) after the delete.
            let ids = self.viewModel.configurations.map(\.id)
            let previous = ids.firstIndex(of: id).flatMap { $0 > 0 ? ids[$0 - 1] : nil }
            self.viewModel.remove(id)
            self.rebuildPanels(selecting: previous ?? self.viewModel.configurations.first?.id)
        }

        if let window = view.window {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn { confirmDelete() }
            }
        } else if alert.runModal() == .alertFirstButtonReturn {
            confirmDelete()
        }
    }
}

/// One configuration's detail panel: its title (the config name) is the sidebar
/// row label + detail-pane title. Its body is two cards:
///
/// ```
/// Anthropic API
/// Anthropic · Claude · API Key
/// Connection
/// ┌──────────────────────────────┐
/// │ Name / key / endpoint fields │   ← LLMProviderEditorView (SwiftUI)
/// └──────────────────────────────┘
/// Test Chat
/// ┌──────────────────────────────┐
/// │ Provider: name               │   ← AIChatViewController, pinned to this
/// │ Model: …     [Choose Model…] │     configuration, filling the rest of
/// │ transcript / entry           │     the pane
/// └──────────────────────────────┘
/// ```
///
/// It hosts its own scrolling (`hostsOwnScroll`): the transcript scrolls inside
/// its card, and a panel wrapped in the framework's scroll view would grow
/// with the transcript instead of filling the pane.
@MainActor
private final class ProviderConfigPanelViewController: ComposableSettings.SettingsPanelViewController {

    let config: AIProviderConfiguration
    private let viewModel: LLMProvidersListViewModel
    private let onRenamed: () -> Void
    private var nameObserver: AnyCancellable?
    private let chat: AIChatViewController

    init(config: AIProviderConfiguration,
         viewModel: LLMProvidersListViewModel,
         pluginManager: AIPluginManager,
         onRenamed: @escaping () -> Void) {
        self.config = config
        self.viewModel = viewModel
        self.onRenamed = onRenamed
        self.chat = AIChatViewController(
            pluginManager: pluginManager, configuration: config, pinsConfiguration: true)
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: config.name,
            icon: NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)
        ))
        // Keep the sidebar row title + detail title in sync when this config is
        // renamed in the editor.
        nameObserver = viewModel.$configurations
            .compactMap { configs in configs.first(where: { $0.id == config.id })?.name }
            .removeDuplicates()
            .sink { [weak self] name in
                guard let self, self.descriptor.title != name else { return }
                // The Test Chat card observes the stored configurations itself; a
                // refresh from here runs in willSet and reads the old name.
                self.descriptor.title = name
                self.onRenamed()
            }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var searchKeywords: [String] {
        ["provider", "api key", "endpoint", "model", config.name]
    }

    override var hostsOwnScroll: Bool { true }

    /// The Test Chat transcript, for the panel's scripting verbs.
    var chatViewModel: AIChatViewModel? {
        loadViewIfNeeded()
        return chat.chatViewModel
    }

    override func loadView() {
        let layout = ComposableSettings.SettingsLayout.default
        let inset = layout[.panelInset]
        let root = NSView()

        let editor = Self.hostingView(
            for: LLMProviderEditorView(configuration: config, viewModel: viewModel).themedRoot())
        let caption = ComposableSettings.HeaderView(title: "Test Chat")
        let card = ThemedBox(fill: .card, stroke: .outline, cornerRadius: layout[.cardCornerRadius])
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer?.masksToBounds = true

        addChild(chat)
        let chatView = chat.view
        chatView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(chatView)

        for subview in [editor, caption, card] { root.addSubview(subview) }
        // The editor keeps its own height; the card takes whatever is left.
        editor.setContentHuggingPriority(.required, for: .vertical)
        editor.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: root.topAnchor),
            editor.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: root.trailingAnchor),

            caption.topAnchor.constraint(equalTo: editor.bottomAnchor, constant: layout[.groupSpacing]),
            caption.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: inset),
            caption.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -inset),

            card.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: layout[.captionSpacing]),
            card.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: inset),
            card.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -inset),
            card.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -inset),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 240),

            chatView.topAnchor.constraint(equalTo: card.topAnchor),
            chatView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            chatView.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        self.view = root
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        // Selecting this row shows this panel — record it as the active selection
        // (drives the footer's remove target).
        viewModel.selectedId = config.id
    }
}
