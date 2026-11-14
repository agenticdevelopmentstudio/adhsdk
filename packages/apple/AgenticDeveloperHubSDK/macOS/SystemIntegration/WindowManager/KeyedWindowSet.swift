//
//  KeyedWindowSet.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore

/// One window per key, remembered across launches.
///
/// Opening a key that already has a window brings that window forward;
/// opening a new one asks the owner's `open` closure for a window and, when
/// it makes one, appends the key to an ordered list persisted in `setting`.
/// The `onClose` handed to `open` forgets the key, so the owner calls it when
/// the user closes the window (and not for closes made while the app quits,
/// which should reopen). `restore()` reopens the list at launch without
/// taking the foreground and drops every key whose window cannot be opened.
///
/// The set builds no window itself: the File Browser opens its windows
/// through `ProjectWindowManager`, the git window builds its own, and both
/// share this bookkeeping. Recipe: `ui/windows/keyed-window-set`.
@MainActor
public final class KeyedWindowSet<Controller: AnyObject> {

    /// Makes `key`'s window, or returns `nil` when it cannot (the owner logs
    /// why). `onClose` is to be called when the user closes that window.
    public typealias Open = (_ key: String, _ activates: Bool, _ onClose: @escaping () -> Void) -> Controller?

    private let setting: UserSetting<[String]>
    private let openWindow: Open
    private let bringForward: (Controller) -> Void
    private var controllers: [String: Controller] = [:]

    /// - Parameter setting: where the ordered key list persists; the owner
    ///   names it, so an existing list keeps restoring.
    public init(
        setting: UserSetting<[String]>,
        open: @escaping Open,
        bringForward: @escaping (Controller) -> Void
    ) {
        self.setting = setting
        self.openWindow = open
        self.bringForward = bringForward
    }

    /// The remembered keys, in the order they were first opened.
    public var keys: [String] { setting.value }

    /// The controller of `key`'s open window, if it has one.
    public func controller(for key: String) -> Controller? {
        controllers[key]
    }

    /// Brings forward `key`'s window, or opens one and remembers `key`.
    ///
    /// - Parameter activates: false for launch restore, which reopens what
    ///   was open without taking the foreground.
    /// - Returns: the window's controller, or `nil` when `open` declined.
    @discardableResult
    public func open(key: String, activates: Bool = true) -> Controller? {
        if let existing = controllers[key] {
            bringForward(existing)
            return existing
        }
        guard let controller = openWindow(key, activates, { [weak self] in self?.closed(key) }) else {
            return nil
        }
        controllers[key] = controller
        remember(key)
        return controller
    }

    /// Reopens every remembered key, without taking the foreground, and
    /// forgets each one whose window cannot be opened.
    public func restore() {
        for key in keys where open(key: key, activates: false) == nil {
            forget(key)
        }
    }

    // MARK: - Private

    private func closed(_ key: String) {
        controllers[key] = nil
        forget(key)
    }

    private func remember(_ key: String) {
        var keys = setting.value
        guard !keys.contains(key) else { return }
        keys.append(key)
        setting.value = keys
    }

    private func forget(_ key: String) {
        let keys = setting.value
        guard keys.contains(key) else { return }
        setting.value = keys.filter { $0 != key }
    }
}
