import AppKit
import Foundation
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKDesktop

/// The smallest possible Desktop App: a greeting and the time.
@MainActor
public final class HelloWorldApp: DesktopApp {
    public let descriptor = DesktopAppDescriptor(
        identifier: "com.agenticdeveloperhub.desktop.helloworld",
        displayName: "Hello World",
        version: "1.0",
        summary: "The smallest possible Desktop app.",
        icon: .symbol(name: "hand.wave.fill", tint: "#F28C28"),
        attribution: DesktopAppAttribution(
            author: "Agentic Developer Hub",
            copyright: "© 2026 Agentic Developer Hub",
            url: nil
        ),
        defaultWindowSize: CGSize(width: 480, height: 320),
        minimumWindowSize: CGSize(width: 320, height: 220),
        settingsSchema: DesktopAppSettingsSchema(fields: [
            .init(key: "greeting", label: "Greeting", kind: .text(default: "Hello, World!", placeholder: nil)),
            .init(key: "showTime", label: "Show the time", kind: .toggle(default: true))
        ])
    )

    /// One content controller per open window, so a window's menus act on its own content.
    private var controllers: [ObjectIdentifier: HelloWorldViewController] = [:]

    public init() {}

    public func makeContentViewController(context: DesktopAppContext) -> NSViewController {
        let controller = HelloWorldViewController(settings: context.settings)
        controllers[ObjectIdentifier(context)] = controller
        return controller
    }

    public func makeMenus(context: DesktopAppContext) -> [NSMenu] {
        guard let controller = controllers[ObjectIdentifier(context)] else { return [] }
        let settings = context.settings
        let menu = NSMenu(title: "Greeting")

        let uppercase = ClosureMenuItemTarget(
            action: { [weak controller] in controller?.isUppercase.toggle() },
            isChecked: { [weak controller] in controller?.isUppercase ?? false }
        )
        let reset = ClosureMenuItemTarget(action: { settings.reset("greeting") })
        controller.menuTargets = [uppercase, reset]

        menu.addItem(item("Uppercase", key: "u", target: uppercase))
        menu.addItem(item("Reset Greeting", key: "", target: reset))
        return [menu]
    }

    public func appWillClose(context: DesktopAppContext) {
        controllers.removeValue(forKey: ObjectIdentifier(context))?.stopClock()
    }

    private func item(_ title: String, key: String, target: ClosureMenuItemTarget) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: #selector(ClosureMenuItemTarget.performMenuAction(_:)),
            keyEquivalent: key
        )
        item.keyEquivalentModifierMask = key.isEmpty ? [] : .command
        item.target = target
        return item
    }
}
