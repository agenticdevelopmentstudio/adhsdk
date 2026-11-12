import AppKit

/// The `‹ ›` control: a momentary two-segment control rather than two buttons.
/// It is one control with one meaning — where in the trail you are — and the
/// shared, separated bezel is how System Settings and Xcode's editor say so
/// (`native-controls`).
///
/// It renders a trail; it does not keep one. The owner sets `canGoBack` and
/// `canGoForward` from its history (a `NavigationHistory`, typically) and
/// answers `onBack` / `onForward`. Used by the Settings window's toolbar and by
/// a document editor's navigation row.
@MainActor
public final class BackForwardControl: NSSegmentedControl {

    /// The segment that steps back.
    public static let backSegment = 0

    /// The segment that steps forward.
    public static let forwardSegment = 1

    /// Called when the `‹` segment is clicked.
    public var onBack: (() -> Void)?

    /// Called when the `›` segment is clicked.
    public var onForward: (() -> Void)?

    /// The enabled state of the `‹` segment.
    public var canGoBack: Bool {
        get { isEnabled(forSegment: Self.backSegment) }
        set { setEnabled(newValue, forSegment: Self.backSegment) }
    }

    /// The enabled state of the `›` segment.
    public var canGoForward: Bool {
        get { isEnabled(forSegment: Self.forwardSegment) }
        set { setEnabled(newValue, forSegment: Self.forwardSegment) }
    }

    /// A control with both segments disabled until the owner says otherwise —
    /// a fresh trail has nowhere to go.
    public init() {
        super.init(frame: .zero)
        segmentCount = 2
        trackingMode = .momentary
        segmentStyle = .separated
        let symbols = [("chevron.backward", "Back"), ("chevron.forward", "Forward")]
        for (segment, (symbol, name)) in symbols.enumerated() {
            setImage(NSImage(systemSymbolName: symbol, accessibilityDescription: name), forSegment: segment)
            setToolTip(name, forSegment: segment)
            setEnabled(false, forSegment: segment)
        }
        setAccessibilityLabel("Back and forward")
        target = self
        action = #selector(segmentClicked(_:))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func segmentClicked(_ sender: NSSegmentedControl) {
        // Named segments, not "0 or anything else": `selectedSegment` is -1
        // when the control has no selection, and a bare `else` turned that into
        // a forward step nobody asked for.
        switch sender.selectedSegment {
        case Self.backSegment: onBack?()
        case Self.forwardSegment: onForward?()
        default: break
        }
    }
}
