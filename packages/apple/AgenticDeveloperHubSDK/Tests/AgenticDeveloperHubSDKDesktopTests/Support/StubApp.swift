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
    /// True by default so tests can open Settings for a schema-less stub.
    var hasSettings = true
    /// Weak, so a test can tell whether closing a window released its content.
    var contentViewControllers: [NSViewController] { weakContents.compactMap(\.value) }
    private var weakContents: [WeakBox] = []
    private final class WeakBox {
        weak var value: NSViewController?
        init(_ value: NSViewController) { self.value = value }
    }
    private(set) var willCloseCount = 0
    /// Strong on purpose: an App that keeps its context must not keep a closed window alive.
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
        weakContents.append(WeakBox(controller))
        contexts.append(context)
        return controller
    }

    func makeMenus(context: DesktopAppContext) -> [NSMenu] { menus }

    func makeSettingsViewController(context: DesktopAppContext) -> NSViewController? { settingsViewController }

    func appWillClose(context: DesktopAppContext) { willCloseCount += 1 }
}
