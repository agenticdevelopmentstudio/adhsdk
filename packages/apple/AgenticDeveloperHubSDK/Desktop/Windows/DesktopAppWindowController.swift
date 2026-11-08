import AppKit
import AgenticDeveloperHubSDKCoreUI

/// What a window controller asks of the Desktop that hosts it.
@MainActor
protocol DesktopWindowHost: AnyObject {
    func closeWindow(id: String)
    func showSettings(forApp identifier: String)
    func showAbout(forApp identifier: String)
    func windowFrameCommitted(id: String, frame: CGRect)
    func presentAlert(_ alert: NSAlert)
}

/// One open in-desktop window: an App, or an About or Settings window for an App.
/// It is the `DesktopAppContext` its content talks to.
@MainActor
final class DesktopAppWindowController: DesktopAppContext {
    enum Kind {
        case app, about, settings

        func windowID(forApp identifier: String) -> String {
            switch self {
            case .app: return identifier
            case .about: return "about:\(identifier)"
            case .settings: return "settings:\(identifier)"
            }
        }
    }

    let kind: Kind
    let app: DesktopApp
    let windowID: String
    let chrome = DesktopWindowChromeView(frame: .zero)
    let settings: DesktopAppSettings
    private(set) var contentViewController: NSViewController!
    /// Menus searched for key equivalents: the App's menus, or just Close for About and Settings.
    private(set) var menus: [NSMenu] = []
    private let menuBar = DesktopMenuBarView()
    private var menuTargets: [ClosureMenuItemTarget] = []
    private weak var host: DesktopWindowHost?

    init(
        kind: Kind,
        app: DesktopApp,
        settings: DesktopAppSettings,
        host: DesktopWindowHost,
        makeContent: (DesktopAppContext) -> NSViewController
    ) {
        self.kind = kind
        self.app = app
        self.settings = settings
        self.host = host
        self.windowID = kind.windowID(forApp: app.descriptor.identifier)
        let name = app.descriptor.displayName
        switch kind {
        case .app: chrome.title = name
        case .about: chrome.title = "About \(name)"
        case .settings: chrome.title = "\(name) Settings"
        }
        chrome.minimumSize = app.descriptor.minimumWindowSize
        chrome.onClose = { [weak self] in self?.closeWindow() }
        contentViewController = makeContent(self)
        chrome.contentContainer.addSubview(contentViewController.view)
        if kind == .app {
            menus = [standardMenu()] + app.makeMenus(context: self)
            menuBar.configure(menus: menus)
            chrome.accessoryView = menuBar
            chrome.accessoryHeight = DesktopMenuBarView.height
        } else {
            let closeOnly = NSMenu(title: name)
            closeOnly.addItem(closeItem(title: "Close"))
            menus = [closeOnly]
        }
    }

    // MARK: Menus

    private func menuItem(title: String, key: String, action: @escaping () -> Void) -> NSMenuItem {
        let target = ClosureMenuItemTarget(action: action)
        menuTargets.append(target)
        let item = NSMenuItem(
            title: title,
            action: #selector(ClosureMenuItemTarget.performMenuAction(_:)),
            keyEquivalent: key
        )
        item.keyEquivalentModifierMask = key.isEmpty ? [] : .command
        item.target = target
        return item
    }

    private func closeItem(title: String) -> NSMenuItem {
        menuItem(title: title, key: "w") { [weak self] in self?.closeWindow() }
    }

    private func standardMenu() -> NSMenu {
        let name = app.descriptor.displayName
        let menu = NSMenu(title: name)
        menu.addItem(menuItem(title: "About \(name)", key: "") { [weak self] in self?.showAbout() })
        menu.addItem(menuItem(title: "Settings…", key: ",") { [weak self] in self?.showSettings() })
        menu.addItem(.separator())
        menu.addItem(closeItem(title: "Close \(name)"))
        return menu
    }

    /// Offers a key event to this window's menus.
    func performKeyEquivalent(with event: NSEvent) -> Bool {
        menus.contains { $0.performKeyEquivalent(with: event) }
    }

    // MARK: DesktopAppContext

    func setWindowTitle(_ title: String) {
        chrome.title = title
    }

    func closeWindow() {
        host?.closeWindow(id: windowID)
    }

    func showSettings() {
        host?.showSettings(forApp: app.descriptor.identifier)
    }

    func showAbout() {
        host?.showAbout(forApp: app.descriptor.identifier)
    }

    func presentAlert(_ alert: NSAlert) {
        host?.presentAlert(alert)
    }
}
