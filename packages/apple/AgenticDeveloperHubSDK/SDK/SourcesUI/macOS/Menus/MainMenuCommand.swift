import AppKit

/// One entry in an app's main menu: a command, a separator, or a titled
/// submenu of further entries.
///
/// A value type rather than a prebuilt `NSMenuItem` so a host can describe its
/// whole menu bar as data and hand it to ``StandardMainMenu``, which fills in
/// the platform-standard sections around it. `target` is `weak` for the same
/// reason `NSMenuItem.target` is: the object that owns the action outlives the
/// description, never the other way round.
public struct MainMenuCommand {

    public var title: String
    public var action: Selector?
    public weak var target: AnyObject?
    public var keyEquivalent: String
    public var modifiers: NSEvent.ModifierFlags
    public var children: [MainMenuCommand]?
    public var isSeparator: Bool

    /// Accessibility identifier suffix. `nil` derives one from the title, which
    /// is right for items whose title is stable vocabulary ("Minimize") and
    /// wrong for ones that interpolate the app name ("Quit Whippet") — those
    /// pass an explicit id so the identifier survives a rename.
    public var identifier: String?

    /// A command. Pass `target: nil` to send the action up the responder chain,
    /// which is what every editing and window command here wants.
    public init(
        _ title: String,
        action: Selector? = nil,
        target: AnyObject? = nil,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = .command,
        identifier: String? = nil
    ) {
        self.title = title
        self.action = action
        self.target = target
        self.keyEquivalent = key
        self.modifiers = modifiers
        self.children = nil
        self.isSeparator = false
        self.identifier = identifier
    }

    /// A submenu. Its own item has no action — opening it is the action.
    public init(submenu title: String, _ children: [MainMenuCommand], identifier: String? = nil) {
        self.title = title
        self.action = nil
        self.target = nil
        self.keyEquivalent = ""
        self.modifiers = .command
        self.children = children
        self.isSeparator = false
        self.identifier = identifier
    }

    /// Computed rather than stored: the type holds an `AnyObject` target, so a
    /// `static let` of it would not be concurrency-safe.
    public static var separator: MainMenuCommand { MainMenuCommand(separator: ()) }

    private init(separator: ()) {
        self.title = ""
        self.action = nil
        self.target = nil
        self.keyEquivalent = ""
        self.modifiers = .command
        self.children = nil
        self.isSeparator = true
        self.identifier = nil
    }

    /// Builds the `NSMenuItem`, tagging it `menu.<prefix>.<id>` so UI
    /// automation can address it by identifier rather than by title — titles
    /// are localised and change, identifiers do not.
    @MainActor
    public func makeMenuItem(prefix: String) -> NSMenuItem {
        guard !isSeparator else { return .separator() }

        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = modifiers
        if let target { item.target = target }

        if let children {
            let submenu = NSMenu(title: title)
            let childPrefix = "\(prefix).\(identifier ?? AccessibilityID.slug(title))"
            for child in children {
                submenu.addItem(child.makeMenuItem(prefix: childPrefix))
            }
            item.submenu = submenu
        }

        item.accessibilityID("menu.\(prefix).\(identifier ?? AccessibilityID.slug(title))")
        return item
    }
}
