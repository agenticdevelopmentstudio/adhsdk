//
//  OverrideMarker.swift
//  AgenticDeveloperHubSDK
//

import AppKit

/// The dot a row of a browser pane's settings sheet carries while the pane
/// holds its own value for that setting, and the context menu that puts the
/// global value back (spec section 3).
///
/// One indicator for every overridable row, so "this row is not the global
/// value" reads the same wherever it appears (`principle-of-least-astonishment`).
/// A plain `NSImageView` with a system symbol: AppKit has no stock override
/// badge, and a symbol tinted with the accent colour is the native way to
/// draw a small status dot.
@MainActor
final class OverrideMarker: NSImageView {

    static let tooltip = "Overrides the global setting"
    static let useGlobalTitle = "Use Global Setting"

    /// The context menu's one item, reverting the row. Kept so a test can
    /// fire it the way a click would.
    let useGlobalItem: NSMenuItem
    /// What a right-click on the row shows.
    let rowMenu: NSMenu
    private let revert: () -> Void

    /// - Parameter revert: drops the pane's value for the row's setting.
    init(revert: @escaping () -> Void) {
        self.revert = revert
        self.useGlobalItem = NSMenuItem(title: Self.useGlobalTitle, action: nil, keyEquivalent: "")
        self.rowMenu = NSMenu()
        super.init(frame: .zero)
        let configuration = NSImage.SymbolConfiguration(pointSize: 6, weight: .regular)
        image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: Self.tooltip)?
            .withSymbolConfiguration(configuration)
        contentTintColor = .controlAccentColor
        toolTip = Self.tooltip
        setAccessibilityLabel(Self.tooltip)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        useGlobalItem.target = self
        useGlobalItem.action = #selector(useGlobal(_:))
        useGlobalItem.setAccessibilityIdentifier("settings.browser.override.use-global")
        // `show(overridden:)` decides the item's state, not menu validation.
        rowMenu.autoenablesItems = false
        rowMenu.addItem(useGlobalItem)
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Shows the dot while the pane overrides the setting. The menu item
    /// follows, so it is never offered on a row that already is the global value.
    func show(overridden: Bool) {
        isHidden = !overridden
        useGlobalItem.isEnabled = overridden
    }

    var isShowingOverride: Bool { !isHidden }

    @objc private func useGlobal(_ sender: Any?) {
        revert()
    }
}
