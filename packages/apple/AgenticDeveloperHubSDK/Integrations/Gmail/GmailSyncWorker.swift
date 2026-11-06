import Foundation

public struct GmailSyncOutcome: Sendable, Equatable {
    public enum Mode: String, Sendable { case full, incremental }

    public var mode: Mode
    public var upserted: Int
    public var tombstoned: Int

    public init(mode: Mode, upserted: Int, tombstoned: Int) {
        self.mode = mode
        self.upserted = upserted
        self.tombstoned = tombstoned
    }
}

/// Mirrors one Gmail account into `IntegrationsStore`: a full sync when the connection has no
/// cursor, otherwise a history-based incremental sync that falls back to a full one when Gmail
/// no longer has the cursor. `MailClassifier` and the connection's settings decide what is kept.
public struct GmailSyncWorker: Sendable {
    private static let fetchConcurrency = 8
    private static let upsertBatchSize = 100

    private let api: any GmailAPI
    private let store: IntegrationsStore
    private let now: @Sendable () -> Date

    public init(api: any GmailAPI, store: IntegrationsStore, now: @escaping @Sendable () -> Date = Date.init) {
        self.api = api
        self.store = store
        self.now = now
    }

    /// Persists the new cursor and status through `store.updateSyncState` once, on success.
    public func sync(connection: IntegrationConnection) async throws -> GmailSyncOutcome {
        try await syncLabels(connection: connection)
        let result: (GmailSyncOutcome, String)
        if let existing = connection.syncCursor {
            do {
                result = try await incremental(connection: connection, since: existing)
            } catch is GmailCursorExpired {
                result = try await full(connection: connection)
            }
        } else {
            result = try await full(connection: connection)
        }
        try store.updateSyncState(
            id: connection.id, cursor: result.1, lastSyncAt: IntegrationClock.string(from: now()),
            status: .active, lastError: nil)
        return result.0
    }

    // MARK: - Labels

    private func syncLabels(connection: IntegrationConnection) async throws {
        let labels = try await api.labels().map { dto in
            EmailLabel(
                id: UUID().uuidString.lowercased(), connectionId: connection.id, externalId: dto.id,
                name: dto.name, parentName: Self.parentName(of: dto.name),
                type: dto.type == "system" ? "system" : "user", color: dto.color,
                messagesTotal: dto.messagesTotal, messagesUnread: dto.messagesUnread)
        }
        // The store keeps the local id of a label that is already present.
        try store.replaceLabels(connectionId: connection.id, with: labels)
    }

    private static func parentName(of name: String) -> String? {
        guard let slash = name.lastIndex(of: "/") else { return nil }
        return String(name[..<slash])
    }

    // MARK: - Full sync

    /// Lists the window, then fetches and stores it batch by batch, so a long first sync keeps
    /// what it has fetched if it fails partway. Tombstoning — rows in the window Gmail no longer
    /// lists, and rows older than the window — happens only after the whole pass.
    private func full(connection: IntegrationConnection) async throws -> (GmailSyncOutcome, String) {
        let settings = connection.syncSettings
        // Taken before listing, so a change made while listing is replayed by the next incremental sync.
        let baseline = try await api.profile().historyId
        let (query, includeSpamTrash) = GmailQuery.fullSync(settings: settings, now: now())
        var ids: [String] = []
        var pageToken: String?
        repeat {
            let page = try await api.listMessageIds(
                query: query, includeSpamTrash: includeSpamTrash, pageToken: pageToken)
            ids += page.ids
            pageToken = page.nextPageToken
        } while pageToken != nil

        var keptIds = Set<String>()
        try await fetch(ids: ids, connection: connection) { batch in
            let kept = batch.compactMap { $0.1 }.filter { settings.allows($0.mailClass) }
            try store.upsertMessages(kept)
            keptIds.formUnion(kept.map(\.externalId))
        }

        let windowStart = IntegrationClock.string(from: windowStart(settings))
        let live = try store.liveExternalIds(connectionId: connection.id, since: windowStart)
        var tombstoned = try store.tombstoneMessages(
            connectionId: connection.id, externalIds: Array(live.subtracting(keptIds)))
        tombstoned += try store.tombstoneMessages(connectionId: connection.id, olderThan: windowStart)
        return (GmailSyncOutcome(mode: .full, upserted: keptIds.count, tombstoned: tombstoned), baseline)
    }

