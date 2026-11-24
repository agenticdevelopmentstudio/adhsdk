import XCTest
@testable import AgenticDeveloperHubSDKCore

final class OversightScriptDTOConformanceTests: XCTestCase {

    private let gteCondition = ScriptPredicate.condition(
        field: .contextUsedPct, operation: .greaterOrEqual, value: "80")

    private func jsonObject(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func makeScript(enabled: Bool = true, confirmation: LLMConfirmation? = nil) -> OversightScript {
        OversightScript(
            id: "compact", name: "Compact", enabled: enabled, builtIn: true, version: 1,
            trigger: ScriptTrigger(predicate: gteCondition, llmConfirmation: confirmation),
            response: ScriptResponse(
                kind: "compact", reasonTemplate: "Context {{context_used_pct}}% used",
                action: .injectText("/compact")))
    }

    func testV001_conditionEncodesFixedKeys() throws {
        let object = try jsonObject(JSONEncoder().encode(gteCondition))
        XCTAssertEqual(object["type"] as? String, "condition")
        XCTAssertEqual(object["field"] as? String, "context_used_pct")
        XCTAssertEqual(object["op"] as? String, "gte")
        XCTAssertEqual(object["value"] as? String, "80")
        XCTAssertNil(object["operation"])
    }

    func testV002_nestedGroupsRoundTrip() throws {
        let nested = ScriptPredicate.all([gteCondition, .any([gteCondition])])
        let data = try JSONEncoder().encode(nested)
        let object = try jsonObject(data)
        XCTAssertEqual(object["type"] as? String, "all")
        let children = try XCTUnwrap(object["predicates"] as? [[String: Any]])
        XCTAssertEqual(children.count, 2)
        XCTAssertEqual(children[0]["type"] as? String, "condition")
        XCTAssertEqual(children[1]["type"] as? String, "any")
        XCTAssertEqual(try JSONDecoder().decode(ScriptPredicate.self, from: data), nested)
    }

    func testV003_unknownPredicateTypeThrowsDataCorrupted() {
        let json = Data(#"{"type":"xor","predicates":[]}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(ScriptPredicate.self, from: json)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                return XCTFail("expected dataCorrupted, got \(error)")
            }
            XCTAssertEqual(context.debugDescription, "Unknown predicate type 'xor'")
        }
    }

    func testV004_emptyGroupRoundTrips() throws {
        let data = try JSONEncoder().encode(ScriptPredicate.all([]))
        XCTAssertEqual(try JSONDecoder().decode(ScriptPredicate.self, from: data), .all([]))
    }

    func testV005_actionWireShape() throws {
        let inject = try jsonObject(JSONEncoder().encode(ScriptAction.injectText("/compact")))
        XCTAssertEqual(inject as? [String: String], ["type": "inject", "text": "/compact"])
        let none = try jsonObject(JSONEncoder().encode(ScriptAction.none))
        XCTAssertEqual(none as? [String: String], ["type": "none"])
    }

