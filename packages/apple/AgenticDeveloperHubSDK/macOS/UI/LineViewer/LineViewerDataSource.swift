import Foundation

/// Supplies a `LineViewerViewController`'s rows on demand. The viewer asks only
/// for the rows it is drawing, so `row(at:)` should be cheap.
///
/// Between `reloadData()` calls, `rowCount` and every row's content (its text
/// and runs) MUST NOT change: the viewer caches layout derived from long rows
/// and drops it only on `reloadData()`. A data source that updates its rows
/// calls `reloadData()`.
@MainActor
public protocol LineViewerDataSource: AnyObject {
    var gutterColumnCount: Int { get }
    var rowCount: Int { get }
    func row(at index: Int) -> LineViewerRow
    /// The width of gutter column `column`, in characters of the code font,
    /// not counting the one character of padding the viewer adds on each side.
    /// A value wider than this is clipped to its column.
    func gutterColumnWidth(_ column: Int) -> Int
}

public extension LineViewerDataSource {
    /// Wide enough for a line number: `max(3, digits of rowCount)`.
    func gutterColumnWidth(_ column: Int) -> Int {
        max(3, String(rowCount).count)
    }
}

/// Hears about selection changes and gutter clicks. Row indices are the data
/// source's, whatever is folded.
@MainActor
public protocol LineViewerDelegate: AnyObject {
    func lineViewer(_ viewer: LineViewerViewController, didSelectRows rows: IndexSet)
    func lineViewer(_ viewer: LineViewerViewController, didClickGutterColumn column: Int, row: Int)
}
