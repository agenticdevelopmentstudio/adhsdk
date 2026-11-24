import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Privacy word store conformance") struct PrivacyWordStoreConformanceTests {
    @Test("V1: load is empty when nothing is saved",
          .disabled("Needs a real keychain with the keychain-access-groups entitlement"))
    func testV1_loadEmptyWhenAbsent() {}

    @Test("V2: save then load round-trips one pair",
          .disabled("Needs a real keychain with the keychain-access-groups entitlement"))
    func testV2_saveThenLoad() {}

    @Test("V3: save replaces the whole list",
          .disabled("Needs a real keychain with the keychain-access-groups entitlement"))
    func testV3_saveReplaces() {}

    @Test("V4: saving an empty list removes the item",
          .disabled("Needs a real keychain with the keychain-access-groups entitlement"))
    func testV4_saveEmptyRemoves() {}

    @Test("V5: saving an empty list on an empty keychain succeeds",
          .disabled("Needs a real keychain with the keychain-access-groups entitlement"))
    func testV5_saveEmptyOnEmpty() {}

    @Test("V6: an undecodable value throws unreadable",
          .disabled("Needs a real keychain with the keychain-access-groups entitlement"))
    func testV6_unreadable() {}

    @Test("V7: an item guarded by userPresence throws needsAuthentication",
          .disabled("Needs a real keychain item with a userPresence access control"))
    func testV7_needsAuthentication() {}

    @Test("V8: load with an authenticated context returns the pairs",
          .disabled("Needs real owner authentication (Touch ID or password prompt)"))
    func testV8_loadWithContext() {}

    @Test("V9: save after an authenticated load can be read silently",
          .disabled("Needs real owner authentication (Touch ID or password prompt)"))
    func testV9_saveRemovesGuard() {}

    @Test("V10: a keychain failure carries its status",
          .disabled("Depends on the signing of the test host, which a unit test cannot control"))
    func testV10_keychainError() {}

    @Test("V11: authenticate throws when the Mac cannot authenticate its owner",
          .disabled("Needs a Mac with no usable owner authentication"))
    func testV11_authenticateCannotEvaluate() {}

    @Test("V12: every error has its description")
    func testV12_errorDescriptions() {
        #expect(PrivacyWordStore.StoreError.unreadable.errorDescription
                == "The privacy words in the keychain could not be read.")
        #expect(PrivacyWordStore.StoreError.needsAuthentication.errorDescription
                == "The privacy words need you to authenticate once before they can be read.")
        #expect(PrivacyWordStore.StoreError.authenticationFailed("nope").errorDescription == "nope")
        let status = PrivacyWordStore.StoreError.keychain(-25300).errorDescription
        #expect(status?.isEmpty == false)
    }

    @Test("V13: the default identity is the privacy-words service and account")
    func testV13_defaultIdentity() {
        let store = PrivacyWordStore(accessGroup: nil)
        #expect(store.service == "com.agenticdevelopmentstudio.privacy-words")
        #expect(store.account == "privacy-words")
        #expect(store.accessGroup == nil)
    }

    @Test("V14: the access group is the caller's",
          .disabled("Needs a real keychain with two signed access groups"))
    func testV14_accessGroupInjected() {}

    @Test("V15: authenticate rejected by the user throws authenticationFailed",
          .disabled("Needs a user to cancel the system authentication sheet"))
    func testV15_authenticateRejected() {}
}
