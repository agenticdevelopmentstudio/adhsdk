import Foundation

/// What an accounts screen shows for one account's state: the platform-free
/// half of every account detail view. macOS and iOS draw it with their own
/// controls; the rules for what is visible live here once.
public struct AccountDisplay: Sendable, Equatable {
    /// The status line shown while a stored login is being checked.
    public static let restoringText = "Checking sign-in…"

    /// Who to show: the signed-in user, or — while `busy` — the user shown
    /// before it began, so signing out keeps showing who is signing out
    /// rather than flashing the signed-out controls. Pass it back as
    /// `lastUser` on the next render.
    public let shownUser: AccountUser?
    /// Whether the `restoringText` status line shows.
    public let showsStatusText: Bool
    /// Whether a progress spinner shows (restoring or busy).
    public let showsSpinner: Bool
    public let showsLogin: Bool
    public let showsSignup: Bool
    public let showsLogout: Bool
    /// False while busy: every button is disabled.
    public let controlsEnabled: Bool
    /// The account's error or status line; `nil` hides it.
    public let message: String?

    /// `lastUser` is the previous render's `shownUser`.
    public init(state: AccountState, message: String?, hasSignupURL: Bool, lastUser: AccountUser?) {
        let busy = state == .busy
        let restoring = state == .restoring
        var signedInUser: AccountUser?
        if case .signedIn(let user) = state { signedInUser = user }
        let shownUser = signedInUser ?? (busy ? lastUser : nil)
        let signedOutLike = state == .signedOut || (busy && shownUser == nil)

        self.shownUser = shownUser
        self.showsStatusText = restoring
        self.showsSpinner = restoring || busy
        self.showsLogin = signedOutLike
        self.showsSignup = signedOutLike && hasSignupURL
        self.showsLogout = shownUser != nil
        self.controlsEnabled = !busy
        self.message = message
    }

    /// The display for `account`'s current state.
    @MainActor
    public init(account: any Account, lastUser: AccountUser?) {
        self.init(
            state: account.state,
            message: account.message,
            hasSignupURL: account.signupURL != nil,
            lastUser: lastUser
        )
    }
}
