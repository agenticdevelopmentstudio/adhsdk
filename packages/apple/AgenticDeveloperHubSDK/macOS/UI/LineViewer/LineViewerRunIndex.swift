import Foundation

/// A long row's runs, indexed once so that each frame finds the runs that
/// overlap a UTF-16 range without walking the others. Runs may overlap and
/// may come in any order.
///
/// The row's non-empty clipped runs are sorted by `range.location`; a bisection
/// finds the first run that starts at or after the range's end, and a max-tree
/// over the sorted runs' `range.upperBound` (each node holds the furthest
/// reach of the runs beneath it) skips every subtree whose runs all end at or
/// before the range's start. A query costs O(log n) per overlapping run,
/// however many runs the row has and however long they are: a running maximum
/// alone would let one run spanning the row make every query walk from it.
struct LineViewerRunIndex {
    /// Positions in the row's `runs` of its non-empty clipped runs, sorted by
    /// clipped location (ties in the row's order).
    private let order: [Int32]
    /// Each sorted run's clipped location.
    private let starts: [Int]
    /// The max-tree: the sorted runs' clipped upper bounds at `leafBase + i`,
    /// each node above the larger of its two children; node 1 is the root.
    private let reach: [Int]
    private let leafBase: Int

    /// How many non-empty runs the index holds.
    var count: Int { order.count }

    init(runs: [LineViewerRun], length: Int) {
        var entries: [(start: Int, end: Int, position: Int)] = []
        entries.reserveCapacity(runs.count)
        for (position, run) in runs.enumerated() {
            let range = Self.clip(run.range, to: length)
            if range.length > 0 { entries.append((range.location, NSMaxRange(range), position)) }
        }
        entries.sort { ($0.start, $0.position) < ($1.start, $1.position) }

        var base = 1
        while base < entries.count { base *= 2 }
        var tree = [Int](repeating: Int.min, count: 2 * base)
        for (slot, entry) in entries.enumerated() { tree[base + slot] = entry.end }
        for node in stride(from: base - 1, through: 1, by: -1) {
            tree[node] = max(tree[2 * node], tree[2 * node + 1])
        }
        order = entries.map { Int32($0.position) }
        starts = entries.map(\.start)
        reach = tree
        leafBase = base
    }

    /// The positions in the row's `runs` of every run whose clipped range
    /// overlaps `lower..<upper`, in the row's order (so later runs still win
    /// where runs overlap, as on the short-row path).
    func runs(overlapping lower: Int, _ upper: Int) -> [Int] {
        guard lower < upper, !order.isEmpty else { return [] }
        // The first sorted run that starts at or after `upper`; none from it on can overlap.
        var low = 0
        var high = starts.count
        while low < high {
            let mid = (low + high) / 2
            if starts[mid] >= upper { high = mid } else { low = mid + 1 }
        }
        var hits: [Int] = []
        collect(node: 1, first: 0, past: leafBase, before: low, reaching: lower, into: &hits)
        hits.sort()
        return hits
    }

    /// Appends every run under `node` (sorted slots `first..<past`) that sits
    /// before slot `end` and ends after `lower`.
    private func collect(node: Int, first: Int, past: Int, before end: Int, reaching lower: Int,
                         into hits: inout [Int]) {
        guard first < end, reach[node] > lower else { return }
        if node >= leafBase {
            hits.append(Int(order[node - leafBase]))
            return
        }
        let mid = (first + past) / 2
        collect(node: 2 * node, first: first, past: mid, before: end, reaching: lower, into: &hits)
        collect(node: 2 * node + 1, first: mid, past: past, before: end, reaching: lower, into: &hits)
    }

    /// `range` clamped to a text of `length` UTF-16 units.
    static func clip(_ range: NSRange, to length: Int) -> NSRange {
        let start = min(max(0, range.location), length)
        let end = min(max(start, range.location + range.length), length)
        return NSRange(location: start, length: end - start)
    }
}
