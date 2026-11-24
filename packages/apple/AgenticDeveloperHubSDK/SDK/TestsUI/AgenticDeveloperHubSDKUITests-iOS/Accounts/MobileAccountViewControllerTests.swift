import Foundation
import Testing
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
private final class StubAccount: Account {
    let id = "stub"
    let displayName = "Stub Hub"
    let summary = "Sign in to the stub."
    var state: AccountState = .restoring { didSet { onChange() } }
    var message: String?
    var signupURL: URL? = URL(string: "https://example.com/signup")
    var onChange: @MainActor () -> Void = {}
    private(set) var restoreCount = 0
    private(set) var signInCount = 0
    func restore() { restoreCount += 1 }
    func presentSignIn(from anchor: AccountPresentationAnchor) { signInCount += 1 }
    func signOut() async { state = .signedOut }
}

@MainActor
@Suite("MobileAccountViewController")
struct MobileAccountViewControllerTests {
    private let user = AccountUser(id: "u1", name: "Ada", email: "ada@example.com", avatarURL: nil)

    @Test func loading_restoresTheAccount_andShowsTheCheckingRow() {
        let account = StubAccount()
        let controller = MobileAccountViewController(account: account)
        controller.loadViewIfNeeded()
        #expect(account.restoreCount == 1)
        #expect(controller.rows == [.status("Checking sign-in…")])
        #expect(controller.title == "Stub Hub")
    }

    @Test func signedOut_showsLoginAndSignup_withTheSummaryAsFooter() {
        let account = StubAccount()
        let controller = MobileAccountViewController(account: account)
        controller.loadViewIfNeeded()
        account.state = .signedOut
        #expect(controller.rows == [.login, .signup])
        #expect(controller.tableView(controller.tableView, titleForFooterInSection: 0) == "Sign in to the stub.")
    }

    @Test func signedIn_showsTheUserAndLogout() {
        let account = StubAccount()
        let controller = MobileAccountViewController(account: account)
        controller.loadViewIfNeeded()
        account.state = .signedIn(user)
        #expect(controller.rows == [.user(user), .logout])
        #expect(controller.tableView(controller.tableView, titleForFooterInSection: 0) == nil)
    }

    @Test func busyWhileSignedIn_keepsTheUser_andAddsASpinner() {
        let account = StubAccount()
        let controller = MobileAccountViewController(account: account)
        controller.loadViewIfNeeded()
        account.state = .signedIn(user)
        account.state = .busy
        #expect(controller.rows == [.user(user), .status(nil), .logout])
        #expect(!controller.display.controlsEnabled)
    }

    @Test func aMessage_replacesTheFooter() {
        let account = StubAccount()
        account.message = "The hub turned the login down."
        let controller = MobileAccountViewController(account: account)
        controller.loadViewIfNeeded()
        account.state = .signedOut
        #expect(controller.tableView(controller.tableView, titleForFooterInSection: 0) == "The hub turned the login down.")
    }

    @Test func login_presentsTheAccountsSignIn_andSignupOpensItsURL() {
        let account = StubAccount()
        var opened: URL?
        let controller = MobileAccountViewController(account: account, openURL: { opened = $0 })
        controller.loadViewIfNeeded()
        controller.login()
        controller.signup()
        #expect(account.signInCount == 1)
        #expect(opened == account.signupURL)
    }
}
