import AgenticDeveloperHubSDKCore
import AppKit
import Testing
@testable import AgenticDeveloperHubSDKMacOS

/// The read-only, virtualised `LineViewer`: geometry, folding, copy, drawing
/// only what is asked for, and vertical scroll sync.
@MainActor
@Suite
struct LineViewerTests {

    // MARK: - Fixtures

    /// A data source that either serves fixed rows or synthesises `count`
    /// numbered rows, and counts every `row(at:)` call.
    @MainActor
    private final class FakeSource: LineViewerDataSource {
        private let rows: [LineViewerRow]?
        private let count: Int
        var calls = 0
        let gutterColumnCount = 2

        init(count: Int) {
            self.rows = nil
            self.count = count
        }

        init(rows: [LineViewerRow]) {
            self.rows = rows
            self.count = rows.count
        }

        var rowCount: Int { count }

        func row(at index: Int) -> LineViewerRow {
            calls += 1
            if let rows { return rows[index] }
            return LineViewerRow(text: "line \(index)", gutter: ["\(index + 1)", "\(index + 1)"])
        }
    }

    @MainActor
    private final class Recorder: LineViewerDelegate {
        var selections: [IndexSet] = []
        var gutterClicks: [(column: Int, row: Int)] = []

        func lineViewer(_ viewer: LineViewerViewController, didSelectRows rows: IndexSet) {
            selections.append(rows)
        }

        func lineViewer(_ viewer: LineViewerViewController, didClickGutterColumn column: Int, row: Int) {
            gutterClicks.append((column, row))
        }
    }

    /// The viewer holds its data source weakly, so each test keeps `source` alive.
    private func makeViewer(_ source: FakeSource) -> LineViewerViewController {
        let viewer = LineViewerViewController(identifier: "test.lineViewer")
        viewer.view.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        viewer.view.layoutSubtreeIfNeeded()
        viewer.dataSource = source
        viewer.reloadData()
        return viewer
    }

    /// A point inside the text area (right of the gutter) of display row `row`.
    private func textPoint(_ viewer: LineViewerViewController, row: Int) -> NSPoint {
        NSPoint(x: viewer.documentView.textOriginX + 4, y: (CGFloat(row) + 0.5) * viewer.rowHeight)
    }

    // MARK: - Tests

    @Test func rowGeometryMatchesRowCount() {
        let source = FakeSource(count: 100)
        let viewer = makeViewer(source)
        #expect(viewer.rowHeight > 0)
        #expect(viewer.documentView.isFlipped)
        #expect(viewer.documentView.frame.height == 100 * viewer.rowHeight)
        #expect(viewer.scrollView.documentView === viewer.documentView)
        #expect(viewer.scrollView.accessibilityIdentifier() == "test.lineViewer")
        #expect(viewer.documentView.accessibilityIdentifier() == "test.lineViewer.text")
        withExtendedLifetime(source) {}
    }

    @Test func foldingHidesRowsUntilNextHeader() {
        let source = FakeSource(rows: [
            LineViewerRow(kind: .header, text: "@@ one @@", background: .header),
            LineViewerRow(text: "a"), LineViewerRow(text: "b"), LineViewerRow(text: "c"),
            LineViewerRow(kind: .header, text: "@@ two @@", background: .header),
            LineViewerRow(text: "d"), LineViewerRow(text: "e")
        ])
        let viewer = makeViewer(source)
        viewer.foldsAtHeaders = true
        let document = viewer.documentView

        document.handleClick(at: textPoint(viewer, row: 0), modifiers: [])
        #expect(document.displayedRowCount == 4)
        #expect(document.frame.height == 4 * viewer.rowHeight)
        #expect(document.dataRow(forDisplayRow: 0) == 0)
        #expect(document.dataRow(forDisplayRow: 1) == 4)
        #expect(document.dataRow(forDisplayRow: 3) == 6)
        #expect(viewer.selectedRows.isEmpty)

        document.handleClick(at: textPoint(viewer, row: 0), modifiers: [])
        #expect(document.displayedRowCount == 7)
        #expect(document.frame.height == 7 * viewer.rowHeight)
        #expect(document.dataRow(forDisplayRow: 1) == 1)
    }

    @Test func copyJoinsSelectedRows() {
        let source = FakeSource(rows: [LineViewerRow(text: "a"), LineViewerRow(text: "b"), LineViewerRow(text: "c")])
        let viewer = makeViewer(source)
        let recorder = Recorder()
        viewer.delegate = recorder
        let document = viewer.documentView

        document.handleClick(at: textPoint(viewer, row: 0), modifiers: [])
        document.handleClick(at: textPoint(viewer, row: 2), modifiers: [.command])
        #expect(viewer.selectedRows == IndexSet([0, 2]))
        #expect(recorder.selections == [IndexSet([0]), IndexSet([0, 2])])

        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        document.copySelection(to: pasteboard)
        #expect(pasteboard.string(forType: .string) == "a\nc")
    }

    @Test func drawsOnlyVisibleRowsRequested() throws {
        let source = FakeSource(count: 100_000)
        let viewer = makeViewer(source)
        let document = viewer.documentView
        let rect = NSRect(x: 0, y: 0, width: 400, height: 10 * viewer.rowHeight)

        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 400, pixelsHigh: Int(rect.height.rounded(.up)),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let context = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        source.calls = 0
        document.draw(rect)
        NSGraphicsContext.restoreGraphicsState()

        #expect(source.calls >= 10)
        #expect(source.calls <= 20)
    }

    @Test func scrollSyncKeepsOffsetsEqual() {
        let leftSource = FakeSource(count: 1000)
        let rightSource = FakeSource(count: 1000)
        let left = makeViewer(leftSource)
        let right = makeViewer(rightSource)
        let sync = LineViewerScrollSync([left, right])

        left.scrollToRow(500)
        let expected = 500 * left.rowHeight
        #expect(left.scrollView.contentView.bounds.origin.y == expected)
        #expect(right.scrollView.contentView.bounds.origin.y == expected)

        right.scrollToRow(100)
        #expect(left.scrollView.contentView.bounds.origin.y == 100 * right.rowHeight)
        withExtendedLifetime((sync, leftSource, rightSource)) {}
    }
}
