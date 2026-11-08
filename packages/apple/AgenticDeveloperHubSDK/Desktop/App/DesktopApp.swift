import AppKit

/// A self-contained App hosted on the Desktop.
@MainActor
public protocol DesktopApp: AnyObject {
    var descriptor: DesktopAppDescriptor { get }
    /// Where the App's resources live. Defaults to the bundle of the App's own type.
    var resourceBundle: Bundle { get }
    func makeContentViewController(context: DesktopAppContext) -> NSViewController
    func makeMenus(context: DesktopAppContext) -> [NSMenu]
    func makeSettingsViewController(context: DesktopAppContext) -> NSViewController?
    /// Called when the App's window closes; release anything the content holds.
    func appWillClose(context: DesktopAppContext)
}

public extension DesktopApp {
    var resourceBundle: Bundle { Bundle(for: type(of: self)) }
    func makeMenus(context: DesktopAppContext) -> [NSMenu] { [] }
    func makeSettingsViewController(context: DesktopAppContext) -> NSViewController? { nil }
    func appWillClose(context: DesktopAppContext) {}
}

/// What the Desktop gives an App to talk back to its window.
@MainActor
public protocol DesktopAppContext: AnyObject {
    var settings: DesktopAppSettings { get }
    func setWindowTitle(_ title: String)
    func closeWindow()
    func showSettings()
    func showAbout()
    func presentAlert(_ alert: NSAlert)
}
