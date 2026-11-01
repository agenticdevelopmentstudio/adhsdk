import Foundation

/// Read-only access to the current credential. The auth middleware reads through
/// this at request time, so a token rotation takes effect immediately without
/// rebuilding the client.
public protocol CredentialProvider: Sendable {
    /// The credential to send on the next request, or `nil` for an unauthenticated call.
    func currentCredentials() -> Credentials?
}

/// A credential provider that can also persist and clear the credential —
/// what `ADHClient.login(...)` / `createAPIToken(...)` write through.
public protocol CredentialStore: CredentialProvider {
    func save(_ credentials: Credentials)
    func clear()
}

/// Keychain-backed credential store (the production default on macOS).
///
/// Stateless: every call reads/writes the macOS Keychain directly, so the value
/// survives process restarts and is shared across instances scoped to the same
/// ``KeychainHelper/service``.
public struct KeychainCredentialStore: CredentialStore {

    private let tokenKey: String
    private let kindKey: String

    /// - Parameter keyPrefix: namespace for the Keychain account keys, allowing
    ///   multiple independent stores (e.g. in tests) under one service.
    public init(keyPrefix: String = "adh.api") {
        self.tokenKey = "\(keyPrefix).token"
        self.kindKey = "\(keyPrefix).token.kind"
    }

    public func currentCredentials() -> Credentials? {
        guard let token = HubKeychainHelper.get(forKey: tokenKey) else { return nil }
        let kind = HubKeychainHelper.get(forKey: kindKey)
            .flatMap(Credentials.Kind.init(rawValue:)) ?? .jwt
        return Credentials(token: token, kind: kind)
    }

    public func save(_ credentials: Credentials) {
        HubKeychainHelper.set(credentials.token, forKey: tokenKey)
        HubKeychainHelper.set(credentials.kind.rawValue, forKey: kindKey)
    }

    public func clear() {
        HubKeychainHelper.delete(forKey: tokenKey)
        HubKeychainHelper.delete(forKey: kindKey)
    }
}

/// In-memory credential store. Useful for tests and ephemeral, non-persisted
/// sessions. Thread-safe via an internal lock.
public final class InMemoryCredentialStore: CredentialStore, @unchecked Sendable {

    private let lock = NSLock()
    private var credentials: Credentials?

    public init(_ credentials: Credentials? = nil) {
        self.credentials = credentials
    }

    public func currentCredentials() -> Credentials? {
        lock.withLock { credentials }
    }

    public func save(_ credentials: Credentials) {
        lock.withLock { self.credentials = credentials }
    }

    public func clear() {
        lock.withLock { credentials = nil }
    }
}
