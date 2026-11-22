#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation

/// Where a `provider:<id>` rule sends a request: one AI provider configuration
/// resolved to an endpoint, a key, a model and a wire format. No printed form
/// contains `apiKey`.
struct ProviderRoute: Sendable, Equatable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    enum Wire: Sendable, Equatable {
        /// OpenAI Chat Completions; `maxTokensKey` names the output limit field.
        case chatCompletions(maxTokensKey: String)
        /// Anthropic Messages, forwarded without translation.
        case anthropic
    }

    let configID: UUID
    /// The configuration's name, recorded in the `provider` column.
    let name: String
    /// Full URL: `<base>/chat/completions` or `<base>/v1/messages`.
    let endpoint: URL
    let apiKey: String?
    let model: String
    let wire: Wire

    var description: String {
        "ProviderRoute(name: \(name), endpoint: \(printableEndpoint), model: \(model), wire: \(wire), "
            + "apiKey: \(apiKey == nil ? "none" : "[redacted]"))"
    }

    var debugDescription: String { description }

    var customMirror: Mirror {
        Mirror(self, children: ["configID": configID, "name": name, "endpoint": printableEndpoint, "model": model,
                                "wire": wire], displayStyle: .struct)
    }

    /// `scheme://host[:port]/path` only: a base URL's userinfo or query could hold a credential.
    var printableEndpoint: String {
        let scheme = endpoint.scheme ?? "?"
        let host = endpoint.host ?? "?"
        let port = endpoint.port.map { ":\($0)" } ?? ""
        return "\(scheme)://\(host)\(port)\(endpoint.path)"
    }
}

/// Why a provider rule cannot be used; the text goes in the rule's `(fell back: …)`.
enum ProviderUnavailable: String, Error, Sendable {
    case unavailable = "provider unavailable"
    case noModel = "provider has no model"
    /// Plain http would carry whole conversations and the key in clear text.
    case plainHTTP = "provider uses plain http to a host other than this Mac"
}

/// Resolves a configuration id to a route, or why there is none. `model`
/// replaces the configuration's own model (a `provider:<id>/<model>` target).
protocol ModelProviderResolving: Sendable {
    func resolve(_ id: UUID, model: String?) -> Result<ProviderRoute, ProviderUnavailable>
}

extension ModelProviderResolving {
    func resolve(_ id: UUID) -> Result<ProviderRoute, ProviderUnavailable> { resolve(id, model: nil) }
    func route(_ id: UUID) -> ProviderRoute? { try? resolve(id).get() }
}

/// Resolves nothing: every provider rule falls back to Anthropic.
struct NoModelProviders: ModelProviderResolving {
    func resolve(_ id: UUID, model: String?) -> Result<ProviderRoute, ProviderUnavailable> { .failure(.unavailable) }
}

/// The production resolver: the configuration registry the app pushes to the
/// daemon (settings rows), its key from the daemon Keychain. Never throws;
/// anything missing or malformed is nil.
struct ModelProviderResolver: ModelProviderResolving {
    static let openAIPlugin = "com.mikefullerton.agenticdeveloperhubsdk.plugin.openai"
    static let openAICompatiblePlugin = "com.mikefullerton.agenticdeveloperhubsdk.plugin.openai-compatible"
    static let googlePlugin = "com.mikefullerton.agenticdeveloperhubsdk.plugin.google"
    static let claudeAPIPlugin = "com.mikefullerton.agenticdeveloperhubsdk.plugin.claude-api"

    /// The identifiers the plugins had before the SDK was renamed. Configurations
    /// saved then still carry them, so they route the same way.
    static let legacyOpenAIPlugin = "com.agentictoolkit.plugin.openai"
    static let legacyOpenAICompatiblePlugin = "com.agentictoolkit.plugin.openai-compatible"
    static let legacyGooglePlugin = "com.agentictoolkit.plugin.google"
    static let legacyClaudeAPIPlugin = "com.agentictoolkit.plugin.claude-api"

    static let openAIBase = "https://api.openai.com/v1"
    static let googleEndpoint = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
    static let claudeAPIBase = "https://api.anthropic.com"

    private let settings: ProviderSettingsReader
    private let secret: @Sendable (String) -> String?
    private let secretRequired: @Sendable (_ plugin: String, _ template: String) -> Bool

    /// `secretRequired` answers a template's `secretRequired`; production reads
    /// the installed plugin descriptors.
    init(
        settings: @escaping ProviderSettingsReader,
        secret: @escaping @Sendable (String) -> String?,
        secretRequired: @escaping @Sendable (_ plugin: String, _ template: String) -> Bool = {
            ProviderTemplateCatalog.shared.secretRequired(plugin: $0, template: $1, now: Date())
        }
    ) {
        self.settings = settings
        self.secret = secret
        self.secretRequired = secretRequired
    }

