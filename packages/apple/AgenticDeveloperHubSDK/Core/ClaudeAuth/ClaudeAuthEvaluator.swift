import Foundation
import OSLog

/// Decides what each saved credential's token is worth, and mints a fresh one
/// when it isn't worth anything.
///
/// **This is where every judgment about a Claude token lives.** Is this access
/// token still good? Is it close enough to its expiry that a probe started now
/// would arrive after it died? Did the refresh work, and if not, is that a dead
/// account or a rate limit? The app used to answer all of that on its way to the
/// keychain, which meant the answers existed only inside a menu-bar process:
/// nothing else on the machine could ask, and the CLI could not drive any of it.
/// So it moved here, next to the probe and the cache, behind the daemon's own
/// read surfaces.
///
/// What did **not** move is custody. macOS names the requesting process in the
/// permission dialog it raises for a keychain item, and only a process with a UI
/// can answer one — so the app still reads the items and still writes them. The
/// split is: the app supplies and stores, the daemon decides and refreshes.
///
/// That split is what makes the single-use refresh token safe. A rotation is
/// produced only inside a call the app made, and it goes back in that call's
/// reply, so the process that can persist it always learns about it. Nothing
/// here refreshes on a timer of its own, and nothing here refreshes for a caller
/// that has nowhere to put the answer.
public enum ClaudeAuthEvaluator {

    /// What one round of evaluation produced.
    public struct Outcome: Sendable {
        /// The credentials worth probing with, carrying whatever token is
        /// current — rotated where a refresh happened.
        public var probeable: [Sessions.ClaudeCredentialDTO]
        /// Logins whose refresh token was spent this round. The caller MUST get
        /// every one of these back to the app.
        public var rotated: [Sessions.ClaudeRotatedCredentialDTO]
        /// Every pushed credential's state, secret-free.
        public var statuses: [Sessions.ClaudeAccountTokenStatusDTO]

        public init(
            probeable: [Sessions.ClaudeCredentialDTO],
            rotated: [Sessions.ClaudeRotatedCredentialDTO],
            statuses: [Sessions.ClaudeAccountTokenStatusDTO]
        ) {
            self.probeable = probeable
            self.rotated = rotated
            self.statuses = statuses
        }
    }

    /// How a refresh is performed. Injectable so the decision logic can be tested
    /// without a network, and without spending a real single-use refresh token.
    public typealias Refresher = @Sendable (ClaudeOAuthCredential) async throws -> ClaudeOAuthCredential

    public static let liveRefresher: Refresher = { try await ClaudeTokenRefresher.refresh($0) }

    /// Classifies `credential` without touching the network.
    ///
    /// An unknown expiry is `.unknown`, not a reason to refresh: the probe's own
    /// 401 answers the question for certain, and refreshing on a guess spends a
    /// single-use refresh token to learn what a failed request would have said
    /// for free.
    public static func state(
        of credential: Sessions.ClaudeCredentialDTO, now: Date = Date()
    ) -> Sessions.ClaudeTokenState {
        guard let oauth = credential.oauth else { return .unknown }
        guard oauth.expirySeconds != nil else { return .unknown }
        return ClaudeTokenRefresher.isAccessTokenUsable(
            oauth, now: now, margin: credential.refreshWithin) ? .usable : .expired
    }

    /// What one credential's evaluation decided, before the round folds it in.
    private struct Judgment: Sendable {
        /// The credential to probe with, or `nil` when its state says a probe
        /// would only spend a request to be told what we already know.
        let probeable: Sessions.ClaudeCredentialDTO?
        /// A spent refresh token's replacement, which the caller MUST return to
        /// the app.
        let rotated: Sessions.ClaudeRotatedCredentialDTO?
        let status: Sessions.ClaudeAccountTokenStatusDTO
    }

