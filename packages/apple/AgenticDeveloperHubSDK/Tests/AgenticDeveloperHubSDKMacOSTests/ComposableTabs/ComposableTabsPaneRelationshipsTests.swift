import XCTest
import AgenticDeveloperHubSDKMacOS

/// Pane relationships as trees: what "pinned" and "aligned" mean on a binary
/// layout, how a tree is repaired to honour them, and how a move keeps them.
///
/// Labels name the panes: `P` is a primary, `S` its sibling, anything else an
/// unrelated pane. The initializer's precondition (an aligned edge on the pin's
/// own axis) traps, so it is not exercised here.
@MainActor
final class ComposableTabsPaneRelationshipsTests: XCTestCase {

    private let primary = ComposableTabsViewID("test.relationship.primary")
    private let sibling = ComposableTabsViewID("test.relationship.sibling")
    private let other = ComposableTabsViewID("test.relationship.other")

    // MARK: - Building and reading trees

    private func primaryPane(_ label: String = "P") -> LayoutNode {
        .leaf(contentType: primary, paneLabel: label)
    }

    private func siblingPane(_ label: String = "S") -> LayoutNode {
        .leaf(contentType: sibling, paneLabel: label)
    }

    private func pane(_ label: String) -> LayoutNode {
        .leaf(contentType: other, paneLabel: label)
    }

    private func horizontal(_ first: LayoutNode, _ second: LayoutNode) -> LayoutNode {
        .split(orientation: .horizontal, first: first, second: second)
    }

    private func vertical(_ first: LayoutNode, _ second: LayoutNode) -> LayoutNode {
        .split(orientation: .vertical, first: first, second: second)
    }

    /// `H(a, b)` left-to-right, `V(a, b)` top-to-bottom. A leaf with no label
    /// is one a repair made, and reads `new`.
    private func shape(_ node: LayoutNode) -> String {
        switch node.kind {
        case .leaf(_, let label):
            return label ?? "new"
        case .split(let axis, let first, let second):
            return "\(axis == .horizontal ? "H" : "V")(\(shape(first)), \(shape(second)))"
        }
    }

    private func leaves(in node: LayoutNode) -> [LayoutNode] {
        switch node.kind {
        case .leaf:
            return [node]
        case .split(_, let first, let second):
            return leaves(in: first) + leaves(in: second)
        }
    }

    private func relationships(
        _ pin: ComposableTabsPaneRelationship.Pin,
        aligned: Set<ComposableTabsPaneRelationship.Edge> = []
    ) -> ComposableTabsPaneRelationships {
        ComposableTabsPaneRelationships([.init(primary: primary, sibling: sibling, pin: pin, aligned: aligned)])
    }

    /// The sibling after the primary, tops aligned — the app's own declaration.
    private var afterPrimary: ComposableTabsPaneRelationships {
        relationships(.siblingAfterPrimary, aligned: [.top])
    }

    private var spec: ComposableTabLayoutSpec {
        ComposableTabLayoutSpec.split(
            axis: .horizontal,
            children: [.pane(primary), .pane(sibling), .pane(other)],
            allows: [
                .init(primary, min: 0, max: 1),
                .init(sibling, min: 0, max: 1),
                .unbounded(other)
            ]
        )
        .relating([.init(primary: primary, sibling: sibling, pin: .siblingAfterPrimary, aligned: [.top])])
    }

    /// What `ComposableTabsMove` alone does to `tree` when the pair is one pane:
    /// `unit` stands for it, labelled with the pair's own shape, so the string
    /// that comes back is the shape a relationship-aware move should produce.
    private func plainMove(
        _ mover: LayoutNode,
        _ direction: ComposableTabsViewController.Direction,
        in tree: LayoutNode
    ) throws -> String {
        shape(try XCTUnwrap(ComposableTabsMove.moving(mover.id, direction, in: tree)))
    }

    // MARK: - satisfies: the four pins

    func testSiblingAfterPrimaryIsTheSiblingOnTheRight() {
        let pins = relationships(.siblingAfterPrimary)
        XCTAssertTrue(pins.satisfies(horizontal(primaryPane(), siblingPane())))
        XCTAssertFalse(pins.satisfies(horizontal(siblingPane(), primaryPane())), "the wrong side")
        XCTAssertFalse(pins.satisfies(vertical(primaryPane(), siblingPane())), "the wrong axis")
    }

