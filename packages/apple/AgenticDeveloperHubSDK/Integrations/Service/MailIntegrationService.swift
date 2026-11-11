import AIPluginKit
import Foundation
import os

/// The host-agnostic Gmail service a daemon hosts: answers `MailRequest`s, runs the poll
/// scheduler, signs accounts in and writes label changes back to Gmail.
public actor MailIntegrationService {
    static let provider = "gmail"
    static let scopes = "openid email https://www.googleapis.com/auth/gmail.modify"
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
    private var observer: (@Sendable (MailServiceEvent) -> Void)?
    /// When each connection's latest sync started, successful or not. In memory only: after a
    /// restart, due-ness falls back to `lastSyncAt`.
    private var lastAttempt: [String: Date] = [:]
    /// Connections being removed. No sync starts for them while the removal awaits.
    private var removing: Set<String> = []
    /// The browser sign-in in progress, if any. Only one runs at a time: a new one
    /// supersedes it.
    private var pendingSignIn: Task<GoogleCredential, Error>?
    /// Counts provider removals, so a sign-in that was under way when Gmail was removed can
    /// tell, after each of its awaits, that the client it signed in with is gone.
    private var providerGeneration = 0
    /// Provider removals in progress. A sign-in that starts while one awaits would capture the
    /// generation it already bumped, and pass every check, so none starts.
    private var providerRemovals = 0
    private let tokenEndpoint: any GoogleTokenEndpoint
    private static let logger = Logger(subsystem: "com.agenticdeveloperhub.integrations", category: "Mail")

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
        self.tokenEndpoint = tokenEndpoint
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
        case .cancelSignIn:
            pendingSignIn?.cancel()
            return .ok
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
              let secret = try clientSecret() else {
            return MailProviderStatus(configured: false, clientId: nil)
        }
        return MailProviderStatus(
            configured: true, clientId: config.clientId,
            clientSecretSuffix: MailProviderStatus.visibleSuffix(ofSecret: secret))
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
        // A sign-in under way belongs to the client being removed: stop its browser flow, and
        // let one already past it see the change before it saves a credential.
        providerGeneration += 1
        // Until the client is deleted, a new sign-in would still find it and sign in with it.
        providerRemovals += 1
        defer { providerRemovals -= 1 }
        pendingSignIn?.cancel()
        pendingSignIn = nil
        for connection in try store.connections(provider: Self.provider) {
            try await removeAccount(connection)
        }
        try store.deleteProviderConfig(providerId: Self.provider)
        secrets.delete(forKey: GoogleTokenProvider.clientSecretKey)
    }

    /// The imported OAuth client; `notConfigured` without both its id and secret.
    private func oauthConfig() throws -> GoogleOAuthClientConfig {
        guard let config = try store.providerConfig(providerId: Self.provider),
              let secret = try clientSecret() else {
            throw IntegrationError.notConfigured
        }
        return GoogleOAuthClientConfig(clientId: config.clientId, clientSecret: secret)
    }

    /// The stored OAuth client secret, or nil when none is stored. A Keychain that could not
    /// be read (locked, or access denied) throws, rather than reading as "not configured" and
    /// sending the user to import a client they already have.
    private func clientSecret() throws -> String? {
        do {
            return try secrets.read(forKey: GoogleTokenProvider.clientSecretKey)
        } catch {
            throw IntegrationError.keychain("Could not read the OAuth client secret: \(error.localizedDescription)")
        }
    }

    // MARK: - Accounts

    private func signIn() async throws -> MailAccount {
        // Gmail is being removed: its client is about to go, along with every account.
        guard providerRemovals == 0 else { throw IntegrationError.notConfigured }
        let config = try oauthConfig()
        let generation = providerGeneration
        // Gmail was removed while this sign-in waited: the account must not come back, and the
        // grant Google has just issued must not outlive it either.
        func ensureProviderKept(_ credential: GoogleCredential) async throws {
            guard providerGeneration != generation else { return }
            await revoke(credential)
            throw IntegrationError.signInCancelled
        }
        // A sign-in still pending belongs to a client that gave up on it: a panel that was
        // closed, or an app that quit or crashed while the browser was open. Nothing cancels
        // its request when that client goes away, and a fresh panel does not know to offer
        // Cancel, so refusing here would lock Add Account out until the browser flow times
        // out. The newer request wins; cancelling the old flow also closes its redirect
        // listener, so its abandoned browser tab can no longer add an account.
        pendingSignIn?.cancel()
        let flow = signInFlow
        let task = Task { try await flow.signIn(config: config) }
        pendingSignIn = task
        // Clear the slot only if it is still ours: a superseding sign-in owns it now.
        func release() { if pendingSignIn == task { pendingSignIn = nil } }
        let credential: GoogleCredential
        do {
            credential = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            release()
        } catch {
            release()
            if error is CancellationError || task.isCancelled { throw IntegrationError.signInCancelled }
            throw error
        }
        try await ensureProviderKept(credential)
        let accessToken = credential.accessToken
        let email = try await makeAPI({ accessToken }).profile().emailAddress.lowercased()
        try await ensureProviderKept(credential)

        let id = try existingConnection(email: email)?.id ?? Self.newId()
        // The credential is saved first, so a failed Keychain write leaves no active connection
        // without one.
        try await tokens.store(credential, connectionId: id)
        // A removal that ran during the save found no connection to forget this credential
        // through, so it is this sign-in's to forget.
        guard providerGeneration == generation else {
            await tokens.revoke(connectionId: id)
            try? await tokens.forget(connectionId: id)
            throw IntegrationError.signInCancelled
        }
        // Re-read after the await: a sync that finished meanwhile wrote a newer cursor and
        // `lastSyncAt`, which a snapshot taken before it would roll back.
        let existing = try existingConnection(email: email)
        try store.upsertConnection(IntegrationConnection(
            id: id, provider: Self.provider, externalAccountId: email, displayName: email, status: .active,
            lastSyncAt: existing?.lastSyncAt, lastError: nil, syncCursor: existing?.syncCursor,
            syncSettings: existing?.syncSettings ?? .default, scopes: Self.scopes))
        let saved = try connection(id)
        startSync(connectionId: saved.id)
        return Self.account(saved)
    }

    /// Best effort, like `GoogleTokenProvider.revoke(connectionId:)`, for a credential that was
    /// never stored: asks Google to revoke its refresh token, logging a failure.
    private func revoke(_ credential: GoogleCredential) async {
        do {
            try await tokenEndpoint.revoke(token: credential.refreshToken)
        } catch {
            Self.logger.error("Revoking a discarded sign-in at Google failed: \(error.localizedDescription)")
        }
    }

    private func existingConnection(email: String) throws -> IntegrationConnection? {
        try store.connections(provider: Self.provider).first { $0.externalAccountId == email }
    }

    /// Stops the account's sync, revokes its grant at Google (best effort), forgets its
    /// credential and deletes it. No sync starts for it meanwhile. A credential the Keychain
    /// will not remove fails the removal, leaving the account in place.
    private func removeAccount(_ connection: IntegrationConnection) async throws {
        let id = connection.id
        // Another removal of this account is already under way; it finishes the job.
        guard removing.insert(id).inserted else { return }
        defer { removing.remove(id) }
        await quiesce(connectionId: id)
        await tokens.revoke(connectionId: id)
        try await tokens.forget(connectionId: id)
        try store.deleteConnection(id: id)
        lastAttempt[id] = nil
    }

    private func updateSettings(account: String, settings: MailSyncSettings) async throws -> MailAccount {
        let settings = try settings.validated()
        let current = try connection(account)
        // Nothing changed: no reason to interrupt a running sync or start another.
        if current.syncSettings == settings { return Self.account(current) }
        let id = current.id
        // A running sync would write back a cursor taken under the old settings.
        await quiesce(connectionId: id)
        var record = try connection(id)
        let old = record.syncSettings

        let disallowed = Set(MailClass.allCases.filter { old.allows($0) && !settings.allows($0) })
        try store.tombstoneMessages(connectionId: id, classes: disallowed)
        if settings.windowDays < old.windowDays {
            // Rows that fell out of the narrower window go now, not at the next full sync.
            let windowStart = now().addingTimeInterval(-Double(settings.windowDays) * 86_400)
            try store.tombstoneMessages(connectionId: id, olderThan: IntegrationClock.string(from: windowStart))
        }
        let widened = MailClass.allCases.contains { !old.allows($0) && settings.allows($0) }
            || settings.windowDays > old.windowDays
        if widened { record.syncCursor = nil }
        record.syncSettings = settings
        try store.upsertConnection(record)

        // A revoked account keeps its new settings but waits for sign-in to sync.
        if Self.isSyncable(record) { startSync(connectionId: id) }
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
        let observer = self.observer
        // `self` is bound weakly per iteration, so the loop never keeps the service alive while it
        // sleeps; once the service is gone the next iteration ends the loop.
        scheduler = Task { [weak self] in
            while !Task.isCancelled {
                guard await self?.startDueSyncs() != nil else { return }
                observer?(.schedulerTick)
                try? await Task.sleep(for: tick)
            }
        }
    }

    /// Stops the poll loop, cancels running syncs and waits for them to end, for at most
    /// `timeout`: a sync stuck in a call that ignores cancellation does not hold up shutdown.
    public func stop(timeout: Duration = .seconds(5)) async {
        scheduler?.cancel()
        scheduler = nil
        let tasks = running.values.map(\.task)
        for task in tasks { task.cancel() }
        guard !tasks.isEmpty else { return }
        let box = RaceBox<Void>()
        let waiter = Task {
            for task in tasks { await task.value }
            box.finish(.success(()))
        }
        let timer = Task {
            try? await Task.sleep(for: timeout)
            box.finish(.success(()))
        }
        try? await box.value()
        waiter.cancel()
        timer.cancel()
    }

    /// How many syncs are running. For tests.
    var runningSyncCount: Int { running.count }

    /// One scheduler tick: starts every due sync and waits for them.
    public func runDueSyncs() async {
        for task in startDueSyncs() { await task.value }
    }

    /// The poll loop, while started. For tests.
    var schedulerTask: Task<Void, Never>? { scheduler }

    /// Reports internal events. For tests: they wait on events instead of sleeping. The scheduler
    /// takes the observer when `start` is called, so set it first.
    func setObserver(_ observer: (@Sendable (MailServiceEvent) -> Void)?) {
        self.observer = observer
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
            .filter { Self.isSyncable($0) && !removing.contains($0.id) && isDue($0, at: current) }
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
            if let task = startSync(connectionId: target.id) {
                await task.value
            } else if let task = running[target.id]?.task {
                observer?(.joinedRunningSync(target.id))
                await task.value
            }
        }
        return try targets.map { Self.account(try connection($0.id)) }
    }

    private static func isSyncable(_ connection: IntegrationConnection) -> Bool {
        connection.status == .active || connection.status == .error
    }

    /// Due once a poll interval has passed since the later of the last successful sync and the
    /// last attempt, so a failing account retries at the poll interval rather than every tick.
    /// A missing or malformed `lastSyncAt` counts as never synced.
    private func isDue(_ connection: IntegrationConnection, at current: Date) -> Bool {
        let synced = connection.lastSyncAt.flatMap {
            try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse($0)
        }
        let attempted = lastAttempt[connection.id]
        guard let last = [synced, attempted].compactMap({ $0 }).max() else { return true }
        return last.addingTimeInterval(Double(connection.syncSettings.pollIntervalMinutes) * 60) <= current
    }

    /// Starts a sync unless one is already running for the connection; returns the new task.
    @discardableResult
    private func startSync(connectionId: String) -> Task<Void, Never>? {
        guard running[connectionId] == nil, !removing.contains(connectionId) else { return nil }
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
        lastAttempt[connectionId] = now()
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
        let after = try filter.cursor.map(Self.decodeCursor)
        let limit = MailMessageFilter.clamp(filter.limit)
        let labels = try store.labels(connectionId: owner.id)
        let labelIds = try Self.resolveLabels(filter.labels, in: labels)
        // One extra row tells whether another page follows.
        let rows = try store.messages(MessageQuery(
            connectionId: owner.id, since: filter.since, until: filter.until, labelIds: labelIds,
            limit: limit + 1, after: after))
        let names = Self.labelNames(labels)
        let messages = rows.prefix(limit).map {
            Self.mailMessage($0, account: owner.externalAccountId, names: names,
                             includeBodies: filter.includeBodies)
        }
        let last = rows.count > limit ? rows.prefix(limit).last : nil
        return MailMessagePage(messages: messages, nextCursor: last.map(Self.encodeCursor))
    }

    /// A page cursor names the last row it returned, not a count of rows to skip: a sync or a
    /// label change between pages moves rows in and out of the filter, and an offset would
    /// then skip or repeat messages.
    static func encodeCursor(_ row: EmailMessage) -> String {
        "\(row.internalDate)|\(row.id)"
    }

    static func decodeCursor(_ cursor: String) throws -> MessageKey {
        let parts = cursor.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            throw RequestFailure("invalid cursor: \(cursor)")
        }
        return MessageKey(internalDate: String(parts[0]), id: String(parts[1]))
    }

    private func modifyLabels(
        connection: IntegrationConnection, messageIds: [String], add: [String], remove: [String]
    ) async throws -> [MailMessage] {
        let labels = try store.labels(connectionId: connection.id)
        let addIds = try Self.resolveLabels(add, in: labels)
        let removeIds = try Self.resolveLabels(remove, in: labels)
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

        // Write the change to Gmail. A failure logs how many ids Gmail had already applied.
        let api: any GmailAPI
        var applied = 0
        do {
            api = try gmailAPI(for: connection.id)
            for start in stride(from: 0, to: gmailIds.count, by: GmailRESTClient.batchModifyLimit) {
                let chunk = Array(gmailIds[start..<min(start + GmailRESTClient.batchModifyLimit, gmailIds.count)])
                try await api.batchModify(ids: chunk, add: addIds, remove: removeIds)
                applied += chunk.count
            }
        } catch {
            try? store.finishActionLog(id: logId, status: "error", result: Self.json(["applied": applied]),
                                       error: error.localizedDescription)
            if (error as? IntegrationError) == .revoked { record(error, connectionId: connection.id) }
            throw error
        }

        // The change is in Gmail now, so the action succeeded even if refreshing the local copies fails.
        do {
            let fetched = try await fetch(originals, api: api, connectionId: connection.id)
            let refreshed = try storeRefetched(fetched, originals: originals, connectionId: connection.id)
            try store.finishActionLog(
                id: logId, status: "ok", result: Self.json(ModifyResult(modified: applied)), error: nil)
            return refreshed.map { Self.mailMessage($0, account: account, names: names, includeBodies: false) }
        } catch {
            let message = error.localizedDescription
            try? store.finishActionLog(
                id: logId, status: "ok", result: Self.json(ModifyResult(modified: applied, refreshError: message)),
                error: nil)
            if (error as? IntegrationError) == .revoked { record(error, connectionId: connection.id) }
            throw RequestFailure("labels applied; refreshing messages failed: \(message)")
        }
    }

    private struct ModifyPayload: Encodable {
        let messageIds: [String]
        let add: [String]
        let remove: [String]
    }

    private struct ModifyResult: Encodable {
        let modified: Int
        var refreshError: String?
    }

    /// Re-reads each message from Gmail, `refetchConcurrency` at a time. The result is keyed by index into
    /// `originals`; a message Gmail no longer has (404) is absent.
    private func fetch(
        _ originals: [EmailMessage], api: any GmailAPI, connectionId: String
    ) async throws -> [Int: EmailMessage] {
        var fetched: [Int: EmailMessage] = [:]
        let now = now()
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
                                                                existingId: original.id, now: now))
                    } catch IntegrationError.gmail(status: 404, message: _) {
                        return (index, nil)
                    }
                }
            }
            for _ in 0..<Self.refetchConcurrency { addNext() }
            while let (index, message) = try await group.next() {
                if let message { fetched[index] = message }
                addNext()
            }
        }
        return fetched
    }

    /// Stores re-read messages, or tombstones them when the connection no longer mirrors their class
    /// or Gmail no longer has them. Returns the re-read messages in order.
    ///
    /// Synchronous on purpose: the connection is re-read here, after the fetch's awaits, so settings
    /// changed or an account removed meanwhile are honoured, and nothing can change it again before
    /// the writes. A removed account gets no writes at all.
    private func storeRefetched(
        _ fetched: [Int: EmailMessage], originals: [EmailMessage], connectionId: String
    ) throws -> [EmailMessage] {
        let refreshed = originals.indices.compactMap { fetched[$0] }
        guard let current = try store.connection(idOrEmail: connectionId) else { return refreshed }
        let settings = current.syncSettings
        let kept = refreshed.filter { settings.allows($0.mailClass) }
        let gone = originals.indices.filter { fetched[$0] == nil }.map { originals[$0].externalId }
            + refreshed.filter { !settings.allows($0.mailClass) }.map(\.externalId)
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

    /// Resolves each value to a Gmail label id, without duplicates: an exact label id, else an exact
    /// (case-sensitive) name. Any other value fails with "unknown label".
    private static func resolveLabels(_ values: [String], in labels: [EmailLabel]) throws -> [String] {
        var seen = Set<String>()
        return try values.compactMap { value in
            guard let id = labels.first(where: { $0.externalId == value })?.externalId
                    ?? labels.first(where: { $0.name == value })?.externalId else {
                throw RequestFailure("unknown label: \(value)")
            }
            return seen.insert(id).inserted ? id : nil
        }
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
            bodyText: includeBodies ? bodyText(message) : nil, bodyHtml: includeBodies ? message.bodyHtml : nil,
            attachments: message.attachments)
    }

    /// The `text/plain` part; for a message with none (or a blank one), its HTML read as text.
    static func bodyText(_ message: EmailMessage) -> String? {
        if let text = message.bodyText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        guard let html = message.bodyHtml else { return message.bodyText }
        let converted = MailHTMLText.plainText(fromHTML: html)
        return converted.isEmpty ? message.bodyText : converted
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

/// Internal events a test can wait on.
enum MailServiceEvent: Sendable, Equatable {
    /// The scheduler finished starting due syncs and is about to sleep.
    case schedulerTick
    /// `syncNow` joined the sync already running for this connection id.
    case joinedRunningSync(String)
}

/// A request-level failure whose message is shown as is.
struct RequestFailure: Error, LocalizedError {
    let message: String

    init(_ message: String) { self.message = message }

    var errorDescription: String? { message }
}
