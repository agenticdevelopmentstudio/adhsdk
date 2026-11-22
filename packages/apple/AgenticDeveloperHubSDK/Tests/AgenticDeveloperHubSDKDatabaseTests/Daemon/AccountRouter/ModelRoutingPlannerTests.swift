import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class ModelRoutingPlannerTests: XCTestCase {
    private let builtIn = Sessions.ModelRouterTemplateDTO.builtIns[0]

    private let copy = Sessions.ModelRouterTemplateDTO(
        id: "c", name: "C", claudeCode: .init(from: "2.1.300", through: "2.1.310"),
        requests: [
            Sessions.ModelRequestKindDTO(id: "any-subagent", name: "Any subagent", when: .init(thread: .subagent))
        ],
        requestTiers: ["any-subagent": "standard", "unclassified": "heavy"])

    private func planner(
        _ templates: [Sessions.ModelRouterTemplateDTO]? = nil,
        versions: ModelClientVersionMemory = ModelClientVersionMemory()
    ) -> ModelRoutingPlanner {
        var settings = ModelRouterSettings()
        settings.enabled = true
        settings.templates = templates ?? [builtIn, copy]
        let fixed = settings
        return ModelRoutingPlanner(
            settings: { fixed }, window: { _ in nil }, maxOutput: { _ in nil }, versions: versions)
    }

    private func head(userAgent: String?) -> RouterRequestHead {
        RouterRequestHead(
            method: "POST", target: "/v1/messages", version: "HTTP/1.1",
            fields: userAgent.map { [HTTPHeaderField(name: "user-agent", value: $0)] } ?? [])
    }

    private func subagentBody(session: String = "s") -> Data {
        let object: [String: Any] = [
            "model": "claude-opus-5-5", "max_tokens": 1000,
            "system": [["type": "text", "text": "You are a file search specialist \(session)."]],
            "tools": [["name": "Read", "input_schema": ["type": "object"]],
                      ["name": "Grep", "input_schema": ["type": "object"]]],
            "messages": [["role": "user", "content": "find the parser"]]
        ]
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
    }

    private func body(model: String, system: String = "You are a helper.", tools: [String] = ["Read"]) -> Data {
        let object: [String: Any] = [
            "model": model, "max_tokens": 1000,
            "system": system,
            "tools": tools.map { ["name": $0, "input_schema": ["type": "object"]] },
            "messages": [["role": "user", "content": "hi"]]
        ]
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
    }

    func testTheCoveringTemplateDecidesAndPrefixesItsName() {
        let plan = planner().plan(head(userAgent: "claude-cli/2.1.305 (external, cli)"), body: subagentBody())
        XCTAssertEqual(plan.routedModel, "claude-sonnet-5-5")
        XCTAssertEqual(plan.rule, "C › Any subagent → Standard")
    }

    func testTheUserAgentHeaderNameIsMatchedIgnoringCase() {
        for name in ["User-Agent", "USER-AGENT", "uSeR-aGeNt"] {
            let mixed = RouterRequestHead(
                method: "POST", target: "/v1/messages", version: "HTTP/1.1",
                fields: [HTTPHeaderField(name: name, value: "claude-cli/2.1.296")])
            let plan = planner().plan(mixed, body: subagentBody())
            XCTAssertTrue(plan.rule?.hasPrefix("\(builtIn.name) › ") == true, name)
        }
    }

    func testAVersionOutsideTheCopyUsesTheBuiltIn() throws {
        let plan = planner().plan(head(userAgent: "claude-cli/2.1.296"), body: subagentBody())
        XCTAssertEqual(plan.rule, "\(builtIn.name) › Search subagent → Light")
        XCTAssertEqual(plan.routedModel, "claude-haiku-5-5")
    }

    func testTheMainThreadIsPrefixedAndANonRoutedModelIsNot() throws {
        let main = body(model: "claude-opus-5-5", system: "You are Claude Code, Anthropic's official CLI for Claude.")
        let kept = planner().plan(head(userAgent: "claude-cli/2.1.296"), body: main)
        XCTAssertEqual(kept.rule, "\(builtIn.name) › Your conversation (never routed)")
        XCTAssertNil(kept.routedModel)
        let fable = planner().plan(head(userAgent: "claude-cli/2.1.296"), body: body(model: "claude-fable-5-1"))
        XCTAssertEqual(fable.rule, "model: claude-fable-5-1 is not routed")
        XCTAssertNil(fable.routedModel)
    }

    func testAProviderTierTargetIsPlannedForTheProvider() throws {
        let id = UUID()
        var template = builtIn
        template.tierTargets["standard"] = Sessions.ModelTierTarget.provider(id, model: nil).text
        var settings = ModelRouterSettings()
        settings.enabled = true
        settings.templates = [template]
        let fixed = settings
        let plan = ModelRoutingPlanner(settings: { fixed }, window: { _ in nil }, maxOutput: { _ in nil })
            .plan(head(userAgent: "claude-cli/2.1.296"), body: body(model: "claude-opus-5-5", tools: ["Read", "Bash"]))
        // No provider resolves in this planner, so it falls back with the reason.
        XCTAssertEqual(plan.rule, "\(builtIn.name) › Command subagent → Standard (fell back: provider unavailable)")
        XCTAssertNil(plan.routedModel)
    }

    func testAForkAfterTheMainThreadGetsItsOwnTier() throws {
        func request(tools: [String]) -> Data {
            let object: [String: Any] = [
                "model": "claude-opus-5-5", "max_tokens": 1000,
                "system": [["type": "text", "text": "x-anthropic-billing-header: cc_version=2.1.296;"],
                           ["type": "text", "text": "You are a helper."]],
                "tools": tools.map { ["name": $0, "input_schema": ["type": "object"]] },
                "messages": [["role": "user", "content": "hi"]]
            ]
            return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        }
        let planner = planner()
        let main = planner.plan(head(userAgent: "claude-cli/2.1.296"), body: request(tools: ["Read"]))
        XCTAssertEqual(main.rule, "\(builtIn.name) › Your conversation (never routed)")
        // The side call shares main's thread key; main's keep must not stick to it.
        let side = planner.plan(head(userAgent: "claude-cli/2.1.296"), body: request(tools: []))
        XCTAssertEqual(side.thread, .side)
        let rule = try XCTUnwrap(side.rule)
        XCTAssertFalse(rule.hasPrefix("sticky"), rule)
        XCTAssertTrue(rule.hasPrefix("\(builtIn.name) › "), rule)
    }

    func testAProviderThatCannotBeResolvedPinsTheThreadToItsOwnModel() {
        let id = UUID()
        var template = builtIn
        template.tierTargets["standard"] = Sessions.ModelTierTarget.provider(id, model: nil).text
        var settings = ModelRouterSettings()
        settings.enabled = true
        settings.templates = [template]
        let fixed = settings
        let providers = SwitchedProviders(id: id)
        let planner = ModelRoutingPlanner(
            settings: { fixed }, window: { _ in nil }, maxOutput: { _ in nil }, providers: providers)
        let command = body(model: "claude-opus-5-5", tools: ["Read", "Bash"])
        let first = planner.plan(head(userAgent: "claude-cli/2.1.296"), body: command)
        XCTAssertEqual(first.rule, "\(builtIn.name) › Command subagent → Standard (fell back: provider unavailable)")
        // The key is saved mid-conversation: the thread stays on the model it asked for.
        providers.isAvailable = true
        let second = planner.plan(head(userAgent: "claude-cli/2.1.296"), body: command)
        XCTAssertNil(second.provider)
        XCTAssertNil(second.routedModel)
        XCTAssertEqual(second.rule, "sticky: reverted")
    }

    func testAFailedProviderIsSkippedForNewThreadsUntilItsCoolDownEnds() {
        let id = UUID()
        var template = builtIn
        template.tierTargets["standard"] = Sessions.ModelTierTarget.provider(id, model: nil).text
        var settings = ModelRouterSettings()
        settings.enabled = true
        settings.templates = [template]
        let fixed = settings
        let providers = SwitchedProviders(id: id)
        providers.isAvailable = true
        let clock = SettableClock()
        let planner = ModelRoutingPlanner(
            settings: { fixed }, window: { _ in nil }, maxOutput: { _ in nil }, providers: providers,
            health: ModelProviderHealth(cooldown: 300, now: { clock.now }))
        func plan(_ system: String) -> ModelPlan {
            planner.plan(head(userAgent: "claude-cli/2.1.296"),
                         body: body(model: "claude-opus-5-5", system: system, tools: ["Read", "Bash"]))
        }
        let first = plan("Thread A.")
        XCTAssertEqual(first.provider, id)
        planner.fellBack(first)
        let second = plan("Thread B.")
        XCTAssertNil(second.provider)
        XCTAssertNil(second.providerRoute)
        XCTAssertEqual(second.rule, "\(builtIn.name) › Command subagent → Standard (fell back: provider cooling down)")
        clock.now = clock.now.addingTimeInterval(301)
        XCTAssertEqual(plan("Thread C.").provider, id)
    }

    func testRequestNamesThatLookLikeSystemRulesAreStillPrefixedAndStayIntactWhenSticky() {
        let lookalikes = Sessions.ModelRouterTemplateDTO(
            id: "n", name: "N", claudeCode: .init(from: "2.1.0", through: "2.1.999"),
            requests: [
                Sessions.ModelRequestKindDTO(id: "notes", name: "sticky notes", when: .init(thread: .subagent)),
                Sessions.ModelRequestKindDTO(id: "probe", name: "model: probe", when: .init(thread: .side))
            ],
            requestTiers: ["notes": "light", "probe": "light", "unclassified": "heavy"])
        var settings = ModelRouterSettings()
        settings.enabled = true
        settings.templates = [lookalikes]
        let fixed = settings
        let planner = ModelRoutingPlanner(settings: { fixed }, window: { _ in nil }, maxOutput: { _ in nil })
        let agent = head(userAgent: "claude-cli/2.1.296")
        let cases: [(Data, String)] = [(subagentBody(), "N › sticky notes → Light"),
                                       (body(model: "claude-opus-5-5", tools: []), "N › model: probe → Light")]
        for (request, rule) in cases {
            let first = planner.plan(agent, body: request)
            XCTAssertEqual(first.rule, rule)
            XCTAssertEqual(first.routedModel, "claude-haiku-5-5")
            for _ in 0..<2 {
                let again = planner.plan(agent, body: request)
                XCTAssertEqual(again.rule, "sticky: \(rule)")
                XCTAssertEqual(again.routedModel, "claude-haiku-5-5")
            }
        }
    }

    func testNoVersionFallsBackToTheHighestThrough() {
        for agent in [nil, "curl/8.7.1"] {
            let plan = planner().plan(head(userAgent: agent), body: subagentBody())
            XCTAssertEqual(plan.rule, "C › Any subagent → Standard", agent ?? "nil")
        }
    }

    func testTheNewestVersionSeenIsKept() {
        let versions = ModelClientVersionMemory()
        let planner = planner(versions: versions)
        XCTAssertNil(versions.newest)
        for agent in ["claude-cli/2.1.296", "claude-cli/2.1.305", "claude-cli/2.1.300", "curl/8"] {
            _ = planner.plan(head(userAgent: agent), body: subagentBody())
        }
        XCTAssertEqual(versions.newest?.description, "2.1.305")
    }

    func testAStickyDecisionKeepsItsStickyText() throws {
        let planner = planner()
        let first = planner.plan(head(userAgent: "claude-cli/2.1.305"), body: subagentBody())
        XCTAssertEqual(first.rule, "C › Any subagent → Standard")
        let second = planner.plan(head(userAgent: "claude-cli/2.1.305"), body: subagentBody())
        let rule = try XCTUnwrap(second.rule)
        XCTAssertTrue(rule.hasPrefix("sticky"), rule)
    }

    func testDisabledLeavesTheBodyAndSeesNoVersion() {
        var settings = ModelRouterSettings()
        settings.enabled = false
        let fixed = settings
        let versions = ModelClientVersionMemory()
        let plan = ModelRoutingPlanner(settings: { fixed }, versions: versions)
            .plan(head(userAgent: "claude-cli/2.1.305"), body: subagentBody())
        XCTAssertNil(plan.rule)
        XCTAssertNil(versions.newest)
    }

    func testNoTemplatesLeavesTheBodyUntouched() {
        let body = subagentBody()
        let plan = planner([]).plan(head(userAgent: "claude-cli/2.1.305"), body: body)
        XCTAssertEqual(plan.body, body)
        XCTAssertNil(plan.rule)
    }
}

/// Resolves `id` once `isAvailable` is set, as when its key is saved.
private final class SwitchedProviders: ModelProviderResolving, @unchecked Sendable {
    private let lock = NSLock()
    private var available = false
    private let id: UUID

    init(id: UUID) { self.id = id }

    var isAvailable: Bool {
        get { lock.withLock { available } }
        set { lock.withLock { available = newValue } }
    }

    func resolve(_ id: UUID, model: String?) -> Result<ProviderRoute, ProviderUnavailable> {
        guard id == self.id, isAvailable else { return .failure(.unavailable) }
        return .success(ProviderRoute(
            configID: id, name: "P", endpoint: URL(string: "https://provider.example/v1/messages")!,
            apiKey: nil, model: "p-model", wire: .anthropic))
    }
}

/// A settable clock for cool-downs.
private final class SettableClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current = Date(timeIntervalSince1970: 1_000_000)

    var now: Date {
        get { lock.withLock { current } }
        set { lock.withLock { current = newValue } }
    }
}
