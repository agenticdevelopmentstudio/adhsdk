import Foundation
import AgenticDeveloperHubSDKCore
import AIPluginKit

/// Resolves the partner's provider and model settings to the `--model` value for Claude Code.
public enum PartnerModelChoice {
    public static let claudeLocalPluginIdentifier = "com.mikefullerton.agenticdeveloperhubsdk.plugin.claude-local"

    public enum Failure: Error, Equatable {
        case unknownProvider
        case notClaudeCode(String)

        public var message: String {
            switch self {
            case .unknownProvider: "The Coding Partner's provider is no longer configured."
            case .notClaudeCode(let name): "The Coding Partner runs on a Claude Code provider; \(name) is not one."
            }
        }
    }

    /// The `--model` value; "" means Claude Code's own default.
    public static func resolve(
        provider: String,
        configurations: [AIProviderConfiguration],
        model: (UUID) -> String,
        legacyModel: String
    ) -> Result<String, Failure> {
        if provider.isEmpty { return .success(legacyModel) }
        guard let id = UUID(uuidString: provider),
              let configuration = configurations.first(where: { $0.id == id }) else {
            return .failure(.unknownProvider)
        }
        guard configuration.pluginIdentifier == claudeLocalPluginIdentifier else {
            return .failure(.notClaudeCode(configuration.name))
        }
        return .success(model(id))
    }
}
