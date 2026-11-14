import AppKit
import AgenticDeveloperHubSDKCore

/// A read-only, virtualised view of many lines: styled runs, row backgrounds,
/// gutter columns, header folding, selection and copy, drawn with Core Text.
/// Its view is an `NSScrollView` over a flipped document view that asks the
/// data source only for the rows it draws. Diff and blame are configurations of
/// it; it knows nothing about either.
@MainActor
public final class LineViewerViewController: NSViewController {

    public weak var dataSource: LineViewerDataSource?
    public weak var delegate: LineViewerDelegate?

    /// When true, clicking a header row collapses the rows up to the next
    /// header (or the end), and clicking it again expands them.
    public var foldsAtHeaders = false {
        didSet { documentView.foldsAtHeaders = foldsAtHeaders }
    }

    private let accessibilityName: String
    private let scroll = NSScrollView()
    let documentView = LineViewerView(frame: .zero)

    /// - Parameter identifier: the accessibility identifier of the scroll view;
    ///   the document view gets `<identifier>.text`.
    public init(identifier: String) {
        self.accessibilityName = identifier
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func loadView() {
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.setAccessibilityIdentifier(accessibilityName)
        scroll.observeTheme { scrollView, palette in
            scrollView.backgroundColor = palette.windowBackgroundColor
        }
        scroll.contentView.postsBoundsChangedNotifications = true
        documentView.owner = self
        documentView.setAccessibilityIdentifier(accessibilityName + ".text")
        scroll.documentView = documentView
        view = scroll
    }

    public var scrollView: NSScrollView {
        loadViewIfNeeded()
        return scroll
    }

    /// Data-source row indices, whatever is folded.
    public var selectedRows: IndexSet { documentView.selectedRows }

    /// The height of every row, from the theme's code font.
    var rowHeight: CGFloat { documentView.rowHeight }

    /// Re-reads the data source's counts, clears folds and selection, and
    /// redraws.
    public func reloadData() {
        loadViewIfNeeded()
        documentView.reload()
    }

    /// Unfolds the fold hiding data row `row`, if any, and scrolls so the row is
    /// at the top (clamped to the scrollable range), keeping the horizontal
    /// offset.
    public func scrollToRow(_ row: Int) {
        loadViewIfNeeded()
        documentView.unfold(containing: row)
        guard let display = documentView.displayRow(forDataRow: row) else { return }
        let clip = scroll.contentView
        let maximum = max(0, documentView.frame.height - clip.bounds.height)
        let top = min(max(0, CGFloat(display) * rowHeight), maximum)
        clip.scroll(to: NSPoint(x: clip.bounds.origin.x, y: top))
        scroll.reflectScrolledClipView(clip)
    }

    func notifySelection(_ rows: IndexSet) {
        delegate?.lineViewer(self, didSelectRows: rows)
    }

    func notifyGutterClick(column: Int, row: Int) {
        delegate?.lineViewer(self, didClickGutterColumn: column, row: row)
    }
}
