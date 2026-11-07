//
//  BrowserPausedBadge.swift
//  AgenticDeveloperHubSDK
//

import AppKit

/// A `pause.circle.fill` symbol in the address bar, beside the driven badge,
/// shown for exactly as long as the pane's events are paused (Pause Events,
/// spec section 7). A paused page looks like a live one, so without it a
/// pane that ignores every click would read as broken. It has no hold: the
/// pause is the user's own act, on and off at once, unlike a model's drive
/// that `BrowserDrivenBadge` keeps on screen after it ends.
@MainActor
public final class BrowserPausedBadge: NSView {

    private static let explanation = "Events are paused for this pane"

    private let symbol = NSImageView()

    public private(set) var isShowing = false

    public init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 18, height: 18))
        symbol.image = NSImage(systemSymbolName: "pause.circle.fill", accessibilityDescription: Self.explanation)
        symbol.contentTintColor = .systemOrange
        symbol.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbol)
        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(equalToConstant: 18),
            heightAnchor.constraint(equalToConstant: 18)
        ])
        toolTip = Self.explanation
        setAccessibilityIdentifier("browser.paused")
        setAccessibilityLabel(Self.explanation)
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Shows or hides the badge at once.
    public func setPaused(_ paused: Bool) {
        isShowing = paused
        isHidden = !paused
    }
}
