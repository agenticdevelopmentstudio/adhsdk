import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase
import XCTest

/// The credential store the probe saves through. Never the real Keychain: the
/// Keychain form runs over `InMemorySecretStore`.
final class AccountCredentialStoreTests: XCTestCase {
    private let alpha = Sessions.ClaudeCredentialDTO(account: "a@x.com", credentialKind: "long-lived", token: "t1")
    private let beta = Sessions.ClaudeCredentialDTO(account: "b@x.com", credentialKind: "long-lived", token: "t2")

    func testKeychainStoreRoundTripsTheSetAsOneItem() throws {
        let secrets = InMemorySecretStore()
        let store = KeychainAccountCredentialStore(secrets: secrets)
        XCTAssertEqual(try store.load().map(\.token), [])
        try store.save([alpha, beta])
        XCTAssertEqual(secrets.allKeys, [KeychainAccountCredentialStore.itemKey])
        XCTAssertEqual(try store.load().map(\.token), [alpha, beta].map(\.token))
    }

    func testKeychainStoreRemovesTheItemOnAnEmptySave() throws {
        let secrets = InMemorySecretStore()
        let store = KeychainAccountCredentialStore(secrets: secrets)
        try store.save([alpha])
        try store.save([])
        XCTAssertTrue(secrets.isEmpty)
        XCTAssertEqual(try store.load().map(\.token), [])
    }

    func testProbeLoadsTheSavedSetAtInit() {
        let store = InMemoryAccountCredentialStore([alpha])
        let probe = AccountQuotaProbe(credentials: store, prober: { _ in [:] })
        XCTAssertTrue(probe.holds(token: "t1"))
        XCTAssertFalse(probe.holds(token: "t2"))
    }

    func testProbeSavesOnlyWhenTheSetChanges() throws {
        let store = InMemoryAccountCredentialStore()
        let probe = AccountQuotaProbe(credentials: store, prober: { _ in [:] })
        XCTAssertTrue(probe.setCredentials([alpha]))
        XCTAssertFalse(probe.setCredentials([alpha]))
        XCTAssertEqual(store.saves, 1)
        XCTAssertEqual(try store.load().map(\.token), [alpha].map(\.token))
    }
}
