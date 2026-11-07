import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

// Helpers shared by the Notifications settings panel tests.

/// A settings store of its own: nothing a test writes reaches the process's
/// defaults.
@MainActor
func makeTestStore() -> SettingsStore {
    SettingsStore(
        with: InMemorySettingsStorageProvider(),
        secureSettingsProvider: InMemorySecureSettingsStorageProvider())
}

@MainActor
func storedRules(_ store: SettingsStore) -> NoticeRoutingRules {
    store.get(NoticeSettings.routingRules)
}

@MainActor
func descendants(of view: NSView) -> [NSView] {
    view.subviews + view.subviews.flatMap { descendants(of: $0) }
}

@MainActor
func first<T: NSView>(_ type: T.Type, in view: NSView) -> T? {
    descendants(of: view).compactMap { $0 as? T }.first
}

@MainActor
func all<T: NSView>(_ type: T.Type, in view: NSView) -> [T] {
    descendants(of: view).compactMap { $0 as? T }
}

/// The row of `view` whose label reads `title`.
@MainActor
func row(titled title: String, in view: NSView) -> NSStackView? {
    all(NSStackView.self, in: view).first { stack in
        stack.arrangedSubviews.contains { ($0 as? NSTextField)?.stringValue == title }
    }
}

/// Drives a control the way a click does.
@MainActor
func fire(_ control: NSControl) {
    control.sendAction(control.action, to: control.target)
}

@MainActor
func choose(_ title: String, in popup: NSPopUpButton) {
    popup.selectItem(withTitle: title)
    fire(popup)
}
