import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@testable import AgenticDeveloperHubAuth
@testable import AgenticDeveloperHubClient

@Suite("Session stores")
struct SessionStoreTests {

    @Test("in-memory store round-trips a session and exposes its credentials")
    func inMemoryRoundTrip() {
        let store = InMemorySessionStore()
        #expect(store.currentSession() == nil)
        #expect(store.currentCredentials() == nil)

        let session = HubSession(credentials: Credentials(token: "jwt-1", kind: .jwt), refreshToken: "r-1")
        store.save(session)

        #expect(store.currentSession() == session)
        #expect(store.currentCredentials() == Credentials(token: "jwt-1", kind: .jwt))
    }

    @Test("saving bare credentials drops any refresh token (an API token has none)")
    func saveCredentialsDropsRefreshToken() {
        let store = InMemorySessionStore(HubSession(credentials: Credentials(token: "jwt-1", kind: .jwt), refreshToken: "r-1"))

        store.save(Credentials(token: "adh_secret", kind: .apiToken))

        #expect(store.currentSession() == HubSession(credentials: Credentials(token: "adh_secret", kind: .apiToken), refreshToken: nil))
    }

    @Test("clear removes the whole session")
    func clearRemovesSession() {
        let store = InMemorySessionStore(HubSession(credentials: Credentials(token: "jwt-1", kind: .jwt), refreshToken: "r-1"))

        store.clear()

        #expect(store.currentSession() == nil)
        #expect(store.currentCredentials() == nil)
    }

    @Test("a session store is usable wherever a CredentialProvider is expected")
    func isACredentialProvider() {
        let store: any CredentialProvider = InMemorySessionStore(HubSession(credentials: Credentials(token: "t", kind: .jwt)))
        #expect(store.currentCredentials()?.token == "t")
    }

    @Test("keychain store derives its three keys from the prefix")
    func keychainKeys() {
        let store = KeychainSessionStore(keyPrefix: "adh.test")
        #expect(store.tokenKey == "adh.test.token")
        #expect(store.kindKey == "adh.test.token.kind")
        #expect(store.refreshKey == "adh.test.refresh")
    }

    @Test("keychain store's accountKeys are exactly the three keys it writes")
    func keychainAccountKeys() {
        let store = KeychainSessionStore(keyPrefix: "adh.test")
        #expect(store.accountKeys == [store.tokenKey, store.kindKey, store.refreshKey])
        #expect(store.accountKeys == ["adh.test.token", "adh.test.token.kind", "adh.test.refresh"])
    }
}

/// Behavioral cover for `KeychainSessionStore` against the real Keychain.
/// Every test namespaces its items under a unique `keyPrefix` (so parallel
/// tests and reruns cannot see each other's items) and deletes them again.
@Suite("KeychainSessionStore")
struct KeychainSessionStoreTests {

    private static func uniquePrefix(_ label: String) -> String {
        "adh.test.\(label).\(UUID().uuidString)"
    }

    @Test("saves and reads back a whole session")
    func roundTrip() {
        let prefix = Self.uniquePrefix("round-trip")
        let store = KeychainSessionStore(keyPrefix: prefix)
        defer { store.clear() }

        #expect(store.currentSession() == nil)

        let session = HubSession(credentials: Credentials(token: "jwt-kc-1", kind: .jwt), refreshToken: "r-kc-1")
        store.save(session)

        #expect(store.currentSession() == session)
        #expect(store.currentCredentials() == Credentials(token: "jwt-kc-1", kind: .jwt))
        #expect(KeychainSessionStore(keyPrefix: prefix).currentSession() == session)
    }

    /// Adopting an API token replaces the session with one that has no refresh
    /// token. If the stored `<prefix>.refresh` survived, the previous JWT's
    /// refresh token would stay in the Keychain — readable, still valid on the
    /// server, and reattached to the next session read.
    @Test("saving a session with no refresh token deletes a previously stored one")
    func nilRefreshTokenDeletesStoredRefresh() {
        let prefix = Self.uniquePrefix("nil-refresh")
        let store = KeychainSessionStore(keyPrefix: prefix)
        defer { store.clear() }

        store.save(HubSession(credentials: Credentials(token: "jwt-kc-2", kind: .jwt), refreshToken: "r-kc-2"))
        #expect(HubKeychainHelper.exists(forKey: store.refreshKey))

        store.save(Credentials(token: "adh_secret", kind: .apiToken))

        #expect(!HubKeychainHelper.exists(forKey: store.refreshKey))
        #expect(store.currentSession() == HubSession(credentials: Credentials(token: "adh_secret", kind: .apiToken), refreshToken: nil))
    }

