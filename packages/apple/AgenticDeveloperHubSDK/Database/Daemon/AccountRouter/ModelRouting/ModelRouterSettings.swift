#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// The model router's settings, read per request like `AccountRouterSettings`:
/// the on/off row plus the templates and preferred marks the store holds.
/// Tiers live in the templates; an old `model_router_tiers` row is ignored.
struct ModelRouterSettings: Equatable, Sendable {
    static let enabledKey = "model_router_enabled"

    var enabled = false
    var templates = Sessions.ModelRouterTemplateDTO.builtIns
    var preferred: Set<String> = []

    /// Never throws. An unreadable row, or a database still migrating, is the default (off, built-ins only).
    static func load(_ database: DaemonDatabase, store: ModelRouterTemplateStore) -> ModelRouterSettings {
        guard database.isReady else { return ModelRouterSettings() }
        return load(database, loaded: store.load())
    }

    /// The same, from a store read the caller already made.
    static func load(_ database: DaemonDatabase, loaded: ModelRouterTemplateStore.Loaded) -> ModelRouterSettings {
        var settings = ModelRouterSettings()
        guard database.isReady else { return settings }
        settings.enabled = ((try? database.setting(for: enabledKey)) ?? nil) == "1"
        settings.templates = loaded.templates
        settings.preferred = loaded.preferred
        return settings
    }
}
#endif
