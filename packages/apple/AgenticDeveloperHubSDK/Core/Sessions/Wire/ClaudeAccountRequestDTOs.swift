import Foundation

extension Sessions {

    /// What `steno claude` can ask of the daemon about saved Claude accounts.
    ///
    /// Two kinds of operation share one envelope. The daemon answers the ones it
    /// can from what it already holds — `usage` and `token` — so they work with the
    /// menu-bar app shut. Everything that has to touch a keychain item is relayed
    /// to the app, which keeps custody of those items and runs the very code its
    /// own menus run.
    public enum ClaudeAccountOperation: String, Codable, Sendable {
        /// Token states and quota readings for every saved account. Daemon.
        case usage
        /// One saved credential's bearer token, with at least `minimumLifetime`
        /// seconds left. Daemon; asks the app to refresh first when it must.
        case token
        /// Every saved account as the app's Claude Authentication panel lists it —
        /// never mints, so listing cannot spend a refresh token. App.
        case saved
        /// Install a saved login as the machine-wide Claude Code login. App.
        case switchLogin = "switch"
        /// Save a `claude setup-token` token under `account`. App.
        case saveToken = "save_token"
        /// Capture the machine-wide login into the saved store. App.
        case saveLogin = "save_login"
        /// Drop one saved credential. App.
        case forget
        /// Re-push the saved set now, refreshing `itemKey` if it has less than
        /// `minimumLifetime` left. App — the daemon sends this itself on `token`.
        case refresh
    }

    /// One request from `steno claude`, and — for a relayed operation — what the
    /// daemon forwards to the app unchanged.
    public struct ClaudeAccountRequestDTO: Codable, Sendable, Equatable {
        public let operation: ClaudeAccountOperation
        /// The account name (an email) the operation names, where it names one.
        public let account: String?
        /// ``ClaudeCredentialKind``'s raw value, when the account has both kinds
        /// saved and the operation must pick one.
        public let credentialKind: String?
        /// The keychain item addressed (`"<kind>:<account>"`), for `token`/`refresh`.
        public let itemKey: String?
        /// The token to store, for `saveToken` only.
        public let token: String?
        /// Seconds of life the handed-out token must still have, for `token` and
        /// `refresh`.
        public let minimumLifetime: Double?
        /// For `usage`: re-probe every account now instead of serving the cache.
        public let remeasure: Bool?

        public init(
            operation: ClaudeAccountOperation, account: String? = nil, credentialKind: String? = nil,
            itemKey: String? = nil, token: String? = nil, minimumLifetime: Double? = nil,
            remeasure: Bool? = nil
        ) {
            self.operation = operation
            self.account = account
            self.credentialKind = credentialKind
            self.itemKey = itemKey
            self.token = token
            self.minimumLifetime = minimumLifetime
            self.remeasure = remeasure
        }
    }

    /// One saved credential as the app lists it — no secret, only what a table of
    /// accounts shows.
    public struct ClaudeSavedAccountSummaryDTO: Codable, Sendable, Equatable {
        public let name: String
        /// ``ClaudeCredentialKind``'s raw value.
        public let credentialKind: String
        public let itemKey: String
        /// Epoch seconds it was saved.
        public let addedAt: Double?
        /// Access-token expiry, epoch seconds — logins only.
        public let expiresAt: Double?
        /// Refresh-token expiry, epoch seconds — logins only.
        public let refreshExpiresAt: Double?
        /// This saved login IS the machine-wide login.
        public let isCurrentLogin: Bool
        /// Which keychain holds it (`login` or `shared`).
        public let location: String

        public init(
            name: String, credentialKind: String, itemKey: String, addedAt: Double?,
            expiresAt: Double?, refreshExpiresAt: Double?, isCurrentLogin: Bool, location: String
        ) {
            self.name = name
            self.credentialKind = credentialKind
            self.itemKey = itemKey
            self.addedAt = addedAt
            self.expiresAt = expiresAt
            self.refreshExpiresAt = refreshExpiresAt
            self.isCurrentLogin = isCurrentLogin
            self.location = location
        }
    }

    /// The answer to a ``ClaudeAccountRequestDTO``. Each operation fills the
    /// fields it is about and leaves the rest nil; a refusal never gets here — it
    /// travels as the reply's reason string instead (``XPCReply`` convention).
    public struct ClaudeAccountResponseDTO: Codable, Sendable {
        /// For `usage`.
        public var accounts: ClaudeAccountsDTO?
        /// For `saved`.
        public var saved: [ClaudeSavedAccountSummaryDTO]?
        /// For `token`.
        public var token: String?
        /// Whether the app is connected to answer relayed operations. On every reply
        /// the daemon itself writes.
        public var custodianConnected: Bool?
        /// ``XPCCallerTrust`` verdict label for the caller, for `steno claude doctor`.
        public var callerTrust: String?
        /// A one-line confirmation for a write.
        public var message: String?

        public init(
            accounts: ClaudeAccountsDTO? = nil, saved: [ClaudeSavedAccountSummaryDTO]? = nil,
            token: String? = nil,
            custodianConnected: Bool? = nil, callerTrust: String? = nil, message: String? = nil
        ) {
            self.accounts = accounts
            self.saved = saved
            self.token = token
            self.custodianConnected = custodianConnected
            self.callerTrust = callerTrust
            self.message = message
        }
    }

    /// Shared wording both ends compare on.
    public enum ClaudeAccountRelay {
        /// The refusal the daemon sends when a relayed operation arrives and no app
        /// is connected to answer it. `steno` matches on this exact sentence to know
        /// that launching the app — and asking again — will help.
        public static let noCustodianReason =
            "The Stenographer app isn't running; only it can reach the saved accounts' keychain."

        /// The menu-bar app's bundle identifier, which `steno` launches in the
        /// background when it gets ``noCustodianReason``. The app's bundle id IS the
        /// launchd label (`PRODUCT_BUNDLE_IDENTIFIER` in project.yml), so it is the
        /// same constant the app and daemon both name themselves by.
        public static let appBundleIdentifier = StenographerInstance.baseLabel
    }
}