    func testSiblingBeforePrimaryIsTheSiblingOnTheLeft() {
        let pins = relationships(.siblingBeforePrimary)
        XCTAssertTrue(pins.satisfies(horizontal(siblingPane(), primaryPane())))
        XCTAssertFalse(pins.satisfies(horizontal(primaryPane(), siblingPane())))
        XCTAssertFalse(pins.satisfies(vertical(siblingPane(), primaryPane())))
    }

    func testSiblingAbovePrimaryIsTheSiblingOnTop() {
        let pins = relationships(.siblingAbovePrimary)
        XCTAssertTrue(pins.satisfies(vertical(siblingPane(), primaryPane())))
        XCTAssertFalse(pins.satisfies(vertical(primaryPane(), siblingPane())))
        XCTAssertFalse(pins.satisfies(horizontal(siblingPane(), primaryPane())))
    }

    func testSiblingBelowPrimaryIsTheSiblingUnderneath() {
        let pins = relationships(.siblingBelowPrimary)
        XCTAssertTrue(pins.satisfies(vertical(primaryPane(), siblingPane())))
        XCTAssertFalse(pins.satisfies(vertical(siblingPane(), primaryPane())))
        XCTAssertFalse(pins.satisfies(horizontal(primaryPane(), siblingPane())))
    }

    /// "Pinned" is "nothing between them": a pane in the way breaks it, while
    /// a pane beyond the pair does not.
    func testAPaneBetweenThePairBreaksThePin() {
        let pins = relationships(.siblingAfterPrimary)
        XCTAssertFalse(pins.satisfies(horizontal(primaryPane(), horizontal(pane("C"), siblingPane()))))
        XCTAssertTrue(pins.satisfies(horizontal(primaryPane(), horizontal(siblingPane(), pane("C")))))
    }

    /// A relationship only speaks when both of its panes are there.
    func testATreeWithoutTheSiblingSatisfiesTheRelationship() {
        XCTAssertTrue(afterPrimary.satisfies(horizontal(primaryPane(), pane("C"))))
    }

    // MARK: - satisfies: alignment

    /// Pinned side by side with tops aligned: each pane must reach the top of
    /// its side. Without the alignment, overlapping spans are enough.
    func testTopAlignmentRequiresBothPanesToReachTheTop() {
        let pinOnly = relationships(.siblingAfterPrimary)
        let siblingOnTop = horizontal(primaryPane(), vertical(siblingPane(), pane("C")))
        let siblingUnderneath = horizontal(primaryPane(), vertical(pane("C"), siblingPane()))
        let primaryUnderneath = horizontal(vertical(pane("C"), primaryPane()), siblingPane())

        XCTAssertTrue(afterPrimary.satisfies(siblingOnTop))
        XCTAssertFalse(afterPrimary.satisfies(siblingUnderneath))
        XCTAssertFalse(afterPrimary.satisfies(primaryUnderneath))
        XCTAssertTrue(pinOnly.satisfies(siblingUnderneath), "spans still overlap, which is all the pin needs")
        XCTAssertTrue(pinOnly.satisfies(primaryUnderneath))
    }

    func testBottomAlignmentIsTheMirror() {
        let pins = relationships(.siblingAfterPrimary, aligned: [.bottom])
        XCTAssertTrue(pins.satisfies(horizontal(primaryPane(), vertical(pane("C"), siblingPane()))))
        XCTAssertFalse(pins.satisfies(horizontal(primaryPane(), vertical(siblingPane(), pane("C")))))
    }

    // MARK: - normalized

    /// A primary with no sibling gains one, in the canonical placement: the
    /// primary's slot becomes the pair.
    func testAMissingSiblingIsAdded() throws {
        let tree = horizontal(primaryPane(), pane("C"))

        let repaired = afterPrimary.normalized(tree, spec: spec)

        XCTAssertEqual(shape(repaired), "H(H(P, new), C)")
        let added = try XCTUnwrap(leaves(in: repaired).first { shape($0) == "new" })
        guard case .leaf(let contentType, _) = added.kind else { return XCTFail("a leaf") }
        XCTAssertEqual(contentType, sibling)
        XCTAssertTrue(afterPrimary.satisfies(repaired))
    }

    /// A sibling in the wrong place is moved, not replaced: it keeps its id,
    /// so the live pane is the one that arrives beside the primary.
    func testAMisplacedSiblingIsReattachedKeepingItsID() throws {
        let misplaced = siblingPane()
        let tree = horizontal(misplaced, horizontal(pane("C"), primaryPane()))

        let repaired = afterPrimary.normalized(tree, spec: spec)

        XCTAssertEqual(shape(repaired), "H(C, H(P, S))")
        let reattached = try XCTUnwrap(leaves(in: repaired).first { shape($0) == "S" })
        XCTAssertEqual(reattached.id, misplaced.id)
    }

