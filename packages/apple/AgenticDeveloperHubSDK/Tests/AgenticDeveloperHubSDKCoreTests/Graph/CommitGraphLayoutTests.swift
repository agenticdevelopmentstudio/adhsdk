import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// Pins recipe `foundation/graph/commit-graph-layout`: every row's column, lane,
/// top and bottom segments and width, for each conformance vector.
@Suite("CommitGraphLayout")
struct CommitGraphLayoutTests {
    typealias Layout = CommitGraphLayout<String>

    private func seg(_ start: Int, _ end: Int, _ lane: Int) -> Layout.Segment {
        Layout.Segment(from: start, to: end, lane: lane)
    }

    private func row(
        _ column: Int, lane: Int, top: [Layout.Segment], bottom: [Layout.Segment], width: Int
    ) -> Layout.Row {
        Layout.Row(column: column, lane: lane, top: top, bottom: bottom, width: width)
    }

    private func layOut(_ nodes: [(id: String, parents: [String])]) -> [Layout.Row] {
        var layout = Layout()
        return layout.append(nodes)
    }

    @Test("a linear history stays in column 0 on one lane")
    func linearHistoryStaysInColumnZero() {
        let rows = layOut([("C", ["B"]), ("B", ["A"]), ("A", [])])
        #expect(rows == [
            row(0, lane: 0, top: [], bottom: [seg(0, 0, 0)], width: 1),
            row(0, lane: 0, top: [seg(0, 0, 0)], bottom: [seg(0, 0, 0)], width: 1),
            row(0, lane: 0, top: [seg(0, 0, 0)], bottom: [], width: 1)
        ])
    }

    @Test("a merge opens a lane for its second parent, which rejoins the first parent's slot")
    func branchAndMergeOpensAndClosesALane() {
        let rows = layOut([("M", ["A", "B"]), ("A", ["P"]), ("B", ["P"]), ("P", [])])
        #expect(rows == [
            row(0, lane: 0, top: [], bottom: [seg(0, 0, 0), seg(0, 1, 1)], width: 2),
            row(0, lane: 0, top: [seg(0, 0, 0), seg(1, 1, 1)], bottom: [seg(0, 0, 0), seg(1, 1, 1)], width: 2),
            row(1, lane: 1, top: [seg(0, 0, 0), seg(1, 1, 1)], bottom: [seg(0, 0, 0), seg(1, 0, 1)], width: 2),
            row(0, lane: 0, top: [seg(0, 0, 0)], bottom: [], width: 1)
        ])
    }

    @Test("a slot to the right expecting a commit closes into it at the commit's row")
    func laterSlotExpectingACommitClosesIntoIt() {
        let rows = layOut([("M", ["A", "B"]), ("B", ["P"]), ("A", ["P"]), ("P", [])])
        #expect(rows == [
            row(0, lane: 0, top: [], bottom: [seg(0, 0, 0), seg(0, 1, 1)], width: 2),
            row(1, lane: 1, top: [seg(0, 0, 0), seg(1, 1, 1)], bottom: [seg(0, 0, 0), seg(1, 1, 1)], width: 2),
            row(0, lane: 0, top: [seg(0, 0, 0), seg(1, 1, 1)], bottom: [seg(0, 0, 0), seg(1, 1, 1)], width: 2),
            row(0, lane: 0, top: [seg(0, 0, 0), seg(1, 0, 1)], bottom: [], width: 2)
        ])
    }

    @Test("an octopus merge opens a lane for each further parent")
    func octopusMergeOpensThreeLanes() {
        let rows = layOut([("O", ["A", "B", "C"]), ("A", ["R"]), ("B", ["R"]), ("C", ["R"]), ("R", [])])
        let three = [seg(0, 0, 0), seg(1, 1, 1), seg(2, 2, 2)]
        #expect(rows == [
            row(0, lane: 0, top: [], bottom: [seg(0, 0, 0), seg(0, 1, 1), seg(0, 2, 2)], width: 3),
            row(0, lane: 0, top: three, bottom: three, width: 3),
            row(1, lane: 1, top: three, bottom: [seg(0, 0, 0), seg(1, 0, 1), seg(2, 2, 2)], width: 3),
            row(2, lane: 2, top: [seg(0, 0, 0), seg(2, 2, 2)], bottom: [seg(0, 0, 0), seg(2, 0, 2)], width: 3),
            row(0, lane: 0, top: [seg(0, 0, 0)], bottom: [], width: 1)
        ])
    }

    @Test("a parent that never appears keeps its slot open, and lanes are never reused")
    func missingParentLeavesLaneOpenWithoutCrash() {
        let rows = layOut([("A", ["X"]), ("B", []), ("C", [])])
        #expect(rows == [
            row(0, lane: 0, top: [], bottom: [seg(0, 0, 0)], width: 1),
            row(1, lane: 1, top: [seg(0, 0, 0)], bottom: [seg(0, 0, 0)], width: 2),
            row(1, lane: 2, top: [seg(0, 0, 0)], bottom: [seg(0, 0, 0)], width: 2)
        ])
    }

    @Test("two roots both sit in column 0 once the first one's slot is trimmed")
    func twoRootsBothColumnZeroAfterTrim() {
        let rows = layOut([("A", []), ("B", [])])
        #expect(rows == [
            row(0, lane: 0, top: [], bottom: [], width: 1),
            row(0, lane: 1, top: [], bottom: [], width: 1)
        ])
    }

    @Test("appending 3 + 3 commits yields the rows of appending all 6 at once")
    func pagingMatchesOneShot() {
        let nodes: [(id: String, parents: [String])] = [
            ("M", ["A", "B"]), ("A", ["C"]), ("C", ["D"]), ("B", ["D"]), ("D", ["E"]), ("E", [])
        ]
        var paged = Layout()
        let first = paged.append(Array(nodes[0..<3]))
        let second = paged.append(Array(nodes[3..<6]))
        #expect(first.count == 3)
        #expect(second.count == 3)
        #expect(first + second == layOut(nodes))
        #expect(second.first == row(
            1, lane: 1, top: [seg(0, 0, 0), seg(1, 1, 1)], bottom: [seg(0, 0, 0), seg(1, 0, 1)], width: 2
        ))
    }
}
