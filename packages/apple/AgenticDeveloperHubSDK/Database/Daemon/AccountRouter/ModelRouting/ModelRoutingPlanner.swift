#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation

/// What one request sends upstream as its body, and why. Never printed with
/// the body: only model ids, the rule and the thread kind are logged.
struct ModelPlan: Sendable {
    /// What to send (the original bytes when untouched).
    let body: Data
    let original: Data
    let requestedModel: String?
    /// Non-nil only when `body`'s `model` was rewritten.
    let routedModel: String?
    /// The provider configuration a `provider:` tier target chose; nil for Anthropic.
    let provider: UUID?
    /// The `model_rule` column; nil when model routing is off.
    let rule: String?
    let thread: Sessions.ModelThreadKind?
    let writes: Bool?
    /// The thread memory key; nil when the request was never a candidate.
    let threadKey: String?
    /// Where the first attempt goes instead of Anthropic; `body` is already in
    /// its wire format. nil once the request has fallen back.
    var providerRoute: ProviderRoute?
    /// The client asked for a stream (`"stream": true`); read only for a provider.
    var providerStreams = false

    static func untouched(_ body: Data) -> ModelPlan {
        ModelPlan(body: body, original: body, requestedModel: nil, routedModel: nil, provider: nil, rule: nil,
                  thread: nil, writes: nil, threadKey: nil)
    }

    /// The same request sent with its original bytes after upstream refused
    /// the rewritten one with `status`.
    func reverted(after status: Int) -> ModelPlan {
        ModelPlan(body: original, original: original, requestedModel: requestedModel, routedModel: nil,
                  provider: provider, rule: (rule.map { "\($0) " } ?? "") + "(reverted after \(status))",
                  thread: thread, writes: writes, threadKey: threadKey)
    }

    /// The provider attempt failed (`reason`, e.g. `provider 401`): Anthropic
    /// gets the original bytes, and the row says why.
    func fellBack(_ reason: String) -> ModelPlan {
        ModelPlan(body: original, original: original, requestedModel: requestedModel, routedModel: nil,
                  provider: nil, rule: (rule.map { "\($0) " } ?? "") + "(fell back: \(reason))",
                  thread: thread, writes: writes, threadKey: threadKey)
    }
}

/// Chooses each request's body. Implementations never throw: every fault is
/// an untouched plan, so the original bytes go upstream.
protocol ModelPlanning: Sendable {
    func plan(_ head: RouterRequestHead, body: Data) -> ModelPlan
    /// Upstream refused `plan`'s rewritten body with `status`: later requests
    /// on its thread keep their model.
    func reverted(_ plan: ModelPlan, status: Int)
    /// `plan`'s provider attempt fell back to Anthropic: later requests on its
    /// thread keep their model and go straight to Anthropic, as after a revert.
    func fellBack(_ plan: ModelPlan)
}

/// Sends every body as it came, with no rule.
struct PassModelPlanner: ModelPlanning {
    func plan(_ head: RouterRequestHead, body: Data) -> ModelPlan { .untouched(body) }
    func reverted(_ plan: ModelPlan, status: Int) {}
    func fellBack(_ plan: ModelPlan) {}
}

/// The production `ModelPlanning`: settings, facts, policy, thread memory,
/// rewrite. Runs once per request, after the account plan.
final class ModelRoutingPlanner: ModelPlanning, Sendable {
    private let settings: @Sendable () -> ModelRouterSettings
    private let memory: ModelThreadMemory
    private let window: @Sendable (String) -> Int?
    private let maxOutput: @Sendable (String) -> Int?
    private let providers: any ModelProviderResolving
    private let versions: ModelClientVersionMemory
    private let health: ModelProviderHealth

    init(
        settings: @escaping @Sendable () -> ModelRouterSettings,
        memory: ModelThreadMemory = ModelThreadMemory(),
        window: @escaping @Sendable (String) -> Int? = { ModelRoutingPolicy.window(for: $0) },
        maxOutput: @escaping @Sendable (String) -> Int? = { ModelRoutingPolicy.maxOutput(for: $0) },
        providers: any ModelProviderResolving = NoModelProviders(),
        versions: ModelClientVersionMemory = ModelClientVersionMemory(),
        health: ModelProviderHealth = ModelProviderHealth()
    ) {
        self.versions = versions
        self.health = health
        self.settings = settings
        self.memory = memory
        self.window = window
        self.maxOutput = maxOutput
        self.providers = providers
    }

