import Testing
import Foundation
import Security
@testable import AgenticDeveloperHubSDK

/// These tests touch the real macOS Keychain. They use a unique account key
/// per test (UUID-suffixed) to avoid cross-test collisions under parallel
/// execution, and clean up after themselves via `delete(forKey:)`.
///
/// Tests do NOT mutate `KeychainHelper.service` (it's a global static), so
/// the test keychain service is whatever the test host's bundle identifier
/// resolves to at runtime. Isolation is per-account-key, not per-service.
/// Serialized: the retired-service tests append to the global
/// `KeychainHelper.legacyServices`, which the other tests read.
@Suite("KeychainHelper", .serialized)
struct KeychainHelperTests {

    private func uniqueKey(_ prefix: String = "kctest") -> String {
        "\(prefix)-\(UUID().uuidString)"
    }

    @Test("set then get round-trips the value")
    func setGetRoundTrip() {
        let key = uniqueKey()
        defer { KeychainHelper.delete(forKey: key) }

        #expect(KeychainHelper.set("hello-world", forKey: key))
        #expect(KeychainHelper.get(forKey: key) == "hello-world")
    }

    @Test("get returns nil for missing key")
    func getMissing() {
        let key = uniqueKey("missing")
        #expect(KeychainHelper.get(forKey: key) == nil)
    }

    @Test("exists returns true after set, false after delete")
    func existsLifecycle() {
        let key = uniqueKey()
        defer { KeychainHelper.delete(forKey: key) }

        #expect(!KeychainHelper.exists(forKey: key))

        #expect(KeychainHelper.set("x", forKey: key))
        #expect(KeychainHelper.exists(forKey: key))

        #expect(KeychainHelper.delete(forKey: key))
        #expect(!KeychainHelper.exists(forKey: key))
    }

    @Test("set overwrites existing value for same key")
    func setOverwrites() {
        let key = uniqueKey()
        defer { KeychainHelper.delete(forKey: key) }

        #expect(KeychainHelper.set("first", forKey: key))
        #expect(KeychainHelper.set("second", forKey: key))
        #expect(KeychainHelper.get(forKey: key) == "second")
    }

    @Test("delete returns true for non-existent key")
    func deleteMissingReturnsTrue() {
        // KeychainHelper.delete is documented to treat "not found" as success
        // so repeated cleanup calls don't raise spurious failures.
        let key = uniqueKey("ghost")
        #expect(KeychainHelper.delete(forKey: key))
    }

    @Test("set stores empty string and get returns it")
    func emptyStringRoundTrip() {
        let key = uniqueKey()
        defer { KeychainHelper.delete(forKey: key) }

        #expect(KeychainHelper.set("", forKey: key))
        #expect(KeychainHelper.get(forKey: key) == "")
        #expect(KeychainHelper.exists(forKey: key))
    }

    @Test("set stores unicode and get returns identical bytes")
    func unicodeRoundTrip() {
        let key = uniqueKey()
        defer { KeychainHelper.delete(forKey: key) }

        let value = "日本語 🔑 émoji\n\t"
        #expect(KeychainHelper.set(value, forKey: key))
        #expect(KeychainHelper.get(forKey: key) == value)
    }

    // MARK: - Access group (shared-keychain) query building

    // These verify the query the helper builds, NOT live Keychain behavior:
    // a real access-group item requires the `keychain-access-groups` entitlement
    // the unentitled test host lacks. The `accessGroup` argument is passed
    // explicitly so these never mutate the `KeychainHelper.accessGroup` global —
    // keeping the parallel real-Keychain tests above safe.

    @Test("makeQuery injects access group and data-protection flag when set")
    func queryWithAccessGroup() {
        let group = "ABCDE12345.com.agenticdevelopmentstudio.stenographer.shared"
        let query = KeychainHelper.makeQuery(account: "acct", accessGroup: group)

        #expect(query[kSecAttrAccessGroup as String] as? String == group)
        // Access groups only work against the data-protection keychain on macOS.
        #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
        // Base attributes still present.
        #expect(query[kSecAttrAccount as String] as? String == "acct")
    }

    @Test("makeQuery omits access group and data-protection flag when nil")
    func queryWithoutAccessGroup() {
        let query = KeychainHelper.makeQuery(account: "acct", accessGroup: nil)

        #expect(query[kSecAttrAccessGroup as String] == nil)
        #expect(query[kSecUseDataProtectionKeychain as String] == nil)
        #expect(query[kSecAttrAccount as String] as? String == "acct")
    }

    @Test("isolated keys don't interfere")
    func keyIsolation() {
        let keyA = uniqueKey("a")
        let keyB = uniqueKey("b")
        defer {
            KeychainHelper.delete(forKey: keyA)
            KeychainHelper.delete(forKey: keyB)
        }

        #expect(KeychainHelper.set("alpha", forKey: keyA))
        #expect(KeychainHelper.set("beta", forKey: keyB))

        #expect(KeychainHelper.get(forKey: keyA) == "alpha")
        #expect(KeychainHelper.get(forKey: keyB) == "beta")

        #expect(KeychainHelper.delete(forKey: keyA))
        #expect(KeychainHelper.get(forKey: keyA) == nil)
        #expect(KeychainHelper.get(forKey: keyB) == "beta")
    }

    // MARK: - Retired services

