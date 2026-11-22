#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation

struct ModelDecision: Equatable, Sendable {
    enum Target: Equatable, Sendable { case keep, model(String), provider(UUID, model: String?) }
    /// What the rule names, so the planner never reads the rule's text.
    enum Kind: Equatable, Sendable {
        /// Decided under the template: the planner prefixes its name.
        case template
        /// `model: <id> is not routed`: names no template.
        case notRouted
        /// `sticky: <earlier rule>`: the earlier rule already carries its prefix.
        case sticky
    }
    let target: Target
    /// `<request> → <tier>`, `Your conversation (never routed)`, `keep: too large
    /// for <id>` (the planner prefixes the template's name), or the unprefixed
    /// `model: <id> is not routed` and `sticky: …`.
    let rule: String
    let kind: Kind

    init(target: Target, rule: String, kind: Kind = .template) {
        self.target = target
        self.rule = rule
        self.kind = kind
    }
}

enum ModelRoutingPolicy {
    private static let stickyPrefix = "sticky: "
    static let mainThreadRule = "Your conversation (never routed)"

    /// The spec's steps: the main thread, sticky, the requested family, the
    /// request, its tier in `template` (only ever lowered) and that tier's target.
    ///
    /// Lowered means: the requested model sits at the first tier a Claude
    /// model at least its size serves (the top tier when none does), and the
    /// request goes to whichever of that tier and its own is lower. A Claude
    /// model there that is not smaller than the one asked for keeps the
    /// request as it is, so nothing is ever sent to a larger model.
    static func decide(
        _ facts: ModelRequestFacts, template: Sessions.ModelRouterTemplateDTO,
        remembered: ModelThreadMemory.Entry?, window: (String) -> Int?
    ) -> ModelDecision {
        // Before sticky: a fork shares main's thread key, and its remembered decision must never route main.
        if facts.thread == .main { return ModelDecision(target: .keep, rule: mainThreadRule) }
        if let remembered, remembered.requestedModel == facts.requestedModel {
            if remembered.reverted {
                return ModelDecision(target: .keep, rule: stickyPrefix + "reverted", kind: .sticky)
            }
            let earlier = remembered.decision
            // A sticky rule is always `stickyPrefix + <earlier rule>`: drop exactly that, never a request's own text.
            let rule = earlier.kind == .sticky ? String(earlier.rule.dropFirst(stickyPrefix.count)) : earlier.rule
            return ModelDecision(target: earlier.target, rule: stickyPrefix + rule, kind: .sticky)
        }
        guard let requestedSize = facts.family.size else {
            return ModelDecision(target: .keep, rule: "model: \(facts.requestedModel) is not routed", kind: .notRouted)
        }
        let request = template.requests.first(where: { matches($0.when, facts) })
        let requestName = request?.name ?? Sessions.ModelRequestKindDTO.unclassifiedName
        guard let tierId = template.tierId(forRequest: request?.id ?? Sessions.ModelRequestKindDTO.unclassifiedId),
              let own = template.rank(ofTier: tierId)
        else { return ModelDecision(target: .keep, rule: "\(requestName) (no tier)") }
        let sits = template.tiers.firstIndex { tier in
            guard case .claude(let family)? = template.target(forTier: tier.id), let size = family.size else {
                return false
            }
            return size >= requestedSize
        } ?? template.tiers.count - 1
        let routed = template.tiers[min(own, sits)]
        let rule = "\(requestName) → \(routed.name)"
        switch template.target(forTier: routed.id) {
        case .provider(let id, let model)?:
            return ModelDecision(target: .provider(id, model: model), rule: rule)
        case .claude(let family)?:
            guard let size = family.size, size < requestedSize,
                  let id = modelID(for: family, requested: facts.requestedModel), id != facts.requestedModel
            else { return ModelDecision(target: .keep, rule: rule) }
            if let limit = window(id) {
                // Request-derived numbers: an overflow is too large, never a trap.
                let (need, overflow) = facts.estimatedInputTokens.addingReportingOverflow(facts.maxTokens ?? 0)
                if overflow || limit < need {
                    return ModelDecision(target: .keep, rule: "keep: too large for \(id)")
                }
            }
            return ModelDecision(target: .model(id), rule: rule)
        case nil:
            return ModelDecision(target: .keep, rule: "\(rule) (no model)")
        }
    }

    private static func matches(_ when: Sessions.ModelRouteConditionsDTO, _ facts: ModelRequestFacts) -> Bool {
        if let thread = when.thread, thread != facts.thread { return false }
        if let commands = when.commands, commands != facts.commands { return false }
        if let system = when.system, !system.isEmpty, !facts.systemText.contains(system) { return false }
        if let message = when.message, !message.isEmpty, !facts.messageText.contains(message) { return false }
        return true
    }

    /// The requested id with its family word replaced by `family`'s; nil for
    /// `.other` or an id naming no family.
    static func modelID(for family: Sessions.ModelFamily, requested: String) -> String? {
        guard family != .other else { return nil }
        for word in ["haiku", "sonnet", "opus"] {
            guard let range = requested.range(of: word, options: .caseInsensitive) else { continue }
            return requested.replacingCharacters(in: range, with: family.rawValue)
        }
        return nil
    }

    /// Catalog window for an id, else the family floor (haiku 200_000; others unbounded).
    static func window(for id: String) -> Int? {
        if let offering = offering(for: id), let window = offering.contextWindow { return window }
        return ModelRequestFacts.family(of: id) == .haiku ? 200_000 : nil
    }

    /// Catalog output limit for an id, nil when unknown.
    static func maxOutput(for id: String) -> Int? {
        offering(for: id)?.maxOutput
    }

    private static func offering(for id: String) -> AIModelCatalog.Offering? {
        let offerings = AIModelCatalog.shared.offerings
        if let found = offerings["anthropic-api"]?[id] { return found }
        for (_, byModel) in offerings.sorted(by: { $0.key < $1.key }) {
            if let found = byModel[id] { return found }
        }
        return nil
    }
}
#endif
