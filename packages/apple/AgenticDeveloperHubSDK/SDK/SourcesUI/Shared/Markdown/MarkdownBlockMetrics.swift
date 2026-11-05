import Foundation

/// The numbers the block renderer lays out with, in one place so a document
/// viewer and a chat bubble indent the same list by the same amount.
public enum MarkdownBlockMetrics {

    /// One level of list or quote nesting.
    public static let indentStep: CGFloat = 20

    /// Tables are laid out on fixed tab stops rather than measured columns:
    /// `NSAttributedString` has no table primitive, and a measured layout would
    /// need a second pass over content the renderer streams in one.
    public static let tableColumnWidth: CGFloat = 140

    /// How many tab stops a table row is given.
    ///
    /// A table wider than this keeps every cell — the renderer emits them all,
    /// separated by tabs — and only the stops run out, so the overflow columns
    /// fall back to the text system's default tab stops and land on a coarser
    /// grid than the ones before them. That is the right trade: twelve columns
    /// at `tableColumnWidth` is already 1680pt, far past any window this ships
    /// in, so a wider table is unreadable whatever the stops say, and paying
    /// for an unbounded stop list on every table row to make one pathological
    /// document slightly less unreadable is not worth it.
    public static let tableColumnCount = 12

    /// A horizontal rule, drawn with box-drawing characters because an
    /// attributed string cannot carry a border.
    public static let thematicBreakRule = String(repeating: "─", count: 32)
}
