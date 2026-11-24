import Foundation
import Testing
@testable import AgenticDeveloperHubSDK

@MainActor
private final class RegistryProbeAccount: Account {
    let id: String
    var displayName: String { id }
    var summary: String { "" }
    var state: AccountState = .signedOut
    var message: String?
    var signupURL: URL?
    var onChange: @MainActor () -> Void = {}
    private(set) var signOutCalls = 0
    private(set) var restoreCalls = 0
    init(id: String) { self.id = id }
    func restore() { restoreCalls += 1 }
    func presentSignIn(from anchor: AccountPresentationAnchor) {}
    func signOut() async { signOutCalls += 1 }
}

@Suite("AccountRegistry conformance")
@MainActor
struct AccountRegistryConformanceTests {
    @Test("V6: add of a different object with an existing id keeps the original")
    func addKeepsExistingObject() {
        let first = RegistryProbeAccount(id: "a")
        let second = RegistryProbeAccount(id: "a")
        let registry = AccountRegistry(accounts: [first])
        registry.add(second)
        #expect(registry.accounts.count == 1)
        #expect(registry.accounts[0] === first)
    }

    @Test("V7: id equality decides membership and order is preserved")
    func identityById() {
        let registry = AccountRegistry(accounts: [RegistryProbeAccount(id: "a")])
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.add(RegistryProbeAccount(id: "b"))
        registry.add(RegistryProbeAccount(id: "a"))
        #expect(registry.accounts.map(\.id) == ["a", "b"])
        #expect(changes == 1)
    }

    @Test("V8: the initializer stores duplicate ids as given and stays silent")
    func initStoresDuplicates() {
        let registry = AccountRegistry(accounts: [RegistryProbeAccount(id: "a"), RegistryProbeAccount(id: "a")])
        #expect(registry.accounts.count == 2)
    }

    @Test("V9: remove drops only the first entry with the id")
    func removeFirstOfDuplicates() {
        let first = RegistryProbeAccount(id: "a")
        let second = RegistryProbeAccount(id: "a")
        let registry = AccountRegistry(accounts: [first, second])
        registry.remove(id: "a")
        #expect(registry.accounts.count == 1)
        #expect(registry.accounts[0] === second)
    }

    @Test("V10: remove does not tear down the removed account")
    func removeNoTeardown() async {
        let probe = RegistryProbeAccount(id: "a")
        var accountChanges = 0
        probe.onChange = { accountChanges += 1 }
        let registry = AccountRegistry(accounts: [probe])
        registry.remove(id: "a")
        await Task.yield()
        #expect(probe.signOutCalls == 0)
        #expect(probe.restoreCalls == 0)
        probe.onChange()
        #expect(accountChanges == 1)
    }

    @Test("V11: onChange runs synchronously and sees the new array")
    func onChangeSynchronous() {
        let registry = AccountRegistry()
        var seen: [Int] = []
        registry.onChange = { seen.append(registry.accounts.count) }
        registry.add(RegistryProbeAccount(id: "a"))
        #expect(seen == [1])
    }

    @Test("V12: assigning onChange again replaces the earlier closure")
    func onChangeSlot() {
        let registry = AccountRegistry()
        var firstCalls = 0
        var secondCalls = 0
        registry.onChange = { firstCalls += 1 }
        registry.onChange = { secondCalls += 1 }
        registry.add(RegistryProbeAccount(id: "a"))
        #expect(firstCalls == 0)
        #expect(secondCalls == 1)
    }

    @Test("V13: an account's own onChange does not reach the registry")
    func onChangeScope() {
        let probe = RegistryProbeAccount(id: "a")
        let registry = AccountRegistry(accounts: [probe])
        var registryChanges = 0
        registry.onChange = { registryChanges += 1 }
        probe.state = .busy
        probe.onChange()
        #expect(registryChanges == 0)
    }
}
