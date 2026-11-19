import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS
import AIPluginKit

/// "AI Oversight" settings: whether the daemon watches live sessions, whether it
/// asks a model for judgment, and which provider and model it asks.
///
/// A host that lists several panels per feature builds two: ``Part/general``
/// (the watch switch) and ``Part/aiConfig`` (AI judgment, provider, model). A host
/// with one row per feature builds ``Part/all``.
@MainActor
public final class AIOversightSettingsPanel: ComposableSettings.SettingsPanelViewController {

    /// Which of the oversight settings this panel shows.
    public enum Part: Sendable {
        case all, general, aiConfig

        var title: String {
            switch self {
            case .all: "AI Oversight"
            case .general: "General"
            case .aiConfig: "AI Config"
            }
        }

        var symbolName: String {
            switch self {
            case .all: "eye"
            case .general: "gearshape"
            case .aiConfig: "cpu"
            }
        }
    }

    private let service: any StenographerDaemonService
    private let part: Part

    /// Retained: the picker owns the setting observers that keep the provider list
    /// live. (Pushing to the daemon is owned centrally by
    /// `StenographerOversightPrefsPush`, not by this panel.)
    private var picker: ProviderModelPickerView?
    /// Resolves the daemon's provider templates, for the model list and default
    /// name; nil (Stenographer) shows the stored model only.
    private let pluginManager: AIPluginManager?

    public init(service: any StenographerDaemonService, part: Part = .all,
                pluginManager: AIPluginManager? = nil) {
        self.service = service
        self.pluginManager = pluginManager
        self.part = part
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: part.title,
            icon: NSImage(systemSymbolName: part.symbolName, accessibilityDescription: nil)
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override var searchKeywords: [String] {
        switch part {
        case .all: ["oversight", "watch", "sessions", "judgment", "provider", "model"]
        case .general: ["oversight", "watch", "sessions", "findings"]
        case .aiConfig: ["oversight", "judgment", "provider", "model", "ai"]
        }
    }

    private static let watchHelp = ComposableSettings.PanelHelp.Topic(
        title: "Watching Live Sessions",
        body: "When enabled, the always-on daemon periodically watches your live "
            + "sessions and records findings when one needs attention — for now, "
            + "when a session's context window is filling up and should be "
            + "compacted at a clean breakpoint. Findings and the scripts that raise "
            + "them appear in the AI Oversight window (Window menu)."
    )

    private static let configHelp = ComposableSettings.PanelHelp.Topic(
        title: "AI Judgment",
        body: "AI judgment asks the selected provider whether now is a good moment "
            + "to act on a finding; off, the deterministic rules run alone. "
            + "Oversight has its own provider and model, separate from every "
            + "feature's AI Summaries: the provider is one of the configurations "
            + "in System › AI Providers or the Claude CLI, and the model, when set, "
            + "replaces that configuration's model for oversight only."
    )

    public override var helpContent: ComposableSettings.PanelHelp? {
        switch part {
        case .all: ComposableSettings.PanelHelp(topics: [Self.watchHelp, Self.configHelp])
        case .general: ComposableSettings.PanelHelp(topics: [Self.watchHelp])
        case .aiConfig: ComposableSettings.PanelHelp(topics: [Self.configHelp])
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        if part != .aiConfig { addGroup(watchGroup()) }
        if part != .general { addGroup(configGroup()) }
    }

    private func watchGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "AI Oversight")
        group.addSettingSubview(ComposableSettings.CheckboxView(
            with: ComposableSettings.ViewModel<Bool>(
                title: AIOversightProviderControls.enableToggleTitle,
                setting: UserSettings.stenographerAIOversightEnabled
            )
        ))
        return group
    }

    private func configGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "AI Judgment")

        group.addSettingSubview(ComposableSettings.CheckboxView(
            with: ComposableSettings.ViewModel<Bool>(
                title: AIOversightProviderControls.llmToggleTitle,
                setting: UserSettings.stenographerAIOversightLLMEnabled
            )
        ))

        let picker = AIOversightProviderControls.makePicker(service: service, pluginManager: pluginManager)
        self.picker = picker
        group.addSettingSubview(picker)

        return group
    }
}
