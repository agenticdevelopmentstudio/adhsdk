import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class ModelRouterSettingsTests: XCTestCase {
    private var database: DaemonDatabase!
    private var directory: URL!
    private var store: ModelRouterTemplateStore!

    override func setUpWithError() throws {
        database = try DaemonDatabase(
            path: ":memory:", migrations: SessionSchema.migrations, postMigration: SessionSchema.postMigration)
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-settings-\(UUID().uuidString)")
        store = ModelRouterTemplateStore(directory: directory, database: database)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testDefaultsWhenNothingIsStored() {
        let settings = ModelRouterSettings.load(database, store: store)
        XCTAssertEqual(settings, ModelRouterSettings())
        XCTAssertFalse(settings.enabled)
        XCTAssertEqual(settings.templates, Sessions.ModelRouterTemplateDTO.builtIns)
        XCTAssertTrue(settings.preferred.isEmpty)
    }

    func testAnOldTierRowIsIgnored() throws {
        let row = #"{"tiers":[{"tier":"light","about":"L","target":"provider:\#(UUID().uuidString)"}]}"#
        try database.setSetting("model_router_tiers", row)
        XCTAssertEqual(ModelRouterSettings.load(database, store: store), ModelRouterSettings())
    }

    func testIdRules() {
        XCTAssertTrue(Sessions.ModelRequestKindDTO.isValidId("a-1"))
        XCTAssertFalse(Sessions.ModelRequestKindDTO.isValidId("unclassified"))
        XCTAssertTrue(Sessions.ModelRequestKindDTO.isValidId("unclassified", allowUnclassified: true))
        for bad in ["", "-a", "A", "a_b", "a b", String(repeating: "a", count: 65)] {
            XCTAssertFalse(Sessions.ModelRequestKindDTO.isValidId(bad), bad)
        }
        XCTAssertTrue(Sessions.ModelRequestKindDTO.isValidId(String(repeating: "a", count: 64)))
    }

    func testEnabledRowLoads() throws {
        try database.setSetting(ModelRouterSettings.enabledKey, "1")
        XCTAssertTrue(ModelRouterSettings.load(database, store: store).enabled)
    }

    func testUserCopiesAndPreferredMarksLoadFromTheStore() throws {
        let copy = Sessions.ModelRouterTemplateDTO(
            id: "c", name: "C", claudeCode: .init(from: "2.1.300", through: "2.1.310"), requests: [])
        try store.apply(Sessions.ModelRouterPreferencesDTO(saveTemplate: copy, preferTemplate: "c"))
        let settings = ModelRouterSettings.load(database, store: store)
        XCTAssertTrue(settings.templates.contains(copy))
        XCTAssertEqual(settings.preferred, ["c"])
    }
}
