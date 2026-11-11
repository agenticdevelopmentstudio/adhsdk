//
//  WindowTitlebarTitle.swift
//  AgenticDeveloperHubSDK
//

import AppKit

/// A window's title with an icon before it, at the leading edge of the title
/// bar just after the window controls, as a pane's title bar shows its icon
/// and name. It replaces the window's own centred title, which AppKit draws
/// without an icon: the window's `title` still carries the name, for the
/// Window menu and accessibility, but is no longer drawn.
@MainActor
public final class WindowTitlebarTitle: NSTitlebarAccessoryViewController {

    /// The icon's side, the same as a pane title bar's.
    public static let iconSize: CGFloat = 14
    /// Room kept for the trailing accessories (a settings gear) and the
    /// window controls, so a long title truncates rather than running under
    /// them.
    private static let reservedWidth: CGFloat = 160

    public let iconView = NSImageView()
    public let titleLabel = NSTextField(labelWithString: "")
    private let stack: NSStackView
    nonisolated(unsafe) private var resizeObserver: NSObjectProtocol?

    public init() {
        stack = NSStackView(views: [iconView, titleLabel])
        super.init(nibName: nil, bundle: nil)
        layoutAttribute = .leading

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.setAccessibilityElement(false)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize)
        ])

        titleLabel.font = .titleBarFont(ofSize: 0)
        titleLabel.textColor = .labelColor
        titleLabel.cell?.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setAccessibilityIdentifier("window.title")

        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 5
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    public override func loadView() {
        view = stack
    }

    public var icon: NSImage? {
        get { iconView.image }
        set {
            iconView.image = newValue
            iconView.isHidden = newValue == nil
            resize()
        }
    }

    /// The name shown, which is also the window's `title`.
    public var text: String {
        get { titleLabel.stringValue }
        set {
            titleLabel.stringValue = newValue
            view.window?.title = newValue
            resize()
        }
    }

    /// Puts the title in `window`'s title bar and hides the one AppKit draws.
    public func install(in window: NSWindow) {
        window.titleVisibility = .hidden
        window.addTitlebarAccessoryViewController(self)
        window.title = text
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification, object: window, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.resize() }
        }
        resize()
    }

    deinit {
        if let resizeObserver { NotificationCenter.default.removeObserver(resizeObserver) }
    }

    /// A leading accessory is as wide as its view's frame: the title's own
    /// width, but never more than the window leaves it.
    private func resize() {
        let fitting = stack.fittingSize
        let available = (view.window?.frame.width ?? .greatestFiniteMagnitude) - Self.reservedWidth
        let height = max(fitting.height, 28)
        stack.setFrameSize(NSSize(width: max(0, min(fitting.width, available)), height: height))
    }
}
