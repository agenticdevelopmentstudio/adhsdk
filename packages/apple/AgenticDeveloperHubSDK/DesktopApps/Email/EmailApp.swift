import AppKit
import Foundation
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKDesktop
import AgenticDeveloperHubSDKIntegrations
import AgenticDeveloperHubSDKMacOS

/// Reads mail from the connected accounts, in the Mail browser.
@MainActor
public final class EmailApp: DesktopApp {
    public let descriptor = DesktopAppDescriptor(
        identifier: "com.agenticdeveloperhub.desktop.email",
        displayName: "Email",
        version: "1.0",
        summary: "Read your mail from connected accounts.",
        icon: .symbol(name: "envelope.fill", tint: "#2F7CF6"),
        attribution: DesktopAppAttribution(
            author: "Agentic Developer Hub",
            copyright: "© 2026 Agentic Developer Hub",
            url: nil
        ),
        integration: DesktopAppIntegrationBinding(serviceType: "messages", provider: nil),
        defaultWindowSize: CGSize(width: 1000, height: 640),
        minimumWindowSize: CGSize(width: 760, height: 460),
        settingsSchema: .empty
    )

    private let client: MailClient
    /// The browser of each open window, retained for its menu; released when the window closes.
    private var browsers: [ObjectIdentifier: MailBrowserViewController] = [:]
    private var menuTargets: [ObjectIdentifier: [ClosureMenuItemTarget]] = [:]

    public init(client: MailClient) {
        self.client = client
    }

    public func makeContentViewController(context: DesktopAppContext) -> NSViewController {
        let browser = MailBrowserViewController(client: client)
        browsers[ObjectIdentifier(context)] = browser
        return browser
    }

    public func makeMenus(context: DesktopAppContext) -> [NSMenu] {
        let key = ObjectIdentifier(context)
        guard let browser = browsers[key] else { return [] }
        let refresh = ClosureMenuItemTarget(action: { [weak browser] in
            guard let browser else { return }
            Task { await browser.model.reload() }
        })
        menuTargets[key] = [refresh]
        let item = NSMenuItem(
            title: "Refresh",
            action: #selector(ClosureMenuItemTarget.performMenuAction(_:)),
            keyEquivalent: "r"
        )
        item.keyEquivalentModifierMask = .command
        item.target = refresh
        let menu = NSMenu(title: "Mailbox")
        menu.addItem(item)
        return [menu]
    }

    public func makeSettingsViewController(context: DesktopAppContext) -> NSViewController? {
        IntegrationsSettingsPanel(client: client)
    }

    public func appWillClose(context: DesktopAppContext) {
        let key = ObjectIdentifier(context)
        browsers.removeValue(forKey: key)
        menuTargets.removeValue(forKey: key)
    }
}
