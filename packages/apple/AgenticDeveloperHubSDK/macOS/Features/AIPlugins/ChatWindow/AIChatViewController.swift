import AppKit
import AIPluginKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

/// Chat with an AI: pick one of the configured providers, pick its model, and talk
/// to it.
///
/// ```
/// Provider: [popup]                     ┐
///    Model: label        [Choose Model…] │ the configuration view —
/// ─────────────────────────────────────  ┘ hidden by `isConfigurationVisible`
/// [chat transcript]
/// [chat entry]
/// [Cancel] [Choose]      ← only when presented as a modal picker
/// ```
///
/// Three presentations share this one controller:
/// - the AI Chat window (``AIChatWindowController``), one per "New AI Chat…";
/// - an app-modal picker (``LLMChatPicker``) that reports the provider + model the
///   user settled on (`showsChoiceButtons`);
/// - the settings panel's Test Chat, **pinned** to the configuration being edited
///   (`pinsConfiguration`): the provider is a label, not a popup, because that
///   chat exists to test that one connection.
///
/// Choosing a model **persists** it to that configuration (the
/// `AIProviderConfigStore` model setting), in every presentation. The chat is
/// pinned to the live configuration, so the very next message goes to the model
/// just chosen.
@MainActor
public final class AIChatViewController: NSViewController, Themeable {

    /// Called with the chosen provider + model, or `nil` on cancel. Only meaningful
    /// in picker mode; the presenter sets it.
    public var completion: ((Selection?) -> Void)?

    /// Called whenever the provider or the model shown changes — the window
    /// re-titles itself from ``title(for:)``.
    public var onSelectionChange: (() -> Void)?

    /// Shows or completely hides the configuration view (provider + model rows and
    /// the separator under them). Hidden, the transcript takes the whole view.
    public var isConfigurationVisible: Bool = true {
        didSet {
            guard isConfigurationVisible != oldValue, isViewLoaded else { return }
            applyConfigurationVisibility()
        }
    }

    /// Picker mode: show the Cancel / Choose bar under the chat. Declared at init
    /// rather than inferred from `completion` because `loadView` runs the moment a
    /// window is built around this controller — before a presenter could assign it.
    private let showsChoiceButtons: Bool
    /// Test-Chat mode: the configuration is fixed and shown as a label.
    private let pinsConfiguration: Bool
    private let pluginManager: AIPluginManager
    /// Handed to every session this controller builds; nil means a plain chat.
    private let toolSource: (any ChatToolSource)?
    private var configurations: [AIProviderConfiguration]
    private var selectedIndex: Int
    /// A model handed in by the presenter (`init(model:)` / `refresh(model:)`) that
    /// is deliberately NOT written to the store — it only points this view at a
    /// model. Cleared the moment the provider changes or a real choice is made.
    private var overrideModel: String = ""
    /// Rebuilt whenever the provider changes; nil when nothing is configured.
    private var chatSession: AIProviderChatSession?

    private let configView = NSView()
    private let providerLabel = NSTextField(labelWithString: "Provider:")
    private let modelLabel = NSTextField(labelWithString: "Model:")
    private let providerPopUp = NSPopUpButton()
    /// Stands in for the popup when the configuration is pinned.
    private let providerName = NSTextField(labelWithString: "")
    private let modelValue = NSTextField(labelWithString: "")
    private let chooseModelButton = NSButton()
    private let separator = ThemedSeparatorView(role: .border)
    private let chatContainer = NSView()
    private let emptyLabel = NSTextField(labelWithString: "No providers are configured.")
    private let cancelButton = NSButton()
    private let chooseButton = NSButton()

    /// The two places the transcript can start: under the configuration view, or
    /// at the top of the view when that is hidden. Exactly one is active.
    private var chatBelowConfiguration: NSLayoutConstraint?
    private var chatAtTop: NSLayoutConstraint?

