import Foundation

/// A `CredentialStore` that also remembers the refresh token. The
/// `CredentialStore` half is derived: `currentCredentials()` is the session's
/// credentials, `save(_ credentials:)` replaces the session with one that has
/// no refresh token (that is what adopting an API token means).
public protocol SessionStore: CredentialStore {
    func currentSession() -> HubSession?
    func save(_ session: HubSession)
}

extension SessionStore {
    public func currentCredentials() -> Credentials? {
        currentSession()?.credentials
    }

    public func save(_ credentials: Credentials) {
        save(HubSession(credentials: credentials, refreshToken: nil))
    }
}

public final class InMemorySessionStore: SessionStore, @unchecked Sendable {

    private let lock = NSLock()
    private var session: HubSession?

    public init(_ session: HubSession? = nil) {
        self.session = session
    }

    public func currentSession() -> HubSession? {
        lock.withLock { session }
    }

    public func save(_ session: HubSession) {
        lock.withLock { self.session = session }
    }

    public func clear() {
        lock.withLock { session = nil }
    }
}

/// Keychain-backed session. Shares `<prefix>.token` / `<prefix>.token.kind`
/// with `KeychainCredentialStore` (same default prefix `adh.api`), so a
/// credential saved by the older store is readable here as a session with
/// no refresh token, and vice versa.
public struct KeychainSessionStore: SessionStore {

    let tokenKey: String
    let kindKey: String
    let refreshKey: String

    public init(keyPrefix: String = "adh.api") {
        self.tokenKey = "\(keyPrefix).token"
        self.kindKey = "\(keyPrefix).token.kind"
        self.refreshKey = "\(keyPrefix).refresh"
    }

    /// Every Keychain account this store reads or writes, and exactly the
    /// ones `clear()` deletes. Public so a caller that must remove a
    /// session from outside this process (an installer's uninstall purge)
    /// is told the keys rather than restating them.
    public var accountKeys: [String] { [tokenKey, kindKey, refreshKey] }

    public func currentSession() -> HubSession? {
        guard let token = HubKeychainHelper.get(forKey: tokenKey) else { return nil }
        let kind = HubKeychainHelper.get(forKey: kindKey)
            .flatMap(Credentials.Kind.init(rawValue:)) ?? .jwt
        return HubSession(
            credentials: Credentials(token: token, kind: kind),
            refreshToken: HubKeychainHelper.get(forKey: refreshKey)
        )
    }

    public func save(_ session: HubSession) {
        HubKeychainHelper.set(session.credentials.token, forKey: tokenKey)
        HubKeychainHelper.set(session.credentials.kind.rawValue, forKey: kindKey)
        if let refreshToken = session.refreshToken {
            HubKeychainHelper.set(refreshToken, forKey: refreshKey)
        } else {
            HubKeychainHelper.delete(forKey: refreshKey)
        }
    }

    public func clear() {
        for key in accountKeys {
            HubKeychainHelper.delete(forKey: key)
        }
    }
}
