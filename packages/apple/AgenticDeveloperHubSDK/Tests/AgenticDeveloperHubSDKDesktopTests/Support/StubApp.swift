import AppKit
@testable import AgenticDeveloperHubSDKDesktop

/// A minimal `DesktopApp` for tests.
@MainActor
final class StubApp: DesktopApp {
    let descriptor: DesktopAppDescriptor

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
        NSViewController()
    }
}
