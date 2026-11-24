import CryptoKit
import Foundation
import AgenticDeveloperHubSDKCore

/// A short, one-way tag for a credential, so a cache key can tell two accounts
/// apart without the cache (plain user settings) ever holding the secret.
func credentialTag(_ credential: String?) -> String {
    let trimmed = credential?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !trimmed.isEmpty else { return "none" }
    let digest = SHA256.hash(data: Data(trimmed.utf8))
    return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
}

/// Somewhere a provider's current model list can be loaded from.
public protocol ProviderModelSource: Sendable {
    /// Identifies what this source lists, so its result can be cached and shown
    /// again before the next fetch: the endpoint and, for a keyed API, the auth
    /// mode and a one-way tag of the credential, because different accounts on
    /// one endpoint can see different models. Never the secret itself.
    var cacheKey: String { get }
    /// Every cache entry this source's results can be stored under, the most
    /// authoritative first. One key for a single source; a fallback chain names
    /// each of its sources' keys.
    var cacheKeys: [String] { get }
    /// The provider's models, or nil when the source could not be reached.
    func fetch() async -> ProviderModelList?
    /// The provider's models and the cache key of the source that answered.
    func load() async -> (cacheKey: String, list: ProviderModelList)?
}

extension ProviderModelSource {
    public var cacheKeys: [String] { [cacheKey] }

    public func load() async -> (cacheKey: String, list: ProviderModelList)? {
        guard let list = await fetch(), !list.isEmpty else { return nil }
        return (cacheKey, list)
    }
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

    public var cacheKey: String {
        "anthropic-api|\(baseURL)|\(oauth ? "oauth" : "key")|\(credentialTag(apiKey))"
    }

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

    public var cacheKey: String { "openai|\(baseURL)|\(credentialTag(apiKey))" }

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

    public var cacheKeys: [String] { sources.flatMap(\.cacheKeys) }

    public func fetch() async -> ProviderModelList? {
        await load()?.list
    }

    /// The first source that answers, under its own key: a public catalog that
    /// stood in for a keyed account must never land in the account's entry.
    public func load() async -> (cacheKey: String, list: ProviderModelList)? {
        for source in sources {
            if let answer = await source.load() { return answer }
        }
        return nil
    }
}

/// One provider configuration's models: every model it serves, the latest
/// version of each, and what to call them.
///
/// Each provider has its own manager (`AnthropicModelManager`,
/// `OpenAICompatibleModelManager`, `StaticModelManager`), and
/// `ProviderModels.manager(...)` picks it from the descriptor template, the
/// stable key for "which service is this". What they share (the live source,
/// the cache, the descriptor's list as the seed) is this protocol's extension.
///
/// When the list updates: never on a timer. `list` answers at once from the
/// last successful load, cached across launches, or the descriptor's list
/// before the first. `refresh()` loads it live, and every view that shows a
/// model list calls it when it opens (the model chooser, the provider picker,
/// the persona terminal chat), so the list is as fresh as the last time one
/// was looked at.
@MainActor
public protocol ProviderModelManager: AnyObject {
    /// Where the live list comes from, or nil for a provider with none.
    var source: (any ProviderModelSource)? { get }
    /// The descriptor's static list, shown until the first live load.
    var seed: ProviderModelList { get }
    /// The name a person reads for `id`.
    func displayName(for id: String) -> String
    /// The listed model `id` stands for (an alias resolved to the model it
    /// runs), or `id` unchanged.
    func resolve(_ id: String) -> String
}

/// The cache every manager shares: source cache key -> last loaded list.
/// The live model lists every provider has loaded, by source cache key.
/// Public so a view that names a model (an alias resolved against the list)
/// can observe it and redraw when any refresh lands, wherever it started.
@MainActor
public enum ProviderModelCache {
    public static let setting = UserSetting<[String: ProviderModelList]>(
        "aiplugin.providerModelCache", default: [:])
}

extension ProviderModelManager {
    /// Whether this provider's list can be loaded live.
    public var hasLiveSource: Bool { source != nil }

    /// The last loaded list from the most authoritative source that has
    /// answered (the account's own list before a public catalog), else the
    /// descriptor's static one.
    public var list: ProviderModelList {
        guard let source else { return seed }
        let cache = ProviderModelCache.setting.value
        for key in source.cacheKeys {
            if let cached = cache[key], !cached.isEmpty { return cached }
        }
        return seed
    }

    /// Loads the current list from the source and caches it under the key of
    /// the source that answered, then returns `list`. On failure, or when only
    /// a fallback answered, a list from a more authoritative source stands.
    @discardableResult
    public func refresh() async -> ProviderModelList {
        await refreshLive()
        return list
    }

    /// Loads and caches the current list like `refresh()`, but answers nil when
    /// no source could be reached, rather than the cached or static list a
    /// caller cannot tell from a successful load.
    @discardableResult
    public func refreshLive() async -> ProviderModelList? {
        guard let source, let fresh = await source.load() else { return nil }
        var all = ProviderModelCache.setting.value
        all[fresh.cacheKey] = fresh.list
        ProviderModelCache.setting.value = all
        return list
    }
}

