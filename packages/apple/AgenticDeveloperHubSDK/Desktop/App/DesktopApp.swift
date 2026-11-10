import AppKit

/// A self-contained App hosted on the Desktop.
@MainActor
public protocol DesktopApp: AnyObject {
    var descriptor: DesktopAppDescriptor { get }
    /// Where the App's resources live. Defaults to the bundle of the App's own type.
    var resourceBundle: Bundle { get }
    /// Called once per window, always before `makeMenus(context:)` for the same context,
    /// so menus may be built from state the content creates.
    func makeContentViewController(context: DesktopAppContext) -> NSViewController
    /// Called after `makeContentViewController(context:)` for the same context.
    func makeMenus(context: DesktopAppContext) -> [NSMenu]
    func makeSettingsViewController(context: DesktopAppContext) -> NSViewController?
    /// Whether the App has settings to show. Defaults to whether its schema has fields; an App
    /// whose `makeSettingsViewController(context:)` returns its own view must return true.
    /// Without settings, its menu has no Settings… item and `showSettings()` does nothing.
    var hasSettings: Bool { get }
    /// Called when the App's own window closes; release anything the content holds.
    /// It fires only then: hiding or closing the Desktop window, or quitting, does not call it.
    func appWillClose(context: DesktopAppContext)
}

public extension DesktopApp {
    var resourceBundle: Bundle { Bundle(for: type(of: self)) }
    func makeMenus(context: DesktopAppContext) -> [NSMenu] { [] }
    func makeSettingsViewController(context: DesktopAppContext) -> NSViewController? { nil }
    var hasSettings: Bool { !descriptor.settingsSchema.fields.isEmpty }
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
