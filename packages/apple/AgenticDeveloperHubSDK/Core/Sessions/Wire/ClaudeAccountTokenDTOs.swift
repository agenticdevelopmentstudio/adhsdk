import Foundation

extension Sessions {

    /// What the daemon makes of one saved credential's token, right now.
    ///
    /// The states are what a caller can *act* on, which is why `.spent` and
    /// `.expired` are not one case: an expired access token is a routine refresh the
    /// next round performs by itself, and a spent refresh token is a dead account
    /// that no amount of retrying will revive — it needs a browser login. Telling
    /// them apart is the difference between a status line that stays quiet and one
    /// that sends the user somewhere useful.
    public enum ClaudeTokenState: String, Codable, Sendable, CaseIterable {
        /// Good to send, with time to spare.
        case usable
        /// Was expired (or near enough); the daemon minted a fresh pair this round.
        case refreshed
        /// Expired, and no refresh has been attempted yet — the app hasn't offered a
        /// refresh token, or this is a long-lived token that simply ran out.
        case expired
        /// The refresh token is void: this account logged in or refreshed somewhere
        /// else. Nothing recovers it but a fresh login.
        case spent
        /// Anthropic rate-limited the refresh. The credential is untouched and must
        /// not be reported dead.
        case rateLimited = "rate_limited"
        /// A refresh that neither worked nor proved anything — offline, a 5xx, an
        /// unreadable reply. Try again later.
        case inconclusive
        /// A credential with no expiry to read: a `claude setup-token` token, or a
        /// login stored without one. Sent as-is; a 401 from the probe is what
        /// actually answers the question.
        case unknown

        /// What a quota card or a CLI line says when it has room for three words.
        public var title: String {
            switch self {
            case .usable: return "Usable"
            case .refreshed: return "Refreshed"
            case .expired: return "Expired"
            case .spent: return "Spent elsewhere"
            case .rateLimited: return "Rate limited"
            case .inconclusive: return "Unknown — retry"
            case .unknown: return "No expiry"
            }
        }

        /// Whether this credential is worth sending to the API at all. A `.spent`
        /// login's access token may still be within its eight hours, so this is not
        /// the same question as "is the account healthy".
        public var isProbeable: Bool {
            switch self {
            case .usable, .refreshed, .unknown, .rateLimited, .inconclusive: return true
            case .expired, .spent: return false
            }
        }
    }

    /// One saved credential's token state, **with no secret in it**.
    ///
    /// This is the read surface the CLI, the status line and the Usage window get:
    /// everything the daemon knows about a credential except the credential. It is
    /// deliberately separate from ``ClaudeCredentialDTO``, which carries the token
    /// and travels only inward — a single type used for both would be one field
    /// rename away from serving a refresh token over HTTP.
    public struct ClaudeAccountTokenStatusDTO: Codable, Sendable, Equatable {
        /// The account name (an email).
        public let account: String
        /// ``ClaudeCredentialKind``'s raw value, or nil for a credential whose kind
        /// the pushing client never named.
        public let credentialKind: String?
        /// The keychain item it lives in — the same address a rotation is written
        /// back to, so a caller can tell two records of the same email apart.
        public let itemKey: String?
        /// ``ClaudeTokenState``'s raw value. A raw string rather than the enum so a
        /// client older than a state this daemon knows about still decodes the rest.
        public let state: String
        /// Epoch seconds the access token dies, when it says.
        public let expiresAt: Double?
        /// Epoch seconds the *refresh* token dies, when it says. Worth surfacing on
        /// its own: an account whose refresh token has expired is one the user has to
        /// log into again, which no timer is going to fix.
        public let refreshExpiresAt: Double?
        /// Seconds until `expiresAt`, negative once it's past. Computed daemon-side so
        /// every client agrees on "now" — a status line and a menu drawn a second
        /// apart shouldn't disagree about whether a token is alive.
        public let secondsRemaining: Double?
        /// Why, in one line, when the state is anything but `.usable`. Never contains
        /// a token.
        public let detail: String?

        public init(
            account: String, credentialKind: String? = nil, itemKey: String? = nil,
            state: ClaudeTokenState, expiresAt: Double? = nil, refreshExpiresAt: Double? = nil,
            secondsRemaining: Double? = nil, detail: String? = nil
        ) {
            self.account = account
            self.credentialKind = credentialKind
            self.itemKey = itemKey
            self.state = state.rawValue
            self.expiresAt = expiresAt
            self.refreshExpiresAt = refreshExpiresAt
            self.secondsRemaining = secondsRemaining
            self.detail = detail
        }

        /// The state as this build understands it, or `.unknown` for one it doesn't.
        public var tokenState: ClaudeTokenState {
            ClaudeTokenState(rawValue: state) ?? .unknown
        }

        /// The same status with `secondsRemaining` counted against `now`.
        ///
        /// A status is decided once, when the app pushes, and then read for as long
        /// as five minutes — so a countdown frozen at decision time would tell a
        /// caller a token has four hours left when it has three and a half. Everything
        /// else here is a judgment that only a new evaluation can change; this one
        /// field is arithmetic, so it is redone whenever somebody reads.
        public func counting(from now: Date) -> ClaudeAccountTokenStatusDTO {
            ClaudeAccountTokenStatusDTO(
                account: account,
                credentialKind: credentialKind,
                itemKey: itemKey,
                state: tokenState,
                expiresAt: expiresAt,
                refreshExpiresAt: refreshExpiresAt,
                secondsRemaining: expiresAt.map { $0 - now.timeIntervalSince1970 },
                detail: detail
            )
        }
    }

