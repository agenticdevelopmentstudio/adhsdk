import AgenticDeveloperHubSDKCore
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class ModelRouterTemplateStoreTests: XCTestCase {
    private var database: DaemonDatabase!
    private var directory: URL!
    private var store: ModelRouterTemplateStore!

    override func setUpWithError() throws {
        database = try DaemonDatabase(
            path: ":memory:", migrations: SessionSchema.migrations, postMigration: SessionSchema.postMigration)
        directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sten-templates-\(UUID().uuidString)")
        store = ModelRouterTemplateStore(directory: directory, database: database)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private let builtIn = Sessions.ModelRouterTemplateDTO.builtIns[0]

    private func copy(
        _ id: String, name: String? = nil, from: String = "2.1.300", through: String = "2.1.310"
    ) -> Sessions.ModelRouterTemplateDTO {
        Sessions.ModelRouterTemplateDTO(
            id: id, name: name ?? id, claudeCode: .init(from: from, through: through),
            requests: Sessions.ModelRouterTemplateDTO.builtInRequests)
    }

    private func save(_ template: Sessions.ModelRouterTemplateDTO) throws {
        try store.apply(Sessions.ModelRouterPreferencesDTO(saveTemplate: template))
    }

    private func refusal(_ prefs: Sessions.ModelRouterPreferencesDTO) -> String? {
        do {
            try store.apply(prefs)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func testLoadHasTheBuiltInFirstThenCopiesByName() throws {
        try save(copy("z", name: "zeta"))
        try save(copy("a", name: "Alpha"))
        XCTAssertEqual(store.load().templates.map(\.name), [builtIn.name, "Alpha", "zeta"])
    }

    func testSaveReplacesByIdAndRefusesClashesAndBuiltIns() throws {
        try save(copy("one", name: "First"))
        try save(copy("one", name: "Renamed"))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["one.json"])
        XCTAssertEqual(store.load().templates.map(\.name), [builtIn.name, "Renamed"])
        try save(copy("two", name: "Other"))
        XCTAssertEqual(
            refusal(.init(saveTemplate: copy("two", name: "renamed"))),
            Sessions.ModelRouterTemplateValidation.nameTaken)
        XCTAssertEqual(refusal(.init(saveTemplate: builtIn)), Sessions.ModelRouterTemplateValidation.builtInReadOnly)
        XCTAssertEqual(
            refusal(.init(saveTemplate: copy("builtin.mine"))), Sessions.ModelRouterTemplateValidation.builtInReadOnly)
        XCTAssertEqual(refusal(.init(saveTemplate: copy("bad", from: "2.1.310", through: "2.1.300"))),
                       Sessions.ModelRouterTemplateValidation.backwardsRange)
    }

    func testBadIdsAreRefusedOnSave() {
        for id in ["../x", "", "a/b", ".foo", "..", "-x", "mine\n", String(repeating: "a", count: 129)] {
            XCTAssertEqual(
                refusal(.init(saveTemplate: copy(id, name: "n"))), Sessions.ModelRouterTemplateValidation.badId, id)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testPreferClearsOverlappingAndDeleteClearsPreferred() throws {
        try save(copy("A", from: "2.1.290", through: "2.1.296"))
        try save(copy("B", from: "2.1.300", through: "2.1.310"))
        try store.apply(.init(preferTemplate: builtIn.id))
        XCTAssertEqual(store.load().preferred, [builtIn.id])
        try store.apply(.init(preferTemplate: "A"))
        XCTAssertEqual(store.load().preferred, ["A"])
        try store.apply(.init(preferTemplate: "B"))
        XCTAssertEqual(store.load().preferred, ["A", "B"])
        try store.apply(.init(deleteTemplate: "A"))
        XCTAssertEqual(store.load().preferred, ["B"])
        try store.apply(.init(unpreferTemplate: "B"))
        XCTAssertEqual(store.load().preferred, [])
        XCTAssertEqual(
            refusal(.init(deleteTemplate: builtIn.id)), Sessions.ModelRouterTemplateValidation.builtInReadOnly)
        XCTAssertEqual(refusal(.init(preferTemplate: "nope")), Sessions.ModelRouterTemplateValidation.noSuchTemplate)
        XCTAssertEqual(refusal(.init(deleteTemplate: "../x")), Sessions.ModelRouterTemplateValidation.noSuchTemplate)
    }

    func testRequestStepsRunInOrderSaveDeletePreferUnprefer() throws {
        try save(copy("old", name: "Old"))
        try store.apply(.init(saveTemplate: copy("new", name: "Old2"), deleteTemplate: "old", preferTemplate: "new"))
        XCTAssertEqual(store.load().templates.map(\.id), [builtIn.id, "new"])
        XCTAssertEqual(store.load().preferred, ["new"])
    }

    func testUnreadableAndNewerFormatFilesAreSkippedWithReasons() throws {
        try save(copy("ok"))
        try Data("{".utf8).write(to: directory.appendingPathComponent("junk.json"))
        var newer = copy("future", name: "Future")
        newer.format = Sessions.ModelRouterTemplateDTO.currentFormat + 1
        try newer.encodedFile().write(to: directory.appendingPathComponent("future.json"))
        try copy("builtin.evil", name: "Evil").encodedFile()
            .write(to: directory.appendingPathComponent("builtin.evil.json"))
        let loaded = store.load()
        XCTAssertEqual(loaded.templates.map(\.id), [builtIn.id, "ok"])
        XCTAssertEqual(loaded.skipped.count, 3)
        for name in ["junk.json", "future.json", "builtin.evil.json"] {
            XCTAssertTrue(loaded.skipped.contains { $0.hasPrefix("\(name): ") }, name)
        }
        XCTAssertFalse(loaded.skipped.joined().contains("Evil\""))
    }

    /// Final review minor 2: a hand-placed file gets the same checks as a
    /// save, and a failure is listed with its sentence.
    func testAHandPlacedFileThatFailsValidationIsSkippedWithItsSentence() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try copy("backwards", name: "Backwards", from: "2.1.310", through: "2.1.300").encodedFile()
            .write(to: directory.appendingPathComponent("backwards.json"))
        try copy("escape", name: "Bad\u{1B}[31m").encodedFile()
            .write(to: directory.appendingPathComponent("escape.json"))
        let loaded = store.load()
        XCTAssertEqual(loaded.templates.map(\.id), [builtIn.id])
        XCTAssertEqual(Set(loaded.skipped), [
            "backwards.json: \(Sessions.ModelRouterTemplateValidation.backwardsRange)",
            "escape.json: \(Sessions.ModelRouterTemplateValidation.nameHasControls)"
        ])
    }

    /// Final review minor 3: the rows (the caller's and the preferred row)
    /// commit first; when the file step then fails, every row goes back.
    func testAFailedFileWriteRestoresTheRowsItCommitted() throws {
        try store.apply(.init(preferTemplate: builtIn.id))
        try database.setSetting("other_row", "before")
        let blocker = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-blocker-\(UUID())")
        try Data("not a directory".utf8).write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }
        let broken = ModelRouterTemplateStore(
            directory: blocker.appendingPathComponent("templates"), database: database)
        let plan = try broken.plan(.init(saveTemplate: copy("new", name: "New"), preferTemplate: "new"))
        let rows: [ModelRouterTemplateStore.Row] = [
            .init(key: "other_row", value: "after"), .init(key: "fresh_row", value: "1")
        ]
        XCTAssertThrowsError(try broken.commit(plan, rows: rows))
        XCTAssertEqual(try database.setting(for: "other_row"), "before")
        XCTAssertNil(try database.setting(for: "fresh_row"))
        XCTAssertEqual(store.load().preferred, [builtIn.id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: blocker.appendingPathComponent("templates").path))
    }

    func testOneRequestIsRefusedWhole() throws {
        try save(copy("one", name: "One"))
        try store.apply(.init(preferTemplate: "one"))
        let refused = refusal(.init(saveTemplate: copy("two", name: "ONE"), preferTemplate: builtIn.id))
        XCTAssertEqual(refused, Sessions.ModelRouterTemplateValidation.nameTaken)
        XCTAssertEqual(store.load().preferred, ["one"])
        XCTAssertEqual(store.load().templates.count, 2)
        let refusedLater = refusal(.init(saveTemplate: copy("three", name: "Three"), preferTemplate: "nope"))
        XCTAssertEqual(refusedLater, Sessions.ModelRouterTemplateValidation.noSuchTemplate)
        XCTAssertEqual(store.load().templates.count, 2)
    }

    func testAnIdDifferingOnlyByCaseIsRefused() throws {
        try save(copy("mine", name: "Mine"))
        XCTAssertEqual(
            refusal(.init(saveTemplate: copy("MINE", name: "Other"))), Sessions.ModelRouterTemplateValidation.badId)
        XCTAssertEqual(store.load().templates.count, 2)
    }

    func testSavingAPreferredTemplateWithAChangedRangeClearsNewOverlaps() throws {
        try save(copy("A", from: "2.1.290", through: "2.1.296"))
        try save(copy("B", from: "2.1.300", through: "2.1.310"))
        try store.apply(.init(preferTemplate: "A"))
        try store.apply(.init(preferTemplate: "B"))
        XCTAssertEqual(store.load().preferred, ["A", "B"])
        try save(copy("A", from: "2.1.290", through: "2.1.305"))
        XCTAssertEqual(store.load().preferred, ["A"])
    }

    func testTheTemplateRoundTripsThroughPlainAndSnakeCaseCoders() throws {
        let original = copy("rt", name: "Round trip")
        let plain = try JSONDecoder().decode(Sessions.ModelRouterTemplateDTO.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(plain, original)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let wire = try decoder.decode(Sessions.ModelRouterTemplateDTO.self, from: encoder.encode(original))
        XCTAssertEqual(wire, original)
    }

    func testAFormatOneCopyLoadsWithTheBuiltInRequestsAndAnOldPreferredMarkDisappears() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let json = #"{"format":1,"id":"old","name":"Old","provider":"Anthropic","model":"Opus","claude_code":{"from":"2.1.200","through":"2.1.250"},"rules":[],"models":{}}"# // swiftlint:disable:this line_length
        try Data(json.utf8).write(to: directory.appendingPathComponent("old.json"))
        try database.setSetting(
            ModelRouterTemplateStore.preferredKey, #"["builtin.anthropic.claude-opus-5-5.2.1.296","old"]"#)
        let loaded = store.load()
        XCTAssertEqual(loaded.templates.map(\.id), [builtIn.id, "old"])
        XCTAssertEqual(loaded.templates.last?.requests, Sessions.ModelRouterTemplateDTO.builtInRequests)
        XCTAssertEqual(loaded.preferred, ["old"])
        XCTAssertTrue(loaded.skipped.isEmpty)
    }

    func testASavedFileUsesTheClaudeCodeKey() throws {
        try save(copy("keyed"))
        let text = try String(contentsOf: directory.appendingPathComponent("keyed.json"), encoding: .utf8)
        XCTAssertTrue(text.contains("\"claude_code\""))
        XCTAssertFalse(text.contains("claudeCode"))
    }
}
