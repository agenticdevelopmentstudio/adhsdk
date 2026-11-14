import Foundation

/// Supplies a `LineViewerViewController`'s rows on demand. The viewer asks only
/// for the rows it is drawing, so `row(at:)` should be cheap and `rowCount`
/// constant between `reloadData()` calls.
@MainActor
public protocol LineViewerDataSource: AnyObject {
    var gutterColumnCount: Int { get }
    var rowCount: Int { get }
    func row(at index: Int) -> LineViewerRow
}

/// Hears about selection changes and gutter clicks. Row indices are the data
/// source's, whatever is folded.
@MainActor
public protocol LineViewerDelegate: AnyObject {
    func lineViewer(_ viewer: LineViewerViewController, didSelectRows rows: IndexSet)
    func lineViewer(_ viewer: LineViewerViewController, didClickGutterColumn column: Int, row: Int)
}
