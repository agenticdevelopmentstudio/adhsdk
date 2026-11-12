import Foundation

/// Two pane types a layout keeps together: wherever a `primary` is, a
/// `sibling` sits against one of its edges.
///
/// Declared on the layout spec rather than stored per tree, because it names
/// *types*, not leaves: it then holds in every tab and window built from that
/// spec, survives `reshaped(toMatch:)` and mirroring (which rebuild ids), and
/// needs no schema change.
public struct ComposableTabsPaneRelationship: Sendable, Equatable {

    /// Which edge of the primary the sibling is pinned to. One case per edge,
    /// so a relationship cannot pin two.
    public enum Pin: Sendable, Hashable {
        /// `[a][b]`: the sibling's leading edge on the primary's trailing one.
        case siblingAfterPrimary
        /// `[b][a]`: the sibling's trailing edge on the primary's leading one.
        case siblingBeforePrimary
        /// `b` over `a`: the sibling's bottom on the primary's top.
        case siblingAbovePrimary
        /// `a` over `b`: the sibling's top on the primary's bottom.
        case siblingBelowPrimary

        /// The axis the two panes sit along.
        public var axis: ComposableTabsAxis {
            switch self {
            case .siblingAfterPrimary, .siblingBeforePrimary: return .horizontal
            case .siblingAbovePrimary, .siblingBelowPrimary: return .vertical
            }
        }

        /// Whether the sibling is the first of the two in reading order.
        var siblingFirst: Bool {
            self == .siblingBeforePrimary || self == .siblingAbovePrimary
        }
    }

    /// An outer edge both panes must reach, across the pin's axis.
    public enum Edge: Sendable, Hashable {
        case top, bottom, leading, trailing

        /// The axis whose splits decide whether a pane reaches this edge.
        var axis: ComposableTabsAxis {
            switch self {
            case .top, .bottom: return .vertical
            case .leading, .trailing: return .horizontal
            }
        }

        /// Reaching the edge means taking this child at every split on `axis`.
        var childIndex: Int {
            switch self {
            case .top, .leading: return 0
            case .bottom, .trailing: return 1
            }
        }
    }

    public let primary: ComposableTabsViewID
    public let sibling: ComposableTabsViewID
    public let pin: Pin
    public let aligned: Set<Edge>

    /// Fails fast on an alignment the pin cannot mean: top or bottom edges only
    /// line up for panes side by side, leading or trailing only for panes one
    /// over the other (`fail-fast` — a spec is built once, at launch).
    public init(
        primary: ComposableTabsViewID,
        sibling: ComposableTabsViewID,
        pin: Pin,
        aligned: Set<Edge> = []
    ) {
        precondition(
            aligned.allSatisfy { $0.axis != pin.axis },
            "a \(pin) relationship cannot align \(aligned)"
        )
        self.primary = primary
        self.sibling = sibling
        self.pin = pin
        self.aligned = aligned
    }
}

/// The relationships of one layout spec, and the pure tree arithmetic that
/// keeps a `LayoutNode` true to them.
///
/// Beside `ComposableTabsMove` and in the same style: no view controllers, so
/// the rule that greys an arrow and the rule that performs the move are one
/// piece of code (`dry`).
public struct ComposableTabsPaneRelationships: Sendable {

    public typealias Direction = ComposableTabsViewController.Direction

    public let all: [ComposableTabsPaneRelationship]

    public init(_ all: [ComposableTabsPaneRelationship]) {
        self.all = all
    }

    // MARK: - Questions

    /// Whether every relationship holds wherever both of its panes are
    /// present: each primary has a sibling pinned to it, as far as there are
    /// siblings to go round.
    public func satisfies(_ tree: LayoutNode) -> Bool {
        all.allSatisfy { relationship in
            let matching = Self.match(relationship, in: tree)
            return matching.pairs.count == min(matching.primaryCount, matching.siblingCount)
        }
    }

    /// Whether `contentType` is placed by a relationship rather than by the
    /// user — the pane whose close, minimize, zoom and move are disabled.
    public func isManagedSibling(_ contentType: ComposableTabsViewID) -> Bool {
        all.contains { $0.sibling == contentType }
    }

    /// The sibling pinned to the primary `primaryID`, when there is one.
    public func sibling(of primaryID: UUID, in tree: LayoutNode) -> UUID? {
        for relationship in all {
            if let pair = Self.match(relationship, in: tree).pairs.first(where: { $0.primary == primaryID }) {
                return pair.sibling
            }
        }
        return nil
    }

