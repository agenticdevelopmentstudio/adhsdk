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
///
/// With `showsHistoryMenu` it is `‹ [document] ›`: a middle segment that pops
/// down the trail itself, as a menu the owner builds in `historyMenu`.
@MainActor
public final class BackForwardControl: NSSegmentedControl {

    /// The segment that steps back.
    public static let backSegment = 0

    /// The segment that steps forward: the last one, after the history segment
    /// when there is one.
    public let forwardSegment: Int

    /// The segment that pops down the trail, or nil for a plain `‹ ›`.
    public let historySegment: Int?

    /// Builds the menu the history segment pops down, each time it is
    /// clicked. Items carry their own target and action.
    public var historyMenu: (() -> NSMenu?)?

    /// The enabled state of the history segment: whether there is a trail to
    /// list. Always false for a control without one.
    public var canShowHistory: Bool {
        get { historySegment.map { isEnabled(forSegment: $0) } ?? false }
        set { if let historySegment { setEnabled(newValue, forSegment: historySegment) } }
    }

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
        get { isEnabled(forSegment: forwardSegment) }
        set { setEnabled(newValue, forSegment: forwardSegment) }
    }

    /// A control with every segment disabled until the owner says otherwise —
    /// a fresh trail has nowhere to go.
    public init(showsHistoryMenu: Bool = false) {
        historySegment = showsHistoryMenu ? 1 : nil
        forwardSegment = showsHistoryMenu ? 2 : 1
        super.init(frame: .zero)
        var symbols = [("chevron.backward", "Back"), ("chevron.forward", "Forward")]
        if showsHistoryMenu { symbols.insert(("doc", "Recent Documents"), at: 1) }
        segmentCount = symbols.count
        trackingMode = .momentary
        segmentStyle = .separated
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
        let segment = sender.selectedSegment
        if segment == Self.backSegment {
            onBack?()
        } else if segment == forwardSegment {
            onForward?()
        } else if segment == historySegment {
            showHistoryMenu()
        }
    }

    /// Pops the trail down under the history segment. The segments are equal
    /// widths, so a segment's left edge is its share of the control's.
    private func showHistoryMenu() {
        guard let historySegment, let menu = historyMenu?(), !menu.items.isEmpty else { return }
        let x = bounds.width / CGFloat(segmentCount) * CGFloat(historySegment)
        let y = isFlipped ? bounds.maxY + 4 : bounds.minY - 4
        menu.popUp(positioning: nil, at: NSPoint(x: x, y: y), in: self)
    }
}
