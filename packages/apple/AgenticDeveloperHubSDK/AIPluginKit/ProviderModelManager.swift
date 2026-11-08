import Foundation
import AgenticDeveloperHubSDKCore

/// Somewhere a provider's current model list can be loaded from.
public protocol ProviderModelSource: Sendable {
    /// Identifies what this source lists, so its result can be cached and shown
    /// again before the next fetch (an endpoint and, for a keyed API, nothing
    /// secret — the same account sees the same models).
    var cacheKey: String { get }
    /// The provider's models, or nil when the source could not be reached.
    func fetch() async -> ProviderModelList?
}

/// The Anthropic API's `GET /v1/models`: every model the account can call, with
/// its display name and release date. Works with an API key (`x-api-key`) and
/// with a Claude subscription token (`bearer-oauth`).
public struct AnthropicModelsSource: ProviderModelSource {
    public let baseURL: String
    public let apiKey: String
    public let oauth: Bool

    public init(baseURL: String, apiKey: String, oauth: Bool) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.oauth = oauth
    }

    public var cacheKey: String { "anthropic-api|\(baseURL)" }

    public func fetch() async -> ProviderModelList? {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty,
              var components = URLComponents(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return nil }
        components.path = components.path.hasSuffix("/") ? components.path + "models" : components.path + "/models"
        components.queryItems = [URLQueryItem(name: "limit", value: "1000")]
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        if oauth {
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
            request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        } else {
            request.setValue(trimmedKey, forHTTPHeaderField: "x-api-key")
        }
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode)
        else { return nil }
        return Self.parse(data)
    }

    /// Parses a `/v1/models` body (`{"data": [{"id", "display_name", "created_at"}]}`).
    public static func parse(_ data: Data) -> ProviderModelList? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["data"] as? [[String: Any]] else { return nil }
        let models = entries.compactMap { entry -> ProviderModel? in
            guard let id = entry["id"] as? String else { return nil }
            let created = (entry["created_at"] as? String).map { String($0.prefix(10)) }
            return ProviderModel(id: id, displayName: entry["display_name"] as? String,
                                 family: AnthropicModelFamily.family(of: id), releaseDate: created)
        }
        return models.isEmpty ? nil : ProviderModelList(models: models)
    }
}

/// One provider's entry in the public models.dev catalog, which needs no
/// credentials — the source for a provider whose own listing needs an account
/// (or has none, like the local Claude CLI).
public struct ModelsDevModelsSource: ProviderModelSource {
    public static let catalogURL = URL(string: "https://models.dev/api.json")!

    /// models.dev's provider key, e.g. `anthropic`.
    public let provider: String
    /// Model ids to leave out (dated snapshots duplicate their alias for a CLI
    /// that only takes the name).
    public let excludeDatedSnapshots: Bool

    public init(provider: String, excludeDatedSnapshots: Bool = false) {
        self.provider = provider
        self.excludeDatedSnapshots = excludeDatedSnapshots
    }

    public var cacheKey: String { "models.dev|\(provider)|\(excludeDatedSnapshots)" }

    public func fetch() async -> ProviderModelList? {
        let request = URLRequest(url: Self.catalogURL, timeoutInterval: 15)
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode)
        else { return nil }
        return Self.parse(data, provider: provider, excludeDatedSnapshots: excludeDatedSnapshots)
    }

    /// Parses the catalog (`{<provider>: {models: {<id>: {name, family, release_date}}}}`).
    public static func parse(_ data: Data, provider: String,
                             excludeDatedSnapshots: Bool = false) -> ProviderModelList? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entry = json[provider] as? [String: Any],
              let models = entry["models"] as? [String: [String: Any]] else { return nil }
        let parsed = models.compactMap { id, info -> ProviderModel? in
            let model = ProviderModel(
                id: id, displayName: info["name"] as? String,
                family: (info["family"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                    ?? (provider == "anthropic" ? AnthropicModelFamily.family(of: id) : nil),
                releaseDate: info["release_date"] as? String)
            return excludeDatedSnapshots && model.isDatedSnapshot ? nil : model
        }
        // Dictionary order is random; order by id first so equal dates are stable.
        let list = ProviderModelList(models: parsed.sorted { $0.id < $1.id })
        return list.isEmpty ? nil : list
    }
}

/// An OpenAI-compatible `GET /models` (OpenAI, Groq, Ollama, …): ids only, so
/// every model counts as current.
public struct OpenAICompatibleModelsSource: ProviderModelSource {
    public let baseURL: String
    public let apiKey: String?

