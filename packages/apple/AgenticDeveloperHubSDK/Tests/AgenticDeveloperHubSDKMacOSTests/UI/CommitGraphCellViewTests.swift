import AppKit
import Testing
@testable import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKCore

private typealias Row = CommitGraphLayout<String>.Row
private typealias Segment = CommitGraphLayout<String>.Segment

@Suite("CommitGraphCellView")
@MainActor
struct CommitGraphCellViewTests {
    private func row(width: Int, parents: Int = 1) -> Row {
        Row(column: 0, lane: 0,
            top: [Segment(from: 0, to: 0, lane: 0)],
            bottom: (0..<parents).map { Segment(from: 0, to: $0, lane: $0) },
            width: width)
    }

    @Test("the intrinsic width is the row's width in 14 pt columns, and zero without a row")
    func widthFollowsRowWidth() {
        let cell = CommitGraphCellView()
        #expect(CommitGraphCellView.columnWidth == 14)
        #expect(cell.intrinsicContentSize.width == 0)
        #expect(cell.intrinsicContentSize.height == NSView.noIntrinsicMetric)
        cell.row = row(width: 3)
        #expect(cell.intrinsicContentSize.width == 42)
        cell.row = nil
        #expect(cell.intrinsicContentSize.width == 0)
    }

    @Test("lanes cycle ANSI slots 1…6 then 9…14")
    func laneColoursCycleANSI() {
        let theme = BuiltInThemes.dracula
        let palette = SemanticPalette(theme: theme)
        #expect(SemanticPalette.laneANSISlots == [1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14])
        for (lane, slot) in [(0, 1), (5, 6), (6, 9), (11, 14), (12, 1), (-1, 14)] {
            #expect(palette.laneColor(lane) == theme.ansi[slot])
        }
    }

    @Test("a theme without ANSI slots paints every lane in the accent colour")
    func laneColourFallsBackToAccent() {
        var theme = BuiltInThemes.dracula
        theme.ansi = []
        let palette = SemanticPalette(theme: theme)
        #expect(palette.laneColor(0) == palette.color(.accent))
        #expect(palette.laneColor(7) == palette.color(.accent))
    }

    @Test("a merge is a row with two or more parent edges leaving the commit's column")
    func mergeDetection() {
        #expect(!CommitGraphCellView.isMerge(row(width: 1, parents: 0)))
        #expect(!CommitGraphCellView.isMerge(row(width: 1, parents: 1)))
        #expect(CommitGraphCellView.isMerge(row(width: 2, parents: 2)))
        // A pass-through line in another column is not a parent edge.
        let passing = Row(column: 0, lane: 0, top: [],
                          bottom: [Segment(from: 0, to: 0, lane: 0), Segment(from: 1, to: 1, lane: 1)], width: 2)
        #expect(!CommitGraphCellView.isMerge(passing))
    }

    @Test("a commit's node is filled and a merge's is a hollow ring")
    func nodeFillAndRing() throws {
        func centreAlpha(_ row: Row) throws -> CGFloat {
            let cell = CommitGraphCellView(frame: NSRect(x: 0, y: 0, width: 28, height: 20))
            cell.row = row
            let rep = try #require(cell.bitmapImageRepForCachingDisplay(in: cell.bounds))
            cell.cacheDisplay(in: cell.bounds, to: rep)
            let scale = CGFloat(rep.pixelsWide) / cell.bounds.width
            let colour = try #require(rep.colorAt(x: Int(7 * scale), y: Int(10 * scale)))
            return colour.alphaComponent
        }
        // Lines run into the merge's centre from above and below; they must
        // stop at the ring, so the centre stays unpainted.
        let commit = Row(column: 0, lane: 0, top: [], bottom: [], width: 1)
        let merge = Row(column: 0, lane: 0, top: [Segment(from: 0, to: 0, lane: 0)],
                        bottom: [Segment(from: 0, to: 1, lane: 1), Segment(from: 0, to: 1, lane: 2)], width: 2)
        #expect(try centreAlpha(commit) > 0.9)
        #expect(try centreAlpha(merge) < 0.1)
    }

    @Test("carries an accessibility identifier")
    func accessibilityIdentifier() {
        #expect(CommitGraphCellView().accessibilityIdentifier() == "commitGraph.cell")
    }
}
