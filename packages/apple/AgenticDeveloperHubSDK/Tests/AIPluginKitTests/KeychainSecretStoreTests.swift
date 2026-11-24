import Foundation
import Testing
import AgenticDeveloperHubSDKCore
@testable import AIPluginKit

/// Touches the real Keychain, under a per-test service and account, and
/// cleans up after itself. Never changes `KeychainHelper.service`.
@Suite("KeychainSecretStore")
struct KeychainSecretStoreTests {

    @Test("a store with a service keeps its secrets under that service alone")
    func serviceScopedStore() {
        let key = "kssttest-\(UUID().uuidString)"
        let store = KeychainSecretStore(service: "kssttest.service.\(UUID().uuidString)")
        let defaultStore = KeychainSecretStore()
        defer {
            store.delete(forKey: key)
            defaultStore.delete(forKey: key)
        }

        #expect(store.set("scoped", forKey: key))
        #expect(store.get(forKey: key) == "scoped")
        #expect(defaultStore.get(forKey: key) == nil, "the process-wide service holds no copy")

        #expect(store.delete(forKey: key))
        #expect(store.get(forKey: key) == nil)
    }

    @Test("a store with no service uses the process-wide KeychainHelper.service")
    func defaultStoreUsesGlobalService() {
        let key = "kssttest-\(UUID().uuidString)"
        let store = KeychainSecretStore()
        defer { store.delete(forKey: key) }

        #expect(store.service == nil)
        #expect(store.set("global", forKey: key))
        #expect(KeychainHelper.get(forKey: key) == "global")
    }
}