/// Anthropic's models, for the API, a Claude subscription token and the local
/// Claude CLI: the live list, `Opus 5.5`-style names, and the CLI's bare
/// aliases (`opus`) resolved to the newest model of their family.
@MainActor
public final class AnthropicModelManager: ProviderModelManager {
    /// How this configuration reaches Anthropic, which decides the source.
    public enum Access: Sendable {
        /// An API key (`x-api-key`) or a subscription token (`oauth`): the
        /// account's own `/v1/models`, falling back to models.dev.
        case api(baseURL: String, apiKey: String?, oauth: Bool)
        /// The local Claude CLI: no listing of its own (it accepts any full id
        /// through `--model`), so models.dev's catalog without dated snapshots.
        case claudeCLI
    }

    public let source: (any ProviderModelSource)?
    public let seed: ProviderModelList

    public init(access: Access, seed: [String]) {
        switch access {
        case let .api(baseURL, apiKey, oauth):
            source = FallbackModelSource([
                AnthropicModelsSource(baseURL: baseURL, apiKey: apiKey ?? "", oauth: oauth),
                ModelsDevModelsSource(provider: "anthropic")
            ])
        case .claudeCLI:
            source = ModelsDevModelsSource(provider: "anthropic", excludeDatedSnapshots: true)
        }
        self.seed = ProviderModelList(models: seed.map {
            ProviderModel(id: $0, family: AnthropicModelFamily.family(of: $0))
        })
    }

    public func displayName(for id: String) -> String {
        AnthropicModelFamily.displayName(of: id) ?? id
    }

    public func resolve(_ id: String) -> String {
        Self.resolve(id, in: list)
    }

    /// `id` when it is a full model id; for a bare alias, the latest model of
    /// that family in `list`, or the alias itself when the list has none.
    public nonisolated static func resolve(_ id: String, in list: ProviderModelList) -> String {
        guard let family = AnthropicModelFamily.aliasFamily(of: id) else { return id }
        return list.latestIDs.first { AnthropicModelFamily.family(of: $0) == family } ?? id
    }
}

/// An OpenAI or OpenAI-compatible endpoint (OpenAI, Groq, Ollama, ...): its
/// `/models`, ids only, every one current.
@MainActor
public final class OpenAICompatibleModelManager: ProviderModelManager {
    public let source: (any ProviderModelSource)?
    public let seed: ProviderModelList

    public init(baseURL: String, apiKey: String?, seed: [String]) {
        source = baseURL.isEmpty ? nil : OpenAICompatibleModelsSource(baseURL: baseURL, apiKey: apiKey)
        self.seed = ProviderModelList(ids: seed)
    }

    public func displayName(for id: String) -> String { id }
    public func resolve(_ id: String) -> String { id }
}

/// A provider with no listing: the descriptor's list is the list.
@MainActor
public final class StaticModelManager: ProviderModelManager {
    public let source: (any ProviderModelSource)? = nil
    public let seed: ProviderModelList

    public init(seed: [String]) { self.seed = ProviderModelList(ids: seed) }

    public func displayName(for id: String) -> String { id }
    public func resolve(_ id: String) -> String { id }
}

/// Picks a provider configuration's model manager.
public enum ProviderModels {
    /// The manager for a provider configuration, chosen by its template:
    /// `anthropic-api` and `claude-max-token` use Anthropic over the API,
    /// `claude-local` Anthropic through the CLI, an OpenAI-style plugin its
    /// endpoint, and anything else its static list.
    @MainActor
    public static func manager(pluginIdentifier: String,
                               template: AIPluginDescriptor.ProviderTemplate,
                               baseURL: String?, apiKey: String?) -> any ProviderModelManager {
        let resolvedBase = (baseURL?.isEmpty == false ? baseURL : nil)
            ?? template.defaultValues["baseURL"] ?? ""
        switch template.id {
        case "anthropic-api", "claude-max-token":
            let oauth = template.defaultValues["authMode"] == "bearer-oauth"
            return AnthropicModelManager(
                access: .api(baseURL: resolvedBase, apiKey: apiKey, oauth: oauth), seed: template.models)
        case "claude-local":
            return AnthropicModelManager(access: .claudeCLI, seed: template.models)
        default:
            if isOpenAIStyle(pluginIdentifier: pluginIdentifier) {
                return OpenAICompatibleModelManager(baseURL: resolvedBase, apiKey: apiKey, seed: template.models)
            }
            return StaticModelManager(seed: template.models)
        }
    }

    /// True for plugins whose endpoints answer OpenAI's `GET /models`.
    public static func isOpenAIStyle(pluginIdentifier: String) -> Bool {
        pluginIdentifier.hasSuffix(".openai") || pluginIdentifier.hasSuffix(".openai-compatible")
    }
}
