import AppKit
import AgenticDeveloperHubSDKCore
import AIPluginKit

/// One provider configuration a ``ProviderModelPickerView`` lists.
public struct ProviderRegistryEntry: Equatable, Sendable {
    public let id: UUID
    public let name: String
    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

/// Where a ``ProviderModelPickerView`` gets its providers from, and what it
/// knows about each one's models. (Not AIPluginKit's `ProviderModelSource`,
/// which fetches one provider's model catalog.)
///
/// Two registries answer it: this process's own (``LocalProviderRegistrySource``,
/// the app's `AIPluginManager` and `UserSettings.aiProviderConfigurations`) and
/// the session daemon's (``DaemonProviderRegistrySource``, its pushed list).
@MainActor
public protocol ProviderRegistrySource: AnyObject {
    /// The providers, in the order the popup lists them.
    var providers: [ProviderRegistryEntry] { get }
    /// Called whenever ``providers`` changes.
    var onChange: (@MainActor () -> Void)? { get set }
    /// True when ``providers`` is the whole truth, so a stored selection naming
    /// none of them is shown as unavailable (never rewritten). A daemon that
    /// has not answered yet is not.
    var isAuthoritative: Bool { get }
    /// Re-reads the providers (the popup is about to open).
    func reload()
    /// The provider config's own default model, nil when it is not known.
    func defaultModel(for id: UUID) -> String?
    /// What the model chooser lists for a provider, opened on `currentModel`;
    /// nil when the provider is unknown.
    func chooserContext(for id: UUID, currentModel: String) -> ModelChooserContext?
}

/// The chooser's context for one configuration: its resolved field values
/// (base URL, API key), so live catalog lookups reach the right server.
@MainActor
enum ProviderChooserContexts {
    static func context(
        config: AIProviderConfiguration,
        template: AIPluginDescriptor.ProviderTemplate,
        pluginManager: AIPluginManager?,
        currentModel: String
    ) -> ModelChooserContext {
        let fields = pluginManager?.fields(pluginIdentifier: config.pluginIdentifier, template: template) ?? []
        let values = AIProviderConfigStore.configValues(for: config, template: template, fields: fields)
        return ModelChooserContext(
            pluginIdentifier: config.pluginIdentifier, template: template,
            baseURL: values["baseURL"] ?? "", apiKey: values["apiKey"],
            currentModel: currentModel.isEmpty ? template.resolvedDefaultModel : currentModel)
    }

    /// The config's own default model (`AIProviderConfigStore.selectedModel`),
    /// nil when it resolves to nothing.
    static func defaultModel(config: AIProviderConfiguration,
                             template: AIPluginDescriptor.ProviderTemplate) -> String? {
        let model = AIProviderConfigStore.selectedModel(config: config, template: template)
        return model.isEmpty ? nil : model
    }
}

// MARK: - Local

/// This process's provider configurations, resolved through its plugin manager.
@MainActor
public final class LocalProviderRegistrySource: ProviderRegistrySource {

    private let pluginManager: AIPluginManager?
    private var listObserver: UserSettingObserver<[AIProviderConfiguration]>?
    public var onChange: (@MainActor () -> Void)?
    public let isAuthoritative = true

    /// - Parameter pluginManager: resolves each configuration's template; nil
    ///   leaves every configuration listed but with nothing to choose from.
    public init(pluginManager: AIPluginManager?) {
        self.pluginManager = pluginManager
        listObserver = UserSettingObserver(UserSettings.aiProviderConfigurations) { [weak self] _ in
            self?.onChange?()
        }
    }

    public var providers: [ProviderRegistryEntry] {
        UserSettings.aiProviderConfigurations.value.map { .init(id: $0.id, name: $0.name) }
    }

    public func reload() {}

    /// The configuration for `id` and its template, nil when either is gone.
    public func resolved(_ id: UUID)
        -> (config: AIProviderConfiguration, template: AIPluginDescriptor.ProviderTemplate)? {
        guard let config = UserSettings.aiProviderConfigurations.value.first(where: { $0.id == id }),
              let template = pluginManager?.template(
                  pluginIdentifier: config.pluginIdentifier, templateId: config.templateId)
        else { return nil }
        return (config, template)
    }

