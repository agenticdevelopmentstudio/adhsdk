import XCTest
import Foundation
import GRDB
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The importer over fixture stores built with the real schemas: a source
/// directory laid out as stenographerd's (or adkd's) and a target opened the
/// way a runtime opens its four files.
final class LegacySessionImporterTests: XCTestCase {

    private var root: URL!
    private var sourceDirectory: URL!
    // swiftlint:disable:next identifier_name
    private var db: DaemonDatabase!
    private var spool: IngestSpool!
    private var store: EventStore!
    private var archive: RawArchive!
    private var importer: LegacySessionImporter!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("legacy-import-\(UUID().uuidString)", isDirectory: true)
        sourceDirectory = root.appendingPathComponent("source", isDirectory: true)
        let targetDirectory = root.appendingPathComponent("target", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true)

        db = try TestDaemonDatabase.makeSessionDatabase(
            path: targetDirectory.appendingPathComponent("sessions.db").path).db
        let spoolPath = targetDirectory.appendingPathComponent(IngestSpool.defaultDBName).path
        let storePath = targetDirectory.appendingPathComponent(EventStore.fileName).path
        let archivePath = targetDirectory.appendingPathComponent(rawFileName).path
        spool = try IngestSpool(path: spoolPath)
        store = try EventStore(path: storePath)
        archive = try RawArchive(path: archivePath, provider: ClaudeProvider.name)
        importer = LegacySessionImporter(target: .init(
            database: db, spoolPath: spoolPath, eventStorePath: storePath, rawArchivePath: archivePath))
    }

    override func tearDownWithError() throws {
        importer = nil
        archive = nil
        store = nil
        spool = nil
        db = nil
        try? FileManager.default.removeItem(at: root)
    }

    private var rawFileName: String { RawArchive.fileName(provider: ClaudeProvider.name) }

    // MARK: - Fixtures

    /// A stenographerd directory: every store, a few rows in each.
    private func makeStenographerSource() throws {
        try makeMainDatabase(named: "stenographer.db", billingPrefix: "stenographer_billing_")
        try makeSpool()
        try makeArchiveAndStore()
    }

    private func makeMainDatabase(named name: String, billingPrefix: String) throws {
        let path = sourceDirectory.appendingPathComponent(name).path
        let source = try TestDaemonDatabase.openFeatureDatabase(path: path)
        try source.execute("INSERT INTO sessions (session_id, cwd, model) VALUES ('s1', '/src/app', 'opus')")
        try source.execute("INSERT INTO sessions (session_id, cwd, model) VALUES ('s2', '/src/lib', 'sonnet')")
        try source.execute("""
            INSERT INTO event_log (session_id, event_type, timestamp, cwd, message_id)
            VALUES ('s1', 'PreToolUse', '2026-11-01T10:00:00Z', '/src/app', ''),
                   ('s1', 'PreToolUse', '2026-11-01T10:01:00Z', '/src/app', 'msg-1')
            """)
        let table = HookEventType.preToolUse.tableName
        try source.execute("""
            INSERT INTO \(table) (event_log_id, session_id, timestamp, cwd)
            SELECT id, session_id, timestamp, cwd FROM event_log
            """)
        try source.execute("""
            INSERT INTO rate_limit_snapshots (timestamp, session_id, weekly_pct, account_email)
            VALUES ('2026-11-01T10:00:00Z', 's1', 10, 'a@example.com'),
                   ('2026-11-01T10:05:00Z', 's1', 12, 'a@example.com')
            """)
        try source.execute(
            "INSERT INTO settings (key, value) VALUES (?, '30'), ('ingestion_enabled', 'true')",
            params: [billingPrefix + "idle_cutoff_minutes"])
        try source.execute(
            "INSERT INTO billing_client (id, name) VALUES ('client-1', 'Acme')")
    }

    private func makeSpool() throws {
        let path = sourceDirectory.appendingPathComponent(IngestSpool.defaultDBName).path
        _ = try IngestSpool(path: path)
        let queue = try DatabaseQueue(path: path)
        try queue.write { conn in
            try conn.execute(sql: """
                INSERT INTO spooled_event (received_at, event_type, session_id, envelope)
                VALUES (1.0, 'Stop', 's1', x'7B7D')
                """)
        }
    }

    private func makeArchiveAndStore() throws {
        let rawPath = sourceDirectory.appendingPathComponent(rawFileName).path
        let storePath = sourceDirectory.appendingPathComponent(EventStore.fileName).path
        _ = try RawArchive(path: rawPath, provider: ClaudeProvider.name)
        _ = try EventStore(path: storePath)
        try DatabaseQueue(path: rawPath).write { conn in
            // Two rows so the source ids differ from the target's.
            try conn.execute(sql: """
                INSERT INTO raw_record (source_kind, dedup_key, received_at, payload_size, payload_sha256,
                                        compression, payload)
                VALUES ('hook', 'raw-0', 1.0, 2, 'x', 'none', x'7B7D'),
                       ('hook', 'raw-1', 2.0, 2, 'y', 'none', x'7B7D')
                """)
        }
        try DatabaseQueue(path: storePath).write { conn in
            try conn.execute(sql: """
                INSERT INTO sessions (provider, session_id, cwd, as_of) VALUES ('claude', 's1', '/src/app', 1.0)
                """)
            try conn.execute(sql: """
                INSERT INTO events (provider, dedup_key, session_id, kind, provider_type, time, raw_ref)
                VALUES ('claude', 'event-1', 's1', 'tool', 'PreToolUse', 2.0, 2)
                """)
        }
    }

    // MARK: - Tests

    func testImportsEveryStoreAndReportsCounts() throws {
        try makeStenographerSource()

        let report = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        let main = try XCTUnwrap(report.store("stenographer.db"))
        XCTAssertEqual(main.status, .imported)
        XCTAssertEqual(main.inserted["sessions"], 2)
        XCTAssertEqual(main.inserted["event_log"], 2)
        XCTAssertEqual(main.inserted[HookEventType.preToolUse.tableName], 2)
        XCTAssertEqual(main.inserted["rate_limit_snapshots"], 2)
        XCTAssertEqual(main.inserted["settings"], 1, "only the billing setting")
        XCTAssertEqual(main.inserted["billing_client"], 1)
        XCTAssertEqual(report.store(IngestSpool.defaultDBName)?.inserted["spooled_event"], 1)
        XCTAssertEqual(report.store(rawFileName)?.inserted["raw_record"], 2)
        XCTAssertEqual(report.store(EventStore.fileName)?.inserted["events"], 1)
        XCTAssertEqual(report.store(EventStore.fileName)?.inserted["sessions"], 1)
    }

    func testASecondImportInsertsNothing() throws {
        try makeStenographerSource()

        let first = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)
        let second = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        XCTAssertGreaterThan(first.totalInserted, 0)
        XCTAssertEqual(second.totalInserted, 0, "\(second)")
        XCTAssertEqual(try count("SELECT COUNT(*) FROM event_log"), 2)
        XCTAssertEqual(try count("SELECT COUNT(*) FROM \(HookEventType.preToolUse.tableName)"), 2)
    }

    func testChildRowsPointAtTheirParentsTargetIds() throws {
        try makeStenographerSource()
        // Occupy the source's ids in the target, so a copied id would be wrong.
        try db.execute("""
            INSERT INTO event_log (session_id, event_type, timestamp) VALUES ('other', 'Stop', '2026-10-01T00:00:00Z'),
                ('other', 'Stop', '2026-10-01T00:00:01Z')
            """)

        _ = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        let orphans = try count("""
            SELECT COUNT(*) FROM \(HookEventType.preToolUse.tableName) c
            JOIN event_log e ON e.id = c.event_log_id WHERE e.session_id != c.session_id
            """)
        XCTAssertEqual(orphans, 0)
        XCTAssertEqual(try count("SELECT COUNT(*) FROM event_log WHERE session_id = 's1'"), 2)
    }

    func testAnEventTheTargetAlreadyHeldIsNotCopiedNorAreItsChildren() throws {
        try makeStenographerSource()
        try db.execute("""
            INSERT INTO event_log (session_id, event_type, timestamp, message_id)
            VALUES ('s1', 'PreToolUse', '2026-11-01T10:01:00Z', 'msg-1')
            """)

        let report = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        XCTAssertEqual(report.store("stenographer.db")?.inserted["event_log"], 1)
        XCTAssertEqual(report.store("stenographer.db")?.inserted[HookEventType.preToolUse.tableName], 1)
    }

    func testSnapshotsAreKeyedByTimestampAndAccount() throws {
        try makeStenographerSource()
        try db.execute("""
            INSERT INTO rate_limit_snapshots (timestamp, session_id, weekly_pct, account_email)
            VALUES ('2026-11-01T10:00:00Z', 'x', 10, 'a@example.com'),
                   ('2026-11-01T10:05:00Z', 'x', 12, 'b@example.com')
            """)

        let report = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        XCTAssertEqual(report.store("stenographer.db")?.inserted["rate_limit_snapshots"], 1,
                       "the 10:00 reading for a@ is already there; b@'s 10:05 is another account's")
    }

    func testAnExistingSessionIsLeftAlone() throws {
        try makeStenographerSource()
        try db.execute("INSERT INTO sessions (session_id, cwd, model) VALUES ('s1', '/target', 'haiku')")

        _ = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        var model = ""
        try db.query("SELECT model FROM sessions WHERE session_id = 's1'") { model = $0[0] ?? "" }
        XCTAssertEqual(model, "haiku")
    }

    func testBillingSettingsMoveToTheTargetPrefix() throws {
        try makeStenographerSource()

        _ = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        let key = db.billingSettingsKeyPrefix + "idle_cutoff_minutes"
        XCTAssertEqual(try count("SELECT COUNT(*) FROM settings WHERE key = '\(key)' AND value = '30'"), 1)
        XCTAssertEqual(try count("SELECT COUNT(*) FROM settings WHERE key LIKE 'stenographer_billing_%'"), 0)
        XCTAssertEqual(try count("SELECT COUNT(*) FROM settings WHERE key = 'ingestion_enabled'"), 0,
                       "the source's own switches never reach the target")
    }

    func testEventRowsPointAtTheTargetArchivesRecord() throws {
        try makeStenographerSource()

        _ = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        let targetRawId = try DatabaseQueue(path: archivePath).read { conn in
            try Int64.fetchOne(conn, sql: "SELECT id FROM raw_record WHERE dedup_key = 'raw-1'")
        }
        let rawRef = try DatabaseQueue(path: store.path).read { conn in
            try Int64.fetchOne(conn, sql: "SELECT raw_ref FROM events WHERE dedup_key = 'event-1'")
        }
        XCTAssertNotNil(rawRef)
        XCTAssertEqual(rawRef, targetRawId)
    }

    func testAnAdkdDirectoryWithOnlyItsTwoFiles() throws {
        try makeMainDatabase(named: "adkd.db", billingPrefix: "billing_")
        try makeSpool()

        let report = try importer.importStores(kind: .adkd, directory: sourceDirectory)

        XCTAssertEqual(report.store("adkd.db")?.inserted["sessions"], 2)
        XCTAssertEqual(report.store(EventStore.fileName)?.status, .missing)
        XCTAssertEqual(report.store(rawFileName)?.status, .missing)
        XCTAssertEqual(report.store(IngestSpool.defaultDBName)?.inserted["spooled_event"], 1)
    }

    func testTwoSourcesAreTrackedApart() throws {
        try makeStenographerSource()
        _ = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)
        let adkdDirectory = root.appendingPathComponent("adkd", isDirectory: true)
        try FileManager.default.createDirectory(at: adkdDirectory, withIntermediateDirectories: true)
        // With its WAL, in case the source's pool has not checkpointed it.
        for suffix in ["", "-wal", "-shm"] {
            let from = sourceDirectory.appendingPathComponent("stenographer.db" + suffix)
            guard FileManager.default.fileExists(atPath: from.path) else { continue }
            try FileManager.default.copyItem(at: from, to: adkdDirectory.appendingPathComponent("adkd.db" + suffix))
        }

        let report = try importer.importStores(kind: .adkd, directory: adkdDirectory)

        // The keyed event (msg-1) is the target's already; the unkeyed one is
        // another source's row and is copied.
        XCTAssertEqual(report.store("adkd.db")?.inserted["event_log"], 1)
        XCTAssertEqual(report.store("adkd.db")?.inserted["sessions"], 0)
    }

    func testTheReportPrintsAsJSON() throws {
        try makeStenographerSource()

        let report = try importer.importStores(kind: .stenographerd, directory: sourceDirectory)

        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(report.description.utf8)) as? [String: Any])
        XCTAssertEqual(object["source"] as? String, "stenographerd")
        XCTAssertNotNil(object["stores"] as? [[String: Any]])
    }

    // MARK: - Routes

    func testTheRouteImportsTheNamedDirectories() async throws {
        try makeStenographerSource()
        let table = LegacyImportRoutes.table(importer: importer)
        let body = try JSONEncoder().encode(LegacyImportRoutes.Request(stenographer: sourceDirectory.path, adkd: nil))

        let response = await table.handle(RouteRequest(method: "POST", path: "/import-legacy", body: body))

        XCTAssertEqual(response?.status, 200)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try XCTUnwrap(response?.body)) as? [String: Any])
        XCTAssertNotNil(object["stenographer"] as? [String: Any])
    }

    func testTheRouteRefusesAnEmptyRequest() async throws {
        let table = LegacyImportRoutes.table(importer: importer)
        let empty = try JSONEncoder().encode(LegacyImportRoutes.Request(stenographer: nil, adkd: nil))
        let missing = try JSONEncoder().encode(LegacyImportRoutes.Request(stenographer: "/no/such/dir", adkd: nil))

        let noBody = await table.handle(RouteRequest(method: "POST", path: "/import-legacy"))
        let none = await table.handle(RouteRequest(method: "POST", path: "/import-legacy", body: empty))
        let notThere = await table.handle(RouteRequest(method: "POST", path: "/import-legacy", body: missing))

        XCTAssertEqual(noBody?.status, 400)
        XCTAssertEqual(none?.status, 400)
        XCTAssertEqual(notThere?.status, 400)
    }

    // MARK: - Helpers

    private var archivePath: String {
        root.appendingPathComponent("target").appendingPathComponent(rawFileName).path
    }

    private func count(_ sql: String) throws -> Int {
        var value = 0
        try db.query(sql) { value = $0[0] ?? 0 }
        return value
    }
}
