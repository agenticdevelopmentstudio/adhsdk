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

    /// Serves fixed rows and supplies its own gutter column widths.
    @MainActor
    private final class WidthSource: LineViewerDataSource {
        let rows: [LineViewerRow]
        let widths: [Int]
        var gutterColumnCount: Int { widths.count }
        var rowCount: Int { rows.count }

        init(rows: [LineViewerRow], widths: [Int]) {
            self.rows = rows
            self.widths = widths
        }

        func row(at index: Int) -> LineViewerRow { rows[index] }
        func gutterColumnWidth(_ column: Int) -> Int { widths[column] }
    }

    /// The viewer holds its data source weakly, so each test keeps `source` alive.
    private func makeViewer(_ source: LineViewerDataSource) -> LineViewerViewController {
        let viewer = LineViewerViewController(identifier: "test.lineViewer")
        viewer.view.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        viewer.view.layoutSubtreeIfNeeded()
        viewer.dataSource = source
        viewer.reloadData()
        return viewer
    }

    /// Draws `rect` of `document` into a bitmap of the same size.
    private func draw(_ document: LineViewerView, _ rect: NSRect) throws {
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(rect.width.rounded(.up)), pixelsHigh: Int(rect.height.rounded(.up)),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let context = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        document.draw(rect)
        NSGraphicsContext.restoreGraphicsState()
    }

    /// The distinct pixel colours of `view` inside `rect` (view coordinates).
    private func colours(of view: NSView, in rect: NSRect) throws -> Set<String> {
        let rep = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: rep)
        let scale = CGFloat(rep.pixelsWide) / view.bounds.width
        var seen = Set<String>()
        let flippedTop = view.isFlipped ? rect.minY : view.bounds.height - rect.maxY
        for pixelY in Int(flippedTop * scale)..<Int((flippedTop + rect.height) * scale) {
            for pixelX in Int(rect.minX * scale)..<Int(rect.maxX * scale) {
                if let colour = rep.colorAt(x: pixelX, y: pixelY) { seen.insert(colour.description) }
            }
        }
        return seen
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
        #expect(viewer.documentView.gutterView.accessibilityIdentifier() == "test.lineViewer.gutter")
        // Default gutter width: max(3, digits of rowCount) characters plus one of padding each side.
        let charWidth = viewer.documentView.charWidth
        #expect(viewer.documentView.gutterColumnFrame(0).width == 5 * charWidth)
        #expect(viewer.documentView.gutterColumnFrame(1).minX == 5 * charWidth)
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

    @Test func longLineDrawsOnlyTheGlyphsUnderTheRect() throws {
        // One non-ASCII character sends the row down the cached-layout path.
        let line = String(repeating: "x", count: 999_999) + "\u{E9}"
        let source = FakeSource(rows: [LineViewerRow(text: line)])
        let viewer = makeViewer(source)
        let document = viewer.documentView

        try draw(document, NSRect(x: 0, y: 0, width: 400, height: viewer.rowHeight))
        #expect(document.drawnGlyphCount > 0)
        #expect(document.drawnGlyphCount < 1000)
        #expect(document.cachedLineCount == 1)

        // Far along the line: still only the glyphs under the rect, from the same cached layout.
        let farX = document.textOriginX + 600_000 * document.charWidth
        try draw(document, NSRect(x: farX, y: 0, width: 400, height: viewer.rowHeight))
        #expect(document.drawnGlyphCount > 0)
        #expect(document.drawnGlyphCount < 1000)
        #expect(document.cachedLineCount == 1)

        viewer.reloadData()
        #expect(document.cachedLineCount == 0)
        withExtendedLifetime(source) {}
    }

    /// Draws each of `rects` of `document`, clipped to it as AppKit clips a
    /// dirty rect, into one `width`-wide, one-row bitmap, and returns its bytes.
    private func render(_ document: LineViewerView, width: Int, height: CGFloat, rects: [NSRect]) throws -> Data {
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: Int(height.rounded(.up)),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let context = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        for rect in rects {
            context.cgContext.saveGState()
            context.cgContext.clip(to: rect)
            document.draw(rect)
            context.cgContext.restoreGState()
        }
        NSGraphicsContext.restoreGraphicsState()
        let data = try #require(bitmap.bitmapData)
        return Data(bytes: data, count: bitmap.bytesPerRow * bitmap.pixelsHigh)
    }

    @Test func longLineWithWideCharactersDrawsTheSameSplitOrWhole() throws {
        // Tabs, a CJK ideograph and an emoji (a surrogate pair) all advance more than one column.
        let line = String(repeating: "ab\tc\u{4E2D}d\u{1F600}ef", count: 300)
        #expect((line as NSString).length > 2000)
        let source = FakeSource(rows: [LineViewerRow(
            text: line, runs: [LineViewerRun(range: NSRange(location: 40, length: 200), fontStyle: .underline)])])
        let viewer = makeViewer(source)
        let document = viewer.documentView
        let height = viewer.rowHeight

        let whole = try render(document, width: 900, height: height,
                               rects: [NSRect(x: 0, y: 0, width: 900, height: height)])
        // Seams that fall at different points of the repeating pattern.
        let split = try render(document, width: 900, height: height, rects: [
            NSRect(x: 0, y: 0, width: 333, height: height),
            NSRect(x: 333, y: 0, width: 284, height: height),
            NSRect(x: 617, y: 0, width: 283, height: height)
        ])
        #expect(Set(whole).count > 1)
        #expect(split == whole)
        #expect(document.cachedLineCount == 1)
        withExtendedLifetime(source) {}
    }

    @Test func longAsciiLineIsSlicedWithoutALayout() throws {
        let line = String(repeating: "x", count: 1_000_000)
        let source = FakeSource(rows: [LineViewerRow(text: line)])
        let viewer = makeViewer(source)
        let document = viewer.documentView

        for originX in [0, document.textOriginX + 600_000 * document.charWidth] {
            try draw(document, NSRect(x: originX, y: 0, width: 400, height: viewer.rowHeight))
            #expect(document.drawnGlyphCount > 0)
            #expect(document.drawnGlyphCount < 1000)
        }
        #expect(document.longLayoutBuildCount == 0)
        #expect(document.cachedLineCount == 0)
        withExtendedLifetime(source) {}
    }

    @Test func longAsciiLineDrawsTheSameSplitOrWhole() throws {
        // Printable ASCII with bold, italic, underline, highlight and strikethrough runs: the sliced path.
        let line = String(repeating: "func a(b: Int) -> [C] { return d && e || f } // g; ", count: 50)
        #expect((line as NSString).length > 2000)
        let source = FakeSource(rows: [LineViewerRow(text: line, runs: [
            LineViewerRun(range: NSRange(location: 0, length: 4), fontStyle: .bold),
            LineViewerRun(range: NSRange(location: 30, length: 70), fontStyle: [.italic, .underline]),
            LineViewerRun(range: NSRange(location: 120, length: 9), highlight: .emphasis),
            LineViewerRun(range: NSRange(location: 140, length: 20), fontStyle: .strikethrough)
        ])])
        let viewer = makeViewer(source)
        let document = viewer.documentView
        let height = viewer.rowHeight

        let whole = try render(document, width: 900, height: height,
                               rects: [NSRect(x: 0, y: 0, width: 900, height: height)])
        let split = try render(document, width: 900, height: height, rects: [
            NSRect(x: 0, y: 0, width: 333, height: height),
            NSRect(x: 333, y: 0, width: 284, height: height),
            NSRect(x: 617, y: 0, width: 283, height: height)
        ])
        #expect(Set(whole).count > 1)
        #expect(split == whole)
        #expect(document.longLayoutBuildCount == 0)
        withExtendedLifetime(source) {}
    }

    /// A viewer tall enough to show `rows` rows at once, and the rect covering them.
    private func tallViewer(_ source: LineViewerDataSource, rows: Int) -> (LineViewerViewController, NSRect) {
        let viewer = makeViewer(source)
        viewer.view.frame = NSRect(x: 0, y: 0, width: 400, height: CGFloat(rows + 2) * viewer.rowHeight)
        viewer.view.layoutSubtreeIfNeeded()
        return (viewer, NSRect(x: 0, y: 0, width: 400, height: CGFloat(rows) * viewer.rowHeight))
    }

    @Test func manyVisibleLongAsciiRowsRedrawWithoutLayout() throws {
        let rows = (0..<30).map { LineViewerRow(text: String(repeating: "row \($0) text; ", count: 400)) }
        let source = FakeSource(rows: rows)
        let (viewer, rect) = tallViewer(source, rows: 30)
        let document = viewer.documentView

        try draw(document, rect)
        try draw(document, rect)
        #expect(document.longLayoutBuildCount == 0)
        #expect(document.cachedLineCount == 0)
        withExtendedLifetime(source) {}
    }

    @Test func manyVisibleLongNonAsciiRowsRedrawFromTheCache() throws {
        let rows = (0..<30).map {
            LineViewerRow(text: String(repeating: "r\($0)\tc\u{4E2D}d\u{1F600}; ", count: 200))
        }
        let source = FakeSource(rows: rows)
        let (viewer, rect) = tallViewer(source, rows: 30)
        let document = viewer.documentView

        try draw(document, rect)
        let built = document.longLayoutBuildCount
        #expect(built == 30)
        try draw(document, rect)
        #expect(document.longLayoutBuildCount == built)
        #expect(document.cachedLineCount == 30)
        withExtendedLifetime(source) {}
    }

    @Test func cacheTrimsBackToCapacityAfterAFrameBeyondIt() throws {
        // A 300 pt viewer caches about 2 x 17 rows; one dirty rect of 60 rows keeps them all while it draws.
        let rows = (0..<60).map {
            LineViewerRow(text: String(repeating: "r\($0)\tc\u{4E2D}d\u{1F600}; ", count: 200))
        }
        let source = FakeSource(rows: rows)
        let viewer = makeViewer(source)
        let document = viewer.documentView
        let rect = NSRect(x: 0, y: 0, width: 400, height: 60 * viewer.rowHeight)

        try draw(document, rect)
        #expect(document.longLayoutBuildCount == 60)
        #expect(document.lineCacheCapacity < 60)
        #expect(document.cachedLineCount == document.lineCacheCapacity)
        withExtendedLifetime(source) {}
    }

    @Test func cacheTrimsBackToItsUnitBudgetAfterAFrameBeyondIt() throws {
        let rows = (0..<10).map {
            LineViewerRow(text: String(repeating: "r\($0)\tc\u{4E2D}d\u{1F600}; ", count: 200))
        }
        let source = FakeSource(rows: rows)
        let viewer = makeViewer(source)
        let document = viewer.documentView
        let rowLength = (rows[0].text as NSString).length
        document.lineCacheUnitBudget = 3 * rowLength + 1

        try draw(document, NSRect(x: 0, y: 0, width: 400, height: 10 * viewer.rowHeight))
        #expect(document.longLayoutBuildCount == 10)
        #expect(document.cachedUnitCount <= document.lineCacheUnitBudget)
        #expect(document.cachedLineCount == 3)
        withExtendedLifetime(source) {}
    }

    /// Runs `width` units wide across `length` units in two alternating colours,
    /// and over them one bold run across the whole row and one highlight run
    /// across its middle half: they overlap the rest.
    private func denseRuns(length: Int, width: Int) -> [LineViewerRun] {
        let colours = [RGBAColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1),
                       RGBAColor(red: 0.1, green: 0.1, blue: 0.8, alpha: 1)]
        var runs = [LineViewerRun(range: NSRange(location: 0, length: length), fontStyle: .bold)]
        runs.reserveCapacity(length / width + 2)
        for start in stride(from: 0, to: length, by: width) {
            runs.append(LineViewerRun(range: NSRange(location: start, length: min(width, length - start)),
                                      foreground: colours[(start / width) % 2]))
        }
        runs.append(LineViewerRun(range: NSRange(location: length / 4, length: length / 2), highlight: .emphasis))
        return runs
    }

    @Test func longAsciiRowFrameTouchesOnlyTheRunsUnderTheRect() throws {
        let length = 1_000_000
        let runs = denseRuns(length: length, width: 10)
        #expect(runs.count >= 100_000)
        let source = FakeSource(rows: [LineViewerRow(text: String(repeating: "x", count: length), runs: runs)])
        let viewer = makeViewer(source)
        let document = viewer.documentView

        for column in [0, 600_000] {
            let originX = column == 0 ? 0 : document.textOriginX + CGFloat(column) * document.charWidth
            try draw(document, NSRect(x: originX, y: 0, width: 400, height: viewer.rowHeight))
            #expect(document.drawnGlyphCount > 0)
            #expect(document.runsTouchedLastFrame > 0)
            #expect(document.runsTouchedLastFrame <= 16)
        }
        #expect(document.longLayoutBuildCount == 0)
        withExtendedLifetime(source) {}
    }

    @Test func longCachedRowFrameTouchesOnlyTheRunsUnderTheRect() throws {
        // The trailing non-ASCII character sends the row down the cached-layout path.
        let length = 300_000
        let runs = denseRuns(length: length, width: 3)
        #expect(runs.count >= 100_000)
        let text = String(repeating: "x", count: length - 1) + "\u{E9}"
        let source = FakeSource(rows: [LineViewerRow(text: text, runs: runs)])
        let viewer = makeViewer(source)
        let document = viewer.documentView

        for column in [0, 200_000] {
            let originX = column == 0 ? 0 : document.textOriginX + CGFloat(column) * document.charWidth
            try draw(document, NSRect(x: originX, y: 0, width: 400, height: viewer.rowHeight))
            #expect(document.drawnGlyphCount > 0)
            #expect(document.runsTouchedLastFrame > 0)
            #expect(document.runsTouchedLastFrame <= 40)
        }
        #expect(document.longLayoutBuildCount == 1)
        withExtendedLifetime(source) {}
    }

    @Test(arguments: ["", "\u{E9}"])
    func overlappingRunsAcrossSeamsDrawTheSameSplitOrWhole(tail: String) throws {
        // Overlapping runs, given out of order, whose edges fall either side of the seams at 333 and 617 pt.
        let line = String(repeating: "func a(b: Int) -> [C] { return d && e || f } // g; ", count: 50) + tail
        #expect((line as NSString).length > 2000)
        let source = FakeSource(rows: [LineViewerRow(text: line, runs: [
            LineViewerRun(range: NSRange(location: 20, length: 120), foreground: RGBAColor(red: 0.9, green: 0.2,
                                                                                          blue: 0.2, alpha: 1),
                          fontStyle: .strikethrough),
            LineViewerRun(range: NSRange(location: 0, length: 200), highlight: .emphasis),
            LineViewerRun(range: NSRange(location: 30, length: 60), fontStyle: [.bold, .underline]),
            LineViewerRun(range: NSRange(location: 70, length: 50), fontStyle: .italic, highlight: .added),
            LineViewerRun(range: NSRange(location: 40, length: 2000), foreground: RGBAColor(red: 0.2, green: 0.6,
                                                                                           blue: 0.2, alpha: 1))
        ])])
        let viewer = makeViewer(source)
        let document = viewer.documentView
        let height = viewer.rowHeight

        let whole = try render(document, width: 900, height: height,
                               rects: [NSRect(x: 0, y: 0, width: 900, height: height)])
        let split = try render(document, width: 900, height: height, rects: [
            NSRect(x: 0, y: 0, width: 333, height: height),
            NSRect(x: 333, y: 0, width: 284, height: height),
            NSRect(x: 617, y: 0, width: 283, height: height)
        ])
        #expect(Set(whole).count > 1)
        #expect(split == whole)
        #expect(document.longLayoutBuildCount == (tail.isEmpty ? 0 : 1))
        withExtendedLifetime(source) {}
    }

    @Test func gutterColumnsHonourSuppliedWidthsAndClipWideValues() throws {
        let source = WidthSource(
            rows: [LineViewerRow(text: "a", gutter: ["0123456789ABCDEFGHIJKLMNOP", nil])],
            widths: [8, 4])
        let viewer = makeViewer(source)
        let document = viewer.documentView
        let charWidth = document.charWidth
        let first = document.gutterColumnFrame(0)
        let second = document.gutterColumnFrame(1)
        #expect(first.minX == 0)
        #expect(first.width == 10 * charWidth)
        #expect(second.minX == first.maxX)
        #expect(second.width == 6 * charWidth)

        let row = NSRect(x: 0, y: 0, width: 1, height: viewer.rowHeight)
        let gutter = document.gutterView
        #expect(try colours(of: gutter, in: NSRect(x: first.minX, y: 0, width: first.width, height: row.height))
            .count > 1)
        // The 26-character value is clipped to its 8-character column: nothing spills into the next one.
        #expect(try colours(of: gutter, in: NSRect(x: second.minX, y: 0, width: second.width - 1,
                                                    height: row.height)).count == 1)
        withExtendedLifetime(source) {}
    }

    @Test func gutterStaysPinnedDuringHorizontalScroll() {
        let source = FakeSource(count: 50)
        let viewer = makeViewer(source)
        let recorder = Recorder()
        viewer.delegate = recorder
        let document = viewer.documentView
        document.setFrameSize(NSSize(width: 5000, height: document.frame.height))
        #expect(document.gutterView.frame.minX == 0)

        let clip = viewer.scrollView.contentView
        clip.scroll(to: NSPoint(x: 300, y: 0))
        viewer.scrollView.reflectScrolledClipView(clip)
        #expect(clip.bounds.minX == 300)
        #expect(document.gutterView.frame.minX == document.visibleRect.minX)
        #expect(document.gutterView.frame.minX == 300)
        #expect(document.gutterView.frame.width > 0)

        // A click on the pinned gutter is a gutter click, not a text click.
        document.handleClick(at: NSPoint(x: 300 + document.charWidth, y: viewer.rowHeight / 2), modifiers: [])
        #expect(recorder.gutterClicks.count == 1)
        #expect(recorder.gutterClicks.first?.column == 0)
        #expect(viewer.selectedRows.isEmpty)
        withExtendedLifetime(source) {}
    }
}
