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
}