    public init(baseURL: String, apiKey: String?) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    public var cacheKey: String { "openai|\(baseURL)" }

    public func fetch() async -> ProviderModelList? {
        let ids = await OpenAIModelCatalog.fetch(baseURL: baseURL, apiKey: apiKey)
        return ids.isEmpty ? nil : ProviderModelList(ids: ids)
    }
}

/// Tries each source in turn and returns the first that answers.
public struct FallbackModelSource: ProviderModelSource {
    public let sources: [any ProviderModelSource]

    public init(_ sources: [any ProviderModelSource]) { self.sources = sources }

    public var cacheKey: String { sources.first?.cacheKey ?? "" }

    public func fetch() async -> ProviderModelList? {
        for source in sources {
            if let list = await source.fetch(), !list.isEmpty { return list }
        }
        return nil
    }
}

/// One provider configuration's models: every model it serves and the latest
/// version of each, loaded live from the provider (or a public catalog) and
/// cached, with the descriptor's static list as the seed until the first load.
///
/// Which source a provider uses is decided once, in `forProvider`, by the
/// descriptor template's id — the stable key for "which service is this".
@MainActor
public final class ProviderModelManager {

    /// source cache key -> last successfully loaded list.
    private static let cache = UserSetting<[String: ProviderModelList]>(
        "aiplugin.providerModelCache", default: [:])

    public let source: (any ProviderModelSource)?
    private let seed: ProviderModelList

    public init(source: (any ProviderModelSource)?, seed: [String]) {
        self.source = source
        self.seed = ProviderModelList(ids: seed)
    }

    /// The manager for a provider configuration.
    ///
    /// - `anthropic-api`, `claude-max-token`: the account's `/v1/models`, falling
    ///   back to models.dev when the key is missing or the call fails.
    /// - `claude-local`: models.dev's Anthropic list (the CLI has no listing of
    ///   its own; it accepts any full model id through `--model`).
    /// - OpenAI and OpenAI-compatible plugins: the endpoint's `/models`.
    /// - anything else: the descriptor's static list, no live source.
    public static func forProvider(pluginIdentifier: String,
                                   template: AIPluginDescriptor.ProviderTemplate,
                                   baseURL: String?, apiKey: String?) -> ProviderModelManager {
        let resolvedBase = (baseURL?.isEmpty == false ? baseURL : nil)
            ?? template.defaultValues["baseURL"] ?? ""
        let modelsDev = ModelsDevModelsSource(provider: "anthropic")
        let source: (any ProviderModelSource)?
        switch template.id {
        case "anthropic-api", "claude-max-token":
            let oauth = template.defaultValues["authMode"] == "bearer-oauth"
            source = FallbackModelSource([
                AnthropicModelsSource(baseURL: resolvedBase, apiKey: apiKey ?? "", oauth: oauth),
                modelsDev
            ])
        case "claude-local":
            source = ModelsDevModelsSource(provider: "anthropic", excludeDatedSnapshots: true)
        default:
            if ProviderModelManager.isOpenAIStyle(pluginIdentifier: pluginIdentifier), !resolvedBase.isEmpty {
                source = OpenAICompatibleModelsSource(baseURL: resolvedBase, apiKey: apiKey)
            } else {
                source = nil
            }
        }
        return ProviderModelManager(source: source, seed: template.models)
    }

    /// True for plugins whose endpoints answer OpenAI's `GET /models`.
    public nonisolated static func isOpenAIStyle(pluginIdentifier: String) -> Bool {
        pluginIdentifier.hasSuffix(".openai") || pluginIdentifier.hasSuffix(".openai-compatible")
    }

    /// Whether this provider's list can be loaded live.
    public var hasLiveSource: Bool { source != nil }

    /// The last loaded list, else the descriptor's static one.
    public var list: ProviderModelList {
        if let source, let cached = Self.cache.value[source.cacheKey], !cached.isEmpty { return cached }
        return seed
    }

    /// Loads the current list from the source and caches it. On failure the
    /// previous list stands.
    @discardableResult
    public func refresh() async -> ProviderModelList {
        guard let source else { return list }
        if let fresh = await source.fetch(), !fresh.isEmpty {
            var all = Self.cache.value
            all[source.cacheKey] = fresh
            Self.cache.value = all
            return fresh
        }
        return list
    }
}
