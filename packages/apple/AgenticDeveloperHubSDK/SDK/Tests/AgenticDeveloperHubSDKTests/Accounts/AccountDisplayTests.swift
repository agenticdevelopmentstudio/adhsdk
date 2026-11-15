import Foundation
import Testing
@testable import AgenticDeveloperHubSDK

@Suite("AccountDisplay")
struct AccountDisplayTests {
    private let user = AccountUser(id: "u1", name: "Ada Lovelace", email: "ada@example.com", avatarURL: nil)

    @Test func restoring_showsTheStatusLineAndSpinner_andNoButtons() {
        let display = AccountDisplay(state: .restoring, message: nil, hasSignupURL: true, lastUser: nil)
        #expect(display.showsStatusText)
        #expect(display.showsSpinner)
        #expect(!display.showsLogin && !display.showsSignup && !display.showsLogout)
        #expect(display.shownUser == nil)
    }

    @Test func signedOut_showsLoginAndSignup_onlyWithASignupURL() {
        let with = AccountDisplay(state: .signedOut, message: nil, hasSignupURL: true, lastUser: nil)
        #expect(with.showsLogin && with.showsSignup && !with.showsLogout)
        let without = AccountDisplay(state: .signedOut, message: nil, hasSignupURL: false, lastUser: nil)
        #expect(without.showsLogin && !without.showsSignup)
    }

    @Test func signedIn_showsTheUserAndLogout() {
        let display = AccountDisplay(state: .signedIn(user), message: nil, hasSignupURL: true, lastUser: nil)
        #expect(display.shownUser == user)
        #expect(display.showsLogout && !display.showsLogin && !display.showsSignup)
        #expect(!display.showsSpinner && display.controlsEnabled)
    }

    @Test func busyAfterSignedIn_keepsShowingTheUser_withControlsDisabled() {
        let display = AccountDisplay(state: .busy, message: nil, hasSignupURL: true, lastUser: user)
        #expect(display.shownUser == user)
        #expect(display.showsLogout && !display.showsLogin)
        #expect(display.showsSpinner && !display.showsStatusText)
        #expect(!display.controlsEnabled)
    }

    @Test func busyFromSignedOut_keepsTheSignedOutControls() {
        let display = AccountDisplay(state: .busy, message: nil, hasSignupURL: true, lastUser: nil)
        #expect(display.shownUser == nil)
        #expect(display.showsLogin && display.showsSignup && !display.showsLogout)
        #expect(!display.controlsEnabled)
    }

    @Test func signedOut_forgetsTheLastUser() {
        let display = AccountDisplay(state: .signedOut, message: "Signed out", hasSignupURL: false, lastUser: user)
        #expect(display.shownUser == nil)
        #expect(display.message == "Signed out")
    }

    // MARK: Vectors 008 to 014

    private func makeOtherUser() -> AccountUser {
        AccountUser(id: "u2", name: "Grace Hopper", email: "grace@example.com", avatarURL: nil)
    }

    @Test("account-display-008: a signed-in user wins over lastUser")
    func accountDisplay008_signedInBeatsLastUser() {
        let display = AccountDisplay(
            state: .signedIn(user), message: nil, hasSignupURL: true, lastUser: makeOtherUser())
        #expect(display.shownUser == user)
        #expect(display.shownUser != makeOtherUser())
    }

    @Test("account-display-009: restoring shows no user and no logout")
    func accountDisplay009_restoringIgnoresLastUser() {
        let display = AccountDisplay(state: .restoring, message: nil, hasSignupURL: true, lastUser: user)
        #expect(display.shownUser == nil)
        #expect(display.showsLogout == false)
    }

    @Test("account-display-010: restoring hides every button")
    func accountDisplay010_restoringHidesButtons() {
        let display = AccountDisplay(state: .restoring, message: nil, hasSignupURL: true, lastUser: nil)
        #expect(display.showsLogin == false)
        #expect(display.showsSignup == false)
        #expect(display.showsLogout == false)
        #expect(display.controlsEnabled)
    }

    @Test("account-display-011: the restoring text")
    func accountDisplay011_restoringText() {
        #expect(AccountDisplay.restoringText == "Checking sign-in\u{2026}")
    }

    @Test("account-display-012: the message passes through, an empty one is not coerced to nil")
    func accountDisplay012_messagePassthrough() {
        let none = AccountDisplay(state: .signedIn(user), message: nil, hasSignupURL: true, lastUser: nil)
        let empty = AccountDisplay(state: .signedIn(user), message: "", hasSignupURL: true, lastUser: nil)
        #expect(none.message == nil)
        #expect(empty.message == "")
    }

    @Test("account-display-013: the account initializer matches the state initializer")
    @MainActor
    func accountDisplay013_accountInitializer() {
        let account = DisplayStubAccount()
        account.message = "Try again"
        account.signupURL = URL(string: "https://example.com/signup")
        let expected = AccountDisplay(state: .signedOut, message: "Try again", hasSignupURL: true, lastUser: nil)
        #expect(AccountDisplay(account: account, lastUser: nil) == expected)
    }

    @Test("account-display-014: an account with no signup URL hides Signup")
    @MainActor
    func accountDisplay014_accountWithoutSignupURL() {
        let account = DisplayStubAccount()
        account.signupURL = nil
        #expect(AccountDisplay(account: account, lastUser: nil).showsSignup == false)
    }
}

@MainActor
private final class DisplayStubAccount: Account {
    let id = "display-stub"
    let displayName = "Display stub"
    let summary = ""
    var state: AccountState = .signedOut
    var message: String?
    var signupURL: URL?
    var onChange: @MainActor () -> Void = {}
    func restore() {}
    func presentSignIn(from anchor: AccountPresentationAnchor) {}
    func signOut() async {}
}
