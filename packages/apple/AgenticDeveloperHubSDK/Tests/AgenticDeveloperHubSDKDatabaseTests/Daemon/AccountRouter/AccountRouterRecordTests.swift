import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The router's persistence: migration 049, the exchange row, pruning, the
/// report's arithmetic (including 429s that a retry hid), the settings rows,
/// and the scrubber every error string passes through before it is stored.
final class AccountRouterRecordTests: XCTestCase {

    private var tmpDir: URL!
    private var tmpPath: String!
    private var database: DaemonDatabase!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("account-router-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        tmpPath = tmpDir.appendingPathComponent("stenographer.db").path
        database = try DaemonDatabase(
            path: tmpPath, migrations: SessionSchema.migrations, postMigration: SessionSchema.postMigration)
    }

    override func tearDownWithError() throws {
        database = nil
        // The whole directory, so the WAL and shared-memory files go too.
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func row(
        _ account: String?, status: Int?, rule: String?, five: Double? = nil, seven: Double? = nil,
        org: String? = nil, startedAt: Date = Date()
    ) -> AccountRouterExchange {
        AccountRouterExchange(
            startedAt: startedAt, durationMs: 12, sessionId: "s1", method: "POST", path: "/v1/messages",
            status: status, account: account, routingRule: rule, fiveHourUtilization: five,
            sevenDayUtilization: seven, fiveHourStatus: "allowed", sevenDayStatus: "allowed",
            organizationId: org, error: nil)
    }

    func testMigration049CreatesTheExchangeTableAndARowRoundTrips() throws {
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "ranked", five: 0.25, org: "org-a"))
        let rows = try database.routerExchanges(limit: 10)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].account, "oauth:a@x.com")
        XCTAssertEqual(rows[0].routingRule, "ranked")
        XCTAssertEqual(rows[0].fiveHourUtilization ?? -1, 0.25, accuracy: 0.0001)
        XCTAssertEqual(rows[0].organizationId, "org-a")
        XCTAssertEqual(rows[0].path, "/v1/messages")
    }

    func testANullStatusAndNullRuleAreStoredAsNull() throws {
        try database.insertRouterExchange(row(nil, status: nil, rule: nil))
        let rows = try database.routerExchanges(limit: 10)
        XCTAssertNil(rows[0].status)
        XCTAssertNil(rows[0].routingRule)
        XCTAssertNil(rows[0].account)
    }

    func testPruneDeletesOnlyRowsOlderThanRetention() throws {
        let old = Date().addingTimeInterval(-10 * 86400)
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "ranked", startedAt: old))
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "sticky"))
        XCTAssertEqual(try database.deleteOldRouterExchanges(olderThanDays: 7), 1)
        XCTAssertEqual(try database.routerExchanges(limit: 10).map(\.routingRule), ["sticky"])
    }

    /// Final review M1: the prune is batched, oldest first.
    func testPruneDeletesInBatchesOldestFirst() throws {
        let now = Date()
        for age in [12, 11, 10] {
            try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "d\(age)",
                                                  startedAt: now.addingTimeInterval(-Double(age) * 86400)))
        }
        XCTAssertEqual(try database.deleteOldRouterExchanges(olderThanDays: 7, batchSize: 2, now: now), 2)
        XCTAssertEqual(try database.routerExchanges(limit: 10).map(\.routingRule), ["d10"])
        XCTAssertEqual(try database.deleteOldRouterExchanges(olderThanDays: 7, batchSize: 2, now: now), 1)
        XCTAssertEqual(try database.deleteOldRouterExchanges(olderThanDays: 7, batchSize: 2, now: now), 0)
    }

    func testInsertScrubsTheErrorColumnWhateverTheCallerDid() throws {
        var raw = row("oauth:a@x.com", status: 502, rule: "ranked")
        raw.error = "boom sk-ant-oat01-secret\u{07}value"
        try database.insertRouterExchange(raw)
        let stored = try XCTUnwrap(database.routerExchanges(limit: 1).first?.error)
        XCTAssertEqual(stored, "boom [redacted]")
    }

    func testInsertKeepsOnlyVisibleCharactersOfModelProviderAndStopReason() throws {
        var raw = row("oauth:a@x.com", status: 200, rule: "ranked")
        raw.requestedModel = "claude-\u{1B}]52;c;eA==\u{07}x"
        raw.routedModel = "claude-haiku\u{200B}-5-5"
        raw.servedModel = "gpt\u{1B}[2J"
        raw.provider = "P\u{202E}"
        raw.stopReason = "end\u{0}_turn"
        try database.insertRouterExchange(raw)
        let stored = try XCTUnwrap(database.routerExchanges(limit: 1).first)
        XCTAssertEqual(stored.requestedModel, "claude-]52;c;eA==x")
        XCTAssertEqual(stored.routedModel, "claude-haiku-5-5")
        XCTAssertEqual(stored.servedModel, "gpt[2J")
        XCTAssertEqual(stored.provider, "P")
        XCTAssertEqual(stored.stopReason, "end_turn")
    }

    func testReportCountsRequestsPeaksOrgsAndRetried429s() throws {
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "ranked",
                                              five: 0.5, seven: 0.2, org: "org-a"))
        try database.insertRouterExchange(row("oauth:a@x.com", status: 429, rule: "sticky",
                                              five: 0.97, seven: 0.3, org: "org-a"))
        // b served it after a answered 429: a's 429 is in the rule, not the status.
        let retried = "switched: oauth:a@x.com ineligible (retry after oauth:a@x.com 429)"
        try database.insertRouterExchange(row("long-lived:b", status: 200, rule: retried,
                                              five: 0.1, org: "org-b"))
        // c answered 429 and nobody served it afterwards; c has no row of its own.
        try database.insertRouterExchange(row(nil, status: 200, rule: "all-ineligible (retry after oauth:c@x.com 429)"))
        let report = try database.routerReport(sinceHours: 24)
        XCTAssertEqual(report.total, 4)
        let byAccount = Dictionary(uniqueKeysWithValues: report.rows.map { ($0.account ?? "-", $0) })
        XCTAssertEqual(byAccount["oauth:a@x.com"]?.requests, 2)
        XCTAssertEqual(byAccount["oauth:a@x.com"]?.rateLimited, 2, "one relayed 429 plus one retried away")
        XCTAssertEqual(byAccount["oauth:a@x.com"]?.peakFiveHour ?? -1, 0.97, accuracy: 0.0001)
        XCTAssertEqual(byAccount["oauth:a@x.com"]?.organizationIds, ["org-a"])
        XCTAssertEqual(byAccount["long-lived:b"]?.rateLimited, 0)
        XCTAssertEqual(byAccount["oauth:c@x.com"]?.requests, 0)
        XCTAssertEqual(byAccount["oauth:c@x.com"]?.rateLimited, 1)
        XCTAssertEqual(byAccount["-"]?.requests, 1, "verbatim requests are reported under a nil account")
    }

    func testReportSinceHoursExcludesOlderRows() throws {
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "ranked",
                                              startedAt: Date().addingTimeInterval(-3 * 3600)))
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "sticky"))
        XCTAssertEqual(try database.routerReport(sinceHours: 1).total, 1)
        XCTAssertEqual(try database.routerReport(sinceHours: 0).total, 2, "0 means all time")
    }

    func testRetriedAccountParsesOnlyTheTrailingMarker() {
        XCTAssertEqual(
            Sessions.AccountRouterReportDTO.retriedAccount(in: "ranked (retry after oauth:a@x.com 429)", status: 429),
                       "oauth:a@x.com")
        XCTAssertNil(
            Sessions.AccountRouterReportDTO.retriedAccount(in: "ranked (retry after oauth:a@x.com 401)", status: 429))
        XCTAssertNil(Sessions.AccountRouterReportDTO.retriedAccount(in: "ranked (retry after  429)", status: 429))
        XCTAssertNil(Sessions.AccountRouterReportDTO.retriedAccount(in: "ranked", status: 429))
        XCTAssertNil(Sessions.AccountRouterReportDTO.retriedAccount(in: "x (retry after 429)", status: 429))
    }

    func testSettingsDefaultOffAndRejectBadCeilings() throws {
        XCTAssertEqual(AccountRouterSettings.load(database), AccountRouterSettings())
        try database.setSetting(AccountRouterSettings.enabledKey, "1")
        try database.setSetting(AccountRouterSettings.accountsKey, #"["oauth:a@x.com","long-lived:b"]"#)
        try database.setSetting(AccountRouterSettings.ceilingKey, "0.8")
        let loaded = AccountRouterSettings.load(database)
        XCTAssertTrue(loaded.enabled)
        XCTAssertEqual(loaded.accounts, ["oauth:a@x.com", "long-lived:b"])
        XCTAssertEqual(loaded.fiveHourCeiling, 0.8)
        try database.setSetting(AccountRouterSettings.ceilingKey, "1.5")
        try database.setSetting(AccountRouterSettings.accountsKey, "not json")
        let fallback = AccountRouterSettings.load(database)
        XCTAssertEqual(fallback.fiveHourCeiling, 0.95, "an out-of-range ceiling falls back to the default")
        XCTAssertEqual(fallback.accounts, [], "an unreadable pool is an empty pool")
    }

    // Review Focus 1.
    func testScrubRemovesTokensAndControlCharacters() {
        let leaked = "bad token sk-ant-oat01-AbC_d-9 and\nsk-ant-api03-zz\u{07}end"
        let scrubbed = AccountRouterLog.scrub(leaked)
        XCTAssertFalse(scrubbed.contains("sk-ant-oat01"))
        XCTAssertFalse(scrubbed.contains("sk-ant-api03"))
        XCTAssertFalse(scrubbed.contains("\n"))
        XCTAssertFalse(scrubbed.contains("\u{07}"))
        // Control characters are deleted before redaction, so the `\u{07}`
        // joins "end" to the token and it goes with it.
        XCTAssertEqual(scrubbed, "bad token [redacted] and[redacted]")
        XCTAssertEqual(AccountRouterLog.scrub(String(repeating: "x", count: 500)).count, 200)
        XCTAssertEqual(AccountRouterLog.scrub("sk-ant-"), "sk-ant-", "the regex needs at least one token character")
    }

    /// Final review I1: a control character inside a token, or inside its
    /// prefix, must not let any part of the secret through.
    func testScrubDeletesControlCharactersBeforeRedacting() {
        let cases = [
            "leaked sk-ant-oat01-secret\u{07}value",
            "leaked sk-\u{07}ant-oat01-secretvalue",
            "leaked sk-ant-oat01-secret\nvalue",
            "leaked sk-ant-oat01-secret\tvalue",
            "leaked sk-ant-oat01-secret\r\nvalue",
            "leaked sk-a\u{0}nt-oat01-secret\u{2028}value",
            "leaked s\u{200B}k-ant-oat01-secret\u{85}value"
        ]
        for (index, text) in cases.enumerated() {
            let scrubbed = AccountRouterLog.scrub(text)
            XCTAssertEqual(scrubbed, "leaked [redacted]", "case \(index)")
            XCTAssertFalse(scrubbed.contains("secret"), "case \(index)")
            XCTAssertFalse(scrubbed.contains("value"), "case \(index)")
        }
    }

    /// Re-review N1: nothing invisible survives to split a token or hide its
    /// prefix (marks, fillers, variation selectors, private use, unassigned),
    /// and a visible oddity inside a token cannot end the redaction either.
    func testScrubDeletesEveryInvisibleScalarBeforeRedacting() {
        let cases = [
            "leaked sk-ant-oat01-sec\u{0301}retvalue",
            "leaked sk-ant-oat01-sec\u{FE0F}retvalue",
            "leaked sk-ant-oat01-sec\u{034F}retvalue",
            "leaked s\u{0301}k-ant-oat01-secretvalue",
            "leaked sk-a\u{FE0F}nt-oat01-secretvalue",
            "leaked sk\u{034F}-ant-oat01-secretvalue",
            "leaked sk-ant-oat01-sec\u{20DD}retvalue",
            "leaked sk-ant-oat01-sec\u{3164}retvalue",
            "leaked sk\u{115F}-ant-oat01-secret\u{1160}value",
            "leaked sk-ant-oat01-sec\u{FFA0}retvalue",
            "leaked sk-ant-oat01-sec\u{E0100}retvalue",
            "leaked sk-ant-oat01-sec\u{E000}retvalue",
            "leaked sk-ant-oat01-sec\u{0378}retvalue",
            "leaked sk-ant-oat01-sec\u{2800}retvalue",
            "leaked sk-ant-oat01-sec!\u{E9}#retvalue"
        ]
        for (index, text) in cases.enumerated() {
            let scrubbed = AccountRouterLog.scrub(text)
            XCTAssertEqual(scrubbed, "leaked [redacted]", "case \(index)")
            XCTAssertFalse(scrubbed.contains("ret"), "case \(index)")
            XCTAssertFalse(scrubbed.contains("value"), "case \(index)")
        }
        XCTAssertEqual(AccountRouterLog.scrub("café naïve \u{2713} 東京"), "café naïve \u{2713} 東京",
                       "visible text, accents included, is kept")
        XCTAssertEqual(AccountRouterLog.scrub("token sk-ant-oat01-abc then more"), "token [redacted] then more",
                       "a space ends the token")
    }

    /// Final review minor 7: provider keys (OpenAI `sk-`/`sk-proj-`, Google
    /// `AIza`) are redacted too, and the route's own key by exact value.
    func testScrubRedactsProviderKeysAndTheRoutesOwnKey() {
        let openAI = "sk-" + String(repeating: "A1b2", count: 12)
        let project = "sk-proj-" + String(repeating: "Zz9_", count: 20)
        let google = "AIza" + String(repeating: "Sy-x", count: 9)
        XCTAssertEqual(AccountRouterLog.scrub("bad key \(openAI) here"), "bad key [redacted] here")
        XCTAssertEqual(AccountRouterLog.scrub("bad key \(project)"), "bad key [redacted]")
        XCTAssertEqual(AccountRouterLog.scrub("url ?key=\(google)&x=1 done"), "url ?key=[redacted] done")
        XCTAssertEqual(AccountRouterLog.scrub("the disk-full error, risk-free"), "the disk-full error, risk-free",
                       "a short run after sk- is an ordinary word")
        XCTAssertEqual(AccountRouterLog.scrub("AIzaleas is a word"), "AIzaleas is a word")

        let own = "plain-provider-secret-1234"
        XCTAssertEqual(AccountRouterLog.scrub("echoed:\(own):tail", secrets: [own]), "echoed:[redacted]:tail",
                       "the route's key goes by value, whatever its shape")
        XCTAssertEqual(AccountRouterLog.scrub("echoed:plain-pro\u{07}vider-secret-1234!", secrets: [own]),
                       "echoed:[redacted]!", "invisible characters cannot hide the value either")
        XCTAssertEqual(AccountRouterLog.scrub("short abc stays", secrets: ["abc", nil]), "short abc stays",
                       "a value too short to be a key is not matched")
    }

    /// Nothing that could split a log line survives, token or not.
    func testScrubOutputIsAlwaysOneLine() {
        let scrubbed = AccountRouterLog.scrub("one\ntwo\r\nthree\tfour\u{2029}five\u{0B}six")
        XCTAssertEqual(scrubbed, "onetwothreefourfivesix")
        let long = String(repeating: "a", count: 195) + "\n" + "sk-ant-oat01-" + String(repeating: "z", count: 50)
        let cut = AccountRouterLog.scrub(long)
        XCTAssertFalse(cut.contains("zzz"), "truncation comes after redaction")
        XCTAssertEqual(cut.count, 200)
    }

    // MARK: - Exchange page

    private func ids(_ query: Sessions.AccountRouterExchangeQueryDTO, now: Date = Date()) throws -> [Int] {
        try database.routerExchangePage(query, now: now).map(\.id)
    }

    func testPageIsNewestFirstAndPagesByAfterAndBeforeId() throws {
        for index in 1...5 {
            try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "ranked \(index)"))
        }
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO()), [5, 4, 3, 2, 1])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(limit: 2)), [5, 4])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(beforeId: 4, limit: 2)), [3, 2])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(afterId: 3)), [5, 4])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(afterId: 1, beforeId: 4)), [3, 2])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(afterId: 5)), [])
    }

    func testPageCarriesEveryColumnAsStored() throws {
        var full = row("oauth:a@x.com", status: 429, rule: "sticky", five: 0.5, seven: 0.25, org: "org-a",
                       startedAt: Date(timeIntervalSince1970: 1_800_000_000.25))
        full.error = "upstream closed"
        try database.insertRouterExchange(full)
        let dto = try XCTUnwrap(database.routerExchangePage(Sessions.AccountRouterExchangeQueryDTO()).first)
        XCTAssertEqual(dto, Sessions.AccountRouterExchangeDTO(
            id: 1, startedAt: DaemonDatabase.routerTimestamp(full.startedAt), durationMs: 12, sessionId: "s1",
            method: "POST", path: "/v1/messages", status: 429, account: "oauth:a@x.com", routingRule: "sticky",
            fiveHourUtilization: 0.5, sevenDayUtilization: 0.25, fiveHourStatus: "allowed",
            sevenDayStatus: "allowed", organizationId: "org-a", error: "upstream closed"))
    }

    func testMigration050ModelColumnsRoundTripThroughInsertAndPage() throws {
        var full = row("oauth:a@x.com", status: 200, rule: "ranked",
                       startedAt: Date(timeIntervalSince1970: 1_800_000_000.5))
        full.requestedModel = "claude-opus-5-5"
        full.routedModel = "claude-sonnet-5-5"
        full.servedModel = "claude-sonnet-5-5"
        full.modelRule = "Read-only subagents asking for Opus go to Sonnet"
        full.provider = "p-1"
        full.threadKind = "subagent"
        full.writes = false
        full.inputTokens = 120
        full.outputTokens = 34
        full.cacheReadTokens = 5
        full.cacheCreationTokens = 6
        full.stopReason = "end_turn"
        try database.insertRouterExchange(full)
        let dto = try XCTUnwrap(database.routerExchangePage(Sessions.AccountRouterExchangeQueryDTO()).first)
        XCTAssertEqual(dto, Sessions.AccountRouterExchangeDTO(
            id: 1, startedAt: DaemonDatabase.routerTimestamp(full.startedAt), durationMs: 12, sessionId: "s1",
            method: "POST", path: "/v1/messages", status: 200, account: "oauth:a@x.com", routingRule: "ranked",
            fiveHourUtilization: nil, sevenDayUtilization: nil, fiveHourStatus: "allowed",
            sevenDayStatus: "allowed", organizationId: nil, error: nil,
            requestedModel: "claude-opus-5-5", routedModel: "claude-sonnet-5-5", servedModel: "claude-sonnet-5-5",
            modelRule: "Read-only subagents asking for Opus go to Sonnet", provider: "p-1", threadKind: "subagent",
            writes: false, inputTokens: 120, outputTokens: 34, cacheReadTokens: 5, cacheCreationTokens: 6,
            stopReason: "end_turn"))
        XCTAssertEqual(try database.routerExchanges(limit: 1).first, full)
    }

    func testMigration1006IsSafeToRunAgain() throws {
        XCTAssertNoThrow(try DaemonDatabase.migration1006(database))
        try database.insertRouterExchange(row(nil, status: 200, rule: nil))
        let stored = try XCTUnwrap(database.routerExchanges(limit: 1).first)
        XCTAssertNil(stored.modelRule)
        XCTAssertNil(stored.writes)
    }

    func testEachRuleFilterReturnsExactlyItsRows() throws {
        let rules: [String?] = [
            "sticky",                                    // 1
            "ranked",                                    // 2
            "switched: oauth:a@x.com ineligible",        // 3
            "all-ineligible",                            // 4
            "passthrough: not routable",                 // 5
            "ranked (retry after oauth:a@x.com 429)",    // 6
            nil,                                         // 7
            "passthrough: unknown credential"            // 8
        ]
        for rule in rules {
            try database.insertRouterExchange(row(rule == nil ? nil : "oauth:a@x.com", status: 200, rule: rule))
        }
        let expected: [Sessions.AccountRouterRuleFilter: [Int]] = [
            .sticky: [1], .ranked: [6, 2], .switched: [3], .allIneligible: [4], .passthrough: [8, 5],
            .retried: [6], .off: [7]
        ]
        for filter in Sessions.AccountRouterRuleFilter.allCases {
            XCTAssertEqual(
                try ids(Sessions.AccountRouterExchangeQueryDTO(rule: filter)), expected[filter], filter.rawValue)
        }
    }

    func testAccountDashMeansVerbatimAndAnyOtherIsAnExactKey() throws {
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "ranked"))
        try database.insertRouterExchange(row(nil, status: 200, rule: "passthrough: not routable"))
        try database.insertRouterExchange(row("oauth:b@x.com", status: 200, rule: "ranked"))
        XCTAssertEqual(
            try ids(.init(account: Sessions.AccountRouterExchangeQueryDTO.verbatimAccount)),
            [2])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(account: "oauth:b@x.com")), [3])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(account: "oauth:%")), [], "no wildcard")
    }

    func testSinceHoursLimitsTheWindowAndZeroOrLessIsAllTime() throws {
        let now = Date()
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "ranked",
                                              startedAt: now.addingTimeInterval(-10 * 3600)))
        try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "sticky",
                                              startedAt: now.addingTimeInterval(-60)))
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(sinceHours: 5), now: now), [2])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(sinceHours: 0), now: now), [2, 1])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(sinceHours: -3), now: now), [2, 1])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(sinceHours: Int.max), now: now), [2, 1],
                       "a huge window is clamped, never an overflow")
    }

    func testLimitIsClampedToOneThroughAThousand() throws {
        try database.transaction {
            for _ in 0..<1001 {
                try database.insertRouterExchange(row("oauth:a@x.com", status: 200, rule: "ranked"))
            }
        }
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(limit: 0)).count, 1)
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(limit: -7)).count, 1)
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(limit: 5000)).count, 1000)
        XCTAssertEqual(
            try ids(Sessions.AccountRouterExchangeQueryDTO()).count,
            Sessions.AccountRouterExchangeQueryDTO.defaultLimit)
    }

    func testQuotesAndPercentSignsAreDataNotSQL() throws {
        try database.insertRouterExchange(row("o'brien%", status: 200, rule: "sticky' OR '1'='1"))
        try database.insertRouterExchange(row("o'brienX", status: 200, rule: "50% ranked"))
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(account: "o'brien%")), [1])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(account: "x' OR '1'='1")), [])
        XCTAssertEqual(try ids(Sessions.AccountRouterExchangeQueryDTO(rule: .sticky)), [1])
        XCTAssertEqual(
            try ids(Sessions.AccountRouterExchangeQueryDTO(rule: .ranked)), [], "\"50% ranked\" is not a ranked rule")
        XCTAssertEqual(try database.routerExchangePage(Sessions.AccountRouterExchangeQueryDTO()).count, 2)
    }

    func testTheConfigurationDefaultsToTheAnthropicAPI() {
        let data = URL(fileURLWithPath: "/tmp/router-config-test")
        let config = AccountRouterConfiguration(
            label: "router-test", dataDirectory: data, fingerprintsPath: data.appendingPathComponent("fp.json").path)
        XCTAssertEqual(config.upstream.absoluteString, "https://api.anthropic.com")
        XCTAssertEqual(config.label, "router-test")
    }
}