    /// Judges every pushed credential and refreshes the ones that need it.
    ///
    /// `refresh` defaults to the real token endpoint. Pass `nil` to classify
    /// only — which is what an older app build gets, because it refreshed before
    /// pushing and has no way to receive a rotation back.
    ///
    /// The credentials are judged **concurrently**. A refresh is a round trip to
    /// Anthropic with a fifteen-second ceiling of its own, and the app waits on
    /// this call with a ceiling of its own; four expired logins judged one after
    /// another can spend a minute, which is longer than the app is prepared to
    /// wait, and a caller that gives up takes every rotation produced so far with
    /// it. Concurrently, the round costs one refresh's worth of time no matter
    /// how many accounts are saved. Order is restored before folding, so the
    /// statuses come back in the order they were pushed.
    ///
    /// One login saved under two item keys carries one refresh token twice.
    /// Refreshing it twice would let the second refresh find the token the
    /// first one just spent and report a live login `.spent`, so within a round
    /// a refresh token is spent **once**: every credential carrying it shares
    /// that refresh's answer, and each one with an item key gets its own
    /// rotation, so every copy the app holds is replaced.
    public static func evaluate(
        _ credentials: [Sessions.ClaudeCredentialDTO],
        now: Date = Date(),
        refresh: Refresher? = liveRefresher
    ) async -> Outcome {
        let shared = refresh.map { refresh -> Refresher in
            let once = OncePerRefreshToken(refresh)
            return { try await once.refresh($0) }
        }
        let judgments = await withTaskGroup(of: (Int, Judgment).self) { group in
            for (index, credential) in credentials.enumerated() {
                group.addTask { (index, await judge(credential, now: now, refresh: shared)) }
            }
            var collected: [(Int, Judgment)] = []
            for await judged in group { collected.append(judged) }
            return collected.sorted { $0.0 < $1.0 }.map(\.1)
        }

        var outcome = Outcome(probeable: [], rotated: [], statuses: [])
        for judgment in judgments {
            if let probeable = judgment.probeable { outcome.probeable.append(probeable) }
            if let rotated = judgment.rotated { outcome.rotated.append(rotated) }
            outcome.statuses.append(judgment.status)
        }
        return outcome
    }

    /// One credential's half of the round.
    private static func judge(
        _ credential: Sessions.ClaudeCredentialDTO,
        now: Date,
        refresh: Refresher?
    ) async -> Judgment {
        let state = state(of: credential, now: now)
        guard state == .expired, let oauth = credential.oauth, let refresh else {
            // Not everything we decline to refresh is worth probing with. An
            // expired token with no refresher, or a login the endpoint has
            // already called dead, would spend a request to be told what its
            // state already says.
            return Judgment(
                probeable: state.isProbeable ? credential : nil,
                rotated: nil,
                status: status(credential, state: state, oauth: credential.oauth, now: now))
        }

        // Having somewhere to put the replacement is part of the condition for
        // spending a refresh token, not a detail discovered after spending it.
        // The token is single-use, so a rotation we cannot store destroys the
        // saved login: it would work for this round and then be gone, and the
        // app would come back next round holding the pair we just voided.
        guard let itemKey = credential.itemKey else {
            logger.error("""
                token-evaluator: \(credential.account, privacy: .public) is expired but carries no \
                keychain item key — refusing to spend its refresh token on a rotation nothing \
                could store
                """)
            return Judgment(
                probeable: nil,
                rotated: nil,
                status: status(credential, state: state, oauth: oauth, now: now))
        }

        do {
            let fresh = try await refresh(oauth)
            let updated = credential.carrying(fresh)
            return Judgment(
                probeable: updated,
                rotated: Sessions.ClaudeRotatedCredentialDTO(
                    itemKey: itemKey, account: credential.account, oauth: fresh),
                status: status(updated, state: .refreshed, oauth: fresh, now: now))
        } catch let error as ClaudeOAuthRefreshError {
            logger.error("""
                token-evaluator: can't refresh \(credential.account, privacy: .public): \
                \(error.shortText, privacy: .public)
                """)
            let refused = Self.state(for: error)
            return Judgment(
                probeable: refused.isProbeable ? credential : nil,
                rotated: nil,
                status: status(
                    credential, state: refused, oauth: oauth, now: now, detail: error.shortText))
        } catch {
            let reason = error.localizedDescription
            logger.error("""
                token-evaluator: can't refresh \(credential.account, privacy: .public): \
                \(reason, privacy: .public)
                """)
            return Judgment(
                probeable: credential,
                rotated: nil,
                status: status(
                    credential, state: .inconclusive, oauth: oauth, now: now,
                    detail: reason.shortened()))
        }
    }

