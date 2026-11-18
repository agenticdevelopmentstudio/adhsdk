#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation

extension DaemonDatabase {

    /// The synced provider-registry values, read live from this database's settings table.
    public var aiProviderSettings: ProviderSettingsReader {
        { [self] key in ((try? setting(for: key)) ?? nil) }
    }

    /// The reader a feature's completions resolve providers through.
    public func aiProviderSettings(for feature: AIFeature) -> ProviderSettingsReader {
        switch feature {
        case .oversight: oversightAIProviderSettings
        case .summarize: summaryAIProviderSettings(for: .sessions)
        case .summarizeConversations: summaryAIProviderSettings(for: .conversations)
        case .summarizeProjects: summaryAIProviderSettings(for: .projects)
        }
    }

    /// The provider-registry reader for **summary** completions: the plain registry,
    /// except that `ai_summary_model` (when set) overrides the selected
    /// configuration's model, and only that configuration's.
    public var summaryAIProviderSettings: ProviderSettingsReader { summaryAIProviderSettings(for: .sessions) }

    /// The reader for one feature's summaries. Sessions asks the providers'
    /// own selection. Every other feature has a selection of its own
    /// (``SummaryFeature/selectedConfigKey``): never written, it inherits the
    /// providers' selection; "" asks no configuration, which is the Claude CLI;
    /// a configuration id asks that one. Each feature's model key overrides
    /// the model of the configuration it resolved to, and no other.
    public func summaryAIProviderSettings(for feature: SummaryFeature) -> ProviderSettingsReader {
        let base = aiProviderSettings
        let globalKey = AIProviderConfigKeys.selectedConfigIdKey
        let ownKey: String? = feature == .sessions ? nil : feature.selectedConfigKey
        let modelKey = feature.key(SummarySettingsKeys.model)
        return { key in
            let effective: String = {
                if let ownKey, let own = base(ownKey) { return own }
                return base(globalKey) ?? ""
            }()
            if key == globalKey { return effective }
            if let uuid = UUID(uuidString: effective),
               key == AIProviderConfigKeys.modelKey(config: uuid),
               let override = base(modelKey), !override.isEmpty {
                return override
            }
            return base(key)
        }
    }

    /// The provider-registry reader for **oversight** completions: identical to
    /// `aiProviderSettings` except that the summaries selection and its model can be
    /// overridden by the oversight keys — so the toolkit's resolution path needs no
    /// oversight awareness at all.
    ///
    /// - `oversight_selected_config_id` unset/"" → inherit the summaries selection
    ///   (`ai_selected_config_id`), today's behavior.
    /// - the `claude-cli` sentinel → report *no* selection, forcing the zero-config
    ///   CLI path.
    /// - a configuration UUID → report that configuration as selected.
    /// - `oversight_model` (when set) overrides `modelKey(config:)` — scoped to the
    ///   oversight-resolved configuration only, so it can never bleed into another
    ///   configuration's stored model.
    public var oversightAIProviderSettings: ProviderSettingsReader {
        let base = aiProviderSettings
        return { key in
            let choice = base(Oversight.selectedConfigKey) ?? ""
            if key == AIProviderConfigKeys.selectedConfigIdKey {
                if choice.isEmpty { return base(key) }
                if choice == Oversight.claudeCLISentinel { return "" }
                return choice
            }
            // The configuration oversight resolves to (after inherit/sentinel).
            let effective: String = {
                if choice.isEmpty { return base(AIProviderConfigKeys.selectedConfigIdKey) ?? "" }
                if choice == Oversight.claudeCLISentinel { return "" }
                return choice
            }()
            if let uuid = UUID(uuidString: effective),
               key == AIProviderConfigKeys.modelKey(config: uuid),
               let override = base(Oversight.modelKey), !override.isEmpty {
                return override
            }
            return base(key)
        }
    }
}
#endif

#if canImport(AgenticDeveloperHubSDKCore)
extension AIFeature {
    /// The completion log's name for `feature`'s summaries.
    public static func summary(for feature: SummaryFeature) -> AIFeature {
        switch feature {
        case .sessions: .summarize
        case .conversations: .summarizeConversations
        case .projects: .summarizeProjects
        }
    }
}
#endif
