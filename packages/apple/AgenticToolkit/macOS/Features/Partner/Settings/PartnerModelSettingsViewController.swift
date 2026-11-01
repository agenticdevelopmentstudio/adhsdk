import AppKit

import AgenticToolkitCore
import AIPluginKit

/// Model: which provider and model the partner's Claude Code runs on.
@MainActor
public final class PartnerModelSettingsViewController: ComposableSettings.SettingsPanelViewController {

    private let pluginManager: AIPluginManager?
    private let settings: SettingsStore
    /// Self-hiding, so its card row closes up while the selection can run.
    private let note = ComposableSettings.ExplanationView(withText: "")
    private var providerObserver: UserSettingObserver<String>?
    private var configurationsObserver: UserSettingObserver<[AIProviderConfiguration]>?

    public init(pluginManager: AIPluginManager?, settings: SettingsStore = UserSettings.shared) {
        self.pluginManager = pluginManager
        self.settings = settings
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Model", icon: NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] { ["model", "provider", "claude code", "llm"] }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(title: "Model",
                  body: "The partner runs the Claude Code CLI, so a chosen provider must use the Claude Code "
                      + "plugin. Default (Claude Code) passes no --model. The model is kept per provider "
                      + "configuration under the partner's own key, so it does not change the one used by "
                      + "session summaries. A change applies the next time the partner starts.")
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Claude Code")
        group.addSettingSubview(LLMPickerView(
            pluginManager: pluginManager,
            selectedSetting: UserSettings.partnerProvider,
            leadingChoices: [.init(label: "Default (Claude Code)", value: "")],
            modelSetting: { id, _ in UserSettings.partnerModel(config: id) }))
        _ = note.accessibilityID("settings.partner.model.note")
        group.addSettingSubview(note)
        addGroup(group)

        providerObserver = UserSettingObserver(UserSettings.partnerProvider) { [weak self] _ in self?.refreshNote() }
        configurationsObserver = UserSettingObserver(UserSettings.aiProviderConfigurations) { [weak self] _ in
            self?.refreshNote()
        }
        refreshNote()
    }

    /// The reason the selection cannot run, or nothing (hidden) while it resolves.
    var noteText: String? {
        let result = PartnerModelChoice.resolve(
            provider: settings.get(UserSettings.partnerProvider),
            configurations: settings.get(UserSettings.aiProviderConfigurations),
            model: { [settings] in settings.get(UserSettings.partnerModel(config: $0)) },
            legacyModel: settings.get(UserSettings.partnerModel))
        if case .failure(let failure) = result { return failure.message }
        return nil
    }

    private func refreshNote() {
        let text = noteText
        note.text = text ?? ""
        note.isHidden = text == nil
    }
}
