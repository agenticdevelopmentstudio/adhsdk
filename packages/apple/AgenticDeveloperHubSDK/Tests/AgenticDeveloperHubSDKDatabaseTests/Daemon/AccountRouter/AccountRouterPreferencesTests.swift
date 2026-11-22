import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// The one writer of the router's settings rows: what it accepts, what it
/// refuses, and that a refusal leaves every row as it was.
final class AccountRouterPreferencesTests: XCTestCase {
    private var database: DaemonDatabase!
    private var preferences: AccountRouterPreferences!
    private var templatesDir: URL!

    override func setUpWithError() throws {
        database = try DaemonDatabase(
            path: ":memory:", migrations: SessionSchema.migrations, postMigration: SessionSchema.postMigration)
        templatesDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-prefs-templates-\(UUID().uuidString)")
        preferences = AccountRouterPreferences(
            database: database,
            templateStore: ModelRouterTemplateStore(directory: templatesDir, database: database))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: templatesDir)
    }

    func testATemplateSaveStoresAFileAndTheStatusListsIt() throws {
        let copy = Sessions.ModelRouterTemplateDTO(
            id: "mine", name: "Mine", claudeCode: .init(from: "2.1.300", through: "2.1.310"), requests: [])
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            models: Sessions.ModelRouterPreferencesDTO(saveTemplate: copy, preferTemplate: "mine")))
        XCTAssertTrue(FileManager.default.fileExists(atPath: templatesDir.appendingPathComponent("mine.json").path))
        let status = AccountRouterServer(
            database: database, source: FakeQuotaSource(), port: 0, upstream: URL(fileURLWithPath: "/"),
            fingerprintsPath: templatesDir.appendingPathComponent("fp.json").path,
            templateStore: ModelRouterTemplateStore(directory: templatesDir, database: database)).status()
        XCTAssertEqual(status.models?.templates?.map(\.id).last, "mine")
        XCTAssertEqual(status.models?.preferred, ["mine"])
    }

    func testARefusedTemplateWriteReturnsTheSentenceAndWritesNothing() throws {
        let bad = Sessions.ModelRouterTemplateDTO(
            id: "mine", name: "", claudeCode: .init(from: "2.1.300", through: "2.1.310"), requests: [])
        XCTAssertThrowsError(try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            models: Sessions.ModelRouterPreferencesDTO(enabled: true, saveTemplate: bad)))) { error in
            XCTAssertEqual(error.localizedDescription, Sessions.ModelRouterTemplateValidation.nameMissing)
        }
        XCTAssertNil(try database.setting(for: ModelRouterSettings.enabledKey))
        XCTAssertFalse(FileManager.default.fileExists(atPath: templatesDir.path))
    }

    func testWritesEveryFieldItIsGiven() throws {
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            enabled: true, accounts: ["oauth:a@x.com", "long-lived:b"], fiveHourCeiling: 0.8))
        XCTAssertEqual(AccountRouterSettings.load(database), AccountRouterSettings(
            enabled: true, accounts: ["oauth:a@x.com", "long-lived:b"], fiveHourCeiling: 0.8))
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.enabledKey), "1")
    }

    func testAbsentFieldsAreLeftAlone() throws {
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            enabled: true, accounts: ["oauth:a@x.com"], fiveHourCeiling: 0.8))
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(enabled: false))
        let settings = AccountRouterSettings.load(database)
        XCTAssertFalse(settings.enabled)
        XCTAssertEqual(settings.accounts, ["oauth:a@x.com"])
        XCTAssertEqual(settings.fiveHourCeiling, 0.8)
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.enabledKey), "0")
    }

    func testDuplicatesAreDroppedKeepingFirstListedOrder() throws {
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            accounts: ["oauth:b@x.com", "oauth:a@x.com", "oauth:b@x.com"]))
        XCTAssertEqual(AccountRouterSettings.load(database).accounts, ["oauth:b@x.com", "oauth:a@x.com"])
    }

    func testAnEmptyPoolIsAllowed() throws {
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(accounts: ["oauth:a@x.com"]))
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(accounts: []))
        XCTAssertEqual(AccountRouterSettings.load(database).accounts, [])
    }

    func testAnOutOfRangeCeilingIsRefusedAndNothingIsWritten() {
        for bad in [0, -0.1, 1.01] {
            XCTAssertThrowsError(try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
                enabled: true, fiveHourCeiling: bad))) { error in
                XCTAssertTrue(error.localizedDescription.contains("ceiling"), error.localizedDescription)
            }
        }
        XCTAssertEqual(AccountRouterSettings.load(database), AccountRouterSettings(), "the enable was not applied")
    }

    func testANonFiniteCeilingIsRefused() {
        for bad in [Double.nan, .infinity, -.infinity] {
            XCTAssertThrowsError(try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
                enabled: true, fiveHourCeiling: bad))) { error in
                XCTAssertTrue(error.localizedDescription.contains("ceiling"), error.localizedDescription)
            }
        }
        XCTAssertEqual(AccountRouterSettings.load(database), AccountRouterSettings())
    }

    func testANonFiniteStoredCeilingReadsAsTheDefault() throws {
        for raw in ["nan", "NaN", "inf", "-inf", "infinity", "1e400"] {
            try database.setSetting(AccountRouterSettings.ceilingKey, raw)
            XCTAssertEqual(AccountRouterSettings.load(database).fiveHourCeiling,
                           AccountRouterSettings.defaultCeiling, raw)
        }
    }

    func testAnAccountThatIsNotAnItemKeyIsRefused() {
        for bad in ["a@x.com", "oauth:", "nonsense:a@x.com"] {
            XCTAssertThrowsError(try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
                enabled: true, accounts: ["oauth:ok@x.com", bad]))) { error in
                XCTAssertTrue(error.localizedDescription.contains(bad), error.localizedDescription)
            }
        }
        XCTAssertEqual(AccountRouterSettings.load(database), AccountRouterSettings())
    }

    // MARK: - Tuning rows

    func testTheTuningRowsDefaultWhenAbsent() {
        let settings = AccountRouterSettings.load(database)
        XCTAssertEqual(settings.cooldownSeconds, 60)
        XCTAssertEqual(settings.expiryMarginSeconds, 300)
        XCTAssertTrue(settings.retry)
        XCTAssertTrue(settings.sticky)
        XCTAssertEqual(settings.retentionDays, 30)
    }

    func testValidTuningRowsAreRead() throws {
        try database.setSetting(AccountRouterSettings.cooldownKey, "5")
        try database.setSetting(AccountRouterSettings.expiryMarginKey, "0")
        try database.setSetting(AccountRouterSettings.retentionDaysKey, "3650")
        try database.setSetting(AccountRouterSettings.retryKey, "0")
        try database.setSetting(AccountRouterSettings.stickyKey, "0")
        let settings = AccountRouterSettings.load(database)
        XCTAssertEqual(settings.cooldownSeconds, 5)
        XCTAssertEqual(settings.expiryMarginSeconds, 0)
        XCTAssertEqual(settings.retentionDays, 3650)
        XCTAssertFalse(settings.retry)
        XCTAssertFalse(settings.sticky)
        try database.setSetting(AccountRouterSettings.retryKey, "1")
        try database.setSetting(AccountRouterSettings.stickyKey, "1")
        let back = AccountRouterSettings.load(database)
        XCTAssertTrue(back.retry)
        XCTAssertTrue(back.sticky)
    }

    func testAGarbageTuningRowReadsAsItsDefault() throws {
        let rows: [(key: String, aboveMax: String, read: (AccountRouterSettings) -> Int, fallback: Int)] = [
            (AccountRouterSettings.cooldownKey, "3601", { $0.cooldownSeconds }, 60),
            (AccountRouterSettings.expiryMarginKey, "3601", { $0.expiryMarginSeconds }, 300),
            (AccountRouterSettings.retentionDaysKey, "3651", { $0.retentionDays }, 30)
        ]
        for row in rows {
            for raw in ["abc", "", "-1", row.aboveMax, "1e9"] {
                try database.setSetting(row.key, raw)
                XCTAssertEqual(row.read(AccountRouterSettings.load(database)), row.fallback, "\(row.key) = \(raw)")
            }
            try database.setSetting(row.key, "")
        }
        try database.setSetting(AccountRouterSettings.cooldownKey, "0")
        XCTAssertEqual(AccountRouterSettings.load(database).cooldownSeconds, 60, "a cool-down of 0 is out of range")
    }

    func testEveryTuningFieldWritesItsRow() throws {
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            cooldownSeconds: 30, expiryMarginSeconds: 120, retry: false, sticky: false, retentionDays: 0))
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.cooldownKey), "30")
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.expiryMarginKey), "120")
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.retryKey), "0")
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.stickyKey), "0")
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.retentionDaysKey), "0")
        let settings = AccountRouterSettings.load(database)
        XCTAssertEqual(settings.cooldownSeconds, 30)
        XCTAssertEqual(settings.expiryMarginSeconds, 120)
        XCTAssertFalse(settings.retry)
        XCTAssertFalse(settings.sticky)
        XCTAssertEqual(settings.retentionDays, 0)
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(retry: true, sticky: true))
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.retryKey), "1")
        XCTAssertEqual(try database.setting(for: AccountRouterSettings.stickyKey), "1")
        XCTAssertEqual(AccountRouterSettings.load(database).cooldownSeconds, 30, "absent fields are left alone")
    }

    func testOutOfRangeTuningValuesAreRefusedAndNothingIsWritten() {
        let cases: [(Sessions.AccountRouterPreferencesRequestDTO, String)] = [
            (Sessions.AccountRouterPreferencesRequestDTO(cooldownSeconds: 0), "from 1 to 3600 (got 0)"),
            (Sessions.AccountRouterPreferencesRequestDTO(cooldownSeconds: 3601), "from 1 to 3600 (got 3601)"),
            (Sessions.AccountRouterPreferencesRequestDTO(expiryMarginSeconds: -1), "from 0 to 3600 (got -1)"),
            (Sessions.AccountRouterPreferencesRequestDTO(expiryMarginSeconds: 3601), "from 0 to 3600 (got 3601)"),
            (Sessions.AccountRouterPreferencesRequestDTO(retentionDays: -1), "0 to 3650 days (got -1)"),
            (Sessions.AccountRouterPreferencesRequestDTO(retentionDays: 3651), "0 to 3650 days (got 3651)")
        ]
        for (base, phrase) in cases {
            var request = base
            request.enabled = true
            request.fiveHourCeiling = 0.5
            request.retry = false
            XCTAssertThrowsError(try preferences.setAccountRouter(request)) { error in
                XCTAssertTrue(error.localizedDescription.contains(phrase), error.localizedDescription)
            }
        }
        XCTAssertNil(try database.setting(for: AccountRouterSettings.ceilingKey), "the ceiling was not written")
        XCTAssertNil(try database.setting(for: AccountRouterSettings.cooldownKey))
        XCTAssertNil(try database.setting(for: AccountRouterSettings.expiryMarginKey))
        XCTAssertNil(try database.setting(for: AccountRouterSettings.retentionDaysKey))
        XCTAssertNil(try database.setting(for: AccountRouterSettings.retryKey))
        XCTAssertEqual(AccountRouterSettings.load(database), AccountRouterSettings())
    }

    func testTheBoundaryTuningValuesAreAccepted() throws {
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            cooldownSeconds: 1, expiryMarginSeconds: 0, retentionDays: 3650))
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            cooldownSeconds: 3600, expiryMarginSeconds: 3600, retentionDays: 0))
        let settings = AccountRouterSettings.load(database)
        XCTAssertEqual(settings.cooldownSeconds, 3600)
        XCTAssertEqual(settings.expiryMarginSeconds, 3600)
        XCTAssertEqual(settings.retentionDays, 0)
    }

    // MARK: - Status DTO on the wire

    func testAStatusWithoutTheTuningKeysDecodesToTheDefaults() throws {
        let json = #"{"enabled":true,"port":8,"listening":true,"base_url":"http://127.0.0.1:8","#
            + #""five_hour_ceiling":0.9,"pool":[],"saved_credentials":["oauth:a@x.com"]}"#
        let status = try StenographerWire.decoder()
            .decode(Sessions.AccountRouterStatusDTO.self, from: Data(json.utf8))
        XCTAssertEqual(status.cooldownSeconds, 60)
        XCTAssertEqual(status.expiryMarginSeconds, 300)
        XCTAssertTrue(status.retry)
        XCTAssertTrue(status.sticky)
        XCTAssertEqual(status.retentionDays, 30)
        XCTAssertEqual(status.fiveHourCeiling, 0.9)
        XCTAssertEqual(status.savedCredentials, ["oauth:a@x.com"])
    }

    func testAStatusWithTheTuningKeysRoundTrips() throws {
        let status = Sessions.AccountRouterStatusDTO(
            enabled: true, port: 8, listening: false, baseUrl: "http://127.0.0.1:8", fiveHourCeiling: 0.9,
            pool: [], savedCredentials: [], cooldownSeconds: 5, expiryMarginSeconds: 0, retry: false,
            sticky: false, retentionDays: 0)
        let data = try StenographerWire.encoder().encode(status)
        let text = String(bytes: data, encoding: .utf8) ?? ""
        for key in ["cooldown_seconds", "expiry_margin_seconds", "\"retry\"", "\"sticky\"", "retention_days"] {
            XCTAssertTrue(text.contains(key), key)
        }
        XCTAssertEqual(
            try StenographerWire.decoder().decode(Sessions.AccountRouterStatusDTO.self, from: data),
                       status)
    }

    func testAPastedTokenIsRefusedWithoutBeingEchoed() {
        XCTAssertThrowsError(try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(
            accounts: ["sk-ant-oat01-pasted-secret"]))) { error in
            XCTAssertFalse(error.localizedDescription.contains("sk-ant"), "the refusal must not echo a token")
        }
        XCTAssertEqual(AccountRouterSettings.load(database), AccountRouterSettings())
    }

    // MARK: - Model routing

    private func modelPrefs(enabled: Bool = true) -> Sessions.AccountRouterPreferencesRequestDTO {
        Sessions.AccountRouterPreferencesRequestDTO(models: Sessions.ModelRouterPreferencesDTO(enabled: enabled))
    }

    func testTheModelSwitchIsWritten() throws {
        try preferences.setAccountRouter(modelPrefs())
        XCTAssertEqual(try database.setting(for: ModelRouterSettings.enabledKey), "1")
        try preferences.setAccountRouter(modelPrefs(enabled: false))
        XCTAssertEqual(try database.setting(for: ModelRouterSettings.enabledKey), "0")
    }

    func testAbsentModelsLeavesTheRowsAlone() throws {
        try preferences.setAccountRouter(modelPrefs())
        try preferences.setAccountRouter(Sessions.AccountRouterPreferencesRequestDTO(enabled: true))
        XCTAssertEqual(try database.setting(for: ModelRouterSettings.enabledKey), "1")
    }

    // MARK: - Template parts

    private func save(_ template: Sessions.ModelRouterTemplateDTO) -> Sessions.AccountRouterPreferencesRequestDTO {
        Sessions.AccountRouterPreferencesRequestDTO(models: Sessions.ModelRouterPreferencesDTO(saveTemplate: template))
    }

    private func refusal(_ request: Sessions.AccountRouterPreferencesRequestDTO) -> String? {
        do {
            try preferences.setAccountRouter(request)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private func mine() -> Sessions.ModelRouterTemplateDTO {
        var template = Sessions.ModelRouterTemplateDTO.builtIns[0]
        template.id = "user.mine"
        template.name = "Mine"
        return template
    }

    private func statusTemplates() -> [Sessions.ModelRouterTemplateDTO] {
        AccountRouterServer(
            database: database, source: FakeQuotaSource(), port: 0, upstream: URL(fileURLWithPath: "/"),
            fingerprintsPath: templatesDir.appendingPathComponent("fp.json").path,
            templateStore: ModelRouterTemplateStore(directory: templatesDir, database: database))
            .status().models?.templates ?? []
    }

    func testSavingATemplateWritesAllFourPartsAndTheStatusCarriesThem() throws {
        var template = mine()
        template.tiers.append(Sessions.ModelTierDTO(id: "huge", name: "Huge"))
        template.requestTiers["command-subagent"] = "huge"
        template.tierTargets["huge"] = Sessions.ModelTierTarget.provider(UUID(), model: "big-1").text
        try preferences.setAccountRouter(save(template))
        XCTAssertEqual(statusTemplates().first { $0.id == "user.mine" }, template)
        XCTAssertNil(try database.setting(for: "model_router_tiers"), "nothing writes the old tier row")
    }

    func testABadPartIsRefusedWithItsSentenceAndSavesNothing() throws {
        var template = mine()
        template.tierTargets["light"] = "haiku"
        XCTAssertEqual(refusal(save(template)), Sessions.ModelRouterTemplateValidation.tierTargetBad)
        template = mine()
        template.requestTiers["background"] = "huge"
        XCTAssertEqual(refusal(save(template)), Sessions.ModelRouterTemplateValidation.requestTierUnknown)
        XCTAssertFalse(statusTemplates().contains { $0.id == "user.mine" })
    }

    func testAnUnknownProviderIdIsAccepted() throws {
        var template = mine()
        template.tierTargets["light"] = "provider:\(UUID().uuidString)"
        XCTAssertNil(refusal(save(template)))
    }

    func testTheRetiredTierWritesAreIgnored() throws {
        let json = #"{"models":{"set_tier":{"tier":"light","target":"claude"},"reset_tiers":true}}"#
        let request = try StenographerWire.decoder()
            .decode(Sessions.AccountRouterPreferencesRequestDTO.self, from: Data(json.utf8))
        try preferences.setAccountRouter(request)
        XCTAssertNil(try database.setting(for: "model_router_tiers"))
    }
}
