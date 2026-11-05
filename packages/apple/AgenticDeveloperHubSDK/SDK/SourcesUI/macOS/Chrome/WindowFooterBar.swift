import AppKit

/// The strip across the bottom of a document window: a hairline along its top
/// edge, a status string at the leading edge, and a trailing slot that starts
/// empty.
///
/// It takes a string. It does not know what a pane is, what a selection is, or
/// how a path is punctuated — the window formats all of that and hands the
/// result over. That is what lets the same bar sit under a window that has no
/// panes at all.
@MainActor
public final class WindowFooterBar: NSView {

    /// Tall enough for caption text plus the hairline, matching the tab bar's
    /// visual weight so a window with both does not look bottom-heavy.
    public static let height: CGFloat = 22

    /// Exposed rather than private so a host can read back what it set and a
    /// test can assert on the rendered value instead of a shadow copy.
    public let statusLabel = ThemedLabel(role: .secondaryText, textRole: .caption)

    /// The leading status text. Also becomes the tooltip, because a long
    /// display path truncates and the full text has to stay reachable.
    public var status: String {
        get { statusLabel.stringValue }
        set {
            statusLabel.stringValue = newValue
            statusLabel.toolTip = newValue.isEmpty ? nil : newValue
        }
    }

    /// Views pinned to the trailing edge, in leading-to-trailing array order.
    /// Empty today; the slot exists so a progress spinner or a count badge
    /// does not need the bar reopened.
    public var trailingAccessories: [NSView] {
        get { trailingStack.arrangedSubviews }
        set {
            for view in trailingStack.arrangedSubviews {
                trailingStack.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            for view in newValue {
                trailingStack.addArrangedSubview(view)
            }
        }
    }

    private let background = ThemedBackgroundView(role: .elevatedSurface)
    private let hairline = ThemedSeparatorView(role: .border)
    private let trailingStack = NSStackView()

    /// - Parameter accessibilityPrefix: The namespace this bar's controls are
    ///   named under, e.g. `"project.footer"`. Required rather than defaulted,
    ///   because the bar is meant to sit under more than one kind of window and
    ///   two of them sharing one identifier would make a UI test addressing
    ///   "the footer" find whichever came first (`explicit-over-implicit`).
    public init(accessibilityPrefix: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusLabel.accessibilityID("\(accessibilityPrefix).status")

        trailingStack.orientation = .horizontal
        trailingStack.spacing = 6
        trailingStack.alignment = .centerY
        trailingStack.translatesAutoresizingMaskIntoConstraints = false
        trailingStack.setContentHuggingPriority(.required, for: .horizontal)

        for child in [background, hairline, statusLabel, trailingStack] {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),

            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),

            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.topAnchor.constraint(equalTo: topAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            trailingStack.leadingAnchor.constraint(
                greaterThanOrEqualTo: statusLabel.trailingAnchor, constant: 8),
            trailingStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            trailingStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }
}
