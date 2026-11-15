import Foundation
import Testing
@testable import AgenticDeveloperHubSDK

@MainActor
private final class StubAccount: Account {
    let id: String
    var displayName: String { id }
    var summary: String { "" }
    var state: AccountState = .signedOut
    var message: String?
    var signupURL: URL?
    var onChange: @MainActor () -> Void = {}
    init(id: String) { self.id = id }
    func restore() {}
    func presentSignIn(from anchor: AccountPresentationAnchor) {}
    func signOut() async {}
}

@Suite("AccountUser")
struct AccountUserTests {
    @Test("initials take the first letters of the first two words")
    func twoWords() {
        let user = AccountUser(id: "1", name: "ada lovelace byron", email: "a@b.c", avatarURL: nil)
        #expect(user.initials == "AL")
    }

    @Test("initials fall back to the email's first letter for a blank name")
    func blankName() {
        let user = AccountUser(id: "1", name: "   ", email: "zed@b.c", avatarURL: nil)
        #expect(user.initials == "Z")
    }

    @Test("initials are ? when name and email are both empty")
    func nothing() {
        let user = AccountUser(id: "1", name: "", email: "", avatarURL: nil)
        #expect(user.initials == "?")
    }

    @Test("AC-004: a single word gives one letter and no email letter")
    func ac004_singleWord() {
        let user = AccountUser(id: "1", name: "Prince", email: "p@x.y", avatarURL: nil)
        #expect(user.initials == "P")
    }

    @Test("AC-005: an empty name falls back to the email's first letter")
    func ac005_emptyNameUsesEmail() {
        let user = AccountUser(id: "1", name: "", email: "zed@b.c", avatarURL: nil)
        #expect(user.initials == "Z")
    }

    @Test("AC-012: construction stores every field as given, with no validation")
    func ac012_noValidation() {
        let user = AccountUser(id: "", name: "", email: "", avatarURL: nil)
        #expect(user.id == "")
        #expect(user.name == "")
        #expect(user.email == "")
        #expect(user.avatarURL == nil)
    }

    @Test("AC-013: uppercasing one character can yield two")
    func ac013_sharpSUppercasesToTwoLetters() {
        let user = AccountUser(id: "1", name: "\u{00DF}a", email: "x@y.z", avatarURL: nil)
        #expect(user.initials == "SS")
    }
}

@Suite("AccountState conformance")
struct AccountStateConformanceTests {
    private func makeUser() -> AccountUser {
        AccountUser(id: "u1", name: "Ada Lovelace", email: "ada@example.com", avatarURL: nil)
    }

    @Test("AC-007: signedIn states with equal users are equal")
    func ac007_signedInEquality() {
        #expect(AccountState.signedIn(makeUser()) == AccountState.signedIn(makeUser()))
    }

    @Test("AC-008: busy is not equal to signedOut")
    func ac008_busyIsNotSignedOut() {
        #expect(AccountState.busy != AccountState.signedOut)
    }
}

@Suite("Account protocol conformance")
@MainActor
struct AccountProtocolConformanceTests {
    @Test("AC-009: assigning onChange twice leaves one observer", .disabled(
        "Protocol contract with no implementation in this source; only a stub conformer exists"))
    func ac009_onChangeSingleSlot() {}

    @Test("AC-010: restore() is idempotent", .disabled(
        "Protocol contract with no implementation in this source; only a stub conformer exists"))
    func ac010_restoreIdempotent() {}

    @Test("AC-011: a conformer with no signup URL hides Signup")
    func ac011_nilSignupURLHidesSignup() {
        let account = StubAccount(id: "a")
        account.signupURL = nil
        let display = AccountDisplay(account: account, lastUser: nil)
        #expect(display.showsSignup == false)
        #expect(display.showsLogin)
    }
}

@Suite("AccountPresentationAnchor")
struct AccountPresentationAnchorTests {
    @Test("holds its object weakly")
    func weak() {
        var object: NSObject? = NSObject()
        let anchor = AccountPresentationAnchor(object!)
        #expect(anchor.object != nil)
        object = nil
        #expect(anchor.object == nil)
    }
}

@Suite("AccountRegistry")
@MainActor
struct AccountRegistryTests {
    @Test("V1: keeps accounts in the order given")
    func order() {
        let registry = AccountRegistry(accounts: [StubAccount(id: "a"), StubAccount(id: "b")])
        #expect(registry.accounts.map(\.id) == ["a", "b"])
    }

    @Test("V2: add appends and reports a change")
    func add() {
        let registry = AccountRegistry()
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.add(StubAccount(id: "a"))
        #expect(registry.accounts.map(\.id) == ["a"])
        #expect(changes == 1)
    }

    @Test("V3: add ignores an id already present and reports nothing")
    func addDuplicate() {
        let registry = AccountRegistry(accounts: [StubAccount(id: "a")])
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.add(StubAccount(id: "a"))
        #expect(registry.accounts.count == 1)
        #expect(changes == 0)
    }

    @Test("V4: remove drops the account and reports a change")
    func remove() {
        let registry = AccountRegistry(accounts: [StubAccount(id: "a"), StubAccount(id: "b")])
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.remove(id: "a")
        #expect(registry.accounts.map(\.id) == ["b"])
        #expect(changes == 1)
    }

    @Test("V5: remove of an unknown id is a silent no-op")
    func removeUnknown() {
        let registry = AccountRegistry(accounts: [StubAccount(id: "a")])
        var changes = 0
        registry.onChange = { changes += 1 }
        registry.remove(id: "zzz")
        #expect(registry.accounts.count == 1)
        #expect(changes == 0)
    }
}
