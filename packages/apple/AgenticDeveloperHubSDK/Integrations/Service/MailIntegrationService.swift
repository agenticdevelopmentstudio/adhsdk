import AIPluginKit
import Foundation

/// The host-agnostic Gmail service a daemon hosts: answers `MailRequest`s, runs the poll
/// scheduler, signs accounts in and writes label changes back to Gmail.
public actor MailIntegrationService {
    static let provider = "gmail"
    static let scopes = "openid email https://www.googleapis.com/auth/gmail.modify"
    /// Gmail's `messages.batchModify` limit.
    static let batchModifyLimit = 1000
    private static let refetchConcurrency = 8

    private let store: IntegrationsStore
    private let secrets: any SecretStoring
    private let signInFlow: any GoogleSignInFlow
    private let tokens: GoogleTokenProvider
    private let makeAPI: @Sendable (_ accessToken: @escaping @Sendable () async throws -> String) -> any GmailAPI
    private let now: @Sendable () -> Date

    private struct RunningSync {
        let id: UUID
        let task: Task<Void, Never>
    }

    /// One in-flight sync per connection id.
    private var running: [String: RunningSync] = [:]
    private var scheduler: Task<Void, Never>?

    public init(
        store: IntegrationsStore, secrets: any SecretStoring, signIn: any GoogleSignInFlow = AppAuthGoogleSignIn(),
        tokenEndpoint: any GoogleTokenEndpoint = URLSessionGoogleTokenEndpoint(),
        makeAPI: @escaping @Sendable (_ accessToken: @escaping @Sendable () async throws -> String) -> any GmailAPI
            = { GmailRESTClient(accessToken: $0) },
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.store = store
        self.secrets = secrets
        self.signInFlow = signIn
        self.tokens = GoogleTokenProvider(secrets: secrets, endpoint: tokenEndpoint, now: now)
        self.makeAPI = makeAPI
        self.now = now
    }

    // MARK: - Requests

    /// Never throws: every error becomes `.failure(localizedDescription)`.
    public func handle(_ request: MailRequest) async -> MailResponse {
        do {
            return try await dispatch(request)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    /// JSON in, JSON out. An undecodable request answers `.failure("bad request")`.
    public nonisolated func handle(requestData: Data) async -> Data {
        let response: MailResponse
        if let request = try? JSONDecoder().decode(MailRequest.self, from: requestData) {
            response = await handle(request)
        } else {
            response = .failure("bad request")
        }
        return (try? JSONEncoder().encode(response)) ?? Data(#"{"failure":{"_0":"encoding failed"}}"#.utf8)
    }

    private func dispatch(_ request: MailRequest) async throws -> MailResponse {
        switch request {
        case .providerStatus:
            return .providerStatus(try providerStatus())
        case .importOAuthClient(let json):
            return .providerStatus(try importOAuthClient(json: json))
        case .removeProvider:
            try await removeProvider()
            return .ok
        case .listAccounts:
            return .accounts(try store.connections(provider: Self.provider).map(Self.account))
        case .signIn:
            return .account(try await signIn())
        case .removeAccount(let account):
            try await removeAccount(try connection(account))
            return .ok
        case .updateSettings(let account, let settings):
            return .account(try await updateSettings(account: account, settings: settings))
        case .syncNow(let account):
            return .accounts(try await syncNow(account: account))
        case .listLabels(let account):
            return .labels(try store.labels(connectionId: try connection(account).id).map(Self.label))
        case .listMessages(let filter):
            return .messages(try listMessages(filter))
        case .getMessage(let account, let id):
            let owner = try connection(account)
            guard let message = try store.message(connectionId: owner.id, idOrExternalId: id) else {
                throw IntegrationError.unknownMessage(id)
            }
            return .message(try mailMessage(message, connection: owner, includeBodies: true))
        case .modifyLabels(let account, let messageIds, let add, let remove):
            let messages = try await modifyLabels(
                connection: try connection(account), messageIds: messageIds, add: add, remove: remove)
            return .messages(MailMessagePage(messages: messages, nextCursor: nil))
        }
    }

    // MARK: - Provider

    private func providerStatus() throws -> MailProviderStatus {
        guard let config = try store.providerConfig(providerId: Self.provider),
              secrets.get(forKey: GoogleTokenProvider.clientSecretKey) != nil else {
            return MailProviderStatus(configured: false, clientIdHint: nil)
        }
        return MailProviderStatus(configured: true, clientIdHint: String(config.clientId.suffix(12)))
    }

    private func importOAuthClient(json: Data) throws -> MailProviderStatus {
        let parsed = try GoogleOAuthClientConfig.parse(json: json)
        guard secrets.set(parsed.clientSecret, forKey: GoogleTokenProvider.clientSecretKey) else {
            throw RequestFailure("Could not save the OAuth client secret to the Keychain")
        }
        try store.upsertProviderConfig(ProviderConfig(
            id: Self.newId(), providerId: Self.provider, name: "Gmail", clientId: parsed.clientId))
        return try providerStatus()
    }

    private func removeProvider() async throws {
        for connection in try store.connections(provider: Self.provider) {
            try await removeAccount(connection)
        }
        try store.deleteProviderConfig(providerId: Self.provider)
        secrets.delete(forKey: GoogleTokenProvider.clientSecretKey)
    }

    /// The imported OAuth client; `notConfigured` without both its id and secret.
    private func oauthConfig() throws -> GoogleOAuthClientConfig {
        guard let config = try store.providerConfig(providerId: Self.provider),
              let secret = secrets.get(forKey: GoogleTokenProvider.clientSecretKey) else {
            throw IntegrationError.notConfigured
        }
        return GoogleOAuthClientConfig(clientId: config.clientId, clientSecret: secret)
    }

    // MARK: - Accounts

    private func signIn() async throws -> MailAccount {
        let config = try oauthConfig()
        let credential = try await signInFlow.signIn(config: config)
        let accessToken = credential.accessToken
        let email = try await makeAPI({ accessToken }).profile().emailAddress.lowercased()

        let existing = try store.connections(provider: Self.provider).first { $0.externalAccountId == email }
        let id = existing?.id ?? Self.newId()
        // The credential is saved first, so a failed Keychain write leaves no active connection
        // without one.
        try await tokens.store(credential, connectionId: id)
        try store.upsertConnection(IntegrationConnection(
            id: id, provider: Self.provider, externalAccountId: email, displayName: email, status: .active,
            lastSyncAt: existing?.lastSyncAt, lastError: nil, syncCursor: existing?.syncCursor,
            syncSettings: existing?.syncSettings ?? .default, scopes: Self.scopes))
        let saved = try connection(id)
        startSync(connectionId: saved.id)
        return Self.account(saved)
    }

    private func removeAccount(_ connection: IntegrationConnection) async throws {
        await quiesce(connectionId: connection.id)
        await tokens.forget(connectionId: connection.id)
        try store.deleteConnection(id: connection.id)
    }

    private func updateSettings(account: String, settings: MailSyncSettings) async throws -> MailAccount {
        let settings = try settings.validated()
        let id = try connection(account).id
        // A running sync would write back a cursor taken under the old settings.
        await quiesce(connectionId: id)
        var record = try connection(id)
        let old = record.syncSettings

        let disallowed = Set(MailClass.allCases.filter { old.allows($0) && !settings.allows($0) })
        try store.tombstoneMessages(connectionId: id, classes: disallowed)
        let widened = MailClass.allCases.contains { !old.allows($0) && settings.allows($0) }
            || settings.windowDays > old.windowDays
        if widened { record.syncCursor = nil }
        record.syncSettings = settings
        try store.upsertConnection(record)

        startSync(connectionId: id)
        return Self.account(try connection(id))
    }

    /// Resolves an account argument: an exact connection id, else a case-insensitive email.
    private func connection(_ account: String) throws -> IntegrationConnection {
        let connections = try store.connections(provider: Self.provider)
        let email = account.lowercased()
        guard let match = connections.first(where: { $0.id == account })
                ?? connections.first(where: { $0.externalAccountId == email }) else {
            throw IntegrationError.unknownAccount(account)
        }
        return match
    }

    // MARK: - Scheduler

    /// Starts the poll loop: every `tick`, syncs the accounts that are due.
    public func start(tick: Duration = .seconds(60)) {
        scheduler?.cancel()
        scheduler = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.startDueSyncs()
                try? await Task.sleep(for: tick)
            }
        }
    }

    /// Stops the poll loop and cancels running syncs.
    public func stop() {
        scheduler?.cancel()
        scheduler = nil
        for sync in running.values { sync.task.cancel() }
    }

    /// One scheduler tick: starts every due sync and waits for them.
    public func runDueSyncs() async {
        for task in startDueSyncs() { await task.value }
    }

    /// Waits until no sync is running. For tests: sign-in and settings changes start syncs
    /// without awaiting them.
    func waitForIdle() async {
        while let sync = running.values.first { await sync.task.value }
    }

    @discardableResult
    private func startDueSyncs() -> [Task<Void, Never>] {
        guard let connections = try? store.connections(provider: Self.provider) else { return [] }
        let current = now()
        return connections
            .filter { Self.isSyncable($0) && isDue($0, at: current) }
            .compactMap { startSync(connectionId: $0.id) }
    }

    private func syncNow(account: String?) async throws -> [MailAccount] {
        let targets: [IntegrationConnection]
        if let account {
            let target = try connection(account)
            guard Self.isSyncable(target) else {
                throw target.status == .revoked ? IntegrationError.revoked
                    : RequestFailure("account \(target.externalAccountId) is not ready to sync")
            }
            targets = [target]
        } else {
            targets = try store.connections(provider: Self.provider).filter(Self.isSyncable)
        }
        for target in targets {
            // Not twice at once: join the sync already running.
            let task = startSync(connectionId: target.id) ?? running[target.id]?.task
            await task?.value
        }
        return try targets.map { Self.account(try connection($0.id)) }
    }

    private static func isSyncable(_ connection: IntegrationConnection) -> Bool {
        connection.status == .active || connection.status == .error
    }

    private func isDue(_ connection: IntegrationConnection, at current: Date) -> Bool {
        guard let last = connection.lastSyncAt,
              let lastDate = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(last) else {
            return true
        }
        return lastDate.addingTimeInterval(Double(connection.syncSettings.pollIntervalMinutes) * 60) <= current
    }

    /// Starts a sync unless one is already running for the connection; returns the new task.
    @discardableResult
    private func startSync(connectionId: String) -> Task<Void, Never>? {
        guard running[connectionId] == nil else { return nil }
        let token = UUID()
        let task = Task {
            await self.performSync(connectionId: connectionId)
            self.finishSync(connectionId: connectionId, token: token)
        }
        running[connectionId] = RunningSync(id: token, task: task)
        return task
    }

    private func finishSync(connectionId: String, token: UUID) {
        if running[connectionId]?.id == token { running[connectionId] = nil }
    }

    /// Cancels a running sync for the connection and waits for it to end.
    private func quiesce(connectionId: String) async {
        while let sync = running[connectionId] {
            sync.task.cancel()
            await sync.task.value
        }
    }

    private func performSync(connectionId: String) async {
        guard let connection = try? store.connection(idOrEmail: connectionId) else { return }
        do {
            let worker = GmailSyncWorker(api: try gmailAPI(for: connectionId), store: store, now: now)
            _ = try await worker.sync(connection: connection)
        } catch {
            record(error, connectionId: connectionId)
        }
    }

    /// Revocation sets `revoked`; cancellation records nothing; anything else sets `error`.
    private func record(_ error: any Error, connectionId: String) {
        if error is CancellationError || Task.isCancelled { return }
        guard let current = try? store.connection(idOrEmail: connectionId) else { return }
        let status: ConnectionStatus = (error as? IntegrationError) == .revoked ? .revoked : .error
        try? store.updateSyncState(
            id: connectionId, cursor: current.syncCursor, lastSyncAt: current.lastSyncAt,
            status: status, lastError: error.localizedDescription)
    }

    private func gmailAPI(for connectionId: String) throws -> any GmailAPI {
        let config = try oauthConfig()
        let tokens = self.tokens
        return makeAPI { try await tokens.accessToken(connectionId: connectionId, config: config) }
    }

    // MARK: - Messages and labels

    private func listMessages(_ filter: MailMessageFilter) throws -> MailMessagePage {
        let owner = try connection(filter.account)
        let offset: Int
        if let cursor = filter.cursor {
            guard let value = Int(cursor), value >= 0 else { throw RequestFailure("invalid cursor: \(cursor)") }
            offset = value
        } else {
            offset = 0
        }
        let limit = MailMessageFilter.clamp(filter.limit)
        let labels = try store.labels(connectionId: owner.id)
        let labelIds = filter.labels.map { Self.resolveLabel($0, in: labels) ?? $0 }
        // One extra row tells whether another page follows.
        let rows = try store.messages(MessageQuery(
            connectionId: owner.id, since: filter.since, until: filter.until, labelIds: labelIds,
            limit: limit + 1, offset: offset))
        let names = Self.labelNames(labels)
        let messages = rows.prefix(limit).map {
            Self.mailMessage($0, account: owner.externalAccountId, names: names,
                             includeBodies: filter.includeBodies)
        }
        return MailMessagePage(messages: messages, nextCursor: rows.count > limit ? String(offset + limit) : nil)
    }

    private func modifyLabels(
        connection: IntegrationConnection, messageIds: [String], add: [String], remove: [String]
    ) async throws -> [MailMessage] {
        let labels = try store.labels(connectionId: connection.id)
        func resolve(_ names: [String]) throws -> [String] {
            var seen = Set<String>()
            return try names.compactMap { name in
                guard let id = Self.resolveLabel(name, in: labels) else {
                    throw RequestFailure("unknown label: \(name)")
                }
                return seen.insert(id).inserted ? id : nil
            }
        }
        let addIds = try resolve(add)
        let removeIds = try resolve(remove)
        let originals = try messageIds.map { id in
            guard let message = try store.message(connectionId: connection.id, idOrExternalId: id) else {
                throw IntegrationError.unknownMessage(id)
            }
            return message
        }
        let names = Self.labelNames(labels)
        let account = connection.externalAccountId
        guard !addIds.isEmpty || !removeIds.isEmpty, !originals.isEmpty else {
            return originals.map { Self.mailMessage($0, account: account, names: names, includeBodies: false) }
        }

        let gmailIds = originals.map(\.externalId)
        let logId = Self.newId()
        let payload = ModifyPayload(messageIds: gmailIds, add: addIds, remove: removeIds)
        try store.insertActionLog(ActionLog(
            id: logId, connectionId: connection.id, actionType: "modify_labels",
            requestPayload: Self.json(payload)))
        do {
            let api = try gmailAPI(for: connection.id)
            for start in stride(from: 0, to: gmailIds.count, by: Self.batchModifyLimit) {
                let chunk = Array(gmailIds[start..<min(start + Self.batchModifyLimit, gmailIds.count)])
                try await api.batchModify(ids: chunk, add: addIds, remove: removeIds)
            }
            let refreshed = try await refetch(originals, api: api, connection: connection)
            try store.finishActionLog(
                id: logId, status: "ok", result: Self.json(["modified": refreshed.count]), error: nil)
            return refreshed.map { Self.mailMessage($0, account: account, names: names, includeBodies: false) }
        } catch {
            try? store.finishActionLog(id: logId, status: "error", result: nil, error: error.localizedDescription)
            if (error as? IntegrationError) == .revoked { record(error, connectionId: connection.id) }
            throw error
        }
    }

    private struct ModifyPayload: Encodable {
        let messageIds: [String]
        let add: [String]
        let remove: [String]
    }

    /// Re-reads each message from Gmail and stores it, or tombstones it when the connection no
    /// longer mirrors its class or Gmail no longer has it. Returns the re-read messages in order.
    private func refetch(
        _ originals: [EmailMessage], api: any GmailAPI, connection: IntegrationConnection
    ) async throws -> [EmailMessage] {
        let connectionId = connection.id
        var fetched: [Int: EmailMessage] = [:]
        try await withThrowingTaskGroup(of: (Int, EmailMessage?).self) { group in
            var next = 0
            func addNext() {
                guard next < originals.count else { return }
                let index = next
                let original = originals[index]
                next += 1
                group.addTask {
                    do {
                        let dto = try await api.message(id: original.externalId)
                        return (index, GmailMessageParser.parse(dto, connectionId: connectionId,
                                                                existingId: original.id))
                    } catch IntegrationError.gmail(status: 404, message: _) {
                        return (index, nil)
                    }
                }
            }
            for _ in 0..<Self.refetchConcurrency { addNext() }
            while let (index, message) = try await group.next() {
                fetched[index] = message
                addNext()
            }
        }
        let refreshed = originals.indices.compactMap { fetched[$0] }
        let kept = refreshed.filter { connection.syncSettings.allows($0.mailClass) }
        let gone = originals.indices.filter { fetched[$0] == nil }.map { originals[$0].externalId }
            + refreshed.filter { !connection.syncSettings.allows($0.mailClass) }.map(\.externalId)
        try store.upsertMessages(kept)
        try store.tombstoneMessages(connectionId: connectionId, externalIds: gone)
        return refreshed
    }

    private func mailMessage(
        _ message: EmailMessage, connection: IntegrationConnection, includeBodies: Bool
    ) throws -> MailMessage {
        let names = Self.labelNames(try store.labels(connectionId: connection.id))
        return Self.mailMessage(message, account: connection.externalAccountId, names: names,
                                includeBodies: includeBodies)
    }

    // MARK: - Mapping

    /// Exact Gmail label id, else exact (case-sensitive) name.
    private static func resolveLabel(_ value: String, in labels: [EmailLabel]) -> String? {
        labels.first { $0.externalId == value }?.externalId ?? labels.first { $0.name == value }?.externalId
    }

    private static func labelNames(_ labels: [EmailLabel]) -> [String: String] {
        Dictionary(labels.map { ($0.externalId, $0.name) }, uniquingKeysWith: { first, _ in first })
    }

    private static func mailMessage(
        _ message: EmailMessage, account: String, names: [String: String], includeBodies: Bool
    ) -> MailMessage {
        MailMessage(
            id: message.id, gmailId: message.externalId, threadId: message.threadId, account: account,
            from: message.fromAddress, to: message.toAddresses, cc: message.ccAddresses,
            labels: message.labelIds, labelNames: message.labelIds.map { names[$0] ?? $0 },
            subject: message.subject, snippet: message.snippet, date: message.internalDate,
            mailClass: message.mailClass,
            bodyText: includeBodies ? message.bodyText : nil, bodyHtml: includeBodies ? message.bodyHtml : nil,
            attachments: message.attachments)
    }

    private static func account(_ connection: IntegrationConnection) -> MailAccount {
        MailAccount(
            id: connection.id, email: connection.externalAccountId, status: connection.status,
            lastSyncAt: connection.lastSyncAt, lastError: connection.lastError,
            settings: connection.syncSettings)
    }

    private static func label(_ label: EmailLabel) -> MailLabel {
        MailLabel(
            id: label.externalId, name: label.name, type: label.type, parentName: label.parentName,
            messagesTotal: label.messagesTotal, messagesUnread: label.messagesUnread)
    }

    private static func newId() -> String {
        UUID().uuidString.lowercased()
    }

    private static func json(_ value: some Encodable) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(value)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}

/// A request-level failure whose message is shown as is.
struct RequestFailure: Error, LocalizedError {
    let message: String

    init(_ message: String) { self.message = message }

    var errorDescription: String? { message }
}
