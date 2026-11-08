import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDesktop

/// A `DesktopAppContext` backed by in-memory settings, recording what the App asks of its window.
@MainActor
final class FakeDesktopAppContext: DesktopAppContext {
    let settings: DesktopAppSettings
    private(set) var titles: [String] = []

    init(app: DesktopApp) {
        let store = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider()
        )
        settings = DesktopAppSettings(
            appIdentifier: app.descriptor.identifier,
            schema: app.descriptor.settingsSchema,
            store: store
        )
    }

    func setWindowTitle(_ title: String) { titles.append(title) }
    func closeWindow() {}
    func showSettings() {}
    func showAbout() {}
    func presentAlert(_ alert: NSAlert) {}
}

extension NSMenu {
    /// The item with `title`, or nil.
    func item(named title: String) -> NSMenuItem? {
        items.first { $0.title == title }
    }
}

extension NSMenuItem {
    /// Runs the item's action the way a click would.
    @MainActor
    func fire() {
        guard let action, let target else { return }
        _ = (target as AnyObject).perform(action, with: self)
    }
}
