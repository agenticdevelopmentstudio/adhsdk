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

        let kept = try await fetch(ids: ids, connection: connection)
            .compactMap { $0.1 }
            .filter { settings.allows($0.mailClass) }
        try upsert(kept)

        let windowStart = now().addingTimeInterval(-Double(settings.windowDays) * 86_400)
        let live = try store.liveExternalIds(
            connectionId: connection.id, since: IntegrationClock.string(from: windowStart))
        let stale = Array(live.subtracting(kept.map(\.externalId)))
        try store.tombstoneMessages(connectionId: connection.id, externalIds: stale)
        return (GmailSyncOutcome(mode: .full, upserted: kept.count, tombstoned: stale.count), baseline)
    }

    // MARK: - Incremental sync

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

        var tombstones = deletedSet
        var upserts: [EmailMessage] = []
        for (id, message) in try await fetch(ids: toFetch, connection: connection) {
            if let message, settings.allows(message.mailClass) {
                upserts.append(message)
            } else {
                tombstones.insert(id)
            }
        }
        try store.tombstoneMessages(connectionId: connection.id, externalIds: Array(tombstones))
        try upsert(upserts)
        return (GmailSyncOutcome(mode: .incremental, upserted: upserts.count, tombstoned: tombstones.count), latest)
    }

    // MARK: - Shared

    private func upsert(_ messages: [EmailMessage]) throws {
        for start in stride(from: 0, to: messages.count, by: Self.upsertBatchSize) {
            try store.upsertMessages(Array(messages[start..<min(start + Self.upsertBatchSize, messages.count)]))
        }
    }

    /// Fetches and parses `ids`, `fetchConcurrency` at a time. A message Gmail no longer has
    /// (404) comes back as `nil`; any other error fails the sync.
    private func fetch(ids: [String], connection: IntegrationConnection) async throws -> [(String, EmailMessage?)] {
        let api = self.api
        let connectionId = connection.id
        var results: [(String, EmailMessage?)] = []
        try await withThrowingTaskGroup(of: (String, EmailMessage?).self) { group in
            var iterator = ids.makeIterator()
            func addNext() {
                guard let id = iterator.next() else { return }
                group.addTask {
                    do {
                        let dto = try await api.message(id: id)
                        // The store keeps the local id of a row that already exists.
                        return (id, GmailMessageParser.parse(dto, connectionId: connectionId, existingId: nil))
                    } catch IntegrationError.gmail(status: 404, message: _) {
                        return (id, nil)
                    }
                }
            }
            for _ in 0..<Self.fetchConcurrency { addNext() }
            while let result = try await group.next() {
                results.append(result)
                addNext()
            }
        }
        return results
    }
}