    public func defaultModel(for id: UUID) -> String? {
        guard let (config, template) = resolved(id) else { return nil }
        return ProviderChooserContexts.defaultModel(config: config, template: template)
    }

    public func chooserContext(for id: UUID, currentModel: String) -> ModelChooserContext? {
        guard let (config, template) = resolved(id) else { return nil }
        return ProviderChooserContexts.context(
            config: config, template: template, pluginManager: pluginManager, currentModel: currentModel)
    }
}

// MARK: - Daemon

/// The session daemon's provider configurations (`GET /preferences/ai/configs`),
/// read at init and again whenever the popup is about to open.
///
/// Each config's template is resolved through an optional plugin manager, so the
/// model list and the default name can be shown. Without one (Stenographer) the
/// chooser still opens, on a bare template that lists only the current model,
/// and no default name is known.
@MainActor
public final class DaemonProviderRegistrySource: ProviderRegistrySource {

    private let service: any StenographerDaemonService
    private let pluginManager: AIPluginManager?
    private var configs: [DaemonProviderConfig] = []
    private var loadTask: Task<Void, Never>?
    public var onChange: (@MainActor () -> Void)?
    public private(set) var isAuthoritative = false

    public init(service: any StenographerDaemonService, pluginManager: AIPluginManager? = nil) {
        self.service = service
        self.pluginManager = pluginManager
        reload()
    }

    public var providers: [ProviderRegistryEntry] { Self.entries(from: configs) }

    /// The configurations by name, case-insensitively.
    public nonisolated static func entries(from configs: [DaemonProviderConfig]) -> [ProviderRegistryEntry] {
        configs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { .init(id: $0.id, name: $0.name) }
    }

    public func reload() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in await self?.load() }
    }

    /// Re-reads the daemon's configurations; an unreachable daemon keeps the list
    /// as is. ``onChange`` fires when the list changed, and on the first answer
    /// even when it did not (an empty daemon list equals the initial one), so a
    /// picker learns the source is now authoritative.
    public func load() async {
        guard let fresh = await service.aiProviderConfigs(), !Task.isCancelled else { return }
        let becameAuthoritative = !isAuthoritative
        isAuthoritative = true
        guard fresh != configs || becameAuthoritative else { return }
        configs = fresh
        onChange?()
    }

    /// The daemon's config as this process's configuration type, which the
    /// config store keys its values by (the Kitchen pushes the daemon its own
    /// configurations, ids and all).
    private func configuration(_ id: UUID) -> AIProviderConfiguration? {
        guard let config = configs.first(where: { $0.id == id }) else { return nil }
        return AIProviderConfiguration(
            id: config.id, name: config.name,
            pluginIdentifier: config.pluginIdentifier, templateId: config.templateId)
    }

    private func template(for config: AIProviderConfiguration) -> AIPluginDescriptor.ProviderTemplate? {
        pluginManager?.template(pluginIdentifier: config.pluginIdentifier, templateId: config.templateId)
    }

    public func defaultModel(for id: UUID) -> String? {
        guard let config = configuration(id), let template = template(for: config) else { return nil }
        return ProviderChooserContexts.defaultModel(config: config, template: template)
    }

    public func chooserContext(for id: UUID, currentModel: String) -> ModelChooserContext? {
        guard let config = configuration(id) else { return nil }
        if let template = template(for: config) {
            return ProviderChooserContexts.context(
                config: config, template: template, pluginManager: pluginManager, currentModel: currentModel)
        }
        // No plugin host to describe this template: a bare one, so the chooser
        // still opens, listing only the current model, and takes any other
        // model name typed into its search field.
        let bare = AIPluginDescriptor.ProviderTemplate(
            id: config.templateId, displayName: config.name,
            models: currentModel.isEmpty ? [] : [currentModel], secretRequired: false)
        return ModelChooserContext(
            pluginIdentifier: config.pluginIdentifier, template: bare,
            baseURL: "", apiKey: nil, currentModel: currentModel, allowsCustomModel: true)
    }
}
