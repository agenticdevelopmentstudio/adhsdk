import AppKit
import ObjectiveC
@preconcurrency import KeyboardShortcuts

/// Makes a menu item show the key a `KeyCommandRegistry` command is bound to,
/// and keep showing it as the user rebinds it.
///
/// A menu item's key equivalent is fixed when the item is built, while a
/// registered command's chord is the user's to change in Settings › Keyboard.
/// Without this the menu would go on advertising the shipped chord after a
/// rebind — a promise the keyboard no longer keeps — and a cleared binding
/// would leave a key in the menu that does nothing
/// (`principle-of-least-astonishment`).
///
/// Generic on purpose: any menu contribution that names a key command id gets
/// it from the host (`MenuContribution.keyCommandID`), not only the Browser
/// menu's Back and Forward.
@MainActor
public enum KeyCommandMenuBridge {

    /// Shows `registry`'s current shortcut for `id` on `item` — nothing when
    /// the command has none or is switched off — and re-applies it whenever
    /// the registry announces that bindings changed. Binding an item again
    /// replaces the earlier binding; the observation ends with the item.
    public static func bind(
        _ item: NSMenuItem,
        toCommand id: String,
        registry: KeyCommandRegistry = .shared
    ) {
        let observer = Observer(item: item, commandID: id, registry: registry)
        objc_setAssociatedObject(item, &observerKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        observer.apply()
    }

    /// `item`'s key equivalent and modifiers for `shortcut`, or none.
    static func apply(_ shortcut: KeyboardShortcuts.Shortcut?, to item: NSMenuItem) {
        guard let shortcut, let key = shortcut.nsMenuItemKeyEquivalent else {
            item.keyEquivalent = ""
            item.keyEquivalentModifierMask = []
            return
        }
        item.keyEquivalent = key
        item.keyEquivalentModifierMask = shortcut.modifiers
        // The registry's chord is a physical key; letting AppKit relocalize it
        // would show a different key than the one that fires.
        item.allowsAutomaticKeyEquivalentLocalization = false
    }

    private static var observerKey: UInt8 = 0

    /// Owned by the item it updates, through an associated object, so its
    /// lifetime is the item's and nothing else has to keep it.
    @MainActor
    private final class Observer: NSObject {
        private weak var item: NSMenuItem?
        private let commandID: String
        private let registry: KeyCommandRegistry
        /// `nonisolated(unsafe)` only so `deinit` can remove it; written once,
        /// in `init`.
        private nonisolated(unsafe) var token: NSObjectProtocol?

        init(item: NSMenuItem, commandID: String, registry: KeyCommandRegistry) {
            self.item = item
            self.commandID = commandID
            self.registry = registry
            super.init()
            token = NotificationCenter.default.addObserver(
                forName: KeyCommandRegistry.bindingsDidChangeNotification,
                object: registry,
                // Synchronously, on the posting thread: the registry is
                // main-actor and posts there, so the item is current the moment
                // `setBinding` returns.
                queue: nil
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.apply() }
            }
        }

        deinit {
            if let token { NotificationCenter.default.removeObserver(token) }
        }

        func apply() {
            guard let item else { return }
            KeyCommandMenuBridge.apply(registry.shortcut(for: commandID), to: item)
        }
    }
}
