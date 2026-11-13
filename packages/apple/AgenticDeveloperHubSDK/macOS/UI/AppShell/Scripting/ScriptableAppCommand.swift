import AppKit

/// Where AppleScript finds the app's commands and menus. Set once by the host
/// at launch (`dependency-injection`): the registry is an instance the host
/// owns, so the scripting layer is handed it rather than reaching for a global.
@MainActor
public enum AppScripting {

    /// Everything a menu item, palette row or shortcut dispatches. With it,
    /// every feature that registers its actions is scriptable by id without a
    /// verb of its own (`support-automation`).
    public static weak var commandRegistry: CommandRegistry?
}

/// One registered `AppCommand`, as Cocoa Scripting sees it.
@MainActor
@objc(ScriptableAppCommand)
public final class ScriptableAppCommand: NSObject {

    private let command: AppCommand

    init(command: AppCommand) {
        self.command = command
        super.init()
    }

    @objc var uniqueID: String { command.id }
    @objc var name: String { command.title }
    @objc var category: String { command.category }
    @objc var isEnabled: Bool { command.isEnabled() }

    public override nonisolated var objectSpecifier: NSScriptObjectSpecifier? {
        applicationElementSpecifier(key: "appCommands") { self.uniqueID }
    }

    /// Every registered command, in registration order.
    public static var all: [ScriptableAppCommand] {
        (AppScripting.commandRegistry?.allCommands ?? []).map(ScriptableAppCommand.init(command:))
    }

    public static func with(uniqueID: String) -> ScriptableAppCommand? {
        AppScripting.commandRegistry?.command(id: uniqueID).map(ScriptableAppCommand.init(command:))
    }
}

/// AppleScript command: `perform command "<id or title>"` — exactly what the
/// menu item, palette row or shortcut bound to that command does.
@objc(PerformAppCommandCommand)
public final class PerformAppCommandCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        guard let registry = AppScripting.commandRegistry else {
            return fail("The app's commands are not available yet.")
        }
        let reference: String
        if let text = directParameter as? String {
            reference = text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let object = directParameter as? ScriptableAppCommand {
            reference = object.uniqueID
        } else if let object = evaluatedReceivers as? ScriptableAppCommand {
            // `perform command (command id "…")`: Cocoa Scripting makes an
            // object reference in the direct position the receiver.
            reference = object.uniqueID
        } else if let specifier = directParameter as? NSUniqueIDSpecifier,
                  let id = specifier.uniqueID as? String {
            reference = id
        } else if let specifier = directParameter as? NSNameSpecifier {
            reference = specifier.name
        } else if let descriptor = directParameter as? NSAppleEventDescriptor {
            // A `type="any"` parameter arrives undecoded: text as itself, and
            // `command id "…"` / `command "…"` as an object specifier whose
            // key data is the id or name.
            let text = descriptor.descriptorType == DescType(typeObjectSpecifier)
                ? descriptor.forKeyword(AEKeyword(keyAEKeyData))?.stringValue
                : descriptor.stringValue
            reference = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            reference = ""
        }
        guard !reference.isEmpty else { return fail("A command id or title is required.") }
        // An id first: it is what the command is addressed by. A title second,
        // because it is what the palette shows and what a person types.
        let commands = registry.allCommands
        guard let command = registry.command(id: reference)
            ?? commands.first(where: { $0.title == reference })
            ?? commands.first(where: { $0.title.caseInsensitiveCompare(reference) == .orderedSame })
        else {
            return fail("No command matches “\(reference)”.")
        }
        do {
            try registry.execute(id: command.id)
        } catch {
            return fail(String(describing: error))
        }
        return nil
    }

    private func fail(_ message: String) -> Any? {
        scriptErrorNumber = errOSACantAssign
        scriptErrorString = message
        return nil
    }
}

/// AppleScript command: `perform menu item "File > New Window"` — chooses a
/// menu item by its path through the main menu, for the entries no
/// `AppCommand` stands behind. Validated first, like a click: a disabled item
/// answers an error instead of running.
@objc(PerformMenuItemCommand)
public final class PerformMenuItemCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        let path = ((directParameter as? String) ?? "")
            .split(separator: ">")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !path.isEmpty, var menu = NSApp.mainMenu else {
            return fail("A menu path such as “File > New Window” is required.")
        }
        for (index, title) in path.enumerated() {
            menu.update()
            guard let itemIndex = menu.items.firstIndex(where: { Self.matches($0, title) }) else {
                return fail("No menu item “\(title)” in “\(menu.title)”.")
            }
            let item = menu.items[itemIndex]
            if index == path.count - 1 {
                guard item.isEnabled else { return fail("“\(path.joined(separator: " > "))” is disabled.") }
                guard item.submenu == nil else {
                    return fail("“\(title)” is a submenu, not a menu item.")
                }
                menu.performActionForItem(at: itemIndex)
                return nil
            }
            guard let submenu = item.submenu else { return fail("“\(title)” has no submenu.") }
            menu = submenu
        }
        return nil
    }

    /// The title as shown, ignoring case and a trailing ellipsis, so a script
    /// can write `Settings` for `Settings…`.
    private static func matches(_ item: NSMenuItem, _ title: String) -> Bool {
        func normalized(_ text: String) -> String {
            var text = text.trimmingCharacters(in: .whitespaces)
            while text.hasSuffix("…") || text.hasSuffix(".") { text.removeLast() }
            return text.lowercased()
        }
        return !item.isSeparatorItem && !item.isHidden && normalized(item.title) == normalized(title)
    }

    private func fail(_ message: String) -> Any? {
        scriptErrorNumber = errOSACantAssign
        scriptErrorString = message
        return nil
    }
}
