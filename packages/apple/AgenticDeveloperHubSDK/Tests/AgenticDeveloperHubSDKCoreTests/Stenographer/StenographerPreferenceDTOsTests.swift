import XCTest
@testable import AgenticDeveloperHubSDKCore

final class StenographerPreferenceDTOsTests: XCTestCase {

    func testSummaryRequestEncodesSnakeCaseAndOmitsNils() throws {
        var request = SummaryPreferenceRequest()
        request.enabled = false
        request.selectedConfigId = "abc"
        request.maxWords = 12
        let data = try StenographerWire.encoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["enabled"] as? Bool, false)
        XCTAssertEqual(object["selected_config_id"] as? String, "abc")
        XCTAssertEqual(object["max_words"] as? Int, 12)
        XCTAssertNil(object["prompt"])
    }

    func testSummaryResponseDecodesSnakeCase() throws {
        let json = Data("""
        {"enabled":true,"selected_config_id":"","prompt":"p","max_words":8,"activity_lines":60,
         "detail_chars":120,"interval_minutes":5,"max_per_run":5,"timeout_seconds":60}
        """.utf8)
        let response = try StenographerWire.decoder().decode(SummaryPreferenceResponse.self, from: json)
        XCTAssertEqual(response, SummaryPreferenceResponse(
            enabled: true, selectedConfigId: "", prompt: "p", maxWords: 8, activityLines: 60,
            detailChars: 120, intervalMinutes: 5, maxPerRun: 5, timeoutSeconds: 60))
    }

    func testSummaryResponseFromAnOlderDaemonDecodesWithoutEnabledOrSelection() throws {
        let json = Data("""
        {"prompt":"p","max_words":8,"activity_lines":60,"detail_chars":120,
         "interval_minutes":5,"max_per_run":5,"timeout_seconds":60}
        """.utf8)
        let response = try StenographerWire.decoder().decode(SummaryPreferenceResponse.self, from: json)
        XCTAssertNil(response.enabled)
        XCTAssertNil(response.selectedConfigId)
        XCTAssertEqual(response.maxWords, 8)
        XCTAssertEqual(response.timeoutSeconds, 60)
    }

    func testOversightRoundTrip() throws {
        let response = OversightPreferenceResponse(
            enabled: true, contextThresholdPct: 80, llmEnabled: false, selectedConfigId: "claude-cli", model: "")
        let data = try StenographerWire.encoder().encode(response)
        XCTAssertEqual(try StenographerWire.decoder().decode(OversightPreferenceResponse.self, from: data), response)
    }

    private static let summaryBody = """
        {"enabled":true,"selected_config_id":"c","prompt":"p","max_words":8,"activity_lines":60,
         "detail_chars":120,"interval_minutes":5,"max_per_run":5,"timeout_seconds":60}
        """
    private static let oversightBody = """
        {"enabled":true,"context_threshold_pct":80,"llm_enabled":false,"selected_config_id":"x","model":"m"}
        """

    private func assertDecodingError<T: Decodable>(
        _ type: T.Type, _ json: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertThrowsError(try StenographerWire.decoder().decode(type, from: Data(json.utf8)),
                             file: file, line: line) { error in
            XCTAssertTrue(error is DecodingError, "got \(error)", file: file, line: line)
        }
    }

    func testV5_summaryReplyMissingMaxWordsThrows() {
        let json = Self.summaryBody.replacingOccurrences(of: "\"max_words\":8,", with: "")
        assertDecodingError(SummaryPreferenceResponse.self, json)
    }

    func testV6_emptyOversightRequestEncodesAnEmptyObject() throws {
        let data = try StenographerWire.encoder().encode(OversightPreferenceRequest())
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertTrue(object.isEmpty)
    }

    func testV7_oversightRequestEncodesOnlyTheSetFieldsInSnakeCase() throws {
        let request = OversightPreferenceRequest(enabled: true, contextThresholdPct: 75)
        let data = try StenographerWire.encoder().encode(request)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["enabled", "context_threshold_pct"])
        XCTAssertEqual(object["enabled"] as? Bool, true)
        XCTAssertEqual(object["context_threshold_pct"] as? Int, 75)
    }

    func testV8_oversightReplyMissingModelThrows() {
        let json = Self.oversightBody.replacingOccurrences(of: ",\"model\":\"m\"", with: "")
        assertDecodingError(OversightPreferenceResponse.self, json)
    }

    func testV9_emptySummaryRequestHasAllNilProperties() {
        let request = SummaryPreferenceRequest()
        XCTAssertNil(request.enabled)
        XCTAssertNil(request.selectedConfigId)
        XCTAssertNil(request.prompt)
        XCTAssertNil(request.maxWords)
        XCTAssertNil(request.activityLines)
        XCTAssertNil(request.detailChars)
        XCTAssertNil(request.intervalMinutes)
        XCTAssertNil(request.maxPerRun)
        XCTAssertNil(request.timeoutSeconds)
    }

    func testV10_unknownKeysAreIgnored() throws {
        let json = Self.oversightBody.replacingOccurrences(of: "}", with: ",\"future_field\":1}")
        let response = try StenographerWire.decoder().decode(OversightPreferenceResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.contextThresholdPct, 80)
        XCTAssertEqual(response.selectedConfigId, "x")
    }

    func testV11_allFourTypesRoundTripAndResponsesCompare() throws {
        let encoder = StenographerWire.encoder()
        let decoder = StenographerWire.decoder()
        let summaryRequest = SummaryPreferenceRequest(enabled: true, prompt: "p", maxWords: 9, timeoutSeconds: 30)
        let decodedSummaryRequest = try decoder.decode(
            SummaryPreferenceRequest.self, from: encoder.encode(summaryRequest))
        XCTAssertEqual(decodedSummaryRequest.enabled, true)
        XCTAssertEqual(decodedSummaryRequest.prompt, "p")
        XCTAssertEqual(decodedSummaryRequest.maxWords, 9)
        XCTAssertEqual(decodedSummaryRequest.timeoutSeconds, 30)
        XCTAssertNil(decodedSummaryRequest.detailChars)

        let oversightRequest = OversightPreferenceRequest(
            enabled: false, contextThresholdPct: 50, llmEnabled: true, selectedConfigId: "c", model: "m")
        let decodedOversightRequest = try decoder.decode(
            OversightPreferenceRequest.self, from: encoder.encode(oversightRequest))
        XCTAssertEqual(decodedOversightRequest.enabled, false)
        XCTAssertEqual(decodedOversightRequest.contextThresholdPct, 50)
        XCTAssertEqual(decodedOversightRequest.llmEnabled, true)
        XCTAssertEqual(decodedOversightRequest.selectedConfigId, "c")
        XCTAssertEqual(decodedOversightRequest.model, "m")

        let summary = try decoder.decode(SummaryPreferenceResponse.self, from: Data(Self.summaryBody.utf8))
        XCTAssertEqual(try decoder.decode(SummaryPreferenceResponse.self, from: encoder.encode(summary)), summary)
        let other = SummaryPreferenceResponse(
            enabled: summary.enabled, selectedConfigId: summary.selectedConfigId, prompt: summary.prompt,
            maxWords: summary.maxWords + 1, activityLines: summary.activityLines, detailChars: summary.detailChars,
            intervalMinutes: summary.intervalMinutes, maxPerRun: summary.maxPerRun,
            timeoutSeconds: summary.timeoutSeconds)
        XCTAssertNotEqual(summary, other)

        let oversight = try decoder.decode(OversightPreferenceResponse.self, from: Data(Self.oversightBody.utf8))
        XCTAssertEqual(try decoder.decode(OversightPreferenceResponse.self, from: encoder.encode(oversight)), oversight)
        XCTAssertNotEqual(oversight, OversightPreferenceResponse(
            enabled: false, contextThresholdPct: 80, llmEnabled: false, selectedConfigId: "x", model: "m"))
    }

    func testV12_initializersAreUsableFromAnotherModule() throws {
        throw XCTSkip("needs a plain (non-@testable) import from another module; this file imports @testable")
    }

    func testV13_tuningValuesAreNotClamped() throws {
        let data = try StenographerWire.encoder().encode(SummaryPreferenceRequest(maxWords: 1000))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["max_words"] as? Int, 1000)
        let json = Self.summaryBody.replacingOccurrences(of: "\"max_words\":8", with: "\"max_words\":1000")
        let response = try StenographerWire.decoder().decode(SummaryPreferenceResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.maxWords, 1000)
    }

    func testV14_summaryReplyMissingPromptThrows() {
        let json = Self.summaryBody.replacingOccurrences(of: "\"prompt\":\"p\",", with: "")
        assertDecodingError(SummaryPreferenceResponse.self, json)
    }

    func testSessionDTOStillDecodesFromDaemonJSON() throws {
        let json = Data("""
        {"session_id":"s1","cwd":"/x","model":"m","started_at":"2026-10-12T00:00:00Z",
         "last_activity_at":"2026-10-12T00:00:01Z","last_tool":"Bash","status":"active",
         "git_branch":"main","summary":"s","pid":1,"term_program":"iTerm.app",
         "term_session_id":"t","project_root":"/x","event_count":3}
        """.utf8)
        let dto = try StenographerWire.decoder().decode(SessionDTO.self, from: json)
        XCTAssertEqual(dto.sessionId, "s1")
        XCTAssertEqual(dto.eventCount, 3)
    }
}