    private var themeObserver: ThemePaletteObserver?
    /// Follows add/remove/rename edits in Settings, so an open chat never offers a
    /// connection that was deleted or misses one that was added.
    private var configurationsObserver: UserSettingObserver<[AIProviderConfiguration]>?
    /// Follows the selected connection's stored model, which another chat on the
    /// same connection, the settings Test Chat or the host app can change.
    private var modelObserver: UserSettingObserver<String>?
    /// Follows the selected connection's fields (Base URL, API key, …), which
    /// decide whether a model list can be loaded at all, so Choose Model wakes
    /// up the moment an endpoint is typed in AI Connections.
    private var fieldObservers: [UserSettingObserver<String>] = []
    /// Follows every loaded model list. The row resolves an alias (`sonnet`)
    /// against the cached list to name it, so a refresh from anywhere — this
    /// chat's own, a chooser that was then cancelled, another window — has to
    /// redraw it, or it goes on naming a model the alias no longer means.
    private var modelCacheObserver: UserSettingObserver<[String: ProviderModelList]>?
    /// The model the transcript last said it was talking to, so a change made
    /// anywhere is noted once.
    private var announcedModel = ""
    private var chatView: ChatView?

    /// The window's initial content size. Not `preferredContentSize`: setting that
    /// on a window's contentViewController pins min == max and defeats `.resizable`.
    public let initialContentSize = NSSize(width: 560, height: 620)