    func plan(_ head: RouterRequestHead, body: Data) -> ModelPlan {
        let current = settings()
        guard current.enabled else { return .untouched(body) }
        // Only the parsed version is kept or logged, never the User-Agent itself.
        let version = Sessions.ClaudeCodeVersion.fromUserAgent(head.value("User-Agent"))
        if let version { versions.note(version) }
        guard let selection = Sessions.ModelRouterTemplateSelector.select(
            current.templates, preferred: current.preferred, version: version)
        else { return .untouched(body) }
        let template = selection.template
        let facts: ModelRequestFacts
        let object: [String: Any]
        switch ModelRequestFacts.extract(head: head, body: body) {
        case .failure(let reason):
            return Self.log(passthrough(body, rule: "model: passthrough (\(reason.rawValue))"))
        case .success(let extracted):
            (facts, object) = extracted
        }
        let remembered = memory.entry(facts.threadKey)
        var decision = ModelRoutingPolicy.decide(
            facts, template: template, remembered: remembered, window: window)
        // `sticky: …` already carries its prefix; `model: <id> is not routed` names no template.
        if decision.kind == .template {
            decision = ModelDecision(target: decision.target, rule: "\(template.name) › \(decision.rule)")
        }
        // Main is decided before sticky and never reads memory; remembering its
        // keep would pin every fork that shares its thread key.
        if facts.thread != .main {
            // A reverted thread stays reverted while it asks for the same model.
            let stillReverted = remembered?.reverted == true && remembered?.requestedModel == facts.requestedModel
            memory.remember(facts.threadKey, ModelThreadMemory.Entry(
                requestedModel: facts.requestedModel, decision: decision, reverted: stillReverted))
        }

        func kept(_ rule: String) -> ModelPlan {
            ModelPlan(body: body, original: body, requestedModel: facts.requestedModel, routedModel: nil,
                      provider: nil, rule: rule, thread: facts.thread, writes: facts.writes,
                      threadKey: facts.threadKey)
        }
        switch decision.target {
        case .keep:
            return Self.log(kept(decision.rule))
        case .model(let id):
            guard let rewritten = ModelBodyRewriter.rewrite(object, model: id, maxOutput: maxOutput(id)) else {
                return Self.log(kept("\(decision.rule) (rewrite failed)"))
            }
            return Self.log(ModelPlan(
                body: rewritten, original: body, requestedModel: facts.requestedModel, routedModel: id,
                provider: nil, rule: decision.rule, thread: facts.thread, writes: facts.writes,
                threadKey: facts.threadKey))
        case .provider(let id, let model):
            // A plan-time fallback pins the thread like a runtime one, so a key
            // saved mid-conversation never moves it to the provider.
            func fellBack(_ reason: String) -> ModelPlan {
                memory.markReverted(facts.threadKey)
                return Self.log(kept("\(decision.rule) (fell back: \(reason))"))
            }
            if health.isCooling(id) { return fellBack("provider cooling down") }
            let route: ProviderRoute
            switch providers.resolve(id, model: model) {
            case .success(let resolved): route = resolved
            case .failure(let reason): return fellBack(reason.rawValue)
            }
            let translated: Data?
            switch route.wire {
            case .chatCompletions(let maxTokensKey):
                translated = try? AnthropicChatTranslation.chatRequest(
                    fromMessages: body, model: route.model, maxTokensKey: maxTokensKey)
            case .anthropic:
                translated = ModelBodyRewriter.rewrite(object, model: route.model, maxOutput: maxOutput(route.model))
            }
            guard let translated else { return fellBack("untranslatable") }
            return Self.log(ModelPlan(
                body: translated, original: body, requestedModel: facts.requestedModel, routedModel: route.model,
                provider: id, rule: decision.rule, thread: facts.thread, writes: facts.writes,
                threadKey: facts.threadKey, providerRoute: route,
                providerStreams: (object["stream"] as? Bool) == true))
        }
    }

    func reverted(_ plan: ModelPlan, status: Int) {
        guard let key = plan.threadKey else { return }
        memory.markReverted(key)
        let line = AccountRouterLog.scrub(
            "model \(plan.routedModel ?? "-") reverted to \(plan.requestedModel ?? "-") after \(status)")
        AccountRouterLog.logger.info("\(line, privacy: .public)")
    }

    func fellBack(_ plan: ModelPlan) {
        if let id = plan.provider { health.markFailed(id) }
        guard let key = plan.threadKey else { return }
        memory.markReverted(key)
    }

    private func passthrough(_ body: Data, rule: String) -> ModelPlan {
        ModelPlan(body: body, original: body, requestedModel: nil, routedModel: nil, provider: nil, rule: rule,
                  thread: nil, writes: nil, threadKey: nil)
    }

    /// One line per planned request: model ids and the rule, nothing else.
    private static func log(_ plan: ModelPlan) -> ModelPlan {
        let line = AccountRouterLog.scrub(
            "model \(plan.requestedModel ?? "-") -> \(plan.routedModel ?? "kept")"
                + (plan.providerRoute.map { " via \($0.name)" } ?? "") + " (\(plan.rule ?? "-"))")
        AccountRouterLog.logger.info("\(line, privacy: .public)")
        return plan
    }
}
#endif