    /// When a relationship holds for `primaryID`, the id of the lowest common
    /// ancestor of it and its sibling: the subtree that moves as one.
    public func unit(of primaryID: UUID, in tree: LayoutNode) -> UUID? {
        guard let siblingID = sibling(of: primaryID, in: tree) else { return nil }
        return Self.lowestCommonAncestor(primaryID, siblingID, in: tree)?.id
    }

    /// `tree` without `leafID` and, when it is a primary, without its sibling
    /// too — closing a primary takes the pane it keeps with it. `nil` when
    /// nothing would be left.
    public func removing(_ leafID: UUID, from tree: LayoutNode) -> LayoutNode? {
        let siblingID = sibling(of: leafID, in: tree)
        guard let without = ComposableTabsMove.removing(leafID, from: tree) else { return nil }
        guard let siblingID else { return without }
        return ComposableTabsMove.removing(siblingID, from: without)
    }

    // MARK: - Repair

    /// `tree` repaired to satisfy every relationship.
    ///
    /// For each primary: a sibling that is absent is added and one that is
    /// misplaced is detached and re-attached, both in the canonical placement
    /// (`pair(primary, sibling)` in pin order), which satisfies the pin and
    /// every alignment. A re-attached leaf keeps its id, so the live pane is
    /// reused. A sibling is added only while the spec admits it (its `max`
    /// still applies). A sibling left over — no primary, or more siblings than
    /// primaries — gets a new primary beside it, in the same canonical
    /// placement, so the pane and whatever it holds survive; only when the
    /// spec will not admit another primary is the sibling removed, because
    /// nothing would ever let it close.
    ///
    /// Run by `reconcile` at load and after every insertion, so a pane added
    /// beside a primary lands after the pair, never inside it.
    public func normalized(_ tree: LayoutNode, spec: ComposableTabLayoutSpec) -> LayoutNode {
        var tree = tree
        for relationship in all {
            tree = Self.normalized(tree, for: relationship, spec: spec)
        }
        return tree
    }

    private static func normalized(
        _ tree: LayoutNode,
        for relationship: ComposableTabsPaneRelationship,
        spec: ComposableTabLayoutSpec
    ) -> LayoutNode {
        var tree = tree
        let matching = match(relationship, in: tree)
        var spare = matching.unmatchedSiblings
        for primaryID in matching.unmatchedPrimaries {
            if let siblingID = spare.first {
                spare.removeFirst()
                guard let sibling = ComposableTabsMove.leaf(siblingID, in: tree),
                      let detached = ComposableTabsMove.removing(siblingID, from: tree) else { continue }
                tree = attaching(sibling, to: primaryID, relationship, in: detached)
            } else {
                let candidate = attaching(
                    .leaf(contentType: relationship.sibling), to: primaryID, relationship, in: tree)
                if spec.admitsEveryLeaf(candidate) { tree = candidate }
            }
        }
        for orphan in spare {
            // The orphan's primary comes back beside it, so a saved layout
            // with Documents open and no File Browser keeps its open tabs.
            // Only when the spec will not take another primary does the
            // orphan go; a tree of nothing but orphans then starts over, as a
            // tree of nothing but retired views does.
            let candidate = pairing(.leaf(contentType: relationship.primary), with: orphan, relationship, in: tree)
            if spec.admitsEveryLeaf(candidate) {
                tree = candidate
            } else {
                tree = ComposableTabsMove.removing(orphan, from: tree) ?? spec.blueprint()
            }
        }
        return tree
    }

    /// The sibling's slot, now holding `primary` and the sibling in canonical
    /// placement — `attaching` seen from the other side.
    private static func pairing(
        _ primary: LayoutNode,
        with siblingID: UUID,
        _ relationship: ComposableTabsPaneRelationship,
        in tree: LayoutNode
    ) -> LayoutNode {
        replacing(siblingID, in: tree) { sibling in
            var primary = primary, sibling = sibling
            let slot = sibling
            primary.thicknessFraction = nil
            sibling.thicknessFraction = nil
            let siblingFirst = relationship.pin.siblingFirst
            return LayoutNode.split(
                orientation: relationship.pin.axis,
                first: siblingFirst ? sibling : primary,
                second: siblingFirst ? primary : sibling
            ).occupying(slot)
        }
    }

