import Foundation

extension Sessions {

    /// Which kind of Claude Code conversation a request belongs to.
    public enum ModelThreadKind: String, Codable, Sendable, CaseIterable { case main, subagent, side, other }

    /// The model family a Claude model id names.
    public enum ModelFamily: String, Codable, Sendable, CaseIterable {
        case haiku, sonnet, opus, other

        /// The Claude models a tier can be served by, smallest first.
        public static let routable: [ModelFamily] = [.haiku, .sonnet, .opus]

        /// Smallest first; nil for a model that is never routed.
        public var size: Int? { Self.routable.firstIndex(of: self) }

        /// How a tier target naming this family is shown.
        public var modelTitle: String {
            switch self {
            case .haiku: return "Claude Haiku 5.5"
            case .sonnet: return "Claude Sonnet 5.5"
            case .opus: return "Claude Opus 5.5"
            case .other: return "Claude"
            }
        }
    }

    /// One tier a template defines. A template lists its tiers smallest first,
    /// and that order is the ranking routing compares by: a request is only ever
    /// sent down it, never up.
    public struct ModelTierDTO: Codable, Sendable, Equatable, Identifiable {
        public var id: String
        public var name: String

        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }

    /// What serves a tier: one of the Claude models, or an LLM Provider
    /// configuration, optionally with one of its models instead of its own.
    /// Written `claude:<haiku|sonnet|opus>` or `provider:<uuid>[/<model>]`.
    public enum ModelTierTarget: Hashable, Sendable {
        case claude(ModelFamily)
        case provider(UUID, model: String?)

        private static let claudePrefix = "claude:"
        private static let providerPrefix = "provider:"

        public init?(_ text: String) {
            if text.hasPrefix(Self.claudePrefix) {
                guard let family = ModelFamily(rawValue: String(text.dropFirst(Self.claudePrefix.count))),
                      family.size != nil else { return nil }
                self = .claude(family)
                return
            }
            guard text.hasPrefix(Self.providerPrefix) else { return nil }
            let rest = text.dropFirst(Self.providerPrefix.count)
            // A model id may itself hold slashes (`org/model`), so only the first one separates.
            let idText = rest.prefix { $0 != "/" }
            guard let id = UUID(uuidString: String(idText)) else { return nil }
            let model = rest.dropFirst(idText.count).dropFirst()
            if rest.count > idText.count {
                guard !model.isEmpty,
                      !model.unicodeScalars.contains(where: ModelRouterTemplateValidation.isRefusedInName),
                      model.count <= 200 else { return nil }
                self = .provider(id, model: String(model))
            } else {
                self = .provider(id, model: nil)
            }
        }

        public var text: String {
            switch self {
            case .claude(let family): return Self.claudePrefix + family.rawValue
            case .provider(let id, let model):
                return Self.providerPrefix + id.uuidString + (model.map { "/\($0)" } ?? "")
            }
        }

        /// The provider configuration this target names; nil for a Claude model.
        public var providerId: UUID? {
            if case .provider(let id, _) = self { return id }
            return nil
        }
    }

    /// Every condition that is set must hold for a request definition to match; unset ones are ignored.
    /// A stored or imported request that still carries the retired `writes` or
    /// `max_tokens` keys decodes fine: those keys are ignored.
    public struct ModelRouteConditionsDTO: Codable, Sendable, Equatable {
        public var thread: ModelThreadKind?
        /// Its tools include Bash.
        public var commands: Bool?
        /// Its system prompt (the instructions Claude Code wrote for it) contains this text, case and all.
        public var system: String?
        /// Its latest user message contains this text, case and all.
        public var message: String?

        public init(
            thread: ModelThreadKind? = nil, commands: Bool? = nil, system: String? = nil, message: String? = nil
        ) {
            self.thread = thread
            self.commands = commands
            self.system = system
            self.message = message
        }
    }

    /// One kind of request the router recognizes on its own, as a template
    /// defines it. Which tier it goes to is the template's `request_tiers`, not
    /// the request's own: a request that still carries the format-2 `tier` or the
    /// retired `about` decodes fine, and those keys are ignored here.
    public struct ModelRequestKindDTO: Codable, Sendable, Equatable, Identifiable {
        public static let unclassifiedId = "unclassified"
        public static let unclassifiedName = "Unclassified"

        public var id: String
        public var name: String
        public var when: ModelRouteConditionsDTO

        public init(id: String, name: String, when: ModelRouteConditionsDTO) {
            self.id = id
            self.name = name
            self.when = when
        }

