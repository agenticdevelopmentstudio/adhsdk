import AppKit

import AgenticDeveloperHubSDKCore
import AIPluginKit

/// General: whether the partner runs, the model its Claude Code runs on, how its process and window
/// behave, and what its notifications do.
@MainActor
public final class PartnerGeneralSettingsViewController: ComposableSettings.SettingsPanelViewController {

    private let pluginManager: AIPluginManager?
    private let settings: SettingsStore
    /// Why the chosen model cannot run; self-hiding, so its card row closes up while the selection can.
    private let modelNote = ComposableSettings.ExplanationView(withText: "")
    private var providerObserver: UserSettingObserver<String>?
    private var configurationsObserver: UserSettingObserver<[AIProviderConfiguration]>?
    private var registrySource: LocalProviderRegistrySource?
    private weak var tryButton: NSButton?

    public init(pluginManager: AIPluginManager?, settings: SettingsStore = UserSettings.shared) {
        self.pluginManager = pluginManager
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "General", icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        ["partner", "coding partner", "claude", "session", "timeout", "idle", "always on top", "notifications pane",
         "model", "provider", "claude code", "llm", "attention", "needs you", "notification", "retention",
         "question", "blocked"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Coding Partner",
                  body: "The partner is one long-running Claude Code process that watches your sessions and "
                      + "raises items for you. Changes to the model, permission mode, allowed tools and "
                      + "timeouts apply the next time the partner starts."),
            .init(title: "Model",
                  body: "The partner runs the Claude Code CLI, so a chosen provider must use the Claude Code "
                      + "plugin. Default (Claude Code) passes no --model. The model is kept per provider "
                      + "configuration under the partner's own key, so it does not change the one used by "
                      + "session summaries."),
            .init(title: "Notifications",
                  body: "Items the partner raises appear in the Notifications pane. Done items stay for the "
                      + "retention period, then are removed. A kind that is checked also posts a macOS "
                      + "notification when an item of that kind is raised.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let settings = self.settings

        let run = ComposableSettings.GroupView(withTitle: "Partner")
        let enabled = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Run the coding partner",
            get: { settings.get(UserSettings.partnerEnabled) },
            set: { settings.set($0, for: UserSettings.partnerEnabled) },
            explanation: "Off, no partner process runs and nothing is watched."))
        _ = enabled.toggle.accessibilityID("settings.partner.enabled")
        run.addSettingSubview(enabled)
        addGroup(run)

        addModelGroup()

