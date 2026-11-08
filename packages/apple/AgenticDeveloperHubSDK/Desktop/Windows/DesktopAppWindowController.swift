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

/// What an App holds on to: forwards to its window controller without owning it, so an App
/// (or its content) that keeps the context never keeps a closed window alive.
@MainActor
final class DesktopWindowContext: DesktopAppContext {
    let settings: DesktopAppSettings
    fileprivate(set) weak var controller: DesktopAppWindowController?

    init(settings: DesktopAppSettings) {
        self.settings = settings
    }

    func setWindowTitle(_ title: String) { controller?.setWindowTitle(title) }
    func closeWindow() { controller?.closeWindow() }
    func showSettings() { controller?.showSettings() }
    func showAbout() { controller?.showAbout() }
    func presentAlert(_ alert: NSAlert) { controller?.presentAlert(alert) }
}

/// One open in-desktop window: an App, or an About or Settings window for an App.
/// Its content talks to it through a `DesktopWindowContext`.
@MainActor
final class DesktopAppWindowController {
    enum Kind {
        case app, about, settings

        /// The content area an About or Settings window opens at; Apps give their own.
        var panelContentSize: CGSize {
            self == .about ? CGSize(width: 360, height: 430) : CGSize(width: 440, height: 300)
        }

        /// The smallest content area of an About or Settings window.
        var panelMinimumContentSize: CGSize {
            self == .about ? CGSize(width: 300, height: 340) : CGSize(width: 320, height: 200)
        }

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
    let context: DesktopWindowContext
    private(set) var contentViewController: NSViewController?
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
        self.context = DesktopWindowContext(settings: settings)
        self.host = host
        self.windowID = kind.windowID(forApp: app.descriptor.identifier)
        let name = app.descriptor.displayName
        switch kind {
        case .app: chrome.title = name
        case .about: chrome.title = "About \(name)"
        case .settings: chrome.title = "\(name) Settings"
        }
        context.controller = self
        chrome.minimumContentSize = kind == .app ? app.descriptor.minimumWindowSize : kind.panelMinimumContentSize
        chrome.onClose = { [weak self] in self?.closeWindow() }
        let content = makeContent(context)
        contentViewController = content
        chrome.contentContainer.addSubview(content.view)
        if kind == .app {
            menus = [standardMenu()] + app.makeMenus(context: context)
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

    /// The default content area of this window: the App's, or the panel's.
    var defaultContentSize: CGSize {
        kind == .app ? app.descriptor.defaultWindowSize : kind.panelContentSize
    }

    /// Offers a key event to this window's menus. The App's own menus come before the
    /// standard App menu, so an App can claim a key the standard menu would take.
    func performKeyEquivalent(with event: NSEvent) -> Bool {
        let ordered = kind == .app ? Array(menus.dropFirst()) + menus.prefix(1) : menus
        return ordered.contains { $0.performKeyEquivalent(with: event) }
    }

    /// Releases everything the window holds, so nothing it created outlives it.
    func teardown() {
        contentViewController?.view.removeFromSuperview()
        contentViewController = nil
        menus = []
        menuBar.configure(menus: [])
        chrome.accessoryView = nil
        chrome.onClose = nil
        chrome.onActivate = nil
        chrome.onFrameChange = nil
        chrome.onFrameCommit = nil
        // A menu item's action may be what closed this window; free its target a turn later.
        let released = menuTargets
        menuTargets = []
        DispatchQueue.main.async { withExtendedLifetime(released) {} }
    }

    // MARK: Context calls (reached through `DesktopWindowContext`)

    fileprivate func setWindowTitle(_ title: String) {
        chrome.title = title
    }

    fileprivate func closeWindow() {
        host?.closeWindow(id: windowID)
    }

    fileprivate func showSettings() {
        host?.showSettings(forApp: app.descriptor.identifier)
    }

    fileprivate func showAbout() {
        host?.showAbout(forApp: app.descriptor.identifier)
    }

    fileprivate func presentAlert(_ alert: NSAlert) {
        host?.presentAlert(alert)
    }
}
