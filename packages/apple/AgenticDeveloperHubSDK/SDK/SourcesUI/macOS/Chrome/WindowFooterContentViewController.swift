import AppKit

/// A window's content: whatever the window is actually for, with a
/// `WindowFooterBar` across the bottom of it.
///
/// It takes a controller and stacks it above a footer. It does not know what
/// the controller shows or what the footer says — the window fills the string
/// in — which is what lets a window gain a footer by being wrapped rather than
/// by being restructured (`separation-of-concerns`).
@MainActor
public final class WindowFooterContentViewController: NSViewController {

    /// What the window is for. Adopted as a child, so it gets the appearance
    /// and responder-chain participation it would have had as the window's own
    /// content controller.
    public let contentViewController: NSViewController

    public let footer: WindowFooterBar

    /// The footer's leading status text, forwarded so a host holds one
    /// reference rather than reaching through two.
    public var status: String {
        get { footer.status }
        set { footer.status = newValue }
    }

    /// - Parameters:
    ///   - contentViewController: What the window is for.
    ///   - accessibilityPrefix: The namespace the footer's controls are named
    ///     under, e.g. `"project.footer"`. Required rather than defaulted: two
    ///     windows with footers would otherwise share one identifier and a UI
    ///     test addressing "the footer" would find whichever came first
    ///     (`explicit-over-implicit`).
    public init(contentViewController: NSViewController, accessibilityPrefix: String) {
        self.contentViewController = contentViewController
        self.footer = WindowFooterBar(accessibilityPrefix: accessibilityPrefix)
        super.init(nibName: nil, bundle: nil)
        addChild(contentViewController)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let container = NSView()
        let content = contentViewController.view
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        container.addSubview(footer)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: footer.topAnchor),

            footer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        view = container
    }
}
