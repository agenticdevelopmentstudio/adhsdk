#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import OSLog

/// Live per-account quota probe + cache, and the daemon's custody of the Claude
/// account credentials its client relays to it.
///
/// For every held credential it sends a `max_tokens=1` `/v1/messages` request
/// and reads the subscription rate-limit headers off the response. Nothing
/// cheaper works: the `anthropic-ratelimit-unified-*` headers ride on a real
/// completion, and no metadata endpoint carries them.
///
/// **One per daemon.** A Claude refresh token is single-use, so two processes
/// (or two probes in one) judging the same expired login both spend it, and
/// the second spend voids the first one's rotation. The daemon builds exactly
/// one of these, hands it to the database as its `accountQuotaSource` and to
/// the account router as its credential source, and nothing else refreshes.
///
/// The client reads its own Keychain items (they are its own; macOS names the
/// requesting process in the permission dialog, and only a process with a UI
/// can answer one) and relays the whole login in through
/// ``takeCredentials(_:refreshing:now:)``, storing whatever rotation comes back.
/// What this keeps is each credential's probe half
/// (``Sessions/ClaudeCredentialDTO/probeOnly``), in memory and in the injected
/// ``AccountCredentialStore``, so a restarted daemon can measure before the
/// client speaks again. A refresh token is held only for the duration of the
/// call that might spend it. Tokens are never logged.
///
/// The one getter, ``heldToken(itemKey:)``, is for the account router, which
/// swaps the token into a request it relays and never lets it leave the daemon
/// any other way; any other caller must be gated by the daemon's caller trust.
///
/// Probes run on a private utility queue — NEVER on the DB queue (each one is a
/// network round-trip) — and only when a consumer asks while the cache is past
/// its TTL (`refreshIfStale`, piggybacked on status-line renders), so an idle
/// machine probes nothing.
public final class AccountQuotaProbe: AccountQuotaSource, @unchecked Sendable {

    /// The cheapest model that still produces the unified rate-limit headers, one
    /// token of output, just to get the response headers back. The
    /// `anthropic-beta` value is the header the official client sends for
    /// OAuth-token calls.
    private static let messagesURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let anthropicVersion = "2023-06-01"
    private static let oauthBeta = "oauth-2025-04-20"
    private static let probeModel = "claude-haiku-4-5"
    private static let timeout: TimeInterval = 15
    public static let defaultTTL: TimeInterval = 300
    /// How soon a round the *network* failed is measured again. A dropped Wi-Fi
    /// is over in a minute, and the cards it turned into "offline" must not wait
    /// out `defaultTTL` once it is back. A refusal (401, 403) is an answer and
    /// still waits the whole TTL.
    static let networkRetryTTL: TimeInterval = 30

    private let lock = NSLock()
    private var readings: [Sessions.AccountQuotaReadingDTO] = []
    /// What the client last relayed, stripped to what a probe needs. Read only by
    /// `refreshNow` and the router's getters, never handed back.
    private var credentials: [Sessions.ClaudeCredentialDTO] = []
    /// What the last evaluation made of each relayed credential — secret-free, so
    /// this one *is* handed back, to the client and to the CLI alike.
    private var statuses: [Sessions.ClaudeAccountTokenStatusDTO] = []
    private var fetchedAt: Date?
    /// The last round had a probe fail in transport — offline, timed out, DNS
    /// — so its readings are stale after ``networkRetryTTL``, not `defaultTTL`.
    private var lastRoundLostTheNetwork = false
    private var inFlight = false
    /// Guards the "no credentials" warning so a probe that recurs every
    /// `defaultTTL` (5 min) doesn't spam the log forever on a machine where the
    /// client has saved no accounts. Internal (not private) so tests in the same
    /// module can observe it fired exactly once. See `refreshNow`.
    var hasLoggedMissingCredentials = false

