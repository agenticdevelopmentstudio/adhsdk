import AppKit
@testable import AgenticDeveloperHubSDKDesktop

/// A minimal `DesktopApp` for tests that records what the Desktop asks of it.
@MainActor
final class StubApp: DesktopApp {
    let descriptor: DesktopAppDescriptor

    /// Menus `makeMenus` returns.
    var menus: [NSMenu] = []
    /// When set, `makeSettingsViewController` returns it.
    var settingsViewController: NSViewController?
    private(set) var contentViewControllers: [NSViewController] = []
    private(set) var willCloseCount = 0
    private(set) var contexts: [DesktopAppContext] = []

    init(
        identifier: String,
        schema: DesktopAppSettingsSchema = .empty,
        displayName: String = "Stub",
        icon: DesktopAppIcon = .symbol(name: "star", tint: "#FFFFFF")
    ) {
        descriptor = DesktopAppDescriptor(
            identifier: identifier,
            displayName: displayName,
            version: "1.0",
            summary: "Stub app",
            icon: icon,
            attribution: DesktopAppAttribution(author: "Test", copyright: "Test"),
            defaultWindowSize: CGSize(width: 400, height: 300),
            minimumWindowSize: CGSize(width: 200, height: 150),
            settingsSchema: schema
        )
    }

    func makeContentViewController(context: DesktopAppContext) -> NSViewController {
        let controller = NSViewController()
        controller.view = NSView()
        contentViewControllers.append(controller)
        contexts.append(context)
        return controller
    }

    func makeMenus(context: DesktopAppContext) -> [NSMenu] { menus }

    func makeSettingsViewController(context: DesktopAppContext) -> NSViewController? { settingsViewController }

    func appWillClose(context: DesktopAppContext) { willCloseCount += 1 }
}