    /// Spends `oauth`'s refresh token for a fresh pair, unconditionally.
    ///
    /// Unlike a round's `judge`, expiry is not consulted: the caller is about to
    /// hand this login to Claude Code, and the point is both a full access-token
    /// lifetime and proof the refresh token is alive. The caller asked for exactly
    /// this one login and is waiting on the reply, so the rotation has a home.
    public static func renew(
        _ oauth: ClaudeOAuthCredential, refresh: Refresher = liveRefresher
    ) async -> Sessions.ClaudeLoginRenewalDTO {
        do {
            return Sessions.ClaudeLoginRenewalDTO(state: .refreshed, oauth: try await refresh(oauth))
        } catch let error as ClaudeOAuthRefreshError {
            logger.error("token-evaluator: can't renew a login: \(error.shortText, privacy: .public)")
            return Sessions.ClaudeLoginRenewalDTO(
                state: state(for: error), detail: error.shortText,
                tokenUntouched: error.leftTokenUntouched)
        } catch {
            let reason = error.localizedDescription
            logger.error("token-evaluator: can't renew a login: \(reason, privacy: .public)")
            return Sessions.ClaudeLoginRenewalDTO(state: .inconclusive, detail: reason.shortened())
        }
    }

    /// The state a refusal from the token endpoint leaves the credential in —
    /// three answers, because a caller has to treat them differently.
    private static func state(for error: ClaudeOAuthRefreshError) -> Sessions.ClaudeTokenState {
        switch error {
        case .spent: return .spent
        case .rateLimited: return .rateLimited
        case .inconclusive, .unsent: return .inconclusive
        }
    }

    /// The secret-free status for one credential.
    public static func status(
        _ credential: Sessions.ClaudeCredentialDTO,
        state: Sessions.ClaudeTokenState,
        oauth: ClaudeOAuthCredential?,
        now: Date = Date(),
        detail: String? = nil
    ) -> Sessions.ClaudeAccountTokenStatusDTO {
        let expiry = oauth?.expirySeconds
        return Sessions.ClaudeAccountTokenStatusDTO(
            account: credential.account,
            credentialKind: credential.credentialKind,
            itemKey: credential.itemKey,
            state: state,
            expiresAt: expiry,
            refreshExpiresAt: oauth?.refreshExpirySeconds,
            secondsRemaining: expiry.map { $0 - now.timeIntervalSince1970 },
            detail: detail
        )
    }
}

/// One round's refreshes, keyed by refresh token: the first credential to ask
/// starts the refresh, and every later one carrying the same token awaits that
/// same task instead of spending the token again.
private actor OncePerRefreshToken {
    private let refresher: ClaudeAuthEvaluator.Refresher
    private var inFlight: [String: Task<ClaudeOAuthCredential, Error>] = [:]

    init(_ refresher: @escaping ClaudeAuthEvaluator.Refresher) {
        self.refresher = refresher
    }

    func refresh(_ oauth: ClaudeOAuthCredential) async throws -> ClaudeOAuthCredential {
        if let task = inFlight[oauth.refreshToken] { return try await task.value }
        let refresher = self.refresher
        let task = Task { try await refresher(oauth) }
        // Stored before the first suspension, so a second caller always finds it.
        inFlight[oauth.refreshToken] = task
        return try await task.value
    }
}

extension ClaudeAuthEvaluator: Loggable {
    public static nonisolated let logger = makeLogger()
}