    /// - Parameters:
    ///   - configuration: the provider to open on. `nil` opens on the first
    ///     configured provider (or on nothing, when there are none).
    ///   - model: the model to open on. `nil` uses the provider's stored/default
    ///     model. A model is never written to the store just for being passed in —
    ///     only an explicit choice persists.
    ///   - toolSource: tools every session built here may call; nil for a plain
    ///     chat.
    ///   - showsChoiceButtons: picker mode — add the Cancel / Choose bar.
    ///   - pinsConfiguration: Test-Chat mode — `configuration` is fixed, and shown
    ///     as a label instead of a popup.
    public init(pluginManager: AIPluginManager,
                configuration: AIProviderConfiguration? = nil,
                model: String? = nil,
                toolSource: (any ChatToolSource)? = nil,
                showsChoiceButtons: Bool = false,
                pinsConfiguration: Bool = false) {
        self.pluginManager = pluginManager
        self.toolSource = toolSource
        self.showsChoiceButtons = showsChoiceButtons
        self.pinsConfiguration = pinsConfiguration && configuration != nil
        let configs = UserSettings.aiProviderConfigurations.value
        self.configurations = configs
        let wanted = configuration
            ?? PluginChatConfigProvider.defaultConfiguration(in: configs, manager: pluginManager)
        self.selectedIndex = wanted.flatMap { wanted in
            configs.firstIndex { $0.id == wanted.id }
        } ?? (configs.isEmpty ? -1 : 0)
        super.init(nibName: nil, bundle: nil)
        if let model, !model.isEmpty { self.overrideModel = model }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The provider + model currently shown, or `nil` when nothing is configured.
    public var selection: Selection? {
        guard let config = selectedConfiguration else { return nil }
        return Selection(configuration: config, model: currentModel)
    }

    /// The transcript being driven, so automation can send/read messages the chat's
    /// own text field won't take synthetically.
    public var chatViewModel: AIChatViewModel? { chatSession?.viewModel }

    /// The window title for a chat showing `selection`: "<model> (<provider>)
    /// Chat" with both chosen, just the one that is chosen otherwise, and "AI
    /// Chat" with neither.
    public static func title(for selection: Selection?) -> String {
        let provider = selection?.configuration.name ?? ""
        let model = selection?.model ?? ""
        switch (model.isEmpty, provider.isEmpty) {
        case (false, false): return "\(model) (\(provider)) Chat"
        case (false, true): return "\(model) Chat"
        case (true, false): return "\(provider) Chat"
        case (true, true): return "AI Chat"
        }
    }

    private var selectedConfiguration: AIProviderConfiguration? {
        guard selectedIndex >= 0, selectedIndex < configurations.count else { return nil }
        return configurations[selectedIndex]
    }

    /// The model the chat is pointed at: the presenter's override if there is one,
    /// else whatever the store says right now.
    ///
    /// Read live rather than mirrored in a stored property. The same store key is
    /// written from several places — the model chooser here, the same chooser in
    /// another chat window or the settings panel's Test Chat, and the host app's
    /// own feature settings — and the chat resolves the model afresh on every
    /// turn, so a cached copy went on labelling the view with a model that
    /// messages were no longer being sent to.
    private var currentModel: String {
        guard overrideModel.isEmpty else { return overrideModel }
        guard let config = selectedConfiguration, let template = selectedTemplate else { return "" }
        return AIProviderConfigStore.selectedModel(config: config, template: template)
    }

    private var selectedTemplate: AIPluginDescriptor.ProviderTemplate? {
        guard let config = selectedConfiguration else { return nil }
        return pluginManager.template(
            pluginIdentifier: config.pluginIdentifier, templateId: config.templateId)
    }

    // MARK: - View tree

    public override func loadView() {
        let root = NSView()
        root.wantsLayer = true

        configureHeader()
        configureChoiceButtons()

        emptyLabel.alignment = .center
        emptyLabel.lineBreakMode = .byWordWrapping
        emptyLabel.maximumNumberOfLines = 0
        emptyLabel.isHidden = true

        let header = pinsConfiguration ? providerName : providerPopUp
        for subview in [providerLabel, modelLabel, header, modelValue, chooseModelButton, separator] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            configView.addSubview(subview)
        }
        for subview in [configView, chatContainer, emptyLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(subview)
        }

        let below = chatContainer.topAnchor.constraint(equalTo: configView.bottomAnchor)
        let atTop = chatContainer.topAnchor.constraint(equalTo: root.topAnchor)
        chatBelowConfiguration = below
        chatAtTop = atTop

        var constraints: [NSLayoutConstraint] = [
            configView.topAnchor.constraint(equalTo: root.topAnchor),
            configView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            configView.trailingAnchor.constraint(equalTo: root.trailingAnchor),

            providerLabel.leadingAnchor.constraint(equalTo: configView.leadingAnchor, constant: 16),
            providerLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            providerLabel.widthAnchor.constraint(equalTo: modelLabel.widthAnchor),

            header.topAnchor.constraint(equalTo: configView.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: providerLabel.trailingAnchor, constant: 8),
            header.trailingAnchor.constraint(lessThanOrEqualTo: configView.trailingAnchor, constant: -16),

            modelLabel.leadingAnchor.constraint(equalTo: configView.leadingAnchor, constant: 16),
            modelLabel.centerYAnchor.constraint(equalTo: chooseModelButton.centerYAnchor),

            modelValue.leadingAnchor.constraint(equalTo: modelLabel.trailingAnchor, constant: 8),
            modelValue.centerYAnchor.constraint(equalTo: chooseModelButton.centerYAnchor),
            // The flexible space between the model name and the button: the name
            // may claim it, but never crowds the button off the trailing edge.
            modelValue.trailingAnchor.constraint(
                lessThanOrEqualTo: chooseModelButton.leadingAnchor, constant: -8),

            chooseModelButton.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            chooseModelButton.trailingAnchor.constraint(equalTo: configView.trailingAnchor, constant: -16),

            separator.topAnchor.constraint(equalTo: chooseModelButton.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: configView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: configView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: configView.bottomAnchor),

            chatContainer.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            chatContainer.trailingAnchor.constraint(equalTo: root.trailingAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: chatContainer.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: chatContainer.centerYAnchor),
            emptyLabel.widthAnchor.constraint(lessThanOrEqualTo: chatContainer.widthAnchor, constant: -48)
        ]

        if !showsChoiceButtons {
            constraints.append(chatContainer.bottomAnchor.constraint(equalTo: root.bottomAnchor))
        } else {
            for button in [cancelButton, chooseButton] {
                button.translatesAutoresizingMaskIntoConstraints = false
                root.addSubview(button)
            }
            constraints += [
                chatContainer.bottomAnchor.constraint(equalTo: chooseButton.topAnchor, constant: -12),
                chooseButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
                chooseButton.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -16),
                cancelButton.trailingAnchor.constraint(equalTo: chooseButton.leadingAnchor, constant: -10),
                cancelButton.centerYAnchor.constraint(equalTo: chooseButton.centerYAnchor),
                // Cancel is drawn by the theme rather than by a stock bezel (see
                // `applySecondaryActionTheme`), so its size is stated here — matching
                // the default button beside it — instead of coming from the bezel.
                cancelButton.heightAnchor.constraint(equalTo: chooseButton.heightAnchor),
                cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 72)
            ]
        }

        NSLayoutConstraint.activate(constraints)
        self.view = root
        applyConfigurationVisibility()
        themeObserver = ThemePaletteObserver(host: view) { [weak self] palette in self?.applyTheme(palette) }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        reloadProviders()
        configurationsObserver = UserSettingObserver(UserSettings.aiProviderConfigurations) { [weak self] _ in
            self?.refresh()
        }
        modelCacheObserver = UserSettingObserver(ProviderModelCache.setting) { [weak self] _ in
            self?.updateModelRow()
        }
    }

    /// Hidden means gone, not collapsed: the configuration view leaves the layout
    /// and the transcript moves up to the top edge.
    private func applyConfigurationVisibility() {
        configView.isHidden = !isConfigurationVisible
        chatBelowConfiguration?.isActive = isConfigurationVisible
        chatAtTop?.isActive = !isConfigurationVisible
    }

    // MARK: - Subview configuration

    private func configureHeader() {
        providerLabel.alignment = .right
        modelLabel.alignment = .right
        providerName.lineBreakMode = .byTruncatingTail
        modelValue.lineBreakMode = .byTruncatingMiddle
        // Let the value give up width before the label column or the button do.
        modelValue.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        modelValue.setContentHuggingPriority(.defaultLow, for: .horizontal)
        providerName.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        providerPopUp.target = self
        providerPopUp.action = #selector(providerChanged)
        providerPopUp.setAccessibilityIdentifier("ai-chat.provider")

        chooseModelButton.title = "Choose Model…"
        chooseModelButton.bezelStyle = .rounded
        chooseModelButton.setButtonType(.momentaryPushIn)
        chooseModelButton.target = self
        chooseModelButton.action = #selector(chooseModelAction)
        chooseModelButton.setAccessibilityIdentifier("ai-chat.choose-model")
    }

    private func configureChoiceButtons() {
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.setButtonType(.momentaryPushIn)
        cancelButton.keyEquivalent = "\u{1b}"          // Escape
        cancelButton.target = self
        cancelButton.action = #selector(cancelAction)

        chooseButton.title = "Choose"
        chooseButton.bezelStyle = .rounded
        chooseButton.setButtonType(.momentaryPushIn)
        // Deliberately NO Return key equivalent: Return in this window sends the
        // message the user is typing. A default button here would swallow it.
        chooseButton.target = self
        chooseButton.action = #selector(chooseAction)
    }

    // MARK: - Provider / model state

    /// Re-reads the configured providers and points the chat at `configuration`
    /// (or keeps the current one when it's `nil` and still exists), so a view that
    /// outlives add/remove/rename edits in Settings picks up the list again rather
    /// than trusting the snapshot taken at init.
    ///
    /// Rebuilds the transcript only when the selected provider actually changes —
    /// refreshing on the same provider keeps the conversation. A pinned view never
    /// changes provider: `configuration` is ignored.
    public func refresh(selecting configuration: AIProviderConfiguration? = nil, model: String? = nil) {
        let previous = selectedConfiguration?.id
        configurations = UserSettings.aiProviderConfigurations.value
        let wanted = pinsConfiguration ? previous : (configuration?.id ?? previous)
        let fallback = pinsConfiguration ? nil
            : PluginChatConfigProvider.defaultConfiguration(in: configurations, manager: pluginManager)?.id
        selectedIndex = (wanted ?? fallback).flatMap { id in configurations.firstIndex { $0.id == id } }
            ?? fallback.flatMap { id in configurations.firstIndex { $0.id == id } }
            ?? (configurations.isEmpty || pinsConfiguration ? -1 : 0)
        let sameProvider = previous != nil && selectedConfiguration?.id == previous
        // A different provider carries its own model, so drop any override and let
        // `currentModel` fall through to that provider's stored one; an explicit
        // `model` overrides either way.
        overrideModel = model ?? (sameProvider ? overrideModel : "")
        guard isViewLoaded else { return }
        if sameProvider, chatSession != nil {
            syncPopUpTitles()
            updateModelRow()
        } else {
            reloadProviders()
        }
    }

    /// Refreshes the provider's title(s) without disturbing the live chat — for a
    /// rename or a sibling provider added/removed while this view stayed open.
    private func syncPopUpTitles() {
        providerName.stringValue = selectedConfiguration?.name ?? ""
        providerPopUp.removeAllItems()
        providerPopUp.addItems(withTitles: configurations.map(\.name))
        providerPopUp.isEnabled = !configurations.isEmpty
        if selectedIndex >= 0 { providerPopUp.selectItem(at: selectedIndex) }
    }

    /// Repopulates the provider pop-up from the stored configurations and rebuilds
    /// the chat for whichever one is selected.
    private func reloadProviders() {
        providerName.stringValue = selectedConfiguration?.name ?? ""
        providerPopUp.removeAllItems()
        if configurations.isEmpty {
            providerPopUp.addItem(withTitle: "No providers configured")
            providerPopUp.isEnabled = false
        } else {
            providerPopUp.addItems(withTitles: configurations.map(\.name))
            providerPopUp.isEnabled = true
            providerPopUp.selectItem(at: max(0, selectedIndex))
        }
        rebuildChat()
    }

    @objc private func providerChanged() {
        let index = providerPopUp.indexOfSelectedItem
        guard index != selectedIndex, index >= 0, index < configurations.count else { return }
        selectedIndex = index
        // A provider carries its own model; keep nothing from the previous one.
        overrideModel = ""
        rebuildChat()
    }

    /// Swaps in a chat pinned to the selected configuration and refreshes the model
    /// row. Called on load and on every provider change — the session is pinned to
    /// one configuration, so a new provider means a new session and a fresh
    /// transcript.
    private func rebuildChat() {
        chatView?.removeFromSuperview()
        chatView = nil
        chatSession = nil
        modelObserver = nil
        fieldObservers = []

        guard let config = selectedConfiguration else {
            emptyLabel.isHidden = false
            modelValue.stringValue = "—"
            chooseModelButton.isEnabled = false
            chooseButton.isEnabled = false
            onSelectionChange?()
            return
        }

        emptyLabel.isHidden = true
        updateModelRow()
        if let template = selectedTemplate {
            // Load the provider's current list once per chat; the cache observer
            // redraws the row when it lands.
            let manager = modelManager(config: config, template: template)
            Task { await manager.refresh() }
        }

        let session = AIProviderChatSession(
            configuration: config, pluginManager: pluginManager, toolSource: toolSource)
        let view = ChatView(viewModel: session.viewModel)
        view.translatesAutoresizingMaskIntoConstraints = false
        chatContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: chatContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: chatContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: chatContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: chatContainer.bottomAnchor)
        ])
        chatSession = session
        chatView = view
        announcedModel = currentModel
        if let template = selectedTemplate {
            modelObserver = UserSettingObserver(
                AIProviderConfigStore.modelSetting(config: config.id, template: template)
            ) { [weak self] _ in
                self?.updateModelRow()
                self?.noteModelChange()
            }
            let fields = pluginManager.fields(pluginIdentifier: config.pluginIdentifier, template: template)
            fieldObservers = fields.map { field in
                let setting = AIProviderConfigStore.fieldSetting(config: config.id, field: field)
                return UserSettingObserver(setting) { [weak self] _ in self?.updateModelRow() }
            }
        }
    }

    /// Posts "Model changed to …" into the transcript when the model the chat
    /// talks to is no longer the one it last announced.
    private func noteModelChange() {
        let model = currentModel
        guard !model.isEmpty, model != announcedModel else { return }
        announcedModel = model
        chatSession?.viewModel.noteModelChanged(to: model)
    }

    private func updateModelRow() {
        let template = selectedTemplate
        // Show the Model row's Choose button whenever the provider can offer a model:
        // a provider with a live list (Ollama, Anthropic, …) always can, even when its
        // static list is empty; others when they ship a list or already have a model
        // chosen.
        var offersModels = false
        var modelName = currentModel
        if let config = selectedConfiguration, let template {
            let manager = modelManager(config: config, template: template)
            offersModels = manager.hasLiveSource
            modelName = manager.displayName(for: manager.resolve(currentModel))
        }
        chooseModelButton.isEnabled = template != nil
            && (offersModels || !(template?.models.isEmpty ?? true) || !currentModel.isEmpty)
        modelValue.stringValue = currentModel.isEmpty ? "None chosen" : modelName
        chooseButton.isEnabled = selectedConfiguration != nil
        applyModelRowTheme(view.resolvedThemeScope.palette)
        onSelectionChange?()
    }

    /// The model manager for the connection as it is configured right now.
    private func modelManager(config: AIProviderConfiguration,
                              template: AIPluginDescriptor.ProviderTemplate) -> any ProviderModelManager {
        let values = connectionValues(config: config, template: template)
        return ProviderModels.manager(
            pluginIdentifier: config.pluginIdentifier, template: template,
            baseURL: values["baseURL"], apiKey: values["apiKey"])
    }

    /// The connection's stored settings (`baseURL`, `apiKey`, …). An
    /// OpenAI-compatible connection has no model list without its endpoint, so
    /// the model row and the chooser both need these, not the template's defaults.
    private func connectionValues(config: AIProviderConfiguration,
                                  template: AIPluginDescriptor.ProviderTemplate) -> [String: String] {
        let fields = pluginManager.fields(pluginIdentifier: config.pluginIdentifier, template: template)
        return AIProviderConfigStore.configValues(for: config, template: template, fields: fields)
    }

    // MARK: - Actions

    @objc private func chooseModelAction() {
        guard let window = view.window,
              let config = selectedConfiguration,
              let template = selectedTemplate else { return }
        let values = connectionValues(config: config, template: template)
        let context = ModelChooserContext(
            pluginIdentifier: config.pluginIdentifier, template: template,
            baseURL: values["baseURL"] ?? "", apiKey: values["apiKey"],
            currentModel: currentModel.isEmpty ? template.resolvedDefaultModel : currentModel)
        ModelChooser.present(over: window, context: context) { [weak self] model in
            guard let self else { return }
            // The chooser runs its own modal session, and the view it sits over can
            // be pointed somewhere else while it is up — a scripted `send test
            // message` on another provider, or a `refresh` from Settings. Persisting
            // then would write this model against the provider that was showing when
            // the chooser opened, while the label and the transcript describe the one
            // showing now.
            guard self.selectedConfiguration?.id == config.id else { return }
            self.selectModel(model, template: template, config: config)
        }
    }

    /// Commits a model choice: persist it against the configuration, refresh the
    /// label, and — if a conversation is under way — post a "Model changed to …"
    /// notice into the transcript.
    private func selectModel(_ model: String,
                             template: AIPluginDescriptor.ProviderTemplate,
                             config: AIProviderConfiguration) {
        AIProviderConfigStore.modelSetting(config: config.id, template: template).value = model
        // The store now holds the answer, so the presenter's override has to go —
        // leaving it would make the view ignore the choice just made.
        overrideModel = ""
        updateModelRow()
        noteModelChange()
    }

    @objc private func chooseAction() {
        guard let done = completion, let selection else { return }
        completion = nil
        done(selection)
    }

    @objc private func cancelAction() {
        guard let done = completion else { return }
        completion = nil
        done(nil)
    }

    // MARK: - Theme

    public func applyTheme(_ palette: SemanticPalette) {
        // Pinned, the view sits inside a settings card that paints its own fill.
        view.layer?.backgroundColor = pinsConfiguration
            ? NSColor.clear.cgColor : palette.windowBackgroundColor.cgColor
        providerLabel.textColor = palette.secondaryTextColor
        modelLabel.textColor = palette.secondaryTextColor
        providerName.textColor = palette.primaryTextColor
        emptyLabel.textColor = palette.secondaryTextColor
        // The same explicit Cancel styling the pickers use, so the dialogs agree —
        // AppKit's stock bezel does not (see `applySecondaryActionTheme`).
        cancelButton.applySecondaryActionTheme(palette)
        applyModelRowTheme(palette)
    }

    /// The model name greys out when there isn't one, so "None chosen" reads as a
    /// placeholder rather than as a model called that.
    private func applyModelRowTheme(_ palette: SemanticPalette) {
        modelValue.textColor = currentModel.isEmpty ? palette.secondaryTextColor : palette.primaryTextColor
    }
}

extension AIChatViewController {

    /// A provider + one of its models: what the modal picker reports back, and
    /// what a chat window titles itself from.
    public struct Selection: Sendable, Equatable {
        public let configuration: AIProviderConfiguration
        public let model: String

        public init(configuration: AIProviderConfiguration, model: String) {
            self.configuration = configuration
            self.model = model
        }
    }
}

// MARK: - Window delegate (picker presentation only)

/// Only ``LLMChatPicker`` attaches this — a chat window's delegate is its
/// `SingleWindowController`, which does its own frame persistence.
extension AIChatViewController: NSWindowDelegate {

    /// Frame-persistence key for the modal picker window, so its size + location go
    /// through the app's `WindowManager` like every other window.
    public static let pickerWindowID = "llm-chat-picker"

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard completion != nil else { return true }
        cancelAction()   // routes through completion → dismiss; don't let AppKit also close
        return false
    }

    public func windowDidMove(_ notification: Notification) { persistFrame(notification) }
    public func windowDidResize(_ notification: Notification) { persistFrame(notification) }

    private func persistFrame(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        WindowManager.shared.frames.saveFrame(for: window, id: Self.pickerWindowID)
    }
}
