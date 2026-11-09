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
    /// unavailable", "skipped: bulk load", "billing", "billing unreadable").
    /// Not an error; ``waitingText(_:)`` puts it in words.
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
    /// True when `events.db` still holds many free pages after a finished pass,
    /// so the next pass comes back soon to vacuum them. Nil from a daemon that
    /// predates the field.
    public let vacuumPending: Bool?

    public init(
        startedAt: Double, finishedAt: Double, cutoff: Double? = nil, waitingFor: String? = nil,
        events: Int = 0, messages: Int = 0, turns: Int = 0, sessions: Int = 0, rateLimitSnapshots: Int = 0,
        reclaimedBytes: Int64 = 0, vacuum: String = "skipped", finished: Bool = true, error: String? = nil,
        vacuumPending: Bool? = nil
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
        self.vacuumPending = vacuumPending
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

/// Where the background history backfill stands: the replay of the raw
/// archive's older records into a live `events.db` after a cutover that
/// started the daemon on a partly replayed one.
public struct HistoryBackfillDTO: Codable, Sendable, Equatable {
    /// The last archive id the backfill must reach.
    public let targetRawID: Int64
    /// The last archive id replayed so far.
    public let lastRawID: Int64
    /// Whether a slice of it runs now.
    public let running: Bool
    /// The last slice's error, nil when it ended cleanly or none ran yet.
    public let lastError: String?

    /// `targetRawID` encodes as `target_raw_id` under the wire's snake case,
    /// which `.convertFromSnakeCase` reads back as `targetRawId` — a key the
    /// synthesized decoding never matches. Naming the keys the way the decoder
    /// spells them keeps the same wire name and lets both directions agree.
    private enum CodingKeys: String, CodingKey {
        case targetRawID = "targetRawId"
        case lastRawID = "lastRawId"
        case running
        case lastError
    }

    public init(targetRawID: Int64, lastRawID: Int64, running: Bool, lastError: String? = nil) {
        self.targetRawID = targetRawID
        self.lastRawID = lastRawID
        self.running = running
        self.lastError = lastError
    }

    /// Archive ids still to replay (an upper bound: ids can have gaps).
    public var remaining: Int64 { max(0, targetRawID - lastRawID) }

    /// One line for a reader, the same in `steno storage` and the app:
    /// "Replaying older history: raw record 2,486,251 of 15,812,119 (running now)".
    public var summary: String {
        let state = running ? " (running now)" : lastError.map { " (last slice failed: \($0))" } ?? ""
        return "Replaying older history: raw record \(Self.grouped(lastRawID)) of \(Self.grouped(targetRawID))"
            + state
    }

    private static func grouped(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
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
    /// When the running pass started (epoch seconds); nil when none runs, or
    /// from a daemon older than this field.
    public let trimRunningSince: Double?
    /// Set only on the reply to a trim request: true when that request started
    /// the pass, false when it joined one already running. Nil on every other
    /// reply, and from a daemon older than this field.
    public let trimStarted: Bool?
    /// The history backfill while one is pending; nil when none is, and from a
    /// daemon older than this field.
    public let historyBackfill: HistoryBackfillDTO?

    public init(
        historyDays: Int, allowedHistoryDays: [Int], files: [StorageFileDTO], lastTrim: TrimReportDTO?,
        trimRunning: Bool, claudePipeline: String?, trimRunningSince: Double? = nil, trimStarted: Bool? = nil,
        historyBackfill: HistoryBackfillDTO? = nil
    ) {
        self.historyDays = historyDays
        self.allowedHistoryDays = allowedHistoryDays
        self.files = files
        self.lastTrim = lastTrim
        self.trimRunning = trimRunning
        self.claudePipeline = claudePipeline
        self.trimRunningSince = trimRunningSince
        self.trimStarted = trimStarted
        self.historyBackfill = historyBackfill
    }
}

/// The event history windows a daemon keeps, and how any other number of days
/// maps onto them. One copy for the daemon that stores the window and every
/// client that offers it.
public enum StorageHistoryWindow {
    /// The windows that can be chosen, in days, smallest first.
    public static let allowedDays = [7, 14, 30, 60, 90, 180, 365]

    /// The window when nothing usable is stored.
    public static let defaultDays = 30

    /// Whether `days` may be asked for at all: a whole number of days, at
    /// least one. Anything accepted is then snapped (``snap(_:allowed:)``).
    public static func accepts(_ days: Int) -> Bool { days >= 1 }

    /// The allowed window `days` means: the smallest allowed value at or above
    /// it, the largest for anything bigger. An empty `allowed` returns `days`.
    public static func snap(_ days: Int, allowed: [Int] = allowedDays) -> Int {
        let sorted = allowed.sorted()
        guard let largest = sorted.last else { return days }
        return sorted.first { $0 >= days } ?? largest
    }
}

extension TrimReportDTO {
    /// What the pass removed, in words: "removed 1 event, 12 messages, 3 usage
    /// snapshots; reclaimed 4 KB". Zero counts are left out, and so is the
    /// reclaimed space when it is zero; a pass that removed no row reads
    /// "nothing removed". The CLI and the app both print this.
    public var removalSummary: String {
        let counts: [(Int, String, String)] = [
            (events, "event", "events"),
            (messages, "message", "messages"),
            (turns, "turn", "turns"),
            (sessions, "session", "sessions"),
            (rateLimitSnapshots, "usage snapshot", "usage snapshots")
        ]
        let parts = counts.filter { $0.0 > 0 }.map { "\($0.0) \($0.0 == 1 ? $0.1 : $0.2)" }
        var summary = parts.isEmpty ? "nothing removed" : "removed " + parts.joined(separator: ", ")
        if reclaimedBytes > 0 {
            summary += "; reclaimed " + StorageByteCount.text(reclaimedBytes)
        }
        return summary
    }

    /// Whether the pass removed any row or reclaimed any space.
    public var removedAnything: Bool {
        events + messages + turns + sessions + rateLimitSnapshots > 0 || reclaimedBytes > 0
    }

    /// A daemon's `waitingFor` value, in words, as a sentence start ("Waiting
    /// for billing", "Billing could not be read; nothing removed"). An unknown
    /// value reads "Waiting for <value>". The CLI and the app both print this.
    public static func waitingText(_ waitingFor: String) -> String {
        switch waitingFor {
        case "rollups": return "Waiting for rollups"
        case "billing": return "Waiting for billing"
        case "billing unreadable": return "Billing could not be read; nothing removed"
        case "skipped: bulk load": return "Skipped during a bulk import"
        case "events.db unavailable": return "events.db unavailable"
        default: return "Waiting for \(waitingFor)"
        }
    }
}

/// How a storage size reads, wherever it is shown (`steno storage`, the
/// Storage pane, a trim's "reclaimed"): decimal units with one place after the
/// point ("512 bytes", "4.1 KB", "69.0 GB"), the same in every locale.
public enum StorageByteCount {
    public static func text(_ bytes: Int64) -> String {
        guard bytes >= 1000 else { return bytes == 1 ? "1 byte" : "\(bytes) bytes" }
        var value = Double(bytes)
        var unit = "bytes"
        for next in ["KB", "MB", "GB", "TB"] where value >= 1000 {
            value /= 1000
            unit = next
        }
        return String(format: "%.1f %@", locale: Locale(identifier: "en_US_POSIX"), value, unit)
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
