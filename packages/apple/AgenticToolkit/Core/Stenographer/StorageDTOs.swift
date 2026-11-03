import Foundation

/// What one storage trim pass did, as a daemon reports it over HTTP and XPC.
/// Mirrors the Database module's `TrimReport` field for field (Core cannot see
/// that type); `TrimReportDTO(_:)` in the Database module converts.
public struct TrimReportDTO: Codable, Sendable, Equatable {
    public let startedAt: Double
    public let finishedAt: Double
    /// Rows older than this (epoch seconds) were eligible; nil when nothing was.
    public let cutoff: Double?
    /// Why part or all of the pass did nothing ("rollups", "events.db
    /// unavailable", "skipped: bulk load", "billing"). Not an error.
    public let waitingFor: String?
    public let events: Int
    public let messages: Int
    public let turns: Int
    public let sessions: Int
    public let rateLimitSnapshots: Int
    public let reclaimedBytes: Int64
    public let vacuum: String
    /// False when rows may still be due (deadline, failed stage, bulk load).
    public let finished: Bool
    /// A stage that failed; the counts are still what was deleted.
    public let error: String?

    public init(
        startedAt: Double, finishedAt: Double, cutoff: Double? = nil, waitingFor: String? = nil,
        events: Int = 0, messages: Int = 0, turns: Int = 0, sessions: Int = 0, rateLimitSnapshots: Int = 0,
        reclaimedBytes: Int64 = 0, vacuum: String = "skipped", finished: Bool = true, error: String? = nil
    ) {
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.cutoff = cutoff
        self.waitingFor = waitingFor
        self.events = events
        self.messages = messages
        self.turns = turns
        self.sessions = sessions
        self.rateLimitSnapshots = rateLimitSnapshots
        self.reclaimedBytes = reclaimedBytes
        self.vacuum = vacuum
        self.finished = finished
        self.error = error
    }
}

/// One database file in a daemon's support directory and whether the trim
/// keeps it small.
public struct StorageFileDTO: Codable, Sendable, Equatable {
    /// The roles a file can have.
    public enum Role {
        public static let main = "main"
        public static let events = "events"
        public static let rawBackup = "raw-backup"
        public static let spool = "spool"
        public static let legacySpool = "legacy-spool"
    }

    /// The file name, e.g. "stenographer.db".
    public let name: String
    /// One of ``Role``'s values.
    public let role: String
    /// The file plus its `-wal` and `-shm`.
    public let bytes: Int64
    /// Whether the trim deletes old rows from it (never the raw backup or a spool).
    public let trimmed: Bool
    /// A word for the reader, e.g. "Raw backup — not trimmed".
    public let note: String?

    public init(name: String, role: String, bytes: Int64, trimmed: Bool, note: String? = nil) {
        self.name = name
        self.role = role
        self.bytes = bytes
        self.trimmed = trimmed
        self.note = note
    }
}

/// A daemon's storage: the history window, its database files and the last
/// trim pass.
public struct StorageStatusDTO: Codable, Sendable, Equatable {
    /// Days of event history kept.
    public let historyDays: Int
    /// The windows that can be chosen, in days.
    public let allowedHistoryDays: [Int]
    /// The database files that exist (a missing one is left out).
    public let files: [StorageFileDTO]
    /// The last pass's report, nil before the first.
    public let lastTrim: TrimReportDTO?
    /// Whether a pass is running now.
    public let trimRunning: Bool
    /// "open" or "unavailable", as `/health` reports it; nil when unknown.
    public let claudePipeline: String?

    public init(
        historyDays: Int, allowedHistoryDays: [Int], files: [StorageFileDTO], lastTrim: TrimReportDTO?,
        trimRunning: Bool, claudePipeline: String?
    ) {
        self.historyDays = historyDays
        self.allowedHistoryDays = allowedHistoryDays
        self.files = files
        self.lastTrim = lastTrim
        self.trimRunning = trimRunning
        self.claudePipeline = claudePipeline
    }
}

/// The body of a change to the storage preferences.
public struct StoragePreferencesRequestDTO: Codable, Sendable, Equatable {
    /// The new history window; snapped to an allowed value by the daemon.
    public let historyDays: Int

    public init(historyDays: Int) {
        self.historyDays = historyDays
    }
}
