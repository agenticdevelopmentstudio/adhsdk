import AgenticDeveloperHubSDKCore
import Foundation
import GRDB
@testable import AgenticDeveloperHubSDKDatabase

/// The harness pieces the session feature tests (billing, rollup, Usage, trim)
/// use: a pipeline beside a database file, and event-store rows written or
/// deleted directly where a test needs exact rows and nothing else, the way
/// those tests once wrote and trimmed `event_log`.
extension ClaudePipelineTestHarness {

    /// A harness beside the database file at `databasePath`, in a `pipeline`
    /// folder of that file's directory.
    convenience init(besideDatabaseAt databasePath: String, database: DaemonDatabase) throws {
        let directory = URL(fileURLWithPath: databasePath).deletingLastPathComponent()
            .appendingPathComponent("pipeline")
        try self.init(directory: directory, database: database)
    }

    /// Distinct dedup keys and raw refs for seeded rows, across every harness.
    private static let seedCounter = SeedCounter()

    /// Writes one event-store row and nothing else: no session row, no raw
    /// record. `timestamp` is ISO-8601 (fractional seconds allowed).
    func seed(
        sessionId: String, type: String, timestamp: String,
        cwd: String? = "/src/app", toolName: String? = nil, summary: String? = nil
    ) throws {
        guard let time = Self.seedDate(timestamp) else {
            throw DrainFailure(reason: "unparseable seed timestamp \(timestamp)")
        }
        let seeded = Self.seedCounter.next()
        let event = NormalizedEvent(
            dedupKey: "seed-\(seeded)", sessionID: sessionId, kind: .other, providerType: type,
            time: time, cwd: cwd, toolName: toolName, summary: summary, rawRef: Int64(seeded))
        var batch = NormalizedBatch()
        batch.events = [event]
        try store.write(batch, provider: ClaudeProvider.name)
    }

    /// Writes one event-store turn, as a transcript line's turn lands there:
    /// `account` stays nil on the turn itself and lives on the main `sessions`
    /// row instead. With `account` given, a session stub carrying it (and
    /// `authMethod`) is created unless the session already has a row — what the
    /// main-db sink does for a transcript-only session. With `account` nil no
    /// session row is written. `cacheCreation1h` lands in `attrs`, as the
    /// normalizer puts it.
    func seedTurn(
        sessionId: String, timestamp: String, model: String? = "sonnet", dedupKey: String? = nil,
        input: Int = 0, output: Int = 0, cacheRead: Int = 0, cacheCreation: Int = 0,
        cacheCreation1h: Int = 0, toolName: String? = nil, kind: String = "assistant",
        account: String? = nil, authMethod: String = "unknown"
    ) throws {
        guard let time = Self.seedDate(timestamp) else {
            throw DrainFailure(reason: "unparseable seed timestamp \(timestamp)")
        }
        let seeded = Self.seedCounter.next()
        let turn = TurnRow(
            dedupKey: dedupKey ?? "seed-turn-\(seeded)", sessionID: sessionId, time: time,
            model: model, toolName: toolName, inputTokens: input, outputTokens: output,
            cacheReadTokens: cacheRead, cacheWriteTokens: cacheCreation,
            attrs: [
                "kind": .string(kind),
                "cache_creation_1h_tokens": .number(Double(cacheCreation1h)),
                "is_subagent": .bool(false)
            ],
            rawRef: Int64(seeded))
        var batch = NormalizedBatch()
        batch.turns = [turn]
        try store.write(batch, provider: ClaudeProvider.name)
        if let account {
            try database.createSessionStubIfMissing(
                sessionId: sessionId, cwd: "/tmp", model: "", startedAt: timestamp,
                lastActivityAt: timestamp, accountEmail: account, authMethod: authMethod)
        }
    }

    /// Deletes the event-store rows matching `whereClause` (SQL over the
    /// `events` columns, e.g. `"session_id = ?"`), as retention trims them.
    func deleteEvents(where whereClause: String = "1", arguments: [any DatabaseValueConvertible] = []) throws {
        let queue = try DatabaseQueue(path: directory.appendingPathComponent(EventStore.fileName).path)
        try queue.write { conn in
            try conn.execute(
                sql: "DELETE FROM events WHERE \(whereClause)",
                arguments: StatementArguments(arguments.map { $0 as (any DatabaseValueConvertible)? }))
        }
        try queue.close()
    }

    /// Writes one `store_meta` value into `events.db`, as a replay records its progress.
    func setStoreMeta(_ key: String, _ value: String) throws {
        let queue = try DatabaseQueue(path: directory.appendingPathComponent(EventStore.fileName).path)
        try queue.write { conn in
            try conn.execute(sql: "INSERT OR REPLACE INTO store_meta (key, value) VALUES (?, ?)",
                             arguments: [key, value])
        }
        try queue.close()
    }

    /// Empties the event store and lets it number from 1 again, as a store
    /// rebuilt from the raw archive would: the ids readers held no longer exist.
    func rebuildEventIds() throws {
        let queue = try DatabaseQueue(path: directory.appendingPathComponent(EventStore.fileName).path)
        try queue.write { conn in
            try conn.execute(sql: "DELETE FROM events")
            try conn.execute(sql: "DELETE FROM sqlite_sequence WHERE name = 'events'")
        }
        try queue.close()
    }

    /// The epoch seconds an ISO-8601 stamp names, as the event store keeps it.
    static func epoch(_ timestamp: String) -> Double? {
        seedDate(timestamp)?.timeIntervalSince1970
    }

    private static func seedDate(_ timestamp: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return ISO8601DateFormatter().date(from: timestamp) ?? fractional.date(from: timestamp)
    }
}

/// A process-wide counter behind a lock, for `seed` and `seedTurn`.
private final class SeedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }
}
