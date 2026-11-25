import Foundation
import AIPluginKit

/// One model configuration in the shared registry: a provider configuration
/// (which plugin, which template), its non-secret field values, a default
/// model and the roles it can fill. Secrets never live here, only the names of
/// the secret fields the registry holds for it.
public struct ModelEntry: Codable, Sendable, Equatable, Identifiable {
    /// id, name, pluginIdentifier and templateId. The id is also the Keychain
    /// account prefix of the entry's secrets, so an app that imports one of its
    /// own configurations keeps the id and its secrets line up.
    public var configuration: AIProviderConfiguration
    /// Non-secret field values (`baseURL`, `authMode`, …).
    public var fields: [String: String]
    /// The default model id; nil uses the template's default.
    public var model: String?
    /// Free-form roles this entry can fill: fast, smart, local, cheap…
    public var roles: [String]
    public var enabled: Bool
    /// Bundle id of the app that imported it, or nil when it was added directly.
    public var origin: String?
    /// The names of the secret fields the registry holds for this entry. Set by
    /// `ModelRegistry.upsert` from the secrets it is given, so a resolver knows
    /// which ones to read without loading the plugin. Never the values.
    public var secretFields: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public var id: UUID { configuration.id }

    public init(
        configuration: AIProviderConfiguration,
        fields: [String: String] = [:],
        model: String? = nil,
        roles: [String] = [],
        enabled: Bool = true,
        origin: String? = nil,
        secretFields: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.configuration = configuration
        self.fields = fields
        self.model = model
        self.roles = roles
        self.enabled = enabled
        self.origin = origin
        self.secretFields = secretFields
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case configuration, fields, model, roles, enabled, origin, secretFields, createdAt, updatedAt
    }

    /// Only `configuration` is required, so a client can POST a minimal entry;
    /// everything else takes the same default as the memberwise init.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configuration = try container.decode(AIProviderConfiguration.self, forKey: .configuration)
        fields = try container.decodeIfPresent([String: String].self, forKey: .fields) ?? [:]
        model = try container.decodeIfPresent(String.self, forKey: .model)
        roles = try container.decodeIfPresent([String].self, forKey: .roles) ?? []
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        origin = try container.decodeIfPresent(String.self, forKey: .origin)
        secretFields = try container.decodeIfPresent([String].self, forKey: .secretFields) ?? []
        let now = Date()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? now
    }

    /// The model a request uses when the caller names none: the entry's own,
    /// else nil for the template's default.
    public var effectiveModel: String? {
        guard let model, !model.isEmpty else { return nil }
        return model
    }
}
