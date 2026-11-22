import AgenticDeveloperHubSDKCore
import XCTest

final class ModelRouterTemplatesTests: XCTestCase {
    private func template(
        _ id: String, _ name: String, _ from: String, _ through: String
    ) -> Sessions.ModelRouterTemplateDTO {
        Sessions.ModelRouterTemplateDTO(id: id, name: name, claudeCode: .init(from: from, through: through),
                               requests: Sessions.ModelRouterTemplateDTO.builtInRequests)
    }

    func testVersionParsingAndOrdering() {
        XCTAssertEqual(Sessions.ClaudeCodeVersion("2.1.296")?.description, "2.1.296")
        XCTAssertNil(Sessions.ClaudeCodeVersion(""))
        XCTAssertNil(Sessions.ClaudeCodeVersion("2.1.x"))
        XCTAssertNil(Sessions.ClaudeCodeVersion("1.2.3.4.5"))
        XCTAssertNil(Sessions.ClaudeCodeVersion(" 2.1"))
        XCTAssertLessThan(Sessions.ClaudeCodeVersion("2.1.99")!, Sessions.ClaudeCodeVersion("2.1.296")!)
        XCTAssertEqual(Sessions.ClaudeCodeVersion("2.1")!, Sessions.ClaudeCodeVersion("2.1.0")!)
    }

    func testUserAgentExtraction() {
        XCTAssertEqual(
            Sessions.ClaudeCodeVersion.fromUserAgent("claude-cli/2.1.296 (external, cli)")?.description, "2.1.296")
        XCTAssertEqual(Sessions.ClaudeCodeVersion.fromUserAgent("claude-cli/2.1.300(x)")?.description, "2.1.300")
        XCTAssertNil(Sessions.ClaudeCodeVersion.fromUserAgent("curl/8.7.1"))
        XCTAssertNil(Sessions.ClaudeCodeVersion.fromUserAgent(nil))
        XCTAssertNil(Sessions.ClaudeCodeVersion.fromUserAgent("claude-cli/beta"))
    }

    func testBuiltInCarriesTheSpecsRequests() throws {
        let builtIn = try XCTUnwrap(Sessions.ModelRouterTemplateDTO.builtIns.first)
        XCTAssertEqual(builtIn.format, 3)
        XCTAssertEqual(builtIn.id, "builtin.claude-code.2.1.296")
        XCTAssertEqual(builtIn.name, "Claude Code 2.1.296")
        XCTAssertEqual(builtIn.claudeCode, .init(from: "2.1.296", through: "2.1.296"))
        XCTAssertEqual(builtIn.requests, Sessions.ModelRouterTemplateDTO.builtInRequests)
        XCTAssertEqual(builtIn.requests.count, 44)
        XCTAssertEqual(builtIn.requests.first?.id, "explore-subagent")
        XCTAssertEqual(builtIn.requests.first?.when, .init(
            thread: .subagent, system: "You are a file search specialist for Claude Code, Anthropic's official CLI"))
        XCTAssertEqual(builtIn.requests.suffix(3).map(\.id), ["background", "search-subagent", "command-subagent"])
        XCTAssertEqual(builtIn.requests.suffix(3).map(\.name),
                       ["Background task", "Search subagent", "Command subagent"])
        XCTAssertEqual(builtIn.requests.suffix(3).map(\.when), [
            .init(thread: .side), .init(thread: .subagent, commands: false),
            .init(thread: .subagent, commands: true)])
        XCTAssertTrue(builtIn.requests.dropLast(3).allSatisfy { $0.when.system != nil || $0.when.message != nil },
                      "every known kind is recognized by its text")
        XCTAssertTrue(builtIn.isBuiltIn)
        XCTAssertEqual(builtIn.versionText, "2.1.296")
        XCTAssertNil(Sessions.ModelRouterTemplateValidation.problem(builtIn, others: []))
    }

