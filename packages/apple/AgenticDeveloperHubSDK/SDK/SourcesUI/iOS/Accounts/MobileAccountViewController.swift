import UIKit
import AgenticDeveloperHubSDK

/// The iOS twin of the macOS account detail panel: one account's sign-in, as
/// a grouped table. Who is signed in, or the Login and Signup rows; Logout
/// while signed in; a spinner while the login is checked or the account is
/// busy. What is visible comes from `AccountDisplay`, the same rules the
/// macOS panel draws, and nothing here keeps a copy of the account's state.
///
/// The account's `summary` is the section footer while signed out, and its
/// `message` (an error) replaces it whenever there is one.
@MainActor
public final class MobileAccountViewController: UITableViewController {

    /// One row of the account section, in display order.
    enum Row: Equatable {
        case user(AccountUser)
        case status(String?)
        case login
        case signup
        case logout
    }

    public let account: any Account
    private let openURL: @MainActor (URL) -> Void
    private(set) var display: AccountDisplay
    private(set) var rows: [Row] = []

    /// `openURL` opens the signup page; the default hands it to the system.
    public init(
        account: any Account,
        openURL: @escaping @MainActor (URL) -> Void = { UIApplication.shared.open($0) }
    ) {
        self.account = account
        self.openURL = openURL
        self.display = AccountDisplay(account: account, lastUser: nil)
        super.init(style: .insetGrouped)
        title = account.displayName
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "accounts.detail"
        // This screen is the account's one observer; assigning replaces any earlier one.
        account.onChange = { [weak self] in self?.render() }
        render()
        account.restore()
    }

    func render() {
        display = AccountDisplay(account: account, lastUser: display.shownUser)
        rows = Self.rows(for: display)
        guard isViewLoaded else { return }
        tableView.reloadData()
    }

    /// The rows `display` calls for.
    static func rows(for display: AccountDisplay) -> [Row] {
        var rows: [Row] = []
        if let user = display.shownUser { rows.append(.user(user)) }
        if display.showsSpinner {
            rows.append(.status(display.showsStatusText ? AccountDisplay.restoringText : nil))
        }
        if display.showsLogin { rows.append(.login) }
        if display.showsSignup { rows.append(.signup) }
        if display.showsLogout { rows.append(.logout) }
        return rows
    }

    // MARK: Table

    override public func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let message = display.message { return message }
        guard display.shownUser == nil, !account.summary.isEmpty else { return nil }
        return account.summary
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        var content = cell.defaultContentConfiguration()
        cell.selectionStyle = .none
        switch rows[indexPath.row] {
        case .user(let user):
            content.text = user.name
            content.secondaryText = user.email
            content.secondaryTextProperties.color = .secondaryLabel
            content.image = UIImage(systemName: "person.crop.circle.fill")
            cell.accessibilityIdentifier = "accounts.detail.user"
        case .status(let text):
            content.text = text ?? "Working…"
            content.textProperties.color = .secondaryLabel
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            cell.accessoryView = spinner
            cell.accessibilityIdentifier = "accounts.detail.spinner"
        case .login:
            Self.styleAction(&content, title: "Login", enabled: display.controlsEnabled, color: .tintColor)
            cell.selectionStyle = .default
            cell.accessibilityIdentifier = "accounts.detail.login"
        case .signup:
            Self.styleAction(&content, title: "Signup", enabled: display.controlsEnabled, color: .tintColor)
            cell.selectionStyle = .default
            cell.accessibilityIdentifier = "accounts.detail.signup"
        case .logout:
            Self.styleAction(&content, title: "Logout", enabled: display.controlsEnabled, color: .systemRed)
            cell.selectionStyle = .default
            cell.accessibilityIdentifier = "accounts.detail.logout"
        }
        cell.contentConfiguration = content
        return cell
    }

    private static func styleAction(
        _ content: inout UIListContentConfiguration, title: String, enabled: Bool, color: UIColor
    ) {
        content.text = title
        content.textProperties.color = enabled ? color : .tertiaryLabel
    }

    override public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard display.controlsEnabled else { return false }
        switch rows[indexPath.row] {
        case .login, .signup, .logout: return true
        case .user, .status: return false
        }
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard display.controlsEnabled else { return }
        switch rows[indexPath.row] {
        case .login: login()
        case .signup: signup()
        case .logout: Task { await account.signOut() }
        case .user, .status: break
        }
    }

    // MARK: Actions

    func login() {
        account.presentSignIn(from: AccountPresentationAnchor(self))
    }

    func signup() {
        guard let url = account.signupURL else { return }
        openURL(url)
    }
}