        /// `^[a-z0-9][a-z0-9-]{0,63}$`, and not `unclassified` unless `allowUnclassified`.
        public static func isValidId(_ id: String, allowUnclassified: Bool = false) -> Bool {
            if id == unclassifiedId { return allowUnclassified }
            return id.range(of: "^[a-z0-9][a-z0-9-]{0,63}\\z", options: .regularExpression) != nil
        }
    }

    /// Decodes one array element, or nil when it does not decode, so one bad
    /// element is dropped rather than the whole array. Keeps the decoder's key
    /// strategy, unlike re-encoding the element.
    struct LossyDecoded<Value: Decodable>: Decodable {
        let value: Value?

        init(from decoder: Decoder) throws {
            value = try? Value(from: decoder)
        }
    }

    /// The model router's settings as a partial write: a nil field leaves its stored
    /// row untouched, so a caller sends only what it means to change and never
    /// reads-then-writes back what another writer may have changed meanwhile.
    public struct ModelRouterPreferencesDTO: Codable, Sendable, Equatable {
        public var enabled: Bool?
        /// Create or replace a user template (the daemon refuses a built-in's id).
        public var saveTemplate: ModelRouterTemplateDTO?
        public var deleteTemplate: String?
        public var preferTemplate: String?
        public var unpreferTemplate: String?

        public init(
            enabled: Bool? = nil,
            saveTemplate: ModelRouterTemplateDTO? = nil, deleteTemplate: String? = nil,
            preferTemplate: String? = nil, unpreferTemplate: String? = nil
        ) {
            self.enabled = enabled
            self.saveTemplate = saveTemplate
            self.deleteTemplate = deleteTemplate
            self.preferTemplate = preferTemplate
            self.unpreferTemplate = unpreferTemplate
        }
    }

    /// One configured AI provider a `provider:<id>` tier target can name. Secret-free: no key, no URL.
    public struct ModelRouterProviderDTO: Codable, Sendable, Equatable {
        public let id: String
        public let name: String
        /// The configuration's own model, used by a target that names none.
        public let model: String
        /// The daemon can build a route for it right now.
        public let usable: Bool
        /// Every model the provider's catalog lists for this configuration, for a
        /// `provider:<id>/<model>` target; nil from a daemon that sends none.
        public let models: [String]?

        public init(id: String, name: String, model: String, usable: Bool, models: [String]? = nil) {
            self.id = id
            self.name = name
            self.model = model
            self.usable = usable
            self.models = models
        }
    }

    public struct ModelRouterStatusDTO: Codable, Sendable, Equatable {
        public let enabled: Bool
        public let providers: [ModelRouterProviderDTO]
        public let templates: [ModelRouterTemplateDTO]?
        /// Ids of preferred templates.
        public let preferred: [String]?
        /// Template files skipped, each "<file>: <reason>".
        public let skipped: [String]?
        public let clientVersion: String?
        /// Id of the template last used for a request.
        public let inUse: String?
        public let inUseIsFallback: Bool?

        public init(
            enabled: Bool, providers: [ModelRouterProviderDTO], templates: [ModelRouterTemplateDTO]? = nil,
            preferred: [String]? = nil, skipped: [String]? = nil, clientVersion: String? = nil,
            inUse: String? = nil, inUseIsFallback: Bool? = nil
        ) {
            self.templates = templates
            self.preferred = preferred
            self.skipped = skipped
            self.clientVersion = clientVersion
            self.inUse = inUse
            self.inUseIsFallback = inUseIsFallback
            self.enabled = enabled
            self.providers = providers
        }
    }

    /// One `steno router report` line per (requested, served, provider).
    public struct ModelUsageRowDTO: Codable, Sendable, Equatable {
        public let requestedModel: String?
        public let servedModel: String?
        /// The provider configuration's name; nil when Anthropic served it.
        public let provider: String?
        public let requests: Int
        public let inputTokens: Int
        public let outputTokens: Int
        public let cacheReadTokens: Int
        public let cacheCreationTokens: Int

        public init(
            requestedModel: String?, servedModel: String?, provider: String?, requests: Int, inputTokens: Int,
            outputTokens: Int, cacheReadTokens: Int, cacheCreationTokens: Int
        ) {
            self.requestedModel = requestedModel
            self.servedModel = servedModel
            self.provider = provider
            self.requests = requests
            self.inputTokens = inputTokens
            self.outputTokens = outputTokens
            self.cacheReadTokens = cacheReadTokens
            self.cacheCreationTokens = cacheCreationTokens
        }
    }
}
