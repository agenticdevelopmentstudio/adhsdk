import CoreGraphics

/// Where a split's dividers go when a run of its panes is given a new total
/// length and each keeps its share of the old one.
///
/// Pure arithmetic, apart from any view, so the rule a divider drag follows is
/// testable without a window (`ProportionalDividersTests`) and any split that
/// wants proportional resizing uses this one definition of it (`dry`).
public enum ProportionalDividers {

    /// The divider positions that give `oldThicknesses.count` panes, laid out
    /// from `start` and separated by `dividerThickness`, the length `available`
    /// in proportion to their old thicknesses.
    ///
    /// One position per divider *between* the panes (so `count - 1` of them),
    /// each measured from the split's origin, as `NSSplitView.setPosition`
    /// takes it. Empty when there is nothing to divide: fewer than two panes,
    /// no old length to take proportions from, or no room.
    public static func positions(
        oldThicknesses: [CGFloat],
        available: CGFloat,
        start: CGFloat,
        dividerThickness: CGFloat
    ) -> [CGFloat] {
        let oldTotal = oldThicknesses.reduce(0, +)
        guard oldThicknesses.count > 1, oldTotal > 0, available > 0 else { return [] }
        var positions: [CGFloat] = []
        var offset = start
        for old in oldThicknesses.dropLast() {
            offset += available * old / oldTotal
            positions.append(offset)
            offset += dividerThickness
        }
        return positions
    }
}
