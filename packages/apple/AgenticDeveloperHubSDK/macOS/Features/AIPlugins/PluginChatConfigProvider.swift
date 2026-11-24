import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKCore

/// Default `ChatConfigProvider`: the configuration selected in Settings
/// (`UserSettings.selectedAIProviderConfigurationId`), resolved to its plugin,
/// model and values. When nothing is selected, or the selection no longer
/// resolves, the first configuration that does resolve stands in: the seeded
/// default is deliberately left unselected, and a chat that answers "no
/// provider is configured" over a working configuration is a dead chat.
@MainActor
public final class PluginChatConfigProvider: ChatConfigProvider {

    private let pluginManager: AIPluginManager

    public init(pluginManager: AIPluginManager) {
        self.pluginManager = pluginManager
    }

    private var resolved: AIProviderResolver.Resolved? {
        Self.defaultConfiguration(in: UserSettings.aiProviderConfigurations.value, manager: pluginManager)
            .flatMap { AIProviderResolver.resolve($0, manager: pluginManager) }
    }

    /// The configuration a chat opens on when none is named: the one selected in
    /// Settings if it resolves, else the first that does. Nil when none resolves.
    public static func defaultConfiguration(in configurations: [AIProviderConfiguration],
                                            manager: AIPluginManager) -> AIProviderConfiguration? {
        let resolves = { (config: AIProviderConfiguration) in
            AIProviderResolver.resolve(config, manager: manager) != nil
        }
        if let uuid = UUID(uuidString: UserSettings.selectedAIProviderConfigurationId.value),
           let chosen = configurations.first(where: { $0.id == uuid }), resolves(chosen) {
            return chosen
        }
        return configurations.first(where: resolves)
    }

    public var selectedPluginIdentifier: String { resolved?.pluginIdentifier ?? "" }
    public var selectedModel: String { resolved?.model ?? "" }
    public var pluginConfigValues: [String: String] { resolved?.values ?? [:] }
}
