import Foundation

/// Lane layout for a commit history's graph column (recipe
/// `foundation/graph/commit-graph-layout`).
///
/// Append commits newest first, a page at a time; each returned `Row` gives the
/// commit's column, its lane (a colour index that only ever increases, which a
/// view takes modulo its palette) and the segments to draw from the row's top
/// edge to the commit's centre and from the centre to the bottom edge. The
/// layout keeps its open slots and lane counter between calls, so paging yields
/// the same rows as one append, and rows already returned are never revised.
public struct CommitGraphLayout<ID: Hashable & Sendable>: Sendable {
    /// A line between two columns; `lane` is its colour index.
    public struct Segment: Sendable, Hashable {
        public let from: Int
        public let to: Int // swiftlint:disable:this identifier_name
        public let lane: Int

        public init(from: Int, to: Int, lane: Int) { // swiftlint:disable:this identifier_name
            self.from = from
            self.to = to
            self.lane = lane
        }
    }

    public struct Row: Sendable, Hashable {
        public let column: Int
        public let lane: Int
        /// Row top edge → centre: one per slot open at the top, in column order.
        public let top: [Segment]
        /// Centre → row bottom edge, sorted by `from`, then `to`.
        public let bottom: [Segment]
        /// Columns occupied in this row.
        public let width: Int

        public init(column: Int, lane: Int, top: [Segment], bottom: [Segment], width: Int) {
            self.column = column
            self.lane = lane
            self.top = top
            self.bottom = bottom
            self.width = width
        }
    }

    /// An open slot: the commit it waits for and the lane it carries.
    private struct Slot: Sendable {
        let expects: ID
        let lane: Int
    }

    private var slots: [Slot?] = []
    private var nextLane = 0

    public init() {}

    /// Lays out `nodes` (newest first) and returns their rows, in order.
    public mutating func append(_ nodes: [(id: ID, parents: [ID])]) -> [Row] {
        nodes.map { layOut(id: $0.id, parents: $0.parents) }
    }

    private mutating func layOut(id: ID, parents: [ID]) -> Row {
        let topWidth = slots.count
        let expecting = slots.indices.filter { slots[$0]?.expects == id }
        let column: Int
        let lane: Int
        if let first = expecting.first, let slot = slots[first] {
            column = first
            lane = slot.lane
        } else {
            column = slots.firstIndex { $0 == nil } ?? slots.count
            lane = openLane()
            if column == slots.count { slots.append(nil) }
        }

        let top = slots.indices.compactMap { index -> Segment? in
            guard let slot = slots[index] else { return nil }
            return Segment(from: index, to: slot.expects == id ? column : index, lane: slot.lane)
        }

        for index in expecting { slots[index] = nil }
        var bottom = slots.indices.compactMap { index -> Segment? in
            slots[index].map { Segment(from: index, to: index, lane: $0.lane) }
        }

        if let firstParent = parents.first {
            let target = min(column, leftmostSlot(expecting: firstParent) ?? column)
            if target == column { slots[column] = Slot(expects: firstParent, lane: lane) }
            bottom.append(Segment(from: column, to: target, lane: lane))
        }
        for parent in parents.dropFirst() {
            let target: Int
            if let existing = leftmostSlot(expecting: parent) {
                target = existing
            } else {
                target = slots.firstIndex { $0 == nil } ?? slots.count
                if target == slots.count { slots.append(nil) }
                slots[target] = Slot(expects: parent, lane: openLane())
            }
            bottom.append(Segment(from: column, to: target, lane: slots[target]?.lane ?? lane))
        }

        while let last = slots.last, last == nil { slots.removeLast() }
        bottom.sort { ($0.from, $0.to) < ($1.from, $1.to) }
        return Row(
            column: column, lane: lane, top: top, bottom: bottom,
            width: max(topWidth, slots.count, column + 1)
        )
    }

    private func leftmostSlot(expecting id: ID) -> Int? {
        slots.firstIndex { $0?.expects == id }
    }

    private mutating func openLane() -> Int {
        defer { nextLane += 1 }
        return nextLane
    }
}
