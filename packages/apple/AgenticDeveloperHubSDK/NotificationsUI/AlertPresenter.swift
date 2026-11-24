import AppKit
import AgenticDeveloperHubSDKNotifications

/// Alerts: a larger card with full details and every action, centered by
/// default, that stays until the user deals with it. Its panel is
/// non-activating like a toast's, so Return typed into another app can never
/// press one of its buttons; keyboard control comes through hotkeys.
@MainActor
final class AlertPresenter: CardStackPresenter {

    init(rules: @escaping @MainActor () -> NoticeRoutingRules) {
        // Every alert is shown, so the pill (and its history link) never appears.
        super.init(rules: rules, cardStyle: .alert, showHistory: {})
    }

    /// An alert draws only the set's first item.
    override func drawn(_ profiles: [NoticeProfile]) -> [NoticeProfile] {
        Array(profiles.prefix(1))
    }

    /// An alert never times out, whatever the profile says.
    override func autoDismiss(for profile: NoticeProfile) -> TimeInterval? { nil }
}
