import AppKit

/// The body of an options dialog: an optional heading, the rows whoever raised
/// it handed over, and the one button that ends it.
///
/// Container-agnostic on purpose. The same body is presented as a sheet on a
/// pane and as a small modal window from a window's gear, and the only thing
/// that differs between those two is who owns the window — not the layout, not
/// the insets, and not the rule that every row spans one width. A second
/// spelling of this is a second place for those to drift apart (`dry`).
///
/// Every row applies its change as it is made — the window resizes behind the
/// dialog as a text-size slider moves — so there is nothing to commit and
/// nothing to cancel. `Done` is the way out, not an acceptance.
@MainActor
public final class OptionsDialogViewController: NSViewController {

    /// Fires when `Done` is pressed. The presenter decides what closing means:
    /// a sheet dismisses, a modal window stops its run loop. Left `nil` the
    /// button does nothing, which is why every presenter sets it.
    public var onDone: (() -> Void)?

    /// Fires once the dialog is off screen.
    ///
    /// Controls that coalesce their writes — a stepper ticking through a
    /// gesture — still have the last one pending when the dialog goes away.
    /// The dialog closing *is* the end of the gesture, and hosts listen here
    /// to finish it.
    public var onDidClose: (() -> Void)?

    /// The name at the head of the dialog, or `nil` to show none.
    ///
    /// Settable, because something named by its content can be renamed while
    /// the dialog is up, and a heading frozen at the moment it was built would
    /// then be naming the wrong thing. `nil` is for a presenter whose container
    /// already names it — a titled window puts the name in its title bar, and
    /// saying it twice is just saying it twice.
    public var heading: String? {
        didSet {
            headingLabel.stringValue = heading ?? ""
            headingLabel.isHidden = heading == nil
        }
    }

    /// What a dialog is wide, unless its rows need more. Wide enough that a
    /// slider has room to be aimed with and a caption like "140%" does not
    /// crowd the title beside it. It was 320 when the rows were drawn at the
    /// small control size; they are at the standard one now, so the same rows
    /// need more room.
    ///
    /// `nonisolated` because its only readers are the default arguments of two
    /// `init`s — this class's own and `WindowOptionsDialog`'s — and a default
    /// argument is evaluated in the caller's context, not the callee's. Reading
    /// a main-actor static from there is an error under Swift 6, and the
    /// constant has no isolation to give up: it is a `let` of a `Sendable` type.
    nonisolated public static let defaultWidth: CGFloat = 340

    /// The rows are held off the edges by this much, and each row is pinned to
    /// the stack's width minus both sides — so a slider gets the full run and
    /// its caption right-aligns to one edge.
    private static let insets = NSEdgeInsets(top: 18, left: 20, bottom: 8, right: 20)

    private let headingLabel: ThemedLabel
    private let rows: [NSView]
    private let width: CGFloat
    private let accessibilityPrefix: String

    /// - Parameter accessibilityPrefix: names this dialog's two identifiers,
    ///   `<prefix>.dialog` and `<prefix>.dialog.done`, so two dialogs on screen
    ///   at once are still tellable apart by a UI test.
    public init(
        heading: String?,
        rows: [NSView],
        width: CGFloat = OptionsDialogViewController.defaultWidth,
        accessibilityPrefix: String = "options"
    ) {
        self.heading = heading
        self.headingLabel = ThemedLabel(
            string: heading ?? "", role: .secondaryText, textRole: .button)
        self.headingLabel.isHidden = heading == nil
        self.rows = rows
        self.width = width
        self.accessibilityPrefix = accessibilityPrefix
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("OptionsDialogViewController is code-built, never decoded")
    }

    public override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)
        container.accessibilityID("\(accessibilityPrefix).dialog")

        let stack = NSStackView(views: [headingLabel] + rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = Self.insets
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let done = NSButton(title: "Done", target: self, action: #selector(doneTapped))
        done.bezelStyle = .rounded
        done.keyEquivalent = "\r"
        done.translatesAutoresizingMaskIntoConstraints = false
        done.accessibilityID("\(accessibilityPrefix).dialog.done")
        container.addSubview(done)

        var constraints = [
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            done.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: done.trailingAnchor, constant: Self.insets.right),
            container.bottomAnchor.constraint(equalTo: done.bottomAnchor, constant: 16),

            // A floor, not a width. Pinned exactly, this is a *required*
            // constraint that outranks every row's compression resistance, so a
            // row carrying something wider than the number — a popup with a
            // long provider name, a label and a trailing button — gets squeezed
            // and truncated instead of the dialog getting wider. `width` is
            // documented as what a dialog is wide "unless its rows need more";
            // `>=` is what makes the second half of that true, and `fittingSize`
            // still settles on exactly `width` when nothing needs more.
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: width)
        ]
        for row in rows {
            constraints.append(
                row.widthAnchor.constraint(
                    equalTo: stack.widthAnchor,
                    constant: -(Self.insets.left + Self.insets.right)))
        }
        NSLayoutConstraint.activate(constraints)

        self.view = container
    }

    public override func viewDidDisappear() {
        super.viewDidDisappear()
        onDidClose?()
    }

    @objc private func doneTapped() {
        onDone?()
    }
}
