import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKNotifications

/// Toasts: compact cards stacked per screen and position, at most
/// `toastStackLimit` visible plus a "+N more" pill. A toast auto-dismisses if
/// its profile says so, paused while the pointer is over it.
@MainActor
final class ToastPresenter: CardStackPresenter {

    init(
        rules: @escaping @MainActor () -> NoticeRoutingRules,
        showHistory: @escaping @MainActor () -> Void,
        store: SettingsStore = UserSettings.shared
    ) {
        super.init(rules: rules, cardStyle: .toast, showHistory: showHistory, store: store)
    }

    /// One window per stack, with the hover chrome and drag.
    override var groupsIntoStackWindow: Bool { true }

    override var visibleLimit: Int { rules().toastStackLimit }
}
