import AppKit

/// The Desktop's Settings App, modeled on macOS System Settings: a sidebar of panes
/// (Appearance, Menu Bar) beside the selected pane. It edits `DesktopSettings`, the
/// Desktop's own settings, so it lives with the Desktop rather than among the other Apps.
@MainActor
public final class DesktopSettingsApp: DesktopApp {
    public static let identifier = "com.agenticdeveloperhub.desktop.settings"

    public let descriptor = DesktopAppDescriptor(
        identifier: DesktopSettingsApp.identifier,
        displayName: "Settings",
        version: "1.0",
        summary: "Change how the Desktop looks and where menus appear.",
        icon: .symbol(name: "gearshape.fill", tint: "#8E8E93"),
        attribution: DesktopAppAttribution(
            author: "Agentic Developer Hub",
            copyright: "© 2026 Agentic Developer Hub",
            url: nil
        ),
        defaultWindowSize: CGSize(width: 680, height: 460),
        minimumWindowSize: CGSize(width: 560, height: 360)
    )

    private let settings: DesktopSettings

    public init(settings: DesktopSettings = .shared) {
        self.settings = settings
    }

    public func makeContentViewController(context: DesktopAppContext) -> NSViewController {
        DesktopSettingsAppViewController(settings: settings)
    }
}
