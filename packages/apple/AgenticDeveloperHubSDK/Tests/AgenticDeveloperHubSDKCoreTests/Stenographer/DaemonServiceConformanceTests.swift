import XCTest
@testable import AgenticDeveloperHubSDKCore

/// Records the full-operation calls the protocol extension's default overloads make.
private final class RecordingDaemonService: StenographerDaemonService, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []
    var calls: [String] { lock.withLock { recorded } }
    private func record(_ text: String) { lock.withLock { recorded.append(text) } }

    func health() async -> HealthDTO? { nil }
    func sessions(status: String?, project: String?, sinceHours: Int, includeCounts: Bool) async -> [SessionDTO]? {
        record("sessions \(status ?? "nil") \(project ?? "nil") \(sinceHours) \(includeCounts)")
        return nil
    }
    func session(id: String, includeCounts: Bool) async -> SessionDTO?? {
        record("session \(id) \(includeCounts)")
        return nil
    }
    func summarize(sessionId: String) async throws {}
    func conversations(
        limit: Int, includeWorkOutput: Bool, before: String?, sessionId: String?
    ) async -> [ConversationEntryDTO]? {
        record("conversations \(limit) \(includeWorkOutput) \(before ?? "nil") \(sessionId ?? "nil")")
        return nil
    }
    func oversightFindings(status: String?) async -> [OversightFindingDTO]? {
        record("findings \(status ?? "nil")")
        return nil
    }
    func oversightActionTarget(findingId: Int) async -> OversightActionTargetDTO? { nil }
    func actOnOversightFinding(findingId: Int) async -> OversightActResultDTO? { nil }
    func oversightScripts() async -> [OversightScript]? { nil }
    func saveOversightScript(_ script: OversightScript) async -> OversightScript? { nil }
    func deleteOversightScript(id: String) async -> Bool { false }
    func resetOversightScript(id: String) async -> OversightScript? { nil }
    func aiInteractions(limit: Int) async -> [AIInteractionDTO]? {
        record("interactions \(limit)")
        return nil
    }
    func aiInteraction(id: Int) async -> AIInteractionDTO? { nil }
    func aiProviderConfigs() async -> [DaemonProviderConfig]? { nil }
    func summaryPreferences() async -> SummaryPreferenceResponse? { nil }
    func oversightPreferences() async -> OversightPreferenceResponse? { nil }
    func setSummaryPreferences(_ request: SummaryPreferenceRequest) async -> Bool { false }
    func setOversightPreferences(_ request: OversightPreferenceRequest) async -> Bool { false }
    func setAIPreferences(_ sync: AIProviderConfigSync) async -> Bool { false }
    func onReconnect(_ handler: @escaping @Sendable () -> Void) {}
}

/// Conformance vectors for the daemon-service protocol, its default overloads and its value types.
final class DaemonServiceConformanceTests: XCTestCase {

    private func makeClient() -> StenographerHTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubDaemonProtocol.self]
        return StenographerHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:22847")!,
            session: URLSession(configuration: config),
            healthPollInterval: 3600)
    }

    override func tearDown() { StubDaemonProtocol.handler = nil }

    func testDaemonService004_sessionAnswersOuterNilWhenUnreachable() async {
        StubDaemonProtocol.handler = nil
        let reply = await makeClient().session(id: "s1", includeCounts: true)
        XCTAssertTrue(reply == nil, "outer nil means the daemon is unreachable")
    }

    func testDaemonService006_summarizeThrowsCannotConnectWhenNoReply() async {
        StubDaemonProtocol.handler = nil
        do {
            try await makeClient().summarize(sessionId: "s1")
            XCTFail("expected a throw")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cannotConnectToHost)
        } catch {
            XCTFail("wrong error \(error)")
        }
    }

    func testDaemonService014_conversationsAndInteractionsDefaults() async {
        let service = RecordingDaemonService()
        _ = await service.conversations()
        _ = await service.aiInteractions()
        XCTAssertEqual(service.calls, ["conversations 200 false nil nil", "interactions 200"])
    }

    func testDaemonService015_timeoutTable() {
        XCTAssertEqual(StenographerHTTPClient.timeout(method: "POST", path: "/sessions/x/summarize"), 605)
        XCTAssertEqual(StenographerHTTPClient.timeout(method: "GET", path: "/conversations"), 15)
        XCTAssertEqual(StenographerHTTPClient.timeout(method: "GET", path: "/ai/interactions/3"), 15)
        XCTAssertEqual(StenographerHTTPClient.timeout(method: "GET", path: "/health"), 10)
    }

    func testDaemonService016_providerConfigWireKeys() throws {
        let identifier = UUID()
        let body = Data("""
        {"id":"\(identifier.uuidString)","name":"n","plugin_identifier":"p","template_id":"t"}
        """.utf8)
        let config = try StenographerWire.decoder().decode(DaemonProviderConfig.self, from: body)
        XCTAssertEqual(config, DaemonProviderConfig(id: identifier, name: "n", pluginIdentifier: "p", templateId: "t"))
        XCTAssertEqual(config.id, identifier)
    }

    func testDaemonService017_transportErrorReadsAsCannotConnect() async {
        StubDaemonProtocol.handler = nil
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TimedOutDaemonProtocol.self]
        let client = StenographerHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:22847")!, session: URLSession(configuration: config))
        do {
            try await client.summarize(sessionId: "s1")
            XCTFail("expected a throw")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cannotConnectToHost, "a timeout reads exactly like an unreachable daemon")
        } catch {
            XCTFail("wrong error \(error)")
        }
    }

    func testDaemonService018_actFallsBackToActedWhenBodyDoesNotDecode() async {
        StubDaemonProtocol.handler = { _ in (200, Data(#"{"unexpected":true}"#.utf8)) }
        let result = await makeClient().actOnOversightFinding(findingId: 7)
        XCTAssertEqual(result?.succeeded, true)
        XCTAssertEqual(result?.status, "acted")
    }

    func testDaemonService019_sessionsDefaults() async {
        let service = RecordingDaemonService()
        _ = await service.sessions()
        XCTAssertEqual(service.calls, ["sessions nil nil 0 true"])
    }

    func testDaemonService020_sinceHoursOnlySentWhenPositive() async throws {
        let captured = Captured()
        StubDaemonProtocol.handler = { request in
            captured.set(request.url!)
            return (200, Data("[]".utf8))
        }
        let client = makeClient()
        _ = await client.sessions(status: nil, project: nil, sinceHours: 0, includeCounts: true)
        let first = URLComponents(url: try XCTUnwrap(captured.url), resolvingAgainstBaseURL: false)
        XCTAssertFalse((first?.queryItems ?? []).contains { $0.name == "since_hours" })
        _ = await client.sessions(status: nil, project: nil, sinceHours: 6, includeCounts: true)
        let second = URLComponents(url: try XCTUnwrap(captured.url), resolvingAgainstBaseURL: false)
        XCTAssertTrue((second?.queryItems ?? []).contains(URLQueryItem(name: "since_hours", value: "6")))
    }
}

/// Fails every request the way an expired request timeout does.
private final class TimedOutDaemonProtocol: URLProtocol {
    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { client?.urlProtocol(self, didFailWithError: URLError(.timedOut)) }
    override func stopLoading() {}
}