    @Test("clear removes all three keys")
    func clearRemovesEveryKey() {
        let prefix = Self.uniquePrefix("clear")
        let store = KeychainSessionStore(keyPrefix: prefix)
        defer { store.clear() }

        store.save(HubSession(credentials: Credentials(token: "jwt-kc-3", kind: .jwt), refreshToken: "r-kc-3"))

        store.clear()

        #expect(!HubKeychainHelper.exists(forKey: store.tokenKey))
        #expect(!HubKeychainHelper.exists(forKey: store.kindKey))
        #expect(!HubKeychainHelper.exists(forKey: store.refreshKey))
        #expect(store.currentSession() == nil)
        #expect(store.currentCredentials() == nil)
    }

    /// The compatibility the doc comment promises: both stores share
    /// `<prefix>.token` / `<prefix>.token.kind`, so a credential written by
    /// the older store reads back here as a session with no refresh token,
    /// and a session written here reads back there as its credentials.
    @Test("round-trips with KeychainCredentialStore under the same prefix")
    func interoperatesWithCredentialStore() {
        let prefix = Self.uniquePrefix("compat")
        let sessionStore = KeychainSessionStore(keyPrefix: prefix)
        let credentialStore = KeychainCredentialStore(keyPrefix: prefix)
        defer { sessionStore.clear() }

        credentialStore.save(Credentials(token: "adh_older", kind: .apiToken))
        #expect(sessionStore.currentSession() == HubSession(credentials: Credentials(token: "adh_older", kind: .apiToken), refreshToken: nil))

        sessionStore.save(HubSession(credentials: Credentials(token: "jwt-kc-4", kind: .jwt), refreshToken: "r-kc-4"))
        #expect(credentialStore.currentCredentials() == Credentials(token: "jwt-kc-4", kind: .jwt))

        credentialStore.clear()
        #expect(sessionStore.currentSession() == nil)
        // `clear()` on the older store knows nothing about the refresh key —
        // the session store's own `clear()` is what removes it.
        #expect(HubKeychainHelper.exists(forKey: sessionStore.refreshKey))
    }
}

/// Tokens must never reach a log or a test failure message. The default
/// reflection-based description prints every stored property, so both types
/// override it.
@Suite("Credential redaction")
struct CredentialRedactionTests {

    private static let accessToken = "eyJhbGciOiJIUzI1NiJ9.super-secret-access-value"
    private static let refreshToken = "rt_super-secret-refresh-value"

    @Test("Credentials never prints its token")
    func credentialsRedacted() {
        let credentials = Credentials(token: Self.accessToken, kind: .apiToken)

        #expect(!"\(credentials)".contains(Self.accessToken))
        #expect(!String(reflecting: credentials).contains(Self.accessToken))
        #expect(credentials.description == "Credentials(kind: apiToken, token: <redacted>)")
        #expect(credentials.debugDescription == credentials.description)
    }

    @Test("Session never prints either token but reports whether a refresh token is present")
    func sessionRedacted() {
        let withRefresh = HubSession(
            credentials: Credentials(token: Self.accessToken, kind: .jwt),
            refreshToken: Self.refreshToken
        )
        let withoutRefresh = HubSession(credentials: Credentials(token: Self.accessToken, kind: .apiToken))

        for text in ["\(withRefresh)", String(reflecting: withRefresh), "\(withoutRefresh)", String(reflecting: withoutRefresh)] {
            #expect(!text.contains(Self.accessToken))
            #expect(!text.contains(Self.refreshToken))
        }
        #expect(withRefresh.description == "Session(kind: jwt, token: <redacted>, refreshToken: <redacted>)")
        #expect(withoutRefresh.description == "Session(kind: apiToken, token: <redacted>, refreshToken: none)")
    }

    /// Redaction is a printing concern only: equality, hashing through
    /// `Codable` round trips, and every existing caller behave as before.
    @Test("redaction does not change value semantics")
    func valueSemanticsUnchanged() throws {
        let credentials = Credentials(token: Self.accessToken, kind: .jwt)
        let session = HubSession(credentials: credentials, refreshToken: Self.refreshToken)

        #expect(credentials == Credentials(token: Self.accessToken, kind: .jwt))
        #expect(session == HubSession(credentials: credentials, refreshToken: Self.refreshToken))

        let encoded = try JSONEncoder().encode(session)
        #expect(try JSONDecoder().decode(HubSession.self, from: encoded) == session)
        // The tokens are still *stored* — only the description hides them.
        #expect(session.credentials.token == Self.accessToken)
        #expect(session.refreshToken == Self.refreshToken)
    }
}