    /// A sibling with no primary gets its primary back, in the canonical
    /// placement, keeping its own id: removing it would close whatever it
    /// holds (Documents' open tabs).
    func testAnOrphanSiblingGetsItsPrimaryBack() throws {
        let orphan = siblingPane()
        let tree = horizontal(orphan, pane("C"))

        let repaired = afterPrimary.normalized(tree, spec: spec)

        XCTAssertEqual(shape(repaired), "H(H(new, S), C)")
        let kept = try XCTUnwrap(leaves(in: repaired).first { shape($0) == "S" })
        XCTAssertEqual(kept.id, orphan.id)
        let added = try XCTUnwrap(leaves(in: repaired).first { shape($0) == "new" })
        guard case .leaf(let contentType, _) = added.kind else { return XCTFail("a leaf") }
        XCTAssertEqual(contentType, primary)
        XCTAssertTrue(afterPrimary.satisfies(repaired))
    }

    /// Only when the spec will not take another primary does the orphan go.
    func testAnOrphanSiblingIsRemovedWhenNoPrimaryFits() {
        let noPrimary = ComposableTabLayoutSpec.split(
            axis: .horizontal,
            children: [.pane(sibling), .pane(other)],
            allows: [.init(sibling, min: 0, max: 1), .unbounded(other)]
        )
        .relating([.init(primary: primary, sibling: sibling, pin: .siblingAfterPrimary, aligned: [.top])])
        let tree = horizontal(siblingPane(), pane("C"))

        XCTAssertEqual(shape(afterPrimary.normalized(tree, spec: noPrimary)), "C")
    }

    func testATreeThatAlreadySatisfiesIsUnchanged() {
        let tree = horizontal(horizontal(primaryPane(), siblingPane()), pane("C"))

        XCTAssertEqual(shape(afterPrimary.normalized(tree, spec: spec)), shape(tree))
    }

    // MARK: - moving

    /// The primary carries its sibling: the move is the one the pair would make
    /// if it were a single pane.
    func testMovingThePrimaryCarriesItsSibling() throws {
        let mover = primaryPane()
        let tree = horizontal(horizontal(mover, siblingPane()), pane("C"))
        let standIn = pane("H(P, S)")

        let moved = try XCTUnwrap(afterPrimary.moving(mover.id, .right, in: tree))

        XCTAssertEqual(shape(moved), try plainMove(standIn, .right, in: horizontal(standIn, pane("C"))))
        XCTAssertTrue(afterPrimary.satisfies(moved))
    }

    /// The shape of the default blueprint, `[P | [S | C]]`: the pair is not a
    /// subtree of its own until it is tightened, and without that the primary
    /// could not move at all.
    func testThePrimaryMovesOutOfARightChainedRow() throws {
        let mover = primaryPane()
        let tree = horizontal(mover, horizontal(siblingPane(), pane("C")))
        let standIn = pane("H(P, S)")

        let moved = try XCTUnwrap(afterPrimary.moving(mover.id, .right, in: tree))

        XCTAssertEqual(shape(moved), try plainMove(standIn, .right, in: horizontal(standIn, pane("C"))))
        XCTAssertTrue(afterPrimary.satisfies(moved))
    }

    /// An unrelated pane steps over the pair as a whole instead of landing
    /// between them.
    func testAnUnrelatedPaneMovesAroundThePair() throws {
        let mover = pane("C")
        let tree = horizontal(mover, horizontal(primaryPane(), siblingPane()))
        let standIn = pane("H(P, S)")

        let moved = try XCTUnwrap(afterPrimary.moving(mover.id, .right, in: tree))

        XCTAssertEqual(shape(moved), try plainMove(mover, .right, in: horizontal(mover, standIn)))
        XCTAssertTrue(afterPrimary.satisfies(moved))
    }

    /// A managed sibling goes where its primary goes and nowhere on its own.
    func testAManagedSiblingCannotMove() {
        let managed = siblingPane()
        let tree = horizontal(horizontal(primaryPane(), managed), pane("C"))

        XCTAssertTrue(afterPrimary.availableDirections(for: managed.id, in: tree).isEmpty)
        for direction in ComposableTabsViewController.Direction.allCases {
            XCTAssertNil(afterPrimary.moving(managed.id, direction, in: tree), "\(direction)")
        }
        XCTAssertTrue(afterPrimary.isManagedSibling(sibling))
        XCTAssertFalse(afterPrimary.isManagedSibling(primary))
    }
}