    /// The primary's slot, now holding the primary and `sibling` in canonical
    /// placement.
    private static func attaching(
        _ sibling: LayoutNode,
        to primaryID: UUID,
        _ relationship: ComposableTabsPaneRelationship,
        in tree: LayoutNode
    ) -> LayoutNode {
        replacing(primaryID, in: tree) { primary in
            var primary = primary, sibling = sibling
            // A fraction is a share of one split; the new one has none yet.
            let slot = primary
            primary.thicknessFraction = nil
            sibling.thicknessFraction = nil
            let siblingFirst = relationship.pin.siblingFirst
            return LayoutNode.split(
                orientation: relationship.pin.axis,
                first: siblingFirst ? sibling : primary,
                second: siblingFirst ? primary : sibling
            ).occupying(slot)
        }
    }

    // MARK: - Moving

    /// The directions `leafID` may travel under `moving(_:_:in:)`.
    public func availableDirections(for leafID: UUID, in tree: LayoutNode) -> Set<Direction> {
        Set(Direction.allCases.filter { moving(leafID, $0, in: tree) != nil })
    }

    /// The relationship-aware form of `ComposableTabsMove.moving`.
    ///
    /// - A managed sibling never moves: it goes where its primary goes.
    /// - Every intact unit is collapsed to one stand-in leaf, the move is made
    ///   on that tree, and the stand-ins are expanded back. So a primary carries
    ///   its sibling and everything else inside the unit, and an unrelated pane
    ///   moves *around* the pair instead of into it.
    /// - A pane inside a unit that is not its primary (a terminal stacked under
    ///   the primary, say) moves on the full tree, kept only if the result
    ///   still satisfies every relationship.
    ///
    /// Units are tightened first (`tightened(_:)`): `[a | [b | c]]` and
    /// `[[a | b] | c]` look the same on screen, but only the second has a
    /// subtree that is just the pair, and without one the unit would be the
    /// whole row and the primary could never move.
    public func moving(_ leafID: UUID, _ direction: Direction, in tree: LayoutNode) -> LayoutNode? {
        guard !all.isEmpty else { return ComposableTabsMove.moving(leafID, direction, in: tree) }
        guard let leaf = ComposableTabsMove.leaf(leafID, in: tree) else { return nil }
        if case .leaf(let contentType, _) = leaf.kind, isManagedSibling(contentType) { return nil }

        let tree = tightened(tree)
        let units = outermostUnits(in: tree)

        if let unit = units.first(where: { $0.primary == leafID }) {
            return movingCollapsed(unit.node.id, direction, in: tree, units: units)
        }
        if units.contains(where: { $0.node.leafIDs.contains(leafID) }) {
            guard let moved = ComposableTabsMove.moving(leafID, direction, in: tree),
                  satisfies(moved) else { return nil }
            return moved
        }
        return movingCollapsed(leafID, direction, in: tree, units: units)
    }

    private func movingCollapsed(
        _ moverID: UUID,
        _ direction: Direction,
        in tree: LayoutNode,
        units: [(primary: UUID, node: LayoutNode)]
    ) -> LayoutNode? {
        var collapsed = tree
        for unit in units {
            collapsed = Self.replacing(unit.node.id, in: collapsed) { node in
                LayoutNode.leaf(id: node.id, contentType: .placeholder, thicknessFraction: node.thicknessFraction)
            }
        }
        guard var moved = ComposableTabsMove.moving(moverID, direction, in: collapsed) else { return nil }
        for unit in units {
            moved = Self.replacing(unit.node.id, in: moved) { standIn in unit.node.occupying(standIn) }
        }
        return moved
    }

    /// Every unit not inside another, each with the primary it belongs to.
    private func outermostUnits(in tree: LayoutNode) -> [(primary: UUID, node: LayoutNode)] {
        var units: [(primary: UUID, node: LayoutNode)] = []
        for relationship in all {
            for pair in Self.match(relationship, in: tree).pairs {
                guard let node = Self.lowestCommonAncestor(pair.primary, pair.sibling, in: tree) else { continue }
                units.append((pair.primary, node))
            }
        }
        return units.filter { unit in
            !units.contains { other in other.node.id != unit.node.id && other.node.allIDs.contains(unit.node.id) }
        }
    }