    // MARK: - Incremental sync

    /// Replays history since `cursor`. A changed message is stored unless the settings exclude
    /// its class or it is older than the window; then (or when Gmail no longer has it) it is
    /// tombstoned. The outcome counts the rows actually written.
    private func incremental(
        connection: IntegrationConnection, since cursor: String
    ) async throws -> (GmailSyncOutcome, String) {
        let settings = connection.syncSettings
        var changed: [String] = []
        var deleted: [String] = []
        var latest = cursor
        var pageToken: String?
        repeat {
            let page = try await api.history(startHistoryId: cursor, pageToken: pageToken)
            changed += page.changedIds
            deleted += page.deletedIds
            latest = page.historyId
            pageToken = page.nextPageToken
        } while pageToken != nil

        let deletedSet = Set(deleted)
        var seen = Set<String>()
        let toFetch = changed.filter { !deletedSet.contains($0) && seen.insert($0).inserted }
        let windowStart = IntegrationClock.string(from: windowStart(settings))

        var tombstoned = try store.tombstoneMessages(connectionId: connection.id, externalIds: Array(deletedSet))
        var upserted = 0
        try await fetch(ids: toFetch, connection: connection) { batch in
            var upserts: [EmailMessage] = []
            var tombstones: [String] = []
            for (id, message) in batch {
                if let message, settings.allows(message.mailClass), message.internalDate >= windowStart {
                    upserts.append(message)
                } else {
                    tombstones.append(id)
                }
            }
            tombstoned += try store.tombstoneMessages(connectionId: connection.id, externalIds: tombstones)
            try store.upsertMessages(upserts)
            upserted += upserts.count
        }
        return (GmailSyncOutcome(mode: .incremental, upserted: upserted, tombstoned: tombstoned), latest)
    }

    // MARK: - Shared

    private func windowStart(_ settings: MailSyncSettings) -> Date {
        now().addingTimeInterval(-Double(settings.windowDays) * 86_400)
    }

    /// Fetches and parses `ids`, `fetchConcurrency` at a time, handing them to `store` in batches
    /// of `upsertBatchSize` as they arrive (the last batch may be smaller). A message Gmail no
    /// longer has (404) comes back as `nil`; any other error fails the sync, after every batch
    /// already handed over.
    private func fetch(
        ids: [String], connection: IntegrationConnection,
        store handle: ([(String, EmailMessage?)]) throws -> Void
    ) async throws {
        let api = self.api
        let connectionId = connection.id
        let now = now()
        try await withThrowingTaskGroup(of: (String, EmailMessage?).self) { group in
            var iterator = ids.makeIterator()
            func addNext() {
                guard let id = iterator.next() else { return }
                group.addTask {
                    do {
                        let dto = try await api.message(id: id)
                        // The store keeps the local id of a row that already exists.
                        return (id, GmailMessageParser.parse(
                            dto, connectionId: connectionId, existingId: nil, now: now))
                    } catch IntegrationError.gmail(status: 404, message: _) {
                        return (id, nil)
                    }
                }
            }
            for _ in 0..<Self.fetchConcurrency { addNext() }
            var pending: [(String, EmailMessage?)] = []
            while let result = try await group.next() {
                pending.append(result)
                if pending.count == Self.upsertBatchSize {
                    try handle(pending)
                    pending.removeAll(keepingCapacity: true)
                }
                addNext()
            }
            if !pending.isEmpty { try handle(pending) }
        }
    }
}