    /// A login the daemon just rotated, on its way back to the process that can
    /// store it.
    ///
    /// **A refresh token is single-use**, so the pair in here is the only copy of
    /// that login that still works: the one it replaced was voided the instant the
    /// token endpoint answered. It goes back down the very connection that supplied
    /// it, in the reply to the call that asked for the evaluation, because that is
    /// the one path guaranteed to reach the process holding the keychain item — and
    /// the one path that hands it to nobody else.
    public struct ClaudeRotatedCredentialDTO: Codable, Sendable {
        /// The keychain item to write it into.
        public let itemKey: String
        /// The account name, for logging and for a caller that addresses by name.
        public let account: String
        /// The fresh pair, to be stored before anything else is allowed to fail.
        public let oauth: ClaudeOAuthCredential

        public init(itemKey: String, account: String, oauth: ClaudeOAuthCredential) {
            self.itemKey = itemKey
            self.account = account
            self.oauth = oauth
        }
    }

    /// What the daemon answers when the app hands over its saved credentials.
    ///
    /// `rotated` is the urgent half: it holds logins whose single-use refresh tokens
    /// have already been spent, so the pair in there is the only copy that still
    /// works and the caller MUST store every one of them before doing anything that
    /// can fail. Arriving at all is the acceptance — a reply the app never gets is a
    /// thrown error, not a field.
    ///
    /// The secret-free per-credential summary is deliberately **not** here. It is one
    /// document, served by `GET /accounts` alongside the quota readings it has to be
    /// read with, and a second copy riding back on the push would be a copy nobody
    /// reads and everybody has to keep in step.
    public struct ClaudeCredentialEvaluationDTO: Codable, Sendable {
        /// Whether the set differed from the one already held — which is also when
        /// the quota cache was invalidated, so the next render measures.
        public let changed: Bool
        /// Logins rotated during this evaluation. Store every one of them.
        public let rotated: [ClaudeRotatedCredentialDTO]

        public init(changed: Bool, rotated: [ClaudeRotatedCredentialDTO] = []) {
            self.changed = changed
            self.rotated = rotated
        }
    }

    /// What the daemon made of a request to renew one saved login — the answer to
    /// "is this login still good, and if so, here is a fresh eight hours of it".
    ///
    /// Asked when the app is about to install a saved login as Claude Code's own:
    /// renewing then hands `claude` a full access-token lifetime instead of whatever
    /// was left of the saved one, and it proves the refresh token is alive before it
    /// is installed rather than after — a spent one is the "login expired" `claude`
    /// would otherwise report on its first request.
    ///
    /// **`oauth`, when present, is the only copy of the login that still works.** The
    /// refresh token it replaced was voided when the endpoint answered, so the caller
    /// MUST store it before doing anything else that can fail.
    public struct ClaudeLoginRenewalDTO: Codable, Sendable {
        /// ``ClaudeTokenState``'s raw value: `.refreshed` with `oauth`, or `.spent`,
        /// `.rateLimited` or `.inconclusive` without. A raw string for the same reason
        /// as ``ClaudeAccountTokenStatusDTO/state``.
        public let state: String
        /// The fresh pair, when the renewal worked.
        public let oauth: ClaudeOAuthCredential?
        /// Why, in one line, when it didn't. Never contains a token.
        public let detail: String?
        /// True only when the failed renewal certainly left the refresh token
        /// unspent — a rate limit, or a request that never left the Mac. A timeout,
        /// a 5xx or an unreadable reply may have rotated the pair server-side and
        /// lost the answer, so those are `false`, and the saved pair must not be
        /// installed as if it still worked. Absent (an older daemon) reads `false`.
        public let tokenUntouched: Bool?

        public init(
            state: ClaudeTokenState, oauth: ClaudeOAuthCredential? = nil, detail: String? = nil,
            tokenUntouched: Bool = false
        ) {
            self.state = state.rawValue
            self.oauth = oauth
            self.detail = detail
            self.tokenUntouched = tokenUntouched
        }

        /// Whether the saved pair is certainly still the live one after this reply.
        public var leftTokenUntouched: Bool { tokenUntouched ?? false }

        /// The state as this build understands it, or `.inconclusive` for one it
        /// doesn't — never a reason to refuse a login.
        public var tokenState: ClaudeTokenState {
            ClaudeTokenState(rawValue: state) ?? .inconclusive
        }
    }

    /// The whole account picture the CLI reads: what the daemon makes of each saved
    /// credential's token, and the quota it last measured with it.
    ///
    /// One document rather than two endpoints because the two answers are read
    /// together — "why is this account at 0%" is answered by the quota row *or* by
    /// the token being spent, and a caller that had to correlate two fetches would
    /// get that wrong on the one round where they disagree.
    public struct ClaudeAccountsDTO: Codable, Sendable {
        public let tokens: [ClaudeAccountTokenStatusDTO]
        public let quotas: [AccountQuotaReadingDTO]
        /// Epoch seconds of the last completed probe round, or nil if none has run.
        public let measuredAt: Double?

        public init(
            tokens: [ClaudeAccountTokenStatusDTO], quotas: [AccountQuotaReadingDTO],
            measuredAt: Double? = nil
        ) {
            self.tokens = tokens
            self.quotas = quotas
            self.measuredAt = measuredAt
        }
    }
}