    /// `tree` re-associated so each satisfied pair's lowest common ancestor
    /// holds nothing along the pin's axis but the pair's own two sides.
    ///
    /// `[X | [Y1 | Y2]]` becomes `[[X | Y1] | Y2]` — the same panes in the same
    /// places, with the fractions recomputed so nothing visibly moves.
    public func tightened(_ tree: LayoutNode) -> LayoutNode {
        var tree = tree
        for relationship in all {
            for pair in Self.match(relationship, in: tree).pairs {
                // Each rotation shrinks the pair's common ancestor by one node,
                // so this ends; the bound only guards a malformed tree.
                for _ in 0..<64 {
                    guard let ancestor = Self.lowestCommonAncestor(pair.primary, pair.sibling, in: tree),
                          let rotated = Self.rotatedTowardPair(ancestor, axis: relationship.pin.axis)
                    else { break }
                    tree = Self.replacing(ancestor.id, in: tree) { _ in rotated }
                }
            }
        }
        return tree
    }

    /// One rotation pulling the far half of a same-axis child out of `split`,
    /// or `nil` when neither child is a split along `axis`.
    private static func rotatedTowardPair(_ split: LayoutNode, axis: ComposableTabsAxis) -> LayoutNode? {
        guard case .split(let orientation, let first, let second) = split.kind, orientation == axis else {
            return nil
        }
        if case .split(let innerAxis, let near, let far) = second.kind, innerAxis == axis {
            // [X | [Y1 | Y2]] -> [[X | Y1] | Y2]
            let shares = rotatedShares(outer: first.thicknessFraction, inner: near.thicknessFraction)
            var left = first, middle = near, right = far
            left.thicknessFraction = shares?.left
            middle.thicknessFraction = shares?.middle
            right.thicknessFraction = shares?.right
            let inner = LayoutNode.split(
                id: second.id, orientation: axis, first: left, second: middle, thicknessFraction: shares?.inner)
            return .split(id: split.id, orientation: axis, first: inner, second: right,
                          thicknessFraction: split.thicknessFraction)
        }
        if case .split(let innerAxis, let farSide, let near) = first.kind, innerAxis == axis {
            // [[X1 | X2] | Y] -> [X1 | [X2 | Y]], the mirror image.
            let shares = rotatedShares(outer: second.thicknessFraction, inner: near.thicknessFraction)
            var left = farSide, middle = near, right = second
            left.thicknessFraction = shares?.right
            middle.thicknessFraction = shares?.middle
            right.thicknessFraction = shares?.left
            let inner = LayoutNode.split(
                id: first.id, orientation: axis, first: middle, second: right, thicknessFraction: shares?.inner)
            return .split(id: split.id, orientation: axis, first: left, second: inner,
                          thicknessFraction: split.thicknessFraction)
        }
        return nil
    }

    /// The shares after `[X | [Y1 | Y2]]` becomes `[[X | Y1] | Y2]`, given X's
    /// share of the outer split and Y1's of the inner one. `nil` when either is
    /// unsized: a guess would put numbers on dividers that do not add up, and
    /// unsized panes take their preferred share instead.
    private static func rotatedShares(
        outer: Double?,
        inner: Double?
    ) -> (left: Double, middle: Double, right: Double, inner: Double)? {
        guard let outer, let inner else { return nil }
        let newInner = outer + (1 - outer) * inner
        guard newInner > 0, newInner < 1 else { return nil }
        let left = outer / newInner
        return (left, 1 - left, 1 - newInner, newInner)
    }

    // MARK: - Matching primaries to siblings

    private struct Matching {
        var pairs: [(primary: UUID, sibling: UUID)] = []
        var unmatchedPrimaries: [UUID] = []
        var unmatchedSiblings: [UUID] = []
        var primaryCount = 0
        var siblingCount = 0
    }

    /// Each primary, in reading order, paired with the first unused sibling
    /// that is pinned to it.
    private static func match(_ relationship: ComposableTabsPaneRelationship, in tree: LayoutNode) -> Matching {
        let leaves = ComposableTabLayoutSpec.leaves(in: tree)
        let primaries = leaves.filter { contentType(of: $0) == relationship.primary }.map(\.id)
        var siblings = leaves.filter { contentType(of: $0) == relationship.sibling }.map(\.id)
        var matching = Matching(primaryCount: primaries.count, siblingCount: siblings.count)
        for primaryID in primaries {
            if let index = siblings.firstIndex(where: {
                isPinned(sibling: $0, to: primaryID, relationship, in: tree)
            }) {
                matching.pairs.append((primaryID, siblings.remove(at: index)))
            } else {
                matching.unmatchedPrimaries.append(primaryID)
            }
        }
        matching.unmatchedSiblings = siblings
        return matching
    }

