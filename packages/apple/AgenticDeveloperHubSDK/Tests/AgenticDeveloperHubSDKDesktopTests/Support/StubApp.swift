import AppKit
@testable import AgenticDeveloperHubSDKDesktop

/// A minimal `DesktopApp` for tests.
@MainActor
final class StubApp: DesktopApp {
    let descriptor: DesktopAppDescriptor

    init(
        identifier: String,
        schema: DesktopAppSettingsSchema = .empty,
        displayName: String = "Stub"
    ) {
        descriptor = DesktopAppDescriptor(
            identifier: identifier,
            displayName: displayName,
            version: "1.0",
            summary: "Stub app",
            icon: .symbol(name: "star", tint: "#FFFFFF"),
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