    /// Stores `value` straight under `service`, as an old build would have.
    private func storeRaw(_ value: String, forKey key: String, service: String) {
        var query = KeychainHelper.makeQuery(account: key, accessGroup: nil, service: service)
        query[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func rawExists(_ key: String, service: String) -> Bool {
        var query = KeychainHelper.makeQuery(account: key, accessGroup: nil, service: service)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    /// Appends a unique retired service and removes it afterwards; other
    /// tests' keys never match it, so they are unaffected.
    private func withRetiredService(_ body: (String) -> Void) {
        let retired = "kctest.retired.\(UUID().uuidString)"
        KeychainHelper.legacyServices.append(retired)
        defer { KeychainHelper.legacyServices.removeAll { $0 == retired } }
        body(retired)
    }

    @Test("get recovers a secret stored under a retired service and leaves the old copy")
    func getRecoversRetired() {
        let key = uniqueKey("retired")
        withRetiredService { retired in
            storeRaw("old-key", forKey: key, service: retired)
            defer { KeychainHelper.delete(forKey: key) }
            #expect(KeychainHelper.get(forKey: key) == "old-key")
            #expect(rawExists(key, service: retired))
        }
    }

    @Test("delete also removes the retired copy, so a cleared secret stays cleared")
    func deleteRemovesRetired() {
        let key = uniqueKey("cleared")
        withRetiredService { retired in
            storeRaw("old-key", forKey: key, service: retired)
            #expect(KeychainHelper.get(forKey: key) == "old-key")

            #expect(KeychainHelper.delete(forKey: key))
            #expect(!rawExists(key, service: retired))
            #expect(KeychainHelper.get(forKey: key) == nil)
            #expect(!KeychainHelper.exists(forKey: key))
        }
    }

    @Test("an explicit service scopes set, get, exists and delete without touching the global one")
    func explicitServiceIsolatesItems() {
        let key = uniqueKey("svc")
        let service = "kctest.service.\(UUID().uuidString)"
        let global = KeychainHelper.service
        defer {
            KeychainHelper.delete(forKey: key, service: service)
            KeychainHelper.delete(forKey: key)
        }

        #expect(KeychainHelper.set("scoped", forKey: key, service: service))
        #expect(KeychainHelper.get(forKey: key, service: service) == "scoped")
        #expect(KeychainHelper.exists(forKey: key, service: service))
        #expect(KeychainHelper.get(forKey: key) == nil, "the global service holds no copy")
        #expect(!KeychainHelper.exists(forKey: key))
        #expect(KeychainHelper.service == global)

        #expect(KeychainHelper.delete(forKey: key, service: service))
        #expect(KeychainHelper.get(forKey: key, service: service) == nil)
    }

    // MARK: - Conformance vectors

    @Test("fc-004: service defaults to the fallback identifier when no bundle identifier exists",
          .disabled("the test host always has a bundle identifier, so the fallback branch cannot run"))
    func fc004_serviceDefaultFallback() {}

    @Test("fc-014: get migrates an item from the no-group scope into the access group",
          .disabled("a real access-group item needs the keychain-access-groups entitlement the test host lacks"))
    func fc014_accessGroupMigration() {}

    @Test("fc-016: exists finds a secret under a retired service without migrating it")
    func fc016_existsChecksLegacyWithoutMigrating() {
        let key = uniqueKey("legacyexists")
        withRetiredService { retired in
            storeRaw("old-key", forKey: key, service: retired)
            defer { KeychainHelper.delete(forKey: key) }

            #expect(KeychainHelper.exists(forKey: key))
            #expect(!rawExists(key, service: KeychainHelper.service), "exists must not re-store the item")
            #expect(rawExists(key, service: retired))
        }
    }

    @Test("fc-017: copyValue logs nothing for an item-not-found status",
          .disabled("the unified log is not observable from a unit test"))
    func fc017_notFoundLogsNothing() {}

    @Test("fc-018: no log call site interpolates the secret",
          .disabled("source-review vector: a log call site cannot be inspected at runtime"))
    func fc018_secretNotLogged() {}

    @Test("fc-019: accessGroup and legacyServices are empty before any caller assigns them")
    func fc019_defaults() {
        #expect(KeychainHelper.accessGroup == nil)
        #expect(KeychainHelper.legacyServices.isEmpty)
    }

    @Test("fc-021: secrets go through generic-password add, with no network and no expiry",
          .disabled("source-review vector: the absence of a code path cannot be asserted at runtime"))
    func fc021_storageMechanism() {}

    @Test("fc-040: data protection alone sets the flag and adds no access group")
    func fc040_queryDataProtectionOnly() {
        let query = KeychainHelper.makeQuery(account: "acct", accessGroup: nil, dataProtection: true)

        #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
        #expect(query[kSecAttrAccessGroup as String] == nil)
        #expect(query[kSecAttrAccount as String] as? String == "acct")
    }

    @Test("fc-041: read returns nil for a never-set key without throwing")
    func fc041_readMissingDoesNotThrow() throws {
        let key = uniqueKey("readmissing")
        #expect(try KeychainHelper.read(forKey: key) == nil)
    }

    @Test("fc-042: entitledAccessGroup is nil off macOS and the data-protection default is false",
          .disabled("the nil-off-macOS half cannot run on macOS, where the entitlement lookup is live"))
    func fc042_entitledGroupOffMacOS() {}
}