    private let probeQueue: DispatchQueue
    /// Where the held set is saved; read once, at init.
    private let store: any AccountCredentialStore
    /// Named on purpose. Cloudflare sits in front of the API and rejects a
    /// default client signature outright (403, "error code: 1010") before it ever
    /// reads the request, so every call names its product.
    private let userAgent: String
    /// Serializes ``takeCredentials(_:refreshing:now:)``. The relay route answers
    /// every client that asks and wraps each call in a task of its own, so two
    /// evaluations can otherwise be in flight at once — and two rounds judging the
    /// same expired login both spend its refresh token, which is single-use. The
    /// second spend voids the first one's rotation, and the client is handed a pair
    /// that was dead before it arrived.
    private let evaluations = SerialAsyncGate()
    /// Injectable for tests: returns the (lowercased-key) response headers for
    /// one credential's bearer token, or throws. Defaults to the real probe.
    private let prober: @Sendable (String) throws -> [String: String]
    /// The probes' own URL session, replaced after a round that lost the network
    /// and on every ``remeasure(completion:)``, so the next round opens new
    /// connections rather than reusing ones from an interface that went away.
    private let sessions: ProbeSessions

    /// - Parameters:
    ///   - label: the daemon's label; names the probe queue.
    ///   - credentials: where the held set is saved. Loaded here, once: a set the
    ///     store cannot read is logged and starts empty (the client re-relays).
    ///   - userAgent: the `User-Agent` every probe sends.
    public convenience init(
        label: String,
        credentials: any AccountCredentialStore,
        userAgent: String = ClaudeTokenRefresher.userAgent
    ) {
        self.init(label: label, credentials: credentials, userAgent: userAgent, prober: nil)
    }