    func resolve(_ id: UUID, model chosen: String?) -> Result<ProviderRoute, ProviderUnavailable> {
        guard let config = DaemonProviderResolver.configurations(settings).first(where: { $0.id == id }) else {
            return .failure(.unavailable)
        }
        let model = (chosen ?? DaemonProviderResolver.model(config: id, settings))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else { return .failure(.noModel) }
        return route(config, id: id, model: model)
    }

    private func route(
        _ config: AIProviderConfiguration, id: UUID, model: String
    ) -> Result<ProviderRoute, ProviderUnavailable> {
        let base = field("baseURL", id)
        let endpoint: String
        let wire: ProviderRoute.Wire
        switch config.pluginIdentifier {
        case Self.openAIPlugin, Self.legacyOpenAIPlugin:
            endpoint = Self.versioned(base ?? Self.openAIBase) + "/chat/completions"
            wire = .chatCompletions(maxTokensKey: "max_completion_tokens")
        case Self.openAICompatiblePlugin, Self.legacyOpenAICompatiblePlugin:
            guard let base else { return .failure(.unavailable) }
            endpoint = Self.versioned(base) + "/chat/completions"
            wire = .chatCompletions(maxTokensKey: "max_tokens")
        case Self.googlePlugin, Self.legacyGooglePlugin:
            endpoint = Self.googleEndpoint
            wire = .chatCompletions(maxTokensKey: "max_tokens")
        case Self.claudeAPIPlugin, Self.legacyClaudeAPIPlugin:
            // A subscription token is the account router's business, not a provider's.
            if field("authMode", id) == "bearer-oauth" { return .failure(.unavailable) }
            endpoint = Self.versioned(base ?? Self.claudeAPIBase) + "/messages"
            wire = .anthropic
        default:
            return .failure(.unavailable)
        }
        guard let url = URL(string: endpoint, encodingInvalidCharacters: false),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else { return .failure(.unavailable) }
        if scheme == "http", !Self.isLoopback(host) { return .failure(.plainHTTP) }
        let key = secret(AIProviderConfigKeys.fieldKey(config: id, field: "apiKey"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 }
        if key == nil, secretRequired(config.pluginIdentifier, config.templateId) { return .failure(.unavailable) }
        return .success(
            ProviderRoute(configID: id, name: config.name, endpoint: url, apiKey: key, model: model, wire: wire))
    }

    /// Hosts that never leave this Mac: `localhost`, `127.0.0.0/8` and `::1`.
    static func isLoopback(_ host: String) -> Bool {
        let name = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if name == "localhost" || name == "::1" { return true }
        let parts = name.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 4 && parts[0] == "127" && parts.allSatisfy { UInt8($0) != nil }
    }

    /// A non-empty setting, trimmed.
    private func field(_ name: String, _ id: UUID) -> String? {
        let value = (settings(AIProviderConfigKeys.fieldKey(config: id, field: name)) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    /// `base` without trailing slashes, with `/v1` appended unless its last
    /// path segment is already a version (`v` and a digit), as
    /// `OpenAICompatiblePlugin` does.
    static func versioned(_ base: String) -> String {
        var root = base
        while root.hasSuffix("/") { root.removeLast() }
        let last = root.split(separator: "/").last ?? ""
        let isVersion = last.first == "v" && last.dropFirst().first?.isNumber == true
        return isVersion ? root : root + "/v1"
    }
}

/// Each installed plugin template's `secretRequired`, from
/// `AIPluginManager.scanDescriptors` (descriptors only, no binary is loaded).
/// A template not found requires a key: an unknown configuration is never
/// sent keyless.
final class ProviderTemplateCatalog: @unchecked Sendable {
    static let shared = ProviderTemplateCatalog(searchPaths: { DaemonAIChat.pluginSearchPaths() })

    /// A template not found re-reads the descriptors at most this often.
    static let rereadInterval: TimeInterval = 60

    private let searchPaths: @Sendable () -> [URL]
    private let lock = NSLock()
    private var loaded: [String: [String: Bool]] = [:]
    private var readAt: Date?

    init(searchPaths: @escaping @Sendable () -> [URL]) {
        self.searchPaths = searchPaths
    }

    func secretRequired(plugin: String, template: String, now: Date = Date()) -> Bool {
        let (known, lastRead) = lock.withLock { (loaded[plugin]?[template], readAt) }
        if let known { return known }
        // Not found: read again (throttled), so a plugin installed later counts.
        if let lastRead, now.timeIntervalSince(lastRead) < Self.rereadInterval { return true }
        let fresh = Self.read(searchPaths())
        lock.withLock {
            loaded = fresh
            readAt = now
        }
        return fresh[plugin]?[template] ?? true
    }

    /// The toolkit's own discovery scan; this type only keeps the throttle.
    private static func read(_ paths: [URL]) -> [String: [String: Bool]] {
        var table: [String: [String: Bool]] = [:]
        for found in AIPluginManager.scanDescriptors(in: paths) {
            var templates: [String: Bool] = [:]
            for template in found.descriptor.resolvedTemplates { templates[template.id] = template.secretRequired }
            table[found.descriptor.identifier] = templates
        }
        return table
    }
}
#endif