    func testTheBuiltInCarriesItsTiersRequestTiersAndModels() throws {
        let builtIn = try XCTUnwrap(Sessions.ModelRouterTemplateDTO.builtIns.first)
        XCTAssertEqual(builtIn.tiers.map(\.id), ["light", "standard", "heavy"])
        XCTAssertEqual(builtIn.tiers.map(\.name), ["Light", "Standard", "Heavy"])
        XCTAssertEqual(builtIn.requestTiers, Sessions.ModelRouterTemplateDTO.defaultRequestTiers(for: builtIn.requests))
        XCTAssertEqual(builtIn.requestTiers["background"], "light")
        XCTAssertEqual(builtIn.requestTiers["command-subagent"], "standard")
        XCTAssertEqual(builtIn.requestTiers["plan-subagent"], "heavy")
        XCTAssertEqual(builtIn.requestTiers["unclassified"], "heavy")
        XCTAssertEqual(builtIn.tierTargets, ["light": "claude:haiku", "standard": "claude:sonnet",
                                             "heavy": "claude:opus"])
        XCTAssertEqual(builtIn.tierId(forRequest: "search-subagent"), "light")
        XCTAssertEqual(builtIn.rank(ofTier: "heavy"), 2)
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.defaultTierId(forRequest: "editing-subagent"), "heavy")
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.defaultTierId(forRequest: "anything-else"), "heavy")
    }

    func testATierInUseNamesWhatStillGoesToIt() throws {
        let builtIn = try XCTUnwrap(Sessions.ModelRouterTemplateDTO.builtIns.first)
        let light = try XCTUnwrap(builtIn.removalProblem(tierId: "light"))
        XCTAssertTrue(light.hasPrefix("Explore subagent, "), light)
        XCTAssertTrue(light.hasSuffix("Background task, and Search subagent still go to Light. "
                                      + "Choose another tier for them first."), light)
        XCTAssertEqual(builtIn.removalProblem(tierId: "heavy"),
                       "Plan subagent, Agent team teammate, Worker fork subagent, Compaction, "
                       + "Auto mode permission classifier, Compaction (instruction), and Unclassified "
                       + "still go to Heavy. Choose another tier for them first.")
        var onlyUnclassified = builtIn
        for request in builtIn.requests where builtIn.requestTiers[request.id] == "heavy" {
            onlyUnclassified.requestTiers[request.id] = "standard"
        }
        XCTAssertEqual(onlyUnclassified.removalProblem(tierId: "heavy"),
                       "Unclassified still goes to Heavy. Choose another tier for it first.")
    }

    func testRetiredWritesAndMaxTokensKeysDecodeAndAreIgnored() throws {
        let request = #"{"id":"x","name":"X","tier":"light","when":{"thread":"subagent","writes":true,"commands":false,"max_tokens":500,"maxTokens":500}}"# // swiftlint:disable:this line_length
        let decoded = try JSONDecoder().decode(Sessions.ModelRequestKindDTO.self, from: Data(request.utf8))
        XCTAssertEqual(decoded.when, Sessions.ModelRouteConditionsDTO(thread: .subagent, commands: false))
        let file = #"{"format":2,"id":"B","name":"B","claude_code":{"from":"1","through":"2"},"requests":[{"id":"editing-subagent","name":"Editing subagent","tier":"heavy","when":{"thread":"subagent","writes":true,"max_tokens":9}}]}"# // swiftlint:disable:this line_length
        let imported = try Sessions.ModelRouterTemplateDTO.decodeFile(Data(file.utf8)).get()
        XCTAssertEqual(imported.requests.map(\.id), ["editing-subagent"], "a stored editing-subagent request is kept")
        XCTAssertEqual(imported.requests.first?.when, Sessions.ModelRouteConditionsDTO(thread: .subagent))
        let text = String(bytes: imported.encodedFile(), encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("writes"), text)
        XCTAssertFalse(text.contains("max"), text)
    }

    func testARequestWithoutATierTakesItsIdsDefault() throws {
        let json = #"{"format":2,"id":"B","name":"B","claude_code":{"from":"1","through":"2"},"requests":[{"id":"background","name":"A","when":{}},{"id":"search-subagent","name":"B","when":{}},{"id":"command-subagent","name":"C","when":{}},{"id":"editing-subagent","name":"D","when":{}},{"id":"mine","name":"E","when":{}}]}"# // swiftlint:disable:this line_length
        let decoded = try Sessions.ModelRouterTemplateDTO.decodeFile(Data(json.utf8)).get()
        XCTAssertEqual(decoded.format, 3)
        XCTAssertEqual(decoded.requestTiers, ["background": "light", "search-subagent": "light",
                                              "command-subagent": "standard", "editing-subagent": "heavy",
                                              "mine": "heavy", "unclassified": "heavy"],
                       "no unclassified_tier reads as Heavy")
        XCTAssertEqual(decoded.tiers, Sessions.ModelRouterTemplateDTO.defaultTiers)
        XCTAssertEqual(decoded.tierTargets, Sessions.ModelRouterTemplateDTO.defaultTierTargets)
        XCTAssertNil(Sessions.ModelRouterTemplateValidation.problem(decoded, others: []))
    }

    func testAnInvalidTierDropsTheStoredElementAndRefusesTheFile() throws {
        let json = #"{"format":2,"id":"B","name":"B","claude_code":{"from":"1","through":"2"},"requests":[{"id":"x","name":"X","tier":"huge","when":{}},{"id":"y","name":"Y","tier":"light","when":{}}]}"# // swiftlint:disable:this line_length
        let stored = try JSONDecoder().decode(Sessions.ModelRouterTemplateDTO.self, from: Data(json.utf8))
        XCTAssertEqual(stored.requests.map(\.id), ["y"])
        XCTAssertEqual(stored.requestTiers, ["y": "light", "unclassified": "heavy"])
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.decodeFile(Data(json.utf8)), .failure(.unreadableRequests(1)))
        let badUnclassified = #"{"format":2,"id":"B","name":"B","claude_code":{"from":"1","through":"2"},"requests":[],"unclassified_tier":"huge"}"# // swiftlint:disable:this line_length
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.decodeFile(Data(badUnclassified.utf8)), .failure(.unreadable))
    }

    func testTheFourPartsRoundTripAndBothKeySpellingsRead() throws {
        var tmpl = template("A", "Mine", "2.1.290", "2.1.296")
        tmpl.tiers.append(Sessions.ModelTierDTO(id: "huge", name: "Huge"))
        tmpl.requestTiers["background"] = "huge"
        tmpl.requestTiers["unclassified"] = "light"
        let provider = UUID()
        tmpl.tierTargets["huge"] = Sessions.ModelTierTarget.provider(provider, model: "big-1").text
        let decoded = try Sessions.ModelRouterTemplateDTO.decodeFile(tmpl.encodedFile()).get()
        XCTAssertEqual(decoded, tmpl)
        let text = String(bytes: tmpl.encodedFile(), encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("\"request_tiers\""), text)
        XCTAssertTrue(text.contains("\"tier_targets\""), text)
        XCTAssertTrue(text.contains("\"unclassified\" : \"light\""), text)
        XCTAssertFalse(text.contains("unclassified_tier"), text)
        let converted = #"{"format":2,"id":"B","name":"B","claudeCode":{"from":"1","through":"2"},"requests":[],"unclassifiedTier":"standard"}"# // swiftlint:disable:this line_length
        let viaConverted = try JSONDecoder().decode(Sessions.ModelRouterTemplateDTO.self, from: Data(converted.utf8))
        XCTAssertEqual(viaConverted.requestTiers["unclassified"], "standard")
        let camel = #"{"format":3,"id":"C","name":"C","claudeCode":{"from":"1","through":"2"},"requests":[],"requestTiers":{"unclassified":"light"},"tierTargets":{"light":"claude:haiku"},"tiers":[{"id":"light","name":"Light"}]}"# // swiftlint:disable:this line_length
        let viaCamel = try JSONDecoder().decode(Sessions.ModelRouterTemplateDTO.self, from: Data(camel.utf8))
        XCTAssertEqual(viaCamel.requestTiers, ["unclassified": "light"])
        XCTAssertEqual(viaCamel.tierTargets, ["light": "claude:haiku"])
    }

    func testAFormatThreeFileTakesDefaultsForMissingPartsAndNamesABadOne() throws {
        let bare = #"{"format":3,"id":"B","name":"B","claude_code":{"from":"1","through":"2"}}"#
        let decoded = try Sessions.ModelRouterTemplateDTO.decodeFile(Data(bare.utf8)).get()
        XCTAssertEqual(decoded.tiers, Sessions.ModelRouterTemplateDTO.defaultTiers)
        XCTAssertEqual(decoded.requests, Sessions.ModelRouterTemplateDTO.builtInRequests)
        XCTAssertEqual(decoded.requestTiers, Sessions.ModelRouterTemplateDTO.builtIns[0].requestTiers)
        XCTAssertEqual(decoded.tierTargets, Sessions.ModelRouterTemplateDTO.defaultTierTargets)
        for (key, title) in [("tiers", "tiers"), ("requests", "requests"),
                             ("request_tiers", "request tiers"), ("tier_targets", "tier models")] {
            let bad = #"{"format":3,"id":"B","name":"B","claude_code":{"from":"1","through":"2"},"\#(key)":7}"#
            XCTAssertEqual(
                Sessions.ModelRouterTemplateDTO.decodeFile(Data(bad.utf8)), .failure(.unreadableSection(title)), key)
        }
        XCTAssertEqual(Sessions.ModelRouterTemplateDecodeError.unreadableSection("tiers").reason,
                       "its tiers can't be read, so the file was not imported")
    }

    func testFileRoundTripAndBadFiles() throws {
        var tmpl = template("A", "Mine", "2.1.290", "2.1.296")
        tmpl.requests[0].when.commands = true
        XCTAssertEqual(try Sessions.ModelRouterTemplateDTO.decodeFile(tmpl.encodedFile()).get(), tmpl)
        let text = String(bytes: tmpl.encodedFile(), encoding: .utf8) ?? ""
        for key in ["\"claude_code\"", "\"requests\"", "\"commands\"", "\"format\" : 3", "\"tiers\""] {
            XCTAssertTrue(text.contains(key), key)
        }
        for gone in ["\"rules\"", "\"models\"", "\"provider\"", "\"model\""] {
            XCTAssertFalse(text.contains(gone), gone)
        }
        XCTAssertEqual(tmpl.versionText, "2.1.290 – 2.1.296")
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.decodeFile(Data("nope".utf8)), .failure(.unreadable))
        var newer = tmpl
        newer.format = 4
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.decodeFile(newer.encodedFile()), .failure(.newerFormat(4)))
        // Stored data drops a bad request, never the template.
        let json = #"{"format":2,"id":"B","name":"B","claude_code":{"from":"1","through":"2"},"requests":[{"id":"x","name":"X"},7,{"id":"y","name":"Y","when":{"commands":true}}]}"# // swiftlint:disable:this line_length
        let decoded = try JSONDecoder().decode(Sessions.ModelRouterTemplateDTO.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.requests,
                       [Sessions.ModelRequestKindDTO(id: "y", name: "Y", when: .init(commands: true))])
        XCTAssertEqual(decoded.requestTiers, ["y": "heavy", "unclassified": "heavy"])
        // A file with bad requests is refused, naming how many.
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.decodeFile(Data(json.utf8)), .failure(.unreadableRequests(2)))
        XCTAssertEqual(Sessions.ModelRouterTemplateDecodeError.unreadableRequests(2).reason,
                       "2 of its request definitions can't be read, so the file was not imported")
        let wrongType = #"{"format":2,"id":"B","name":"B","claude_code":{"from":"1","through":"2"},"requests":7}"#
        XCTAssertEqual(Sessions.ModelRouterTemplateDTO.decodeFile(Data(wrongType.utf8)), .failure(.unreadable))
        let none = #"{"format":2,"id":"B","name":"B","claude_code":{"from":"1","through":"2"}}"#
        XCTAssertEqual(try Sessions.ModelRouterTemplateDTO.decodeFile(Data(none.utf8)).get().requests, [])
    }

    func testAFormatOneFileConvertsWithTheBuiltInRequests() throws {
        let json = #"{"format":1,"id":"old","name":"Old","provider":"Anthropic","model":"Opus","claude_code":{"from":"2.1.200","through":"2.1.296"},"rules":[{"name":"r","when":{"families":["opus"]},"target":"sonnet"}],"models":{"haiku":"claude-haiku-9"}}"# // swiftlint:disable:this line_length
        let converted = try Sessions.ModelRouterTemplateDTO.decodeFile(Data(json.utf8)).get()
        XCTAssertEqual(converted, Sessions.ModelRouterTemplateDTO(
            id: "old", name: "Old", claudeCode: .init(from: "2.1.200", through: "2.1.296"),
            requests: Sessions.ModelRouterTemplateDTO.builtInRequests))
        XCTAssertEqual(converted.format, 3)
        XCTAssertEqual(converted.requestTiers, Sessions.ModelRouterTemplateDTO.builtIns[0].requestTiers)
    }

    func testValidation() {
        let builtIn = Sessions.ModelRouterTemplateDTO.builtIns[0]
        var tmpl = template("A", "Mine", "2.1.290", "2.1.296")
        XCTAssertNil(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: [builtIn]))
        tmpl.name = "  "
        XCTAssertEqual(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []), Sessions.ModelRouterTemplateValidation.nameMissing) // swiftlint:disable:this line_length
        tmpl.name = builtIn.name.uppercased()
        XCTAssertEqual(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: [builtIn]), Sessions.ModelRouterTemplateValidation.nameTaken) // swiftlint:disable:this line_length
        tmpl.name = "Mine"
        tmpl.claudeCode.from = "two"
        XCTAssertEqual(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []), Sessions.ModelRouterTemplateValidation.badVersion) // swiftlint:disable:this line_length
        tmpl.claudeCode = .init(from: "2.1.300", through: "2.1.296")
        XCTAssertEqual(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []), Sessions.ModelRouterTemplateValidation.backwardsRange) // swiftlint:disable:this line_length
        tmpl.claudeCode = .init(from: "2.1.290", through: "2.1.296")
        // The same id is the template itself, not a clash.
        XCTAssertNil(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: [tmpl]))
        tmpl.requests = []
        XCTAssertNotNil(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []),
                        "request tiers naming a request that is gone are refused")
        tmpl.requestTiers = Sessions.ModelRouterTemplateDTO.defaultRequestTiers(for: [])
        XCTAssertNil(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []), "no requests: all unclassified")
    }

    func testRequestValidationSentences() {
        let base = template("A", "Mine", "2.1.290", "2.1.296")
        func problem(_ change: (inout [Sessions.ModelRequestKindDTO]) -> Void) -> String? {
            var tmpl = base
            change(&tmpl.requests)
            return Sessions.ModelRouterTemplateValidation.problem(tmpl, others: [])
        }
        typealias Check = Sessions.ModelRouterTemplateValidation
        for bad in ["unclassified", "Bad", "", "-x", "a_b"] {
            XCTAssertEqual(problem { $0[0].id = bad }, Check.badRequestId, bad)
        }
        XCTAssertEqual(problem { $0[1].id = $0[0].id }, Check.duplicateRequestId)
        XCTAssertEqual(problem { $0[0].name = " " }, Check.requestNameMissing)
        XCTAssertEqual(problem { $0[1].name = " background TASK" }, Check.requestNameTaken)
        XCTAssertEqual(problem { $0[0].name = "Tab\there" }, Check.requestNameBad)
        XCTAssertEqual(problem { $0[0].name = String(repeating: "n", count: 81) }, Check.requestNameBad)
        XCTAssertNil(problem { $0[0].name = String(repeating: "n", count: 80) })
        XCTAssertEqual(Check.badRequestId,
                       "A request id is lowercase letters, digits and dashes, and can't be unclassified.")
        XCTAssertEqual(Check.duplicateRequestId, "Two requests have the same id.")
        XCTAssertEqual(Check.requestNameMissing, "Every request needs a name.")
        XCTAssertEqual(Check.requestNameTaken, "Two requests have the same name.")
        XCTAssertEqual(Check.requestNameBad,
                       "A request name can be at most 80 characters, with no control characters or line breaks.")
    }

    func testTierAndMappingValidationSentences() {
        let base = template("A", "Mine", "2.1.290", "2.1.296")
        func problem(_ change: (inout Sessions.ModelRouterTemplateDTO) -> Void) -> String? {
            var tmpl = base
            change(&tmpl)
            return Sessions.ModelRouterTemplateValidation.problem(tmpl, others: [])
        }
        typealias Check = Sessions.ModelRouterTemplateValidation
        XCTAssertEqual(problem { $0.tiers = [] }, Check.noTiers)
        XCTAssertEqual(problem { $0.tiers[0].id = "Bad" }, Check.badTierId)
        XCTAssertEqual(problem { $0.tiers[1].id = $0.tiers[0].id }, Check.duplicateTierId)
        XCTAssertEqual(problem { $0.tiers[0].name = " " }, Check.tierNameMissing)
        XCTAssertEqual(problem { $0.tiers[1].name = "LIGHT" }, Check.tierNameTaken)
        XCTAssertEqual(problem { $0.tiers[0].name = "Flip\u{202E}" }, Check.tierNameBad)
        XCTAssertEqual(problem { $0.tiers[0].name = String(repeating: "n", count: 81) }, Check.tierNameBad)
        XCTAssertEqual(problem { $0.requestTiers["background"] = nil }, Check.requestTierMissing)
        XCTAssertEqual(problem { $0.requestTiers["unclassified"] = nil }, Check.requestTierMissing)
        XCTAssertEqual(problem { $0.requestTiers["background"] = "huge" }, Check.requestTierUnknown)
        XCTAssertEqual(problem { $0.requestTiers["gone"] = "light" }, Check.requestTierStray)
        XCTAssertEqual(problem { $0.tierTargets["light"] = nil }, Check.tierTargetMissing)
        XCTAssertEqual(problem { $0.tierTargets["light"] = "gpt" }, Check.tierTargetBad)
        XCTAssertEqual(problem { $0.tierTargets["huge"] = "claude:opus" }, Check.tierTargetStray)
        XCTAssertNil(problem { $0.tierTargets["light"] = "provider:\(UUID().uuidString)" },
                     "an unknown provider is accepted and falls back when routing")
        XCTAssertEqual(Check.noTiers, "A template needs at least one tier.")
        XCTAssertEqual(Check.requestTierMissing, "Every request, and Unclassified, needs a tier.")
        XCTAssertEqual(Check.tierTargetMissing, "Every tier needs a model.")
    }

    /// Final review minor 1: a name is printed raw by `steno router` and copied
    /// into every routing-log row, so control and format characters are refused
    /// and the length is capped.
    func testNamesRefuseControlsBidiAndLineBreaksAndCapTheLength() {
        var tmpl = template("A", "Mine", "2.1.290", "2.1.296")
        let refused = ["Red\u{1B}[31m", "Tab\there", "Flip\u{202E}ped", "Bell\u{07}", "Iso\u{2066}late",
                       "Mark\u{200F}", "Line\u{2028}break", "Para\u{2029}graph"]
        for bad in refused {
            tmpl.name = bad
            XCTAssertEqual(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []),
                           Sessions.ModelRouterTemplateValidation.nameHasControls, bad.debugDescription)
        }
        tmpl.name = String(repeating: "n", count: Sessions.ModelRouterTemplateValidation.maxNameLength + 1)
        XCTAssertEqual(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []),
                       Sessions.ModelRouterTemplateValidation.nameTooLong)
        tmpl.name = String(repeating: "n", count: Sessions.ModelRouterTemplateValidation.maxNameLength)
        XCTAssertNil(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []))
    }

    func testNamesAllowEmojiAndCombiningAccents() {
        var tmpl = template("A", "Mine", "2.1.290", "2.1.296")
        let family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"
        for good in ["Cafe\u{301}", "\u{2764}\u{FE0F} Opus", "\(family) family",
                     "Café · Opus 4.7 (fast) – 2026", "Zero\u{200B}width"] {
            tmpl.name = good
            XCTAssertNil(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []), good.debugDescription)
        }
    }

    func testTheNameCapCountsCharactersNotScalars() {
        var tmpl = template("A", "Mine", "2.1.290", "2.1.296")
        let family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"
        let max = Sessions.ModelRouterTemplateValidation.maxNameLength
        tmpl.name = String(repeating: family, count: max)
        XCTAssertGreaterThan(tmpl.name.unicodeScalars.count, max)
        XCTAssertNil(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []))
        tmpl.name = String(repeating: "e\u{301}", count: max + 1)
        XCTAssertEqual(Sessions.ModelRouterTemplateValidation.problem(tmpl, others: []),
                       Sessions.ModelRouterTemplateValidation.nameTooLong)
    }

    func testSelectorCoveredPreferredAndTieBreaks() {
        let builtIn = template("builtin.x", "Built", "2.1.296", "2.1.296")
        let alpha = template("A", "alpha", "2.1.290", "2.1.300")
        let beta = template("B", "Beta", "2.1.296", "2.1.296")
        let version = Sessions.ClaudeCodeVersion("2.1.296")
        XCTAssertEqual(
            Sessions.ModelRouterTemplateSelector.select([alpha, beta, builtIn], preferred: [], version: version),
                       .init(template: builtIn, isFallback: false))
        XCTAssertEqual(Sessions.ModelRouterTemplateSelector.select([alpha, beta, builtIn], preferred: ["B"], version: version)?.template, beta) // swiftlint:disable:this line_length
        XCTAssertEqual(Sessions.ModelRouterTemplateSelector.select([beta, alpha], preferred: [], version: version)?.template, alpha) // name // swiftlint:disable:this line_length
        XCTAssertEqual(Sessions.ModelRouterTemplateSelector.select([alpha, beta], preferred: [], version: Sessions.ClaudeCodeVersion("2.1.299"))?.template, alpha) // swiftlint:disable:this line_length
    }

    func testSelectorFallsBackToTheLatest() {
        let old = template("O", "Old", "2.0.0", "2.1.100")
        let new = template("N", "New", "2.1.200", "2.1.296")
        let pick = Sessions.ModelRouterTemplateSelector.select(
            [old, new], preferred: [], version: Sessions.ClaudeCodeVersion("2.1.310"))
        XCTAssertEqual(pick, .init(template: new, isFallback: true))
        XCTAssertEqual(Sessions.ModelRouterTemplateSelector.select([old, new], preferred: [], version: nil),
                       .init(template: new, isFallback: true))
        XCTAssertEqual(Sessions.ModelRouterTemplateSelector.select([old, new], preferred: [], version: Sessions.ClaudeCodeVersion("2.1.150")), // swiftlint:disable:this line_length
                       .init(template: new, isFallback: true))
        XCTAssertNil(Sessions.ModelRouterTemplateSelector.select([], preferred: [], version: nil))
        XCTAssertTrue(Sessions.ModelRouterTemplateSelector.overlaps(old, template("X", "x", "2.1.100", "2.1.100")))
        XCTAssertFalse(Sessions.ModelRouterTemplateSelector.overlaps(old, new))
    }

    func testPreferencesAndStatusDecodeWithoutTheNewFields() throws {
        let prefs = try JSONDecoder().decode(
            Sessions.ModelRouterPreferencesDTO.self, from: Data(#"{"enabled":true}"#.utf8))
        XCTAssertNil(prefs.saveTemplate)
        XCTAssertNil(prefs.preferTemplate)
        let status = try JSONDecoder().decode(
            Sessions.ModelRouterStatusDTO.self, from: Data(#"{"enabled":true,"providers":[]}"#.utf8))
        XCTAssertNil(status.templates)
    }
}
