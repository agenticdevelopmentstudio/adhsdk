import XCTest
import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// `GET /router/status`, `/router/report`, `/router/exchanges` and the credential
/// relay `POST /accounts/credentials`, called through the route table.
///
/// Every router here is given a provider resolver, so nothing reaches the real
/// Keychain, and every probe an in-memory credential store and a stub prober.
final class AccountRouterRoutesTests: XCTestCase {
    private var tmpDir: URL!
    private var database: DaemonDatabase!
    private var dbPath: String!
    private var source: FakeQuotaSource!
    private var store: InMemoryAccountCredentialStore!
    private var probe: AccountQuotaProbe!

    override func setUpWithError() throws {
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("router-routes-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let opened = try TestDaemonDatabase.makeSessionDatabase()
        database = opened.db
        dbPath = opened.path
        source = FakeQuotaSource()
        source.hold("oauth:a@x.com", token: "sk-ant-oat01-a-secret")
        store = InMemoryAccountCredentialStore()
        probe = AccountQuotaProbe(credentials: store, prober: { _ in [:] })
    }

    override func tearDownWithError() throws {
        probe = nil
        store = nil
        database = nil
        TestDaemonDatabase.remove(path: dbPath)
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Helpers

    private func makeRouter(providers: any ModelProviderResolving = NoModelProviders()) -> AccountRouterServer {
        AccountRouterServer(
            database: database, source: source, port: 0, upstream: URL(fileURLWithPath: "/"),
            fingerprintsPath: tmpDir.appendingPathComponent("fp.json").path,
            providers: providers,
            templateStore: ModelRouterTemplateStore(
                directory: tmpDir.appendingPathComponent("templates"), database: database))
    }

    private func table(_ router: AccountRouterServer?) -> RouteTable {
        AccountRouterRoutes.table(router: router, probe: probe)
    }

    /// Sends `method target` through `table`; fails when no route claims it.
    private func send(
        _ method: String, _ target: String, body: Data = Data(), on table: RouteTable
    ) async throws -> RouteResponse {
        let components = try XCTUnwrap(URLComponents(string: target))
        var query: [String: [String]] = [:]
        for item in components.queryItems ?? [] {
            query[item.name, default: []].append(item.value ?? "")
        }
        let request = RouteRequest(method: method, path: components.path, queryValues: query, body: body)
        let response = await table.handle(request)
        return try XCTUnwrap(response, "no route claimed \(method) \(target)")
    }

    private func get(_ target: String, on router: AccountRouterServer?) async throws -> RouteResponse {
        try await send("GET", target, on: table(router))
    }

    private func json(_ response: RouteResponse) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: response.body) as? [String: Any])
    }

    private func text(_ response: RouteResponse) throws -> String {
        try XCTUnwrap(String(bytes: response.body, encoding: .utf8))
    }

    // MARK: - /router/status and /router/report

    func testStatusIsSnakeCaseAndNamesNoSecret() async throws {
        try database.setSetting(AccountRouterSettings.accountsKey, #"["oauth:a@x.com"]"#)
        let response = try await get("/router/status", on: makeRouter())
        XCTAssertEqual(response.status, 200)
        let body = try json(response)
        XCTAssertEqual(body["enabled"] as? Bool, false)
        XCTAssertEqual(body["listening"] as? Bool, false, "this router was never started")
        XCTAssertEqual(body["port"] as? Int, AccountRouterServer.unboundPort)
        XCTAssertEqual(body["base_url"] as? String, "http://127.0.0.1:0", "the configured port while unbound")
        XCTAssertEqual(body["five_hour_ceiling"] as? Double, AccountRouterSettings.defaultCeiling)
        XCTAssertEqual(body["saved_credentials"] as? [String], ["oauth:a@x.com"])
        let pool = try XCTUnwrap(body["pool"] as? [[String: Any]])
        XCTAssertEqual(pool.first?["account"] as? String, "oauth:a@x.com")
        XCTAssertEqual(pool.first?["held"] as? Bool, true)
        XCTAssertFalse(try text(response).contains("sk-ant"))
    }

    func testReportDefaultsToTwentyFourHours() async throws {
        let response = try await get("/router/report", on: makeRouter())
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(try json(response)["since_hours"] as? Int, AccountRouterRoutes.defaultReportHours)
    }

    func testReportCountsRecordedExchanges() async throws {
        try database.insertRouterExchange(AccountRouterExchange(
            startedAt: Date(), durationMs: 5, sessionId: "s", method: "POST", path: "/v1/messages",
            status: 200, account: "oauth:a@x.com", routingRule: "ranked"))
        let response = try await get("/router/report?since_hours=0", on: makeRouter())
        XCTAssertEqual(response.status, 200)
        let body = try json(response)
        XCTAssertEqual(body["since_hours"] as? Int, 0)
        XCTAssertEqual(body["total"] as? Int, 1)
    }

    func testAMalformedWindowIs400() async throws {
        let router = makeRouter()
        for bad in ["abc", "-1", "1.5", "+5", "%20"] {
            let response = try await get("/router/report?since_hours=\(bad)", on: router)
            XCTAssertEqual(response.status, 400, "since_hours=\(bad)")
        }
    }

    func testAHugeWindowIsClampedToACentury() async throws {
        let router = makeRouter()
        let ceiling = AccountRouterServer.maxReportHours
        for huge in ["99999999999999999999", String(Int.max), String(ceiling + 1)] {
            let response = try await get("/router/report?since_hours=\(huge)", on: router)
            XCTAssertEqual(response.status, 200, "since_hours=\(huge)")
            XCTAssertEqual(try json(response)["since_hours"] as? Int, ceiling, huge)
        }
    }

    // MARK: - /router/exchanges

    private func insert(_ account: String?, rule: String?) throws {
        try database.insertRouterExchange(AccountRouterExchange(
            startedAt: Date(), durationMs: 7, sessionId: "s", method: "POST", path: "/v1/messages",
            status: 200, account: account, routingRule: rule, fiveHourUtilization: 0.5))
    }

    func testExchangesAreSnakeCaseNewestFirst() async throws {
        try insert("oauth:a@x.com", rule: "ranked")
        try insert(nil, rule: nil)
        let response = try await get("/router/exchanges", on: makeRouter())
        XCTAssertEqual(response.status, 200)
        let rows = try XCTUnwrap(try json(response)["exchanges"] as? [[String: Any]])
        XCTAssertEqual(rows.map { $0["id"] as? Int }, [2, 1])
        let first = rows[1]
        XCTAssertEqual(first["routing_rule"] as? String, "ranked")
        XCTAssertEqual(first["duration_ms"] as? Int, 7)
        XCTAssertEqual(first["five_hour_utilization"] as? Double, 0.5)
        XCTAssertNotNil(first["started_at"] as? String)
        XCTAssertEqual(first["session_id"] as? String, "s")
    }

    func testExchangesFilterByEveryParameter() async throws {
        try insert("oauth:a@x.com", rule: "ranked")
        try insert(nil, rule: nil)
        try insert("oauth:a@x.com", rule: "sticky")
        let router = makeRouter()
        let cases: [(String, [Int])] = [
            ("/router/exchanges?after_id=1", [3, 2]),
            ("/router/exchanges?before_id=3&limit=1", [2]),
            ("/router/exchanges?account=-", [2]),
            ("/router/exchanges?account=oauth%3Aa%40x.com&rule=sticky", [3]),
            ("/router/exchanges?rule=off", [2]),
            ("/router/exchanges?rule=all-ineligible", []),
            ("/router/exchanges?since_hours=1", [3, 2, 1]),
            ("/router/exchanges?limit=99999999999999999999", [3, 2, 1])
        ]
        for (path, expected) in cases {
            let response = try await get(path, on: router)
            XCTAssertEqual(response.status, 200, path)
            let rows = try XCTUnwrap(try json(response)["exchanges"] as? [[String: Any]], path)
            XCTAssertEqual(rows.map { $0["id"] as? Int }, expected, path)
        }
    }

    func testAMalformedExchangeParameterIs400NamingIt() async throws {
        let router = makeRouter()
        for param in ["after_id", "before_id", "limit", "since_hours"] {
            for bad in ["abc", "-1", "1.5", "%20", ""] {
                let response = try await get("/router/exchanges?\(param)=\(bad)", on: router)
                XCTAssertEqual(response.status, 400, "\(param)=\(bad)")
                let message = try json(response)["error"] as? String ?? ""
                XCTAssertTrue(message.contains(param), message)
            }
        }
    }

    func testAnUnknownRuleIs400ListingTheValidOnes() async throws {
        let response = try await get("/router/exchanges?rule=bogus", on: makeRouter())
        XCTAssertEqual(response.status, 400)
        let message = try json(response)["error"] as? String ?? ""
        for filter in Sessions.AccountRouterRuleFilter.allCases {
            XCTAssertTrue(message.contains(filter.rawValue), message)
        }
    }

    func testNoRouterIs503NotAnEmptyAnswer() async throws {
        for path in ["/router/status", "/router/report", "/router/exchanges"] {
            let response = try await get(path, on: nil)
            XCTAssertEqual(response.status, 503, path)
            XCTAssertEqual(try json(response)["status"] as? String, "unavailable")
        }
    }

    func testUnknownRouterPathIs404() async throws {
        let response = try await get("/router/nope", on: makeRouter())
        XCTAssertEqual(response.status, 404)
    }

    func testTheTableClaimsNothingElse() async {
        let table = table(makeRouter())
        for (method, path) in [("GET", "/router"), ("GET", "/router/status/x"), ("POST", "/router/status"),
                               ("GET", "/accounts/credentials"), ("GET", "/accounts")] {
            let response = await table.handle(RouteRequest(method: method, path: path))
            XCTAssertNil(response, "\(method) \(path)")
        }
    }

    func testTheEndpointsListEveryRoute() {
        XCTAssertEqual(AccountRouterRoutes.endpoints, [
            "GET /router/status", "GET /router/report", "GET /router/exchanges", "POST /accounts/credentials"
        ])
    }

    // MARK: - Model routing

    func testStatusCarriesTheModelSectionInSnakeCase() async throws {
        let body = try json(try await get("/router/status", on: makeRouter()))
        let models = try XCTUnwrap(body["models"] as? [String: Any])
        XCTAssertEqual(models["enabled"] as? Bool, false)
        XCTAssertNil(models["rules"], "the stored table is gone; templates carry the rules")
        let templates = try XCTUnwrap(models["templates"] as? [[String: Any]])
        XCTAssertEqual(templates.count, Sessions.ModelRouterTemplateDTO.builtIns.count)
        XCTAssertNotNil(models["providers"] as? [Any])
    }

    private func subagentBody() -> Data {
        let object: [String: Any] = [
            "model": "claude-opus-5-5", "max_tokens": 1000,
            "system": [["type": "text", "text": "You are a file search specialist."]],
            "tools": [["name": "Read", "input_schema": ["type": "object"]]],
            "messages": [["role": "user", "content": "find the parser"]]
        ]
        return (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
    }

    private func request(_ userAgent: String) -> RouterRequestHead {
        RouterRequestHead(method: "POST", target: "/v1/messages", version: "HTTP/1.1",
                          fields: [HTTPHeaderField(name: "User-Agent", value: userAgent)])
    }

    func testStatusReportsTheTemplateInUseForTheNewestClientVersion() throws {
        try database.setSetting(ModelRouterSettings.enabledKey, "1")
        let builtIn = Sessions.ModelRouterTemplateDTO.builtIns[0]
        let router = makeRouter()
        let before = router.status().models
        XCTAssertNil(before?.clientVersion)
        XCTAssertEqual(before?.inUse, builtIn.id, "the only template is the highest-through fallback")
        XCTAssertEqual(before?.inUseIsFallback, true)

        _ = router.modelPlanner.plan(request("claude-cli/2.1.296"), body: subagentBody())
        let covered = router.status().models
        XCTAssertEqual(covered?.clientVersion, "2.1.296")
        XCTAssertEqual(covered?.inUse, builtIn.id)
        XCTAssertEqual(covered?.inUseIsFallback, false)

        _ = router.modelPlanner.plan(request("claude-cli/9.9.9"), body: subagentBody())
        let uncovered = router.status().models
        XCTAssertEqual(uncovered?.clientVersion, "9.9.9")
        XCTAssertEqual(uncovered?.inUse, builtIn.id)
        XCTAssertEqual(uncovered?.inUseIsFallback, true)
    }

    func testReportCarriesPerModelRows() async throws {
        var row = AccountRouterExchange(
            startedAt: Date(), durationMs: 5, sessionId: "s", method: "POST", path: "/v1/messages",
            status: 200, account: "oauth:a@x.com", routingRule: "ranked")
        row.requestedModel = "claude-opus-4"
        row.servedModel = "claude-haiku-4"
        row.provider = nil
        row.inputTokens = 10
        row.outputTokens = 3
        try database.insertRouterExchange(row)
        try database.insertRouterExchange(row)
        let body = try json(try await get("/router/report?since_hours=0", on: makeRouter()))
        let models = try XCTUnwrap(body["models"] as? [[String: Any]])
        XCTAssertEqual(models.count, 1)
        XCTAssertEqual(models[0]["requested_model"] as? String, "claude-opus-4")
        XCTAssertEqual(models[0]["served_model"] as? String, "claude-haiku-4")
        XCTAssertEqual(models[0]["requests"] as? Int, 2)
        XCTAssertEqual(models[0]["input_tokens"] as? Int, 20)
        XCTAssertEqual(models[0]["output_tokens"] as? Int, 6)
    }

    private struct StubProviders: ModelProviderResolving {
        let usable: UUID
        func resolve(_ id: UUID, model: String?) -> Result<ProviderRoute, ProviderUnavailable> {
            guard id == usable, let url = URL(string: "https://example.test/v1/chat/completions") else {
                return .failure(.unavailable)
            }
            return .success(ProviderRoute(
                configID: id, name: "good", endpoint: url, apiKey: "sk-super-secret", model: "m",
                wire: .chatCompletions(maxTokensKey: "max_tokens")))
        }
    }

    func testStatusProvidersReportUsableAndLeakNothing() async throws {
        let good = UUID()
        let bad = UUID()
        let configs = [
            AIProviderConfiguration(id: good, name: "good", pluginIdentifier: "p", templateId: "t"),
            AIProviderConfiguration(id: bad, name: "bad", pluginIdentifier: "p", templateId: "t")
        ]
        let list = try XCTUnwrap(String(bytes: try JSONEncoder().encode(configs), encoding: .utf8))
        try database.setSetting(AIProviderConfigKeys.configurationsKey, list)
        try database.setSetting(AIProviderConfigKeys.modelKey(config: good), "gpt-x")
        let response = try await get("/router/status", on: makeRouter(providers: StubProviders(usable: good)))
        let models = try XCTUnwrap(try json(response)["models"] as? [String: Any])
        let providers = try XCTUnwrap(models["providers"] as? [[String: Any]])
        XCTAssertEqual(providers.count, 2)
        let byName = Dictionary(uniqueKeysWithValues: providers.compactMap { row in
            (row["name"] as? String).map { ($0, row) }
        })
        XCTAssertEqual(byName["good"]?["usable"] as? Bool, true)
        XCTAssertEqual(byName["bad"]?["usable"] as? Bool, false)
        XCTAssertEqual(byName["good"]?["model"] as? String, "gpt-x")
        for row in providers {
            XCTAssertEqual(Set(row.keys), ["id", "name", "model", "usable"])
        }
        let text = try text(response)
        for leak in ["sk-super-secret", "api_key", "endpoint", "example.test"] {
            XCTAssertFalse(text.contains(leak), leak)
        }
    }

    func testReportModelRowsHonourSinceAndIncludeServedOnlyRows() async throws {
        func row(_ date: Date, requested: String?, served: String?) -> AccountRouterExchange {
            var exchange = AccountRouterExchange(
                startedAt: date, durationMs: 5, sessionId: "s", method: "POST", path: "/v1/messages",
                status: 200, account: "oauth:a@x.com", routingRule: "ranked")
            exchange.requestedModel = requested
            exchange.servedModel = served
            return exchange
        }
        let old = Date().addingTimeInterval(-3 * 3600)
        try database.insertRouterExchange(row(old, requested: "old-req", served: "old"))
        try database.insertRouterExchange(row(Date(), requested: "claude-opus-4", served: "claude-haiku-4"))
        try database.insertRouterExchange(row(Date(), requested: nil, served: "claude-sonnet-4"))
        let body = try json(try await get("/router/report?since_hours=1", on: makeRouter()))
        let models = try XCTUnwrap(body["models"] as? [[String: Any]])
        XCTAssertEqual(models.count, 2)
        XCTAssertFalse(models.contains { ($0["requested_model"] as? String) == "old-req" })
        let servedOnly = try XCTUnwrap(models.first { ($0["served_model"] as? String) == "claude-sonnet-4" })
        XCTAssertNil(servedOnly["requested_model"])
        XCTAssertEqual(servedOnly["requests"] as? Int, 1)
    }

    // MARK: - POST /accounts/credentials

    private let secretToken = "sk-ant-oat01-relayed-secret"

    private func credentialBody(_ credentials: [Sessions.ClaudeCredentialDTO]) throws -> Data {
        try StenographerWire.encoder().encode(credentials)
    }

    private func longLived(_ account: String, token: String) -> Sessions.ClaudeCredentialDTO {
        Sessions.ClaudeCredentialDTO(
            account: account, credentialKind: ClaudeCredentialKind.longLived.rawValue, token: token,
            itemKey: "long-lived:\(account)")
    }

    private func relay(_ body: Data) async throws -> RouteResponse {
        try await send("POST", "/accounts/credentials", body: body, on: table(nil))
    }

    func testRelayStoresTheSetAndEchoesNoToken() async throws {
        let response = try await relay(try credentialBody([longLived("a@x.com", token: secretToken)]))
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(try json(response)["changed"] as? Bool, true)
        XCTAssertFalse(try text(response).contains(secretToken), "the reply carries no token")
        XCTAssertFalse(try text(response).contains("sk-ant"))
        XCTAssertEqual(try store.load().map(\.token), [secretToken])
        XCTAssertEqual(try store.load().map(\.account), ["a@x.com"])
        XCTAssertEqual(store.saves, 1)
    }

    func testRelayingTheSameSetAgainChangesNothing() async throws {
        let body = try credentialBody([longLived("a@x.com", token: secretToken)])
        _ = try await relay(body)
        let again = try await relay(body)
        XCTAssertEqual(again.status, 200)
        XCTAssertEqual(try json(again)["changed"] as? Bool, false)
        XCTAssertEqual(store.saves, 1, "an unchanged push costs nothing")
    }

    func testRelayingAnEmptySetClearsTheStore() async throws {
        _ = try await relay(try credentialBody([longLived("a@x.com", token: secretToken)]))
        let cleared = try await relay(try credentialBody([]))
        XCTAssertEqual(cleared.status, 200)
        XCTAssertEqual(try json(cleared)["changed"] as? Bool, true)
        XCTAssertEqual(try store.load().count, 0)
    }

    func testAnUndecodableBodyIs400AndEchoesNothing() async throws {
        let leaky = Data(#"[{"account":"a@x.com","token":"\#(secretToken)""#.utf8)
        for body in [leaky, Data(), Data(#"{"account":"a@x.com"}"#.utf8)] {
            let response = try await relay(body)
            XCTAssertEqual(response.status, 400)
            XCTAssertFalse(try text(response).contains(secretToken))
            XCTAssertFalse(try text(response).contains("a@x.com"))
        }
        XCTAssertEqual(store.saves, 0)
        XCTAssertEqual(try store.load().count, 0)
    }

    func testRelayWorksWithoutARouter() async throws {
        let response = try await relay(try credentialBody([longLived("b@x.com", token: "t-b")]))
        XCTAssertEqual(response.status, 200, "the relay is the probe's, not the router's")
    }
}
