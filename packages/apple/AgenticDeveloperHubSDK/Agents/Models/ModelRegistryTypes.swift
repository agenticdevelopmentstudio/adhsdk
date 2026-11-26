import Foundation
import AIPluginKit

/// A selector resolved to something a request can be built from: the entry,
/// the model to ask for and the entry's secrets. Never serialized.
public struct ResolvedModel: Sendable, Equatable {
    public var entry: ModelEntry
    /// The model the selector or the entry names; nil uses the template's default.
    public var model: String?
    /// Secret field values by field key (`apiKey`, …).
    public var secrets: [String: String]

    public init(entry: ModelEntry, model: String?, secrets: [String: String]) {
        self.entry = entry
        self.model = model
        self.secrets = secrets
    }
}

/// An installed AI plugin as a client configuring an entry sees it: its
/// templates, each with its resolved fields and models. Read from the plugin's
/// descriptor; no plugin code is loaded.
public struct PluginSummary: Codable, Sendable, Equatable {

    public struct Template: Codable, Sendable, Equatable {
        public var id: String
        public var displayName: String
        public var models: [String]
        public var defaultModel: String
        public var secretRequired: Bool
        /// The template's own field list (shared fields plus its overrides).
        public var fields: [AIPluginDescriptor.Field]
        public var defaultValues: [String: String]

        public init(
            id: String, displayName: String, models: [String], defaultModel: String,
            secretRequired: Bool, fields: [AIPluginDescriptor.Field], defaultValues: [String: String]
        ) {
            self.id = id
            self.displayName = displayName
            self.models = models
            self.defaultModel = defaultModel
            self.secretRequired = secretRequired
            self.fields = fields
            self.defaultValues = defaultValues
        }
    }

    public var identifier: String
    public var displayName: String
    public var version: String
    public var templates: [Template]
    /// Why the host refused to load the plugin (an AIPluginKit ABI mismatch);
    /// nil for a plugin it accepted. A refused plugin has no templates.
    public var loadError: String?

    public init(
        identifier: String, displayName: String, version: String, templates: [Template], loadError: String? = nil
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.version = version
        self.templates = templates
        self.loadError = loadError
    }

    /// A plugin discovery refused, listed so a client can say why it is unusable.
    public init(refused failure: PluginLoadFailure) {
        self.init(
            identifier: failure.identifier, displayName: failure.displayName, version: "",
            templates: [], loadError: failure.message)
    }

    public init(_ descriptor: AIPluginDescriptor) {
        self.init(
            identifier: descriptor.identifier,
            displayName: descriptor.displayName,
            version: descriptor.version,
            templates: descriptor.resolvedTemplates.map { template in
                Template(
                    id: template.id,
                    displayName: template.displayName,
                    models: template.models,
                    defaultModel: descriptor.effectiveModel(stored: nil, templateId: template.id),
                    secretRequired: template.secretRequired,
                    fields: descriptor.fields(for: template),
                    defaultValues: template.defaultValues)
            })
    }
}

/// The outcome of a one-line round trip to an entry's model.
public struct ModelTestResult: Codable, Sendable, Equatable {
    /// Whether the model answered (`ok` on the wire).
    public var isOK: Bool
    public var latencyMs: Int
    /// The model's reply on success, else what went wrong.
    public var message: String

    public init(isOK: Bool, latencyMs: Int, message: String) {
        self.isOK = isOK
        self.latencyMs = latencyMs
        self.message = message
    }

    private enum CodingKeys: String, CodingKey {
        case isOK = "ok"
        case latencyMs, message
    }
}

public enum ModelRegistryError: Error, LocalizedError, Equatable {
    case notFound(UUID)
    case invalidEntry(String)
    case pluginNotInstalled(String)
    case unknownTemplate(plugin: String, template: String)
    /// `create` of an id that is already stored.
    case duplicate(UUID)
    /// The entry's plugin is installed but was refused (an AIPluginKit ABI
    /// mismatch); the message says why.
    case pluginIncompatible(plugin: String, message: String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let id): return "No model entry with id \(id.uuidString)"
        case .invalidEntry(let reason): return reason
        case .pluginNotInstalled(let plugin): return "AI plugin not installed: \(plugin)"
        case let .unknownTemplate(plugin, template):
            return "AI plugin \(plugin) has no template '\(template)'"
        case .duplicate(let id): return "A model entry with id \(id.uuidString) exists"
        case .pluginIncompatible(_, let message): return message
        }
    }
}