    /// The geometry of a pin on a binary tree.
    ///
    /// The two panes' lowest common ancestor is a split along the pin's axis
    /// with the first-in-reading-order pane on its first side. That pane
    /// reaches its side's far edge and the other its side's near edge —
    /// descending, a split along the axis must take the child on the shared
    /// edge, one across it may take either — which is "nothing between them".
    /// Their spans across the axis overlap, and each aligned edge is reached by
    /// both.
    private static func isPinned(
        sibling siblingID: UUID,
        to primaryID: UUID,
        _ relationship: ComposableTabsPaneRelationship,
        in tree: LayoutNode
    ) -> Bool {
        let axis = relationship.pin.axis
        let (firstID, secondID) = relationship.pin.siblingFirst
            ? (siblingID, primaryID) : (primaryID, siblingID)
        guard let ancestor = lowestCommonAncestor(firstID, secondID, in: tree),
              case .split(let orientation, let firstSide, let secondSide) = ancestor.kind,
              orientation == axis,
              let firstPath = path(to: firstID, in: firstSide),
              let secondPath = path(to: secondID, in: secondSide) else { return false }

        let touches = firstPath.allSatisfy { $0.axis != axis || $0.childIndex == 1 }
            && secondPath.allSatisfy { $0.axis != axis || $0.childIndex == 0 }
        guard touches else { return false }

        let firstSpan = span(of: firstPath, across: axis)
        let secondSpan = span(of: secondPath, across: axis)
        guard min(firstSpan.upperBound, secondSpan.upperBound)
                > max(firstSpan.lowerBound, secondSpan.lowerBound) else { return false }

        return relationship.aligned.allSatisfy { edge in
            [firstPath, secondPath].allSatisfy { path in
                path.allSatisfy { $0.axis != edge.axis || $0.childIndex == edge.childIndex }
            }
        }
    }

    /// One step down from a split toward a leaf.
    private struct Step {
        let axis: ComposableTabsAxis
        let childIndex: Int
        /// The first child's share of the split, `0.5` when nobody sized it.
        let firstShare: Double
    }

    private static func path(to id: UUID, in node: LayoutNode) -> [Step]? {
        if node.id == id { return [] }
        guard case .split(let axis, let first, let second) = node.kind else { return nil }
        let share = first.thicknessFraction ?? second.thicknessFraction.map { 1 - $0 } ?? 0.5
        if let below = path(to: id, in: first) {
            return [Step(axis: axis, childIndex: 0, firstShare: share)] + below
        }
        if let below = path(to: id, in: second) {
            return [Step(axis: axis, childIndex: 1, firstShare: share)] + below
        }
        return nil
    }

    /// The part of its side a pane covers across `axis`, as a fraction.
    private static func span(of path: [Step], across axis: ComposableTabsAxis) -> ClosedRange<Double> {
        var lower = 0.0, upper = 1.0
        for step in path where step.axis != axis {
            let divider = lower + (upper - lower) * step.firstShare
            if step.childIndex == 0 { upper = divider } else { lower = divider }
        }
        return lower...upper
    }

    // MARK: - Tree utilities

    private static func contentType(of leaf: LayoutNode) -> ComposableTabsViewID? {
        guard case .leaf(let contentType, _) = leaf.kind else { return nil }
        return contentType
    }

    private static func lowestCommonAncestor(_ lhs: UUID, _ rhs: UUID, in node: LayoutNode) -> LayoutNode? {
        let ids = node.allIDs
        guard ids.contains(lhs), ids.contains(rhs) else { return nil }
        if case .split(_, let first, let second) = node.kind {
            if let deeper = lowestCommonAncestor(lhs, rhs, in: first) { return deeper }
            if let deeper = lowestCommonAncestor(lhs, rhs, in: second) { return deeper }
        }
        return node
    }

    /// Rewrites the subtree with `id` in place, leaving the rest untouched.
    private static func replacing(
        _ id: UUID,
        in node: LayoutNode,
        with transform: (LayoutNode) -> LayoutNode
    ) -> LayoutNode {
        if node.id == id { return transform(node) }
        guard case .split(let axis, let first, let second) = node.kind else { return node }
        return .split(
            id: node.id,
            orientation: axis,
            first: replacing(id, in: first, with: transform),
            second: replacing(id, in: second, with: transform),
            thicknessFraction: node.thicknessFraction
        )
    }
}