    /// Tests' form: `prober` stands in for the network probe, and the store is
    /// in memory unless given.
    init(
        label: String = "account-quota",
        credentials: any AccountCredentialStore = InMemoryAccountCredentialStore(),
        userAgent: String = ClaudeTokenRefresher.userAgent,
        prober: (@Sendable (String) throws -> [String: String])?
    ) {
        let sessions = ProbeSessions()
        self.sessions = sessions
        self.store = credentials
        self.userAgent = userAgent
        self.probeQueue = DispatchQueue(label: "\(label).account-quota", qos: .utility)
        self.prober = prober ?? { try Self.probeHeaders(token: $0, userAgent: userAgent, session: sessions.current) }
        do {
            self.credentials = try credentials.load()
        } catch {
            Self.logger.error(
                "account-quota: could not read the saved credentials: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    /// Latest readings (possibly empty when no probe has completed yet).
    public func current() -> [Sessions.AccountQuotaReadingDTO] {
        lock.lock(); defer { lock.unlock() }
        return readings
    }

    /// When the last probe round finished, or nil if none has.
    public func measuredAt() -> Date? {
        lock.lock(); defer { lock.unlock() }
        return fetchedAt
    }

    /// The whole account picture in one document: token states and quota
    /// readings, which are read together because either one can be the answer to
    /// "why is this account at zero".
    public func accounts(now: Date = Date()) -> Sessions.ClaudeAccountsDTO {
        lock.lock()
        let held = statuses
        let quotas = readings
        let measured = fetchedAt
        lock.unlock()
        return Sessions.ClaudeAccountsDTO(
            tokens: held.map { $0.counting(from: now) },
            quotas: quotas,
            measuredAt: measured?.timeIntervalSince1970
        )
    }

    /// The bearer token held for one saved credential, and when it dies — the
    /// one read of a secret this store allows, for the account router.
    ///
    /// Two callers. The account router reads it in-process to swap the token
    /// on a request it relays (`AccountPool`), and never lets it leave the
    /// daemon except as that request's `Authorization`. Any other path to it
    /// must pass the daemon's caller trust first, and a CLI that hands a token
    /// out guards the rest. nil when nothing probeable is held under `itemKey`
    /// — never relayed, or judged dead.
    public func heldToken(itemKey: String) -> HeldToken? {
        lock.lock(); defer { lock.unlock() }
        guard let held = credentials.first(where: { $0.itemKey == itemKey }) else { return nil }
        let expiry = statuses.first(where: { $0.itemKey == itemKey })?.expiresAt
        return HeldToken(token: held.token, expiresAt: expiry, credentialKind: held.credentialKind)
    }

    /// Whether `token` is one of the credentials the client relayed: the account
    /// router's fence. Compared digest to digest, so the comparison never
    /// branches on the secret's own bytes.
    public func holds(token: String) -> Bool {
        let digest = AccountFingerprints.fingerprint(of: token)
        lock.lock(); defer { lock.unlock() }
        return credentials.contains { AccountFingerprints.fingerprint(of: $0.token) == digest }
    }

    /// Item keys of every held credential, in push order. Secret-free: this is
    /// what the router's status offers as choosable pool entries.
    public func savedItemKeys() -> [String] {
        lock.lock(); defer { lock.unlock() }
        return credentials.compactMap(\.itemKey)
    }

    /// The reading held for one (account, kind) bucket.
    public func reading(account: String, credentialKind: String?) -> Sessions.AccountQuotaReadingDTO? {
        lock.lock(); defer { lock.unlock() }
        return readings.first { $0.account == account && $0.credentialKind == credentialKind }
    }

    /// Folds one routed response's `anthropic-ratelimit-unified-*` headers
    /// (lowercased keys) into that bucket's reading, field by field: a window
    /// the response omits keeps its previous value. A response with no window
    /// at all changes nothing.
    ///
    /// A probe round (`refreshNow`) still replaces the whole list. A merge that
    /// lands while a round is in flight can be overwritten by that round's
    /// result; that is accepted, because both are real readings of the same bucket.
    public func observe(account: String, credentialKind: String?, headers: [String: String]) {
        let fresh = Sessions.AccountQuotaReadingDTO(account: account, credentialKind: credentialKind, headers: headers)
        guard fresh.carriesAnyWindow else { return }
        lock.lock(); defer { lock.unlock() }
        if let index = readings.firstIndex(where: { $0.account == account && $0.credentialKind == credentialKind }) {
            readings[index] = readings[index].merging(fresh)
        } else {
            readings.append(
                Sessions.AccountQuotaReadingDTO(account: account, credentialKind: credentialKind).merging(fresh))
        }
    }

    /// What ``heldToken(itemKey:)`` hands out.
    public struct HeldToken: Sendable {
        public let token: String
        /// Epoch seconds it dies, when the daemon was told.
        public let expiresAt: Double?
        /// ``ClaudeCredentialKind``'s raw value, as pushed.
        public let credentialKind: String?

        public init(token: String, expiresAt: Double?, credentialKind: String?) {
            self.token = token
            self.expiresAt = expiresAt
            self.credentialKind = credentialKind
        }

        /// A login the client relayed probe-only — the machine-wide one, which
        /// Claude Code refreshes itself. It came without its expiry, so how long
        /// it lives is not something the daemon can promise anybody.
        public var isUnjudgedLogin: Bool {
            credentialKind == ClaudeCredentialKind.oauth.rawValue && expiresAt == nil
        }
    }

    /// Judges everything the client just read out of its keychain, refreshes what
    /// has expired, and takes custody of the result.
    ///
    /// **The reply is not optional to the caller.** `rotated` holds logins whose
    /// single-use refresh tokens have already been spent, so the pair in there is
    /// the only copy that still works — a caller that drops it kills the saved
    /// account. That is why the refreshing happens inside this call and not on a
    /// timer of the daemon's own: the daemon cannot write a keychain item, so it
    /// refreshes only where the answer can be handed straight back to the process
    /// that can.
    ///
    /// `refreshing: false` is the classify-only path, for a caller that has
    /// nowhere to put a rotation.
    ///
    /// Rounds run one at a time. See ``evaluations``.
    public func takeCredentials(
        _ pushed: [Sessions.ClaudeCredentialDTO], refreshing: Bool = true, now: Date = Date()
    ) async -> Sessions.ClaudeCredentialEvaluationDTO {
        await evaluations.run { [self] in
            let outcome = await ClaudeAuthEvaluator.evaluate(
                pushed, now: now, refresh: refreshing ? ClaudeAuthEvaluator.liveRefresher : nil
            )
            // Only the probe half is kept. A refresh token that lived past this
            // line could never be used for anything — nothing else in the daemon
            // may spend one — so keeping it would be exposure bought for nothing.
            let changed = setCredentials(outcome.probeable.map { $0.probeOnly })
            setStatuses(outcome.statuses)
            return Sessions.ClaudeCredentialEvaluationDTO(changed: changed, rotated: outcome.rotated)
        }
    }

    /// Swaps in what the last evaluation decided.
    ///
    /// Its own method because ``takeCredentials(_:refreshing:now:)`` is async and
    /// `NSLock` may not be taken from an async context: the lock is held across
    /// an assignment and nothing else, which is exactly what a synchronous
    /// helper guarantees and an inline `lock()` there would not.
    private func setStatuses(_ fresh: [Sessions.ClaudeAccountTokenStatusDTO]) {
        lock.lock()
        statuses = fresh
        lock.unlock()
    }

    /// Swaps in the set to probe with — the storage half of
    /// ``takeCredentials(_:refreshing:now:)``, and the only way the probe set ever
    /// moves.
    ///
    /// Returns `true` when the set actually changed — a different account, a
    /// different credential kind, or a token the evaluation has since refreshed.
    /// The app re-pushes on its own timer and on every reconnect, so most pushes
    /// say nothing new and must cost nothing.
    ///
    /// A change *invalidates* the cache rather than probing on the spot. The
    /// readings it holds are about the set that just went away — an account the
    /// user deleted would otherwise keep drawing its last numbers for the rest of
    /// the TTL — but probing from here would also spend a request per account on a
    /// machine nobody is looking at. Clearing `fetchedAt` instead means the next
    /// render measures, which is the same rule the TTL already follows.
    @discardableResult
    public func setCredentials(_ fresh: [Sessions.ClaudeCredentialDTO]) -> Bool {
        lock.lock()
        let changed = !Self.sameSet(credentials, fresh)
        if changed {
            credentials = fresh
            fetchedAt = nil
        }
        lock.unlock()
        guard changed else { return false }
        do {
            try store.save(fresh)
        } catch {
            Self.logger.error(
                "account-quota: could not save the credentials: \(error.localizedDescription, privacy: .public)"
            )
        }
        Self.logger.info(
            "account-quota: the client relayed \(fresh.count, privacy: .public) credential(s)"
        )
        return true
    }

    /// Kick a background refresh when the cache is older than `ttl`.
    /// Non-blocking; single-flight. Consumers keep reading `current()` and pick
    /// the new readings up on a later call (stale-while-revalidate, same pattern
    /// as the usage-rows cache).
    /// ``AccountQuotaSource``'s form: ``refreshIfStale(ttl:now:)`` at the default TTL.
    public func refreshIfStale() {
        refreshIfStale(ttl: Self.defaultTTL, now: Date())
    }

    public func refreshIfStale(ttl: TimeInterval, now: Date = Date()) {
        lock.lock()
        let window = lastRoundLostTheNetwork ? min(ttl, Self.networkRetryTTL) : ttl
        let fresh = fetchedAt.map { now.timeIntervalSince($0) <= window } ?? false
        let start = !fresh && !inFlight
        if start { inFlight = true }
        lock.unlock()
        guard start else { return }
        probeQueue.async { [weak self] in self?.refreshNow() }
    }

    /// Re-probe regardless of the TTL, calling back once the cache holds the
    /// answer. This is what the Usage window's Reload reaches: a reload that only
    /// re-read the cache would redraw, instantly, the very number it was
    /// clicked to correct.
    ///
    /// `probeQueue` is serial, so a round already queued finishes first and this
    /// one measures after it rather than alongside it. Claiming `inFlight` up
    /// front is what stops a `refreshIfStale` arriving in between from queueing a
    /// third round behind this one to re-measure what it is already measuring.
    ///
    /// The completion reports whether this round **measured**, which is not the
    /// same question as whether the cache has anything in it. A daemon the client has
    /// not spoken to yet keeps whatever readings it was last given, so asking
    /// `current()` would answer "yes, measured" with numbers from before the
    /// reload — and the caller that needs the difference is the HTTP endpoint that
    /// answers 409 when there is nothing to measure.
    ///
    /// It also starts the round on a new URL session: a Reload is what someone
    /// clicks after the network came back, and it has to reconnect rather than
    /// wait on connections the old network left behind.
    public func remeasure(completion: @escaping @Sendable (Bool) -> Void) {
        lock.lock()
        inFlight = true
        lock.unlock()
        sessions.reset()
        probeQueue.async { [weak self] in
            guard let self else {
                completion(false)
                return
            }
            completion(self.refreshNow())
        }
    }

    /// Probe every pushed credential sequentially and swap the cache. Runs on
    /// `probeQueue` (or a test's thread) — never the DB queue.
    ///
    /// Returns whether a round actually happened. `false` means there was nothing
    /// to probe: the client has relayed no credentials.
    @discardableResult
    public func refreshNow() -> Bool {
        lock.lock()
        let pending = credentials
        lock.unlock()

        guard !pending.isEmpty else {
            logMissingCredentialsOnce()
            // Whatever readings are already held stay. An empty credential set is
            // the client not having spoken yet, which is a failure to read and
            // not a reading of nothing — overwriting good numbers with it would
            // blank the window every time the client restarted.
            lock.lock()
            fetchedAt = Date()
            inFlight = false
            lock.unlock()
            return false
        }

        lock.lock()
        let previous = readings
        lock.unlock()

        var fresh: [Sessions.AccountQuotaReadingDTO] = []
        var lostTheNetwork = false
        for credential in pending {
            let name = credential.account
            do {
                let headers = try prober(credential.token)
                fresh.append(Sessions.AccountQuotaReadingDTO(
                    account: name, credentialKind: credential.credentialKind, headers: headers
                ))
            } catch {
                if let kept = Self.lastGoodReading(for: credential, after: error, in: previous) {
                    Self.logger.info("""
                        account-quota: \(name, privacy: .public)'s live login copy has expired; \
                        keeping its last reading until Claude Code refreshes it
                        """)
                    fresh.append(kept)
                    continue
                }
                if (error as NSError).domain == NSURLErrorDomain { lostTheNetwork = true }
                let reason = error.localizedDescription
                Self.logger.warning(
                    "account-quota probe failed for \(name, privacy: .public): \(reason, privacy: .public)"
                )
                fresh.append(Sessions.AccountQuotaReadingDTO(
                    account: name, credentialKind: credential.credentialKind,
                    errorText: reason.shortened()
                ))
            }
        }
        if lostTheNetwork { sessions.reset() }
        lock.lock()
        readings = fresh
        fetchedAt = Date()
        lastRoundLostTheNetwork = lostTheNetwork
        inFlight = false
        lock.unlock()
        return true
    }

    /// The reading to keep instead of an error for `credential`, or nil.
    ///
    /// Only for the account Claude Code is logged in as, which the client relays
    /// probe-only (`oauth` nil): its refresh token is Claude Code's to spend, so
    /// nothing here may refresh it, and its copy's access token dies whenever
    /// Claude Code sits idle past eight hours — overnight, routinely. A 401 then
    /// says "Claude Code hasn't refreshed yet", not "this account is broken", and
    /// the last good numbers are a truer picture than an error card until the
    /// app's next round brings the refreshed pair.
    static func lastGoodReading(
        for credential: Sessions.ClaudeCredentialDTO, after error: Error,
        in previous: [Sessions.AccountQuotaReadingDTO]
    ) -> Sessions.AccountQuotaReadingDTO? {
        let failure = error as NSError
        guard credential.oauth == nil,
              credential.credentialKind == ClaudeCredentialKind.oauth.rawValue,
              failure.domain == "AccountQuota", [401, 403].contains(failure.code)
        else { return nil }
        return previous.first {
            $0.account == credential.account && $0.credentialKind == credential.credentialKind
                && $0.errorText == nil
        }
    }

    /// Warn once (not on every 5-min probe) that the client has relayed nothing, so a
    /// silent "no accounts configured" degradation is diagnosable from the logs
    /// instead of just showing an empty section.
    private func logMissingCredentialsOnce() {
        lock.lock()
        let shouldLog = !hasLoggedMissingCredentials
        if shouldLog { hasLoggedMissingCredentials = true }
        lock.unlock()
        guard shouldLog else { return }
        Self.logger.warning(
            "account-quota: the client has relayed no credentials — no accounts to measure"
        )
    }

    /// Whether two credential sets name the same accounts carrying the same
    /// tokens, in any order. Compared by digest, never by token text, so nothing
    /// that reads this comparison ever holds one.
    private static func sameSet(
        _ lhs: [Sessions.ClaudeCredentialDTO], _ rhs: [Sessions.ClaudeCredentialDTO]
    ) -> Bool {
        guard lhs.count == rhs.count else { return false }
        func keys(_ set: [Sessions.ClaudeCredentialDTO]) -> Set<String> {
            Set(set.map {
                ClaudeCredentialKind.key(account: $0.account, kindRawValue: $0.credentialKind)
                    + "|" + AccountFingerprints.fingerprint(of: $0.token)
            })
        }
        return keys(lhs) == keys(rhs)
    }

    // MARK: - Network probe

    /// Synchronous single-credential probe (runs on `probeQueue`). A 429 still
    /// carries the usage headers, so it is a success for our purposes — it is the
    /// account being *out* of quota, which is a reading; 401/403 mean the
    /// credential needs re-minting or re-saving in the client.
    private static func probeHeaders(
        token: String, userAgent: String, session: URLSession
    ) throws -> [String: String] {
        var request = URLRequest(url: messagesURL, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue(oauthBeta, forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": probeModel,
            "max_tokens": 1,
            "messages": [["role": "user", "content": "."]]
        ])

        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var result: Result<[String: String], Error> = .failure(
            URLError(.unknown)
        )
        let task = session.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }
            if let error {
                result = .failure(error)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                result = .failure(URLError(.badServerResponse))
                return
            }
            if http.statusCode == 401 || http.statusCode == 403 {
                result = .failure(NSError(
                    domain: "AccountQuota", code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "token invalid or expired"]
                ))
                return
            }
            var headers: [String: String] = [:]
            for (key, value) in http.allHeaderFields {
                if let name = key as? String, let text = value as? String {
                    headers[name.lowercased()] = text
                }
            }
            result = .success(headers)
        }
        task.resume()
        semaphore.wait()
        return try result.get()
    }
}

/// The probe store's URL session, swapped whole by ``reset()``. Ephemeral, so a
/// swap leaves no connection, cookie or cache behind to carry into the next one.
private final class ProbeSessions: @unchecked Sendable {
    private let lock = NSLock()
    private var session = URLSession(configuration: .ephemeral)

    var current: URLSession {
        lock.lock(); defer { lock.unlock() }
        return session
    }

    /// Lets a probe already running on the old session finish, then drops it.
    func reset() {
        lock.lock()
        let old = session
        session = URLSession(configuration: .ephemeral)
        lock.unlock()
        old.finishTasksAndInvalidate()
    }
}

extension AccountQuotaProbe: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
