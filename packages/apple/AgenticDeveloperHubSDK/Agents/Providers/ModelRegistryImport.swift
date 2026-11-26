import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKCore

/// The one-time copy of an app's own provider configurations
/// (`aiplugin.configurations`) into the shared `ModelRegistry`, so a daemon or
/// another app sees the models this app was already set up with.
///
/// `run` is the core: it takes the configurations already read, so it can be
/// tested against an in-memory registry and a fake secret store. `sources`
/// reads them from this app's settings (secrets through the app's own
/// Keychain provider), and `runIfNeeded` does both once, behind a flag.
public enum ModelRegistryImport {

    /// Set in the app's standard defaults once an import has run cleanly.
    public static let flagKey = "models_registry_imported_v1"

    /// One configuration as the app stores it.
    public struct Source: Sendable, Equatable {
        public var configuration: AIProviderConfiguration
        /// Non-secret field values that are set (blank ones are left out).
        public var fields: [String: String]
        /// Secret field values that are set. Never logged or returned.
        public var secrets: [String: String]
        /// The model chosen for it, nil for the template's default.
        public var model: String?

        public init(
            configuration: AIProviderConfiguration,
            fields: [String: String] = [:],
            secrets: [String: String] = [:],
            model: String? = nil
        ) {
            self.configuration = configuration
            self.fields = fields
            self.secrets = secrets
            self.model = model
        }
    }

    /// What an import did, by configuration id. No secret values.
    public struct Outcome: Sendable, Equatable {
        public var imported: [UUID] = []
        /// Already in the registry: the same id, or the same plugin with the
        /// same non-secret field values.
        public var skipped: [UUID] = []
        /// The configuration's template no longer resolves (its plugin is
        /// not installed), so its fields and secrets cannot be read.
        public var unresolved: [UUID] = []
        /// The upsert threw; the message says why.
        public var failed: [UUID: String] = [:]

        public init() {}
    }

    /// Upserts each source as a `ModelEntry` with `origin`, unless the
    /// registry already holds one with its id, or one of the same plugin whose
    /// non-secret fields are equal. Its secrets go into the registry's secret
    /// store. A failure on one source does not stop the rest.
    public static func run(_ sources: [Source], into registry: ModelRegistry, origin: String) -> Outcome {
        var outcome = Outcome()
        var existing: [ModelEntry]
        do {
            existing = try registry.list()
        } catch {
            for source in sources { outcome.failed[source.configuration.id] = error.localizedDescription }
            return outcome
        }
        for source in sources {
            let config = source.configuration
            let duplicate = existing.contains { entry in
                entry.id == config.id
                    || (entry.configuration.pluginIdentifier == config.pluginIdentifier
                        && entry.fields == source.fields)
            }
            if duplicate {
                outcome.skipped.append(config.id)
                continue
            }
            let entry = ModelEntry(configuration: config, fields: source.fields, model: source.model, origin: origin)
            do {
                try registry.upsert(entry, secrets: source.secrets)
                existing.append(entry)
                outcome.imported.append(config.id)
            } catch {
                outcome.failed[config.id] = error.localizedDescription
            }
        }
        return outcome
    }

    /// The app's configurations with their stored values: each field through
    /// `AIProviderConfigStore.fieldSetting` (a secret one through the app's
    /// Keychain provider) and the model through `modelSetting`. The second
    /// list holds the ids whose template does not resolve.
    @MainActor
    public static func sources(
        configurations: [AIProviderConfiguration],
        pluginManager: AIPluginManager
    ) -> (sources: [Source], unresolved: [UUID]) {
        var sources: [Source] = []
        var unresolved: [UUID] = []
        for config in configurations {
            guard let template = pluginManager.template(
                pluginIdentifier: config.pluginIdentifier, templateId: config.templateId
            ) else {
                unresolved.append(config.id)
                continue
            }
            var source = Source(configuration: config)
            for field in pluginManager.fields(pluginIdentifier: config.pluginIdentifier, template: template) {
                let value = AIProviderConfigStore.fieldSetting(config: config.id, field: field).currentValue
                guard !value.isEmpty else { continue }
                if field.isSecret {
                    source.secrets[field.key] = value
                } else {
                    source.fields[field.key] = value
                }
            }
            let model = AIProviderConfigStore.modelSetting(config: config.id, template: template).currentValue
            source.model = model.isEmpty ? nil : model
            sources.append(source)
        }
        return (sources, unresolved)
    }

    /// Imports this app's configurations once. Nil when the flag is already
    /// set. The flag is set only when no upsert failed, so a Keychain or
    /// database failure is retried at the next launch; an entry imported the
    /// first time is skipped then, never doubled.
    @MainActor
    @discardableResult
    public static func runIfNeeded(
        registry: ModelRegistry,
        pluginManager: AIPluginManager,
        origin: String,
        defaults: UserDefaults = .standard
    ) -> Outcome? {
        guard !defaults.bool(forKey: flagKey) else { return nil }
        let (sources, unresolved) = sources(
            configurations: UserSettings.aiProviderConfigurations.value, pluginManager: pluginManager)
        var outcome = run(sources, into: registry, origin: origin)
        outcome.unresolved = unresolved
        if outcome.failed.isEmpty {
            defaults.set(true, forKey: flagKey)
        }
        return outcome
    }
}