    func testV006_unknownActionTypeThrowsDataCorrupted() {
        XCTAssertThrowsError(try JSONDecoder().decode(ScriptAction.self, from: Data(#"{"type":"notify"}"#.utf8))) {
            guard case DecodingError.dataCorrupted(let context) = $0 else {
                return XCTFail("expected dataCorrupted, got \($0)")
            }
            XCTAssertEqual(context.debugDescription, "Unknown action type 'notify'")
        }
    }

    func testV007_injectWithoutTextThrowsKeyNotFound() {
        XCTAssertThrowsError(try JSONDecoder().decode(ScriptAction.self, from: Data(#"{"type":"inject"}"#.utf8))) {
            guard case DecodingError.keyNotFound(let key, _) = $0 else {
                return XCTFail("expected keyNotFound, got \($0)")
            }
            XCTAssertEqual(key.stringValue, "text")
        }
    }

    func testV008_scriptEncodesSnakeCaseAndOmitsNilConfirmation() throws {
        let object = try jsonObject(StenographerWire.encoder().encode(makeScript()))
        XCTAssertEqual(
            Set(object.keys), ["id", "name", "enabled", "built_in", "version", "trigger", "response"])
        XCTAssertEqual(object["built_in"] as? Bool, true)
        let trigger = try XCTUnwrap(object["trigger"] as? [String: Any])
        XCTAssertNotNil(trigger["predicate"] as? [String: Any])
        XCTAssertNil(trigger["llm_confirmation"])
    }

    func testV009_triggerDecodesLLMConfirmation() throws {
        let json = Data("""
        {"predicate":{"type":"all","predicates":[]},
         "llm_confirmation":{"system_prompt":"p","act_keyword":"COMPACT"}}
        """.utf8)
        let trigger = try StenographerWire.decoder().decode(ScriptTrigger.self, from: json)
        XCTAssertEqual(trigger.llmConfirmation, LLMConfirmation(systemPrompt: "p", actKeyword: "COMPACT"))
    }

    func testV010_responseMissingReasonTemplateThrows() {
        let json = Data(#"{"kind":"compact","action":{"type":"none"}}"#.utf8)
        XCTAssertThrowsError(try StenographerWire.decoder().decode(ScriptResponse.self, from: json))
    }

    func testV011_isNumericMatchesFieldKind() {
        let numeric: Set<ConditionField> = [.tokensInContext, .contextUsedPct, .contextWindowSize, .idleMinutes]
        XCTAssertEqual(ConditionField.allCases.count, 8)
        for field in ConditionField.allCases {
            XCTAssertEqual(field.isNumeric, numeric.contains(field), "\(field)")
        }
    }

    func testV012_unknownFieldAndOperatorThrowKnownOnesDecode() throws {
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(ConditionField.self, from: Data(#""cpu_pct""#.utf8)))
        XCTAssertThrowsError(try decoder.decode(ConditionOperator.self, from: Data(#""matches""#.utf8)))
        let fields = ["tokens_in_context", "context_used_pct", "context_window_size", "last_event_type",
                      "idle_minutes", "session_status", "model", "project_path"]
        for raw in fields {
            XCTAssertEqual(try decoder.decode(ConditionField.self, from: Data("\"\(raw)\"".utf8)).rawValue, raw)
        }
        let operators = ["eq", "ne", "gt", "gte", "lt", "lte", "contains"]
        for raw in operators {
            XCTAssertEqual(try decoder.decode(ConditionOperator.self, from: Data("\"\(raw)\"".utf8)).rawValue, raw)
        }
        XCTAssertEqual(ConditionField.allCases.count, fields.count)
        XCTAssertEqual(ConditionOperator.allCases.count, operators.count)
    }

    func testV013_providerSentinelValue() {
        XCTAssertEqual(OversightProviderSelection.claudeCLISentinel, "claude-cli")
    }

    func testV014_predicateKeysIgnoreKeyStrategy() throws {
        let camel = JSONEncoder()
        camel.keyEncodingStrategy = .useDefaultKeys
        camel.outputFormatting = [.sortedKeys]
        let snake = JSONEncoder()
        snake.keyEncodingStrategy = .convertToSnakeCase
        snake.outputFormatting = [.sortedKeys]
        XCTAssertEqual(try camel.encode(gteCondition), try snake.encode(gteCondition))
    }

    func testV015_scriptInitAndEquality() {
        let script = makeScript()
        XCTAssertEqual(script.id, "compact")
        XCTAssertTrue(script.builtIn)
        XCTAssertEqual(script.version, 1)
        XCTAssertEqual(script.response.kind, "compact")
        XCTAssertEqual(script, makeScript())
        XCTAssertNotEqual(script, makeScript(enabled: false))
    }

    func testV016_triggerWithoutConfirmationDecodesNil() throws {
        let json = Data(#"{"predicate":{"type":"all","predicates":[]}}"#.utf8)
        let trigger = try StenographerWire.decoder().decode(ScriptTrigger.self, from: json)
        XCTAssertNil(trigger.llmConfirmation)
        XCTAssertEqual(trigger.predicate, .all([]))
    }
}
