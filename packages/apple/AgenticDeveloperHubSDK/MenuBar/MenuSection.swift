import AppKit
import Foundation
import AgenticDeveloperHubSDKCore

/// A bundle of menu items a client contributes to the status-bar menu.
///
/// Sections are rendered top-to-bottom in the order registered with
/// ``MenuComposer``. Each section decides whether it's visible based on the
/// current snapshot (return an empty array to hide).
///
/// Typical built-ins:
/// - ``HealthMenuSection`` (header with status + uptime)
/// - ``TimingStrategySection`` (timing strategy work units)
/// - ``EventStrategySection`` (event strategy indicators)
/// - ``CrashesMenuSection`` (recent crashes)
/// - ``DaemonControlsSection`` (Start/Stop/Restart + Quit)
///
/// Daemons also implement their own sections for domain-specific views
/// (e.g. stenographer's "Sessions" list).
public protocol MenuSection: Sendable {
    /// Produce menu items for this refresh. Return empty to hide the section.
    /// The renderer inserts a separator after each non-empty section.
    func items(snapshot: MenuSnapshot) -> [NSMenuItem]
}

/// Point-in-time data passed to every section's render.
///
/// Extensible: sections that need richer data can subclass ``MenuSnapshot``
/// or attach data to ``userInfo``. The basic fields cover most needs.
public struct MenuSnapshot: Sendable {
    /// `true` if the daemon's `/health` responded successfully on the last refresh.
    public let isReachable: Bool
    /// Parsed `/health` response if reachable.
    public let health: DaemonHealthReport?
    /// Arbitrary per-daemon data sections can read (e.g. crash lists,
    /// session lists). Keyed by a string the section and fetcher agree on.
    public let userInfo: [String: any Sendable]
    public let now: Date

    public init(
        isReachable: Bool,
        health: DaemonHealthReport? = nil,
        userInfo: [String: any Sendable] = [:],
        now: Date = Date.now
    ) {
        self.isReachable = isReachable
        self.health = health
        self.userInfo = userInfo
        self.now = now
    }
}

/// Assembles an ``NSMenu`` from a declared list of sections.
///
/// Stateless — call `build(snapshot:)` on every refresh. Sections that
/// render no items are skipped (no dangling separators).
public final class MenuComposer: @unchecked Sendable {
    public let sections: [any MenuSection]

    public init(sections: [any MenuSection]) {
        self.sections = sections
    }

    public func build(snapshot: MenuSnapshot) -> NSMenu {
        let menu = NSMenu()
        // AppKit's default (`true`) force-enables any item whose target
        // doesn't implement `validateMenuItem(_:)` once the item is installed
        // in a real, tracked menu.
        // That silently overrode a section's own `isEnabled = false` (e.g.
        // `DaemonActionsSection`'s "Sync Now" while the daemon is down).
        // With autoenabling off, `NSMenuItem` defaults to enabled, so this
        // changes nothing for any item a section left alone — only an
        // explicit `isEnabled = false`, which is what `disabledItem` sets,
        // starts being honoured.
        menu.autoenablesItems = false
        var first = true
        for section in sections {
            let items = section.items(snapshot: snapshot)
            guard !items.isEmpty else { continue }
            if !first { menu.addItem(.separator()) }
            for item in items { menu.addItem(item) }
            first = false
        }
        return menu
    }
}

/// NSMenuItem subclass that dispatches to a closure on click.
/// Exposed publicly because client sections need to build actionable items.
///
/// `isEnabled` and `isOn` are asked again every time the menu opens, through
/// `validateMenuItem` — not once when the item is built. The status item
/// rebuilds its menu only when the daemon's snapshot changes, so an answer
/// read at build time goes stale: Stop Timer stays greyed after a timer
/// starts, a window's checkmark stays after it closes. Validation needs the
/// menu's `autoenablesItems` left on (the default).
public final class BlockMenuItem: NSMenuItem, NSMenuItemValidation {
    private let block: @Sendable () -> Void
    private let enabledCheck: (@Sendable () -> Bool)?
    private let onCheck: (@Sendable () -> Bool)?

    public init(
        title: String,
        isEnabled: (@Sendable () -> Bool)? = nil,
        isOn: (@Sendable () -> Bool)? = nil,
        action block: @escaping @Sendable () -> Void
    ) {
        self.block = block
        self.enabledCheck = isEnabled
        self.onCheck = isOn
        super.init(title: title, action: #selector(invoke), keyEquivalent: "")
        self.target = self
        _ = applyChecks()
    }

    public required init(coder: NSCoder) { fatalError("not implemented") }

    @objc private func invoke() { block() }

    /// Re-reads the checkmark and answers whether the item is enabled.
    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        applyChecks()
    }

    /// One body for the build-time read and every validation after it. The
    /// init is nonisolated, so it cannot call the main-actor
    /// `validateMenuItem` itself.
    private func applyChecks() -> Bool {
        if let onCheck { state = onCheck() ? .on : .off }
        // No closure → the stored flag, so a section's explicit
        // `isEnabled = false` survives validation in a menu that autoenables.
        let enabled = enabledCheck?() ?? isEnabled
        // Also stored, so a menu with `autoenablesItems` off still shows the
        // answer from the last validation rather than a stale build-time one.
        isEnabled = enabled
        return enabled
    }
}

/// Small rendering helpers sections can share.
public enum MenuBarHelpers {

    public static func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    public static func headerItem(_ title: String) -> NSMenuItem {
        disabledItem(title)
    }

    public static func infoItem(label: String, value: String, indent: Int = 1) -> NSMenuItem {
        let item = NSMenuItem(title: "\(label):  \(value)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.indentationLevel = indent
        return item
    }

    public static func formatUptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        if total < 60 { return "\(total)s" }
        if total < 3600 { return "\(total / 60)m \(total % 60)s" }
        return "\(total / 3600)h \(total % 3600 / 60)m"
    }
}
