import AppKit

/// A pane's title bar: the same four regions a window's title bar has, in the
/// same order.
///
/// ```
/// [ ✕  −  ⤢ ]  Files          <accessory area>          [ ⚙ ]
/// ```
///
/// The accessory area between the title and the gear is the pane's to fill —
/// a file browser's filter field, a terminal's shell name. This view knows only
/// that it is an array of views; what goes in it is decided one framework up,
/// by asking the pane's content.
///
/// The gear is trailing-most and stays there. Everything else in the bar is
/// variable, and the gear's *position* is the convention a reader carries from
/// one window to the next — which is also why the title truncates in the middle
/// instead of pushing the gear off the end.
@MainActor
public final class PaneTitleBarView: NSView {

    /// Tall enough for a 13pt label and a small square button, short enough
    /// that a three-pane column does not spend a quarter of its height on
    /// chrome.
    public static let height: CGFloat = 26

    public let controls = PaneControlCluster()
    public let titleLabel = ThemedLabel(string: "", role: .primaryText, textRole: .body)

    /// Also the label's tooltip, because a long title truncates and the full
    /// text has to stay reachable.
    public var title: String {
        get { titleLabel.stringValue }
        set {
            titleLabel.stringValue = newValue
            titleLabel.toolTip = newValue.isEmpty ? nil : newValue
        }
    }

    /// The pane's own controls, leading-to-trailing in array order.
    /// Assigning replaces: content whose controls change hands back a new
    /// array, and the old views leave the view tree rather than lingering
    /// behind the new ones.
    public var accessoryViews: [NSView] {
        get { accessoryStack.arrangedSubviews }
        set {
            for view in accessoryStack.arrangedSubviews {
                accessoryStack.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
            for view in newValue {
                accessoryStack.addArrangedSubview(view)
                if yieldsWidth { Self.yieldWidth(in: view) }
            }
        }
    }

    /// The gear button, supplied by whoever owns the options dialog. A slot
    /// rather than a built-in `WindowOptionsDialog`, so this view does not have
    /// to know what the dialog contains or when it should rebuild.
    public var gearView: NSView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let gearView else { return }
            gearView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(gearView)
            if yieldsWidth { Self.yieldWidth(in: gearView) }
            NSLayoutConstraint.activate([
                gearView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
                gearView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            accessoryTrailing.isActive = false
            accessoryTrailing = accessoryStack.trailingAnchor.constraint(
                equalTo: gearView.leadingAnchor, constant: -6
            )
            accessoryTrailing.isActive = true
        }
    }

    /// Stops the bar insisting on the width its contents would prefer.
    ///
    /// A pane in a tree that divides whatever width its container has cannot
    /// let its chrome demand more. Every view in here reaches the enclosing
    /// split through this bar's required chain — `controls` pinned to the
    /// leading edge, the gear to the trailing one, the title and the
    /// accessories strung between them — so an intrinsic width in here lands
    /// there as a floor the container never asked for, one per pane, and a tab
    /// that opened a fourth editor drags the pane holding it wider. Below that
    /// width the title truncates to nothing and the dots squeeze: the same
    /// bargain the middle truncation already makes, and what
    /// "the panes divide the width the container has, however little that is"
    /// means for the chrome.
    ///
    /// One way. A pane does not stop being clamped to its container, and
    /// restoring would mean remembering a priority per view — the label's is
    /// not a button's — for a case that never happens (`yagni`).
    public func yieldWidthToContainer() {
        yieldsWidth = true
        Self.yieldWidth(in: self)
    }

    /// Whether chrome installed from here on yields too. The gear and the
    /// accessories arrive after `init`, and the accessories are replaced
    /// whenever the content's controls change hands, so the bar re-applies this
    /// itself rather than trusting each caller to re-ask.
    private var yieldsWidth = false

    /// The lowest priority a constraint may carry: a demand in name only.
    private static let yieldingPriority = NSLayoutConstraint.Priority(rawValue: 1)

    /// Depth-first, because a stack view's own priority says nothing about what
    /// its children ask for — relaxing only the labels measurably left the
    /// floor where it was.
    private static func yieldWidth(in view: NSView) {
        view.setContentCompressionResistancePriority(yieldingPriority, for: .horizontal)
        for subview in view.subviews { yieldWidth(in: subview) }
    }

    private let background = ThemedBackgroundView(role: .elevatedSurface)
    private let hairline = ThemedSeparatorView(role: .border, axis: .horizontal)
    private let accessoryStack = NSStackView()
    private var accessoryTrailing: NSLayoutConstraint!

    public init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.cell?.lineBreakMode = .byTruncatingMiddle
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.accessibilityID("pane.title")

        accessoryStack.orientation = .horizontal
        accessoryStack.spacing = 4
        accessoryStack.alignment = .centerY

        for child in [background, hairline, controls, titleLabel, accessoryStack] as [NSView] {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
        }

        accessoryTrailing = accessoryStack.trailingAnchor.constraint(
            equalTo: trailingAnchor, constant: -6
        )

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),

            background.topAnchor.constraint(equalTo: topAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),

            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),

            controls.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            controls.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: controls.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            accessoryStack.leadingAnchor.constraint(
                greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8
            ),
            accessoryStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            accessoryTrailing
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
