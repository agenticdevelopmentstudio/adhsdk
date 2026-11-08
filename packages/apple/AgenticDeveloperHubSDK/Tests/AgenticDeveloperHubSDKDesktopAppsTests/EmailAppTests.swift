import AppKit
import XCTest
import AgenticDeveloperHubSDKDesktop
import AgenticDeveloperHubSDKMacOS
@testable import AgenticDeveloperHubSDKDesktopApps
import AgenticDeveloperHubSDKIntegrations

@MainActor
final class EmailAppTests: XCTestCase {
    private func makeApp() -> EmailApp { EmailApp(client: ScriptedMail(.ok).client) }

    func test_registry_registersHelloWorldThenEmail() {
        let registry = DesktopApps.makeRegistry(mailClient: ScriptedMail(.ok).client)
        XCTAssertEqual(
            registry.apps.map(\.descriptor.identifier),
            ["com.agenticdeveloperhub.desktop.helloworld", "com.agenticdeveloperhub.desktop.email"])
    }

    func test_email_descriptor_binding_isMessagesAnyProvider() {
        let descriptor = makeApp().descriptor
        XCTAssertEqual(descriptor.identifier, "com.agenticdeveloperhub.desktop.email")
        XCTAssertEqual(descriptor.displayName, "Email")
        XCTAssertEqual(descriptor.version, "1.0")
        XCTAssertEqual(descriptor.summary, "Read your mail from connected accounts.")
        XCTAssertEqual(descriptor.icon, .symbol(name: "envelope.fill", tint: "#2F7CF6"))
        XCTAssertEqual(descriptor.attribution.author, "Agentic Developer Hub")
        XCTAssertEqual(descriptor.attribution.copyright, "© 2026 Agentic Developer Hub")
        XCTAssertNil(descriptor.attribution.url)
        XCTAssertEqual(descriptor.integration, DesktopAppIntegrationBinding(serviceType: "messages", provider: nil))
        XCTAssertEqual(descriptor.defaultWindowSize, CGSize(width: 1000, height: 640))
        XCTAssertEqual(descriptor.minimumWindowSize, CGSize(width: 760, height: 460))
        XCTAssertEqual(descriptor.settingsSchema, .empty)
    }

    func test_email_contentIsMailBrowser_andSettingsIsIntegrationsPanel() {
        let app = makeApp()
        let context = FakeDesktopAppContext(app: app)
        XCTAssertTrue(app.makeContentViewController(context: context) is MailBrowserViewController)
        XCTAssertTrue(app.makeSettingsViewController(context: context) is IntegrationsSettingsPanel)
    }

    func test_email_menus_containMailboxRefresh_cmdR() throws {
        let app = makeApp()
        let context = FakeDesktopAppContext(app: app)
        _ = app.makeContentViewController(context: context)
        let menus = app.makeMenus(context: context)
        XCTAssertEqual(menus.map(\.title), ["Mailbox"])
        let refresh = try XCTUnwrap(menus.first?.item(named: "Refresh"))
        XCTAssertEqual(refresh.keyEquivalent, "r")
        XCTAssertEqual(refresh.keyEquivalentModifierMask, .command)
    }

    func test_email_refresh_reloadsTheBrowserModel() async throws {
        let service = ScriptedMail(.ok)
        let app = EmailApp(client: service.client)
        let context = FakeDesktopAppContext(app: app)
        _ = app.makeContentViewController(context: context)
        let refresh = try XCTUnwrap(app.makeMenus(context: context).first?.item(named: "Refresh"))
        let before = service.requests.count
        refresh.fire()
        for _ in 0..<100 where service.requests.count <= before {
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertGreaterThan(service.requests.count, before)
    }

    func test_email_publicIdentifier_matchesDescriptor() {
        XCTAssertEqual(EmailApp.identifier, "com.agenticdeveloperhub.desktop.email")
        XCTAssertEqual(makeApp().descriptor.identifier, EmailApp.identifier)
    }
}
