#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// Builds the `StorageStatusDTO` that `GET /storage` and XPC `storageStatus`
/// return: the history window, each database file's size, the last trim's
/// report and whether a pass runs now.
///
/// Sizes are read without writing anything: the open event store reports its
/// own; every other file goes through `SQLiteFileStats`, which never creates a
/// file or sidecar. A file that is not there is left out, never an error.
enum StorageStatusReader {
    /// The raw backup's note.
    static let rawBackupNote = "Raw backup — not trimmed"
    /// events.db's note while it has no auto_vacuum (freed pages stay in the file).
    static let eventsNoVacuumNote = "Space is freed after a one-time rebuild in a later update"
    /// The main database's note while it is too big for the trim's weekly full
    /// `VACUUM` (`TrimService.mainVacuumMaxBytes`): its freed pages are reused,
    /// so it stops growing, but the file does not get smaller.
    static let mainNoShrinkNote = "Its size can't shrink yet; space is freed after a one-time rebuild in a later update"

    /// `trimStarted` is set only on the reply to a trim request: whether that
    /// request started the pass (true) or joined one already running (false).
    static func status(
        database: DaemonDatabase, storage: StorageController?, claudePipeline: ClaudePipelineSlot?,
        trimStarted: Bool? = nil
    ) -> StorageStatusDTO {
        status(
            database: database, eventStore: claudePipeline?.current?.store,
            pipelineState: claudePipeline?.state.rawValue, trimRunningSince: storage?.runningSince,
            trimStarted: trimStarted, historyBackfill: storage?.backfill?.status())
    }

    static func status(
        database: DaemonDatabase, eventStore: EventStore?, pipelineState: String?, trimRunningSince: Double?,
        trimStarted: Bool? = nil, historyBackfill: HistoryBackfillDTO? = nil
    ) -> StorageStatusDTO {
        StorageStatusDTO(
            historyDays: StorageSettings.historyDays(database),
            allowedHistoryDays: StorageHistoryWindow.allowedDays,
            files: files(database: database, eventStore: eventStore),
            lastTrim: TrimService.lastReport(database).map(TrimReportDTO.init),
            trimRunning: trimRunningSince != nil,
            claudePipeline: pipelineState,
            trimRunningSince: trimRunningSince,
            trimStarted: trimStarted,
            historyBackfill: historyBackfill)
    }

    /// The files in the main database's directory, in a fixed order: the main
    /// database, events.db, the raw backup, the Claude spool, the legacy spool.
    static func files(database: DaemonDatabase, eventStore: EventStore?) -> [StorageFileDTO] {
        let directory = URL(fileURLWithPath: database.path).deletingLastPathComponent()
        func path(_ name: String) -> String { directory.appendingPathComponent(name).path }
        func stats(_ name: String) -> StoreFileStats? { try? SQLiteFileStats.stats(path: path(name)) }

        var files: [StorageFileDTO] = []
        let mainName = URL(fileURLWithPath: database.path).lastPathComponent
        if let main = try? SQLiteFileStats.stats(path: database.path) {
            files.append(StorageFileDTO(
                name: mainName, role: StorageFileDTO.Role.main, bytes: main.bytes, trimmed: true,
                note: main.bytes >= TrimService.mainVacuumMaxBytes ? mainNoShrinkNote : nil))
        }
        let eventsStats = eventStore.flatMap { try? $0.fileStats() } ?? stats(EventStore.fileName)
        if let events = eventsStats {
            files.append(StorageFileDTO(
                name: EventStore.fileName, role: StorageFileDTO.Role.events, bytes: events.bytes, trimmed: true,
                note: events.autoVacuum == 0 ? eventsNoVacuumNote : nil))
        }
        let rawName = RawArchive.fileName(provider: ClaudeProvider.name)
        if let raw = stats(rawName) {
            files.append(StorageFileDTO(
                name: rawName, role: StorageFileDTO.Role.rawBackup, bytes: raw.bytes, trimmed: false,
                note: rawBackupNote))
        }
        let spoolName = ProviderSpool.fileName(provider: ClaudeProvider.name)
        if let spool = stats(spoolName) {
            files.append(StorageFileDTO(
                name: spoolName, role: StorageFileDTO.Role.spool, bytes: spool.bytes, trimmed: false))
        }
        if let legacy = stats(IngestSpool.defaultDBName) {
            files.append(StorageFileDTO(
                name: IngestSpool.defaultDBName, role: StorageFileDTO.Role.legacySpool, bytes: legacy.bytes,
                trimmed: false))
        }
        return files
    }
}
#endif