        let session = ComposableSettings.GroupView(withTitle: "Timing")
        session.addSettingSubview(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Idle settle (seconds)", minValue: 5, maxValue: 3_600,
                get: { settings.get(UserSettings.partnerIdleSettleSeconds) },
                set: { settings.set($0, for: UserSettings.partnerIdleSettleSeconds) },
                explanation: "How long a session must be quiet before the partner is told it went idle.")))
        session.addSettingSubview(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Turn timeout (minutes)", minValue: 1, maxValue: 240,
                get: { settings.get(UserSettings.partnerTurnTimeoutMinutes) },
                set: { settings.set($0, for: UserSettings.partnerTurnTimeoutMinutes) },
                explanation: "How long one partner turn may run before it is abandoned.")))
        addGroup(session)

        let window = ComposableSettings.GroupView(withTitle: "Window")
        window.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
            title: "Keep the partner window on top",
            get: { settings.get(UserSettings.partnerAlwaysOnTop) },
            set: { settings.set($0, for: UserSettings.partnerAlwaysOnTop) })))
        addGroup(window)

        addNotificationGroups()
    }

    /// Which provider and model the partner's Claude Code runs on.
    ///
    /// The whole group, Try… included, reads and writes the partner's provider
    /// and model through their `UserSetting`s, which are bound to
    /// `UserSettings.shared`, because that is the store the picker uses; going
    /// through the injected `settings` here would let Try… act on another
    /// provider than the one shown.
    private func addModelGroup() {
        let group = ComposableSettings.GroupView(withTitle: "Model")
        let source = LocalProviderRegistrySource(pluginManager: pluginManager)
        registrySource = source
        group.addSettingSubview(ProviderModelPickerView(
            source: source,
            selectedSetting: UserSettings.partnerProvider,
            leadingChoices: [.init(label: "Default (Claude Code)", value: "")],
            modelSetting: { id in id.map { UserSettings.partnerModel(config: $0) } }))
        let tryView = ComposableSettings.ButtonView(
            viewModel: ComposableSettings.ButtonViewModel(title: "Try…") { [weak self] in self?.tryProvider() },
            placement: .leading)
        tryView.button.toolTip = "Chat with this provider, then pick the model that answered best"
        _ = tryView.button.accessibilityID("settings.partner.model.try")
        tryButton = tryView.button
        group.addSettingSubview(tryView)
        _ = modelNote.accessibilityID("settings.partner.model.note")
        group.addSettingSubview(modelNote)
        addGroup(group)

        providerObserver = UserSettingObserver(UserSettings.partnerProvider) { [weak self] _ in
            self?.refreshModelNote()
        }
        configurationsObserver = UserSettingObserver(UserSettings.aiProviderConfigurations) { [weak self] _ in
            self?.refreshModelNote()
        }
        refreshModelNote()
    }

    /// The configuration the partner's provider selection names, with its template.
    private var selectedConfiguration:
        (config: AIProviderConfiguration, template: AIPluginDescriptor.ProviderTemplate)? {
        UUID(uuidString: UserSettings.partnerProvider.value).flatMap { registrySource?.resolved($0) }
    }

    /// Open a real conversation on the selected provider (``LLMChatPicker``) and
    /// keep the provider and model that answered well. The chat can be steered to
    /// another provider, so the model goes to the one settled on and the
    /// selection follows it.
    private func tryProvider() {
        guard let window = view.window, let pluginManager, let (config, template) = selectedConfiguration
        else { return }
        let stored = UserSettings.partnerModel(config: config.id).value
        LLMChatPicker.present(
            over: window, pluginManager: pluginManager, configuration: config,
            model: stored.isEmpty ? AIProviderConfigStore.selectedModel(config: config, template: template) : stored
        ) { selection in
            let chosen = selection.configuration
            UserSettings.partnerProvider.value = chosen.id.uuidString
            UserSettings.partnerModel(config: chosen.id).value = selection.model
        }
    }

    /// How long done items stay, and which kinds also post a system notification.
    private func addNotificationGroups() {
        let settings = self.settings
        let keep = ComposableSettings.GroupView(withTitle: "Notifications")
        keep.addSettingSubview(ComposableSettings.IntegerFieldView(
            viewModel: ComposableSettings.RangeViewModel<Int>(
                title: "Keep done items (days)", minValue: 1, maxValue: 365,
                get: { settings.get(UserSettings.partnerAttentionRetentionDays) },
                set: { settings.set($0, for: UserSettings.partnerAttentionRetentionDays) })))
        addGroup(keep)

        let notify = ComposableSettings.GroupView(withTitle: "System Notifications")
        for kind in AttentionKind.allCases {
            let view = ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
                title: "Notify for \(kind.rawValue)",
                get: { settings.get(UserSettings.partnerNotifyKinds).contains(kind.rawValue) },
                set: { isOn in
                    var kinds = settings.get(UserSettings.partnerNotifyKinds)
                    if isOn { kinds.insert(kind.rawValue) } else { kinds.remove(kind.rawValue) }
                    settings.set(kinds, for: UserSettings.partnerNotifyKinds)
                }))
            _ = view.toggle.accessibilityID("settings.partner.notify.\(kind.rawValue)")
            notify.addSettingSubview(view)
        }
        addGroup(notify)
    }

    /// The reason the chosen model cannot run, or nothing (hidden) while it resolves.
    var modelNoteText: String? {
        let result = PartnerModelChoice.resolve(
            // The picker's store, as in addModelGroup, so the note describes
            // the provider and model the picker shows.
            provider: UserSettings.partnerProvider.value,
            configurations: UserSettings.aiProviderConfigurations.value,
            model: { UserSettings.partnerModel(config: $0).value },
            legacyModel: UserSettings.partnerModel.value)
        if case .failure(let failure) = result { return failure.message }
        return nil
    }

    private func refreshModelNote() {
        let text = modelNoteText
        modelNote.text = text ?? ""
        modelNote.isHidden = text == nil
        // Chatting needs a configuration and a plugin host to build a backend.
        tryButton?.isEnabled = pluginManager != nil && selectedConfiguration != nil
    }
}
