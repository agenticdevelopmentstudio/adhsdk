#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import AIPluginKit
import Foundation

/// Where the daemon keeps the Claude account credentials its client relays to
/// it. `AccountQuotaProbe` is the only reader and writer, and the account
/// router reads tokens only through the probe, so this is the one place a
/// credential outlives a request.
///
/// What is kept is what the probe holds: each credential's probe half
/// (``Sessions/ClaudeCredentialDTO/probeOnly``). A refresh token is spent
/// inside the evaluation that judged it and handed back to the caller as a
/// rotation, never stored here.
public protocol AccountCredentialStore: Sendable {
    /// The credentials saved last, or an empty list when none are.
    func load() throws -> [Sessions.ClaudeCredentialDTO]
    /// Replaces the saved set. An empty set removes it.
    func save(_ credentials: [Sessions.ClaudeCredentialDTO]) throws
}

/// The failures an ``AccountCredentialStore`` reports.
public enum AccountCredentialStoreError: Error, Equatable {
    /// The store refused the write (a locked Keychain, a denied access).
    case writeFailed
}

/// ``AccountCredentialStore`` in the Keychain: one generic-password item under
/// an injected service (a daemon passes `<its label>.accounts`), holding the
/// set as JSON. Built on AIPluginKit's ``SecretStoring``, so it shares the
/// toolkit's Keychain access rather than adding another.
public struct KeychainAccountCredentialStore: AccountCredentialStore {
    /// The item's account name inside `service`.
    public static let itemKey = "claude-credentials"

    private let secrets: any SecretStoring

    /// - Parameter service: the Keychain service the item lives under.
    public init(service: String) {
        self.init(secrets: KeychainSecretStore(service: service))
    }

    /// Over any secret store; tests pass an in-memory one.
    init(secrets: any SecretStoring) {
        self.secrets = secrets
    }

    public func load() throws -> [Sessions.ClaudeCredentialDTO] {
        guard let text = try secrets.read(forKey: Self.itemKey), !text.isEmpty else { return [] }
        return try JSONDecoder().decode([Sessions.ClaudeCredentialDTO].self, from: Data(text.utf8))
    }

    public func save(_ credentials: [Sessions.ClaudeCredentialDTO]) throws {
        guard !credentials.isEmpty else {
            secrets.delete(forKey: Self.itemKey)
            return
        }
        guard let text = String(bytes: try JSONEncoder().encode(credentials), encoding: .utf8) else {
            throw AccountCredentialStoreError.writeFailed
        }
        guard secrets.set(text, forKey: Self.itemKey) else { throw AccountCredentialStoreError.writeFailed }
    }
}

/// ``AccountCredentialStore`` in memory, for tests and for a daemon that must
/// not touch the Keychain. Nothing survives the process.
public final class InMemoryAccountCredentialStore: AccountCredentialStore, @unchecked Sendable {
    private let lock = NSLock()
    private var saved: [Sessions.ClaudeCredentialDTO]
    private var saveCount = 0

    public init(_ credentials: [Sessions.ClaudeCredentialDTO] = []) {
        saved = credentials
    }

    /// How many times ``save(_:)`` ran.
    public var saves: Int {
        lock.withLock { saveCount }
    }

    public func load() throws -> [Sessions.ClaudeCredentialDTO] {
        lock.withLock { saved }
    }

    public func save(_ credentials: [Sessions.ClaudeCredentialDTO]) throws {
        lock.withLock {
            saved = credentials
            saveCount += 1
        }
    }
}
#endif
