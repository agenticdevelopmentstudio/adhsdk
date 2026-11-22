import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class ModelRoutingPolicyTests: XCTestCase {
    private let requests = Sessions.ModelRouterTemplateDTO.builtInRequests

    private func facts(
        model: String = "claude-opus-5-5", thread: Sessions.ModelThreadKind = .subagent, writes: Bool = false,
        commands: Bool = false, tokens: Int = 1000, maxTokens: Int? = nil
    ) -> ModelRequestFacts {
        ModelRequestFacts(
            requestedModel: model, family: ModelRequestFacts.family(of: model), thread: thread, writes: writes,
            commands: commands, estimatedInputTokens: tokens, maxTokens: maxTokens, threadKey: "k")
    }

    private func decide(
        _ facts: ModelRequestFacts, template: Sessions.ModelRouterTemplateDTO? = nil,
        remembered: ModelThreadMemory.Entry? = nil, window: @escaping (String) -> Int? = { _ in nil }
    ) -> ModelDecision {
        ModelRoutingPolicy.decide(
            facts, template: template ?? self.template(), remembered: remembered, window: window)
    }

    /// The built-in with request tiers (`unclassified` included) and tier targets changed.
    private func template(
        _ requestTiers: [String: String] = [:], targets: [String: String] = [:],
        requests: [Sessions.ModelRequestKindDTO]? = nil
    ) -> Sessions.ModelRouterTemplateDTO {
        var template = Sessions.ModelRouterTemplateDTO.builtIns[0]
        if let requests {
            template.requests = requests
            template.requestTiers = Sessions.ModelRouterTemplateDTO.defaultRequestTiers(for: requests)
        }
        template.requestTiers.merge(requestTiers) { _, new in new }
        template.tierTargets.merge(targets) { _, new in new }
        return template
    }

    func testTheMainConversationIsNeverRouted() {
        XCTAssertEqual(decide(facts(thread: .main)),
                       ModelDecision(target: .keep, rule: "Your conversation (never routed)"))
        XCTAssertEqual(decide(facts(model: "claude-fable-5-1", thread: .main)).rule,
                       "Your conversation (never routed)")
    }

    func testOnlyHaikuSonnetAndOpusAreRouted() {
        XCTAssertEqual(decide(facts(model: "claude-fable-5-1")),
                       ModelDecision(target: .keep, rule: "model: claude-fable-5-1 is not routed", kind: .notRouted))
    }

    func testEachBuiltInRequestGoesToItsDefaultTier() {
        XCTAssertEqual(decide(facts(commands: true)),
                       ModelDecision(target: .model("claude-sonnet-5-5"), rule: "Command subagent → Standard"))
        XCTAssertEqual(decide(facts()),
                       ModelDecision(target: .model("claude-haiku-5-5"), rule: "Search subagent → Light"))
        XCTAssertEqual(decide(facts(thread: .side)),
                       ModelDecision(target: .model("claude-haiku-5-5"), rule: "Background task → Light"))
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.builtInRequests.suffix(3).map(\.id),
                       ["background", "search-subagent", "command-subagent"])
    }

    func testAKnownKindIsRecognizedByItsTextBeforeTheFallbacks() {
        var explore = facts(commands: true)
        explore.systemText = "You are a file search specialist for Claude Code, Anthropic's official CLI for Claude."
        XCTAssertEqual(decide(explore),
                       ModelDecision(target: .model("claude-haiku-5-5"), rule: "Explore subagent → Light"))
        var plan = facts(commands: true)
        plan.systemText = "You are a software architect and planning specialist for Claude Code."
        XCTAssertEqual(decide(plan), ModelDecision(target: .keep, rule: "Plan subagent → Heavy"))
        var title = facts(thread: .side)
        title.messageText = "Please generate a title and branch name for this session"
        XCTAssertEqual(decide(title).rule, "Teleport title and branch → Light")
        var elsewhere = facts(thread: .side)
        elsewhere.systemText = "Please generate a title and branch name for this session"
        XCTAssertEqual(decide(elsewhere).rule, "Background task → Light",
                       "message text is not looked for in the system")
    }

    func testWritingNoLongerMattersOnlyCommandsDo() {
        XCTAssertEqual(decide(facts(writes: true)),
                       ModelDecision(target: .model("claude-haiku-5-5"), rule: "Search subagent → Light"),
                       "a subagent that writes but runs no commands is a search subagent")
        XCTAssertEqual(decide(facts(writes: true, commands: true)).rule, "Command subagent → Standard")
    }

    func testAStoredEditingSubagentRequestStillMatchesByItsRemainingConditions() throws {
        let json = #"{"id":"editing-subagent","name":"Editing subagent","when":{"thread":"subagent","writes":true}}"#
        let legacy = try JSONDecoder().decode(Sessions.ModelRequestKindDTO.self, from: Data(json.utf8))
        XCTAssertEqual(decide(facts(), template: template(requests: [legacy])),
                       ModelDecision(target: .keep, rule: "Editing subagent → Heavy"))
    }

    func testRoutingOnlyLowers() {
        let mapped = template(["search-subagent": "heavy"])
        XCTAssertEqual(decide(facts(model: "claude-haiku-5-5"), template: mapped),
                       ModelDecision(target: .keep, rule: "Search subagent → Light"))
        XCTAssertEqual(decide(facts(model: "claude-sonnet-5-5", thread: .other)),
                       ModelDecision(target: .keep, rule: "Unclassified → Standard"))
    }

    func testUnknownRequestsTakeTheTemplatesUnclassifiedTier() {
        XCTAssertEqual(decide(facts(thread: .other)),
                       ModelDecision(target: .keep, rule: "Unclassified → Heavy"))
        XCTAssertEqual(decide(facts(thread: .other), template: template(["unclassified": "standard"])),
                       ModelDecision(target: .model("claude-sonnet-5-5"), rule: "Unclassified → Standard"))
        XCTAssertEqual(decide(facts(model: "claude-sonnet-5-5", thread: .other)).target, .keep,
                       "never raised above the requested model")
    }

    func testTheTemplatesPerRequestTierIsUsed() {
        let edited = template(["command-subagent": "light", "search-subagent": "standard"])
        XCTAssertEqual(decide(facts(commands: true), template: edited),
                       ModelDecision(target: .model("claude-haiku-5-5"), rule: "Command subagent → Light"))
        XCTAssertEqual(decide(facts(), template: edited),
                       ModelDecision(target: .model("claude-sonnet-5-5"), rule: "Search subagent → Standard"))
        XCTAssertEqual(decide(facts(model: "claude-haiku-5-5"), template: edited).rule, "Search subagent → Light",
                       "a request asking for a smaller model stays at its own size")
    }

    func testAProviderTargetSendsTheTierThere() {
        let id = UUID()
        let routed = template(targets: ["light": Sessions.ModelTierTarget.provider(id, model: nil).text])
        XCTAssertEqual(decide(facts(), template: routed),
                       ModelDecision(target: .provider(id, model: nil), rule: "Search subagent → Light"))
        XCTAssertEqual(decide(facts(model: "claude-haiku-5-5"), template: routed).target, .provider(id, model: nil),
                       "a provider serves the tier even when it equals the requested one")
        XCTAssertEqual(decide(facts(thread: .main), template: routed).target, .keep)
        let named = template(targets: ["light": Sessions.ModelTierTarget.provider(id, model: "qwen").text])
        XCTAssertEqual(decide(facts(), template: named).target, .provider(id, model: "qwen"))
    }

    /// Lowering reads the template's own tiers, whatever they are called.
    func testATemplatesOwnTiersAndTheirModelsDecide() {
        let provider = UUID()
        var own = template(requests: Sessions.ModelRouterTemplateDTO.builtInRequests)
        own.tiers = [Sessions.ModelTierDTO(id: "small", name: "Small"), Sessions.ModelTierDTO(id: "big", name: "Big")]
        own.requestTiers = ["background": "small", "search-subagent": "big", "command-subagent": "big",
                            "unclassified": "big"]
        own.tierTargets = ["small": Sessions.ModelTierTarget.claude(.haiku).text,
                           "big": Sessions.ModelTierTarget.provider(provider, model: nil).text]
        XCTAssertEqual(decide(facts(model: "claude-sonnet-5-5"), template: own),
                       ModelDecision(target: .provider(provider, model: nil), rule: "Search subagent → Big"),
                       "no Claude tier is Sonnet's size, so Sonnet sits at the top")
        XCTAssertEqual(decide(facts(model: "claude-haiku-5-5"), template: own),
                       ModelDecision(target: .keep, rule: "Search subagent → Small"),
                       "Haiku sits at Small, the lower of the two")
        XCTAssertEqual(decide(facts(thread: .side), template: own),
                       ModelDecision(target: .model("claude-haiku-5-5"), rule: "Background task → Small"))
    }

    func testAMissingTierOrModelKeepsTheRequest() {
        var noTier = template()
        noTier.requestTiers = [:]
        XCTAssertEqual(decide(facts(), template: noTier),
                       ModelDecision(target: .keep, rule: "Search subagent (no tier)"))
        var noModel = template()
        noModel.tierTargets["light"] = nil
        XCTAssertEqual(decide(facts(), template: noModel),
                       ModelDecision(target: .keep, rule: "Search subagent → Light (no model)"))
    }

    func testStickyAndRevert() {
        let first = decide(facts())
        let entry = ModelThreadMemory.Entry(requestedModel: "claude-opus-5-5", decision: first, reverted: false)
        let sticky = decide(facts(thread: .side), remembered: entry)
        XCTAssertEqual(sticky.target, first.target)
        XCTAssertEqual(sticky.rule, "sticky: Search subagent → Light")
        let again = ModelThreadMemory.Entry(requestedModel: "claude-opus-5-5", decision: sticky, reverted: false)
        XCTAssertEqual(decide(facts(), remembered: again).rule, sticky.rule)
        let reverted = ModelThreadMemory.Entry(requestedModel: "claude-opus-5-5", decision: first, reverted: true)
        XCTAssertEqual(decide(facts(), remembered: reverted),
                       ModelDecision(target: .keep, rule: "sticky: reverted", kind: .sticky))
        let other = ModelThreadMemory.Entry(requestedModel: "claude-sonnet-5-5", decision: first, reverted: true)
        XCTAssertEqual(decide(facts(), remembered: other).target, first.target, "a model change re-decides")
    }

    func testMainIsNeverRoutedByARememberedForkDecision() {
        // A fork shares main's thread key; its routed decision, remembered first, must not carry over.
        let fork = decide(facts())
        XCTAssertNotEqual(fork.target, .keep)
        let entry = ModelThreadMemory.Entry(requestedModel: "claude-opus-5-5", decision: fork, reverted: false)
        XCTAssertEqual(decide(facts(thread: .main), remembered: entry),
                       ModelDecision(target: .keep, rule: ModelRoutingPolicy.mainThreadRule))
    }

    func testStickyDropsOnlyItsOwnPrefixNeverTheRequestsText() {
        let named = template(["notes": "light"], requests: [Sessions.ModelRequestKindDTO(
            id: "notes", name: "sticky: notes", when: .init(thread: .subagent))])
        let first = decide(facts(), template: named)
        XCTAssertEqual(first, ModelDecision(target: .model("claude-haiku-5-5"), rule: "sticky: notes → Light"))
        var entry = ModelThreadMemory.Entry(requestedModel: "claude-opus-5-5", decision: first, reverted: false)
        let sticky = decide(facts(), remembered: entry)
        XCTAssertEqual(sticky, ModelDecision(
            target: .model("claude-haiku-5-5"), rule: "sticky: sticky: notes → Light", kind: .sticky))
        entry = ModelThreadMemory.Entry(requestedModel: "claude-opus-5-5", decision: sticky, reverted: false)
        XCTAssertEqual(decide(facts(), remembered: entry), sticky)
    }

    func testWindowGuard() {
        let big = facts(model: "claude-sonnet-5-5", tokens: 190_000, maxTokens: 20_000)
        XCTAssertEqual(decide(big, window: { _ in 200_000 }),
                       ModelDecision(target: .keep, rule: "keep: too large for claude-haiku-5-5"))
        XCTAssertEqual(decide(big).target, .model("claude-haiku-5-5"))
    }

    func testModelID() {
        XCTAssertNil(ModelRoutingPolicy.modelID(for: .sonnet, requested: "claude-3"))
        XCTAssertNil(ModelRoutingPolicy.modelID(for: .other, requested: "claude-opus-5-5"))
        XCTAssertEqual(ModelRoutingPolicy.modelID(for: .sonnet, requested: "claude-opus-5-5"), "claude-sonnet-5-5")
        XCTAssertEqual(ModelRoutingPolicy.modelID(for: .haiku, requested: "claude-Opus-5-5"), "claude-haiku-5-5")
    }

    func testModelIDKeepsANonASCIIPrefixIntact() {
        // "İ" lowercases to two Characters; the replaced range must still be the family word.
        XCTAssertEqual(ModelRoutingPolicy.modelID(for: .haiku, requested: "claude-İİ-opus-5"), "claude-İİ-haiku-5")
        XCTAssertEqual(ModelRoutingPolicy.modelID(for: .sonnet, requested: "claude-ﬀ-OPUS"), "claude-ﬀ-sonnet")
    }

    func testWindowFloor() {
        XCTAssertEqual(ModelRoutingPolicy.window(for: "claude-haiku-zz"), 200_000)
        XCTAssertNil(ModelRoutingPolicy.window(for: "claude-unknown-zz"))
    }

    func testMemoryEvictsLeastRecentlyUsed() {
        let memory = ModelThreadMemory(capacity: 2)
        let entry = ModelThreadMemory.Entry(
            requestedModel: "m", decision: ModelDecision(target: .keep, rule: "r"), reverted: false)
        memory.remember("a", entry)
        memory.remember("b", entry)
        _ = memory.entry("a")
        memory.remember("c", entry)
        XCTAssertNotNil(memory.entry("a"))
        XCTAssertNil(memory.entry("b"))
        memory.markReverted("a")
        XCTAssertEqual(memory.entry("a")?.reverted, true)
    }

    func testWindowGuardNeverTrapsOnHugeOrNegativeNumbers() {
        let huge = facts(model: "claude-sonnet-5-5", tokens: 1000, maxTokens: Int.max)
        XCTAssertEqual(decide(huge, window: { _ in 200_000 }),
                       ModelDecision(target: .keep, rule: "keep: too large for claude-haiku-5-5"))
        let both = facts(model: "claude-sonnet-5-5", tokens: Int.max, maxTokens: Int.max)
        XCTAssertEqual(decide(both, window: { _ in Int.max }).target, .keep)
        let negative = facts(model: "claude-sonnet-5-5", tokens: 1000, maxTokens: -5)
        XCTAssertEqual(decide(negative, window: { _ in 200_000 }).target, .model("claude-haiku-5-5"))
    }
}
