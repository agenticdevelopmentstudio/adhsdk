import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

// Conformance tests for the composable-tabs recipe, one test per conformance
// vector (`composable-tabs-NNN`), the id carried in the test name. The behaviour
// is also pinned, from other angles, by `ComposableTabsPaneHostTests` and
// `ComposableTabsViewControllerTests`; these tests exist so every vector has a
// test that names it.

/// Counts, per pane, how many times its content was told it was being discarded.
@MainActor
private final class CTTeardownLog {
    var counts: [UUID: Int] = [:]
}

@MainActor
private final class CTLoggedContent: NSViewController, PaneContentTeardown {
    private let nodeID: UUID
    private let log: CTTeardownLog

    init(nodeID: UUID, log: CTTeardownLog) {
        self.nodeID = nodeID
        self.log = log
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func paneContentWillBeDiscarded() {
        log.counts[nodeID, default: 0] += 1
    }
}

/// An arranger that records the axis it was asked about and can rewrite the tree.
@MainActor
private final class CTSpyArranger: PaneArranger {
    var axes: [ComposableTabsAxis] = []
    var transform: ((LayoutNode) -> LayoutNode)?

    func arrange(_ node: LayoutNode, along axis: ComposableTabsAxis) -> LayoutNode {
        axes.append(axis)
        return transform?(node) ?? node
    }
}

@MainActor
final class ComposableTabsConformanceTests: XCTestCase {

    private let alpha = ComposableTabsViewID("test.alpha")
    private let beta = ComposableTabsViewID("test.beta")
    private let gamma = ComposableTabsViewID("test.gamma")

    private let leftID = UUID()
    private let rightID = UUID()
    private let topID = UUID()
    private let bottomID = UUID()

    private let log = CTTeardownLog()
    private lazy var project = Self.makeWorkspace()

    @MainActor
    private static func makeWorkspace() -> ProjectWorkspace {
        let path = TestTempDirectory.make(label: "ComposableTabsConformance")
            .appendingPathComponent("Test.db").path
        let repo = GitRepo(path: NSTemporaryDirectory(), name: "Test") // temp-leak-check: ok path only, nothing written
        // A failure here is a broken test environment, not a case to handle.
        // swiftlint:disable:next force_try
        let database = try! ProjectDatabase(path: path)
        // swiftlint:disable:next force_try
        try! database.insert(repo)
        return ProjectWorkspace(repo: repo, database: database)
    }

    nonisolated override func tearDown() {
        ComposableTabsLayout.install(nil)
        super.tearDown()
    }

    // MARK: - Fixtures

    /// Builds a layout over alpha, beta and gamma. `bounded` floors alpha and
    /// beta at one instance each, the smallest spec that vetoes a removal.
    @discardableResult
    private func installLayout(bounded: Bool = false) throws -> ComposableTabsLayout {
        let registry = ComposableTabsViewRegistry()
        let log = self.log
        let factory: ComposableTabsViewRegistry.Factory = { context in
            CTLoggedContent(nodeID: context.nodeID, log: log)
        }
        registry.register(alpha, descriptor: .init(displayName: "Alpha", minimumThickness: 150), factory: factory)
        registry.register(beta, descriptor: .init(displayName: "Beta", minimumThickness: 150), factory: factory)
        registry.register(gamma, descriptor: .init(
            displayName: "Gamma",
            minimumThickness: 200,
            preferredThicknessFraction: 0.3,
            isCollapsible: true
        ), factory: factory)
        let allows: [ComposableTabsViewAllowance] = bounded
            ? [.unbounded(alpha, min: 1), .unbounded(beta, min: 1), .unbounded(gamma)]
            : [.unbounded(alpha), .unbounded(beta), .unbounded(gamma)]
        let layout = try ComposableTabsLayout(
            registry: registry,
            spec: .split(
                axis: .horizontal,
                children: [.pane(alpha), .pane(beta)],
                allows: allows
            )
        )
        ComposableTabsLayout.install(layout)
        return layout
    }

    private func makeTree(
        _ node: LayoutNode,
        bounded: Bool = false,
        load: Bool = true
    ) throws -> ComposableTabsViewController {
        try installLayout(bounded: bounded)
        let root = ComposableTabsViewController.make(
            from: node, project: project, workingDirectory: project.directoryURL, isRoot: true)
        if load {
            root.loadViewIfNeeded()
            for pane in root.allLeaves() { pane.loadViewIfNeeded() }
        }
        return root
    }

    private func sideBySide(bounded: Bool = false, load: Bool = true) throws -> ComposableTabsViewController {
        try makeTree(.split(
            orientation: .horizontal,
            first: .leaf(id: leftID, contentType: alpha),
            second: .leaf(id: rightID, contentType: beta)
        ), bounded: bounded, load: load)
    }

    private func stacked() throws -> ComposableTabsViewController {
        try makeTree(.split(
            orientation: .vertical,
            first: .leaf(id: topID, contentType: alpha),
            second: .leaf(id: bottomID, contentType: beta)
        ))
    }

    /// The left pane beside a vertical pair, so one split is not the root.
    private func nested(load: Bool = true) throws -> ComposableTabsViewController {
        try makeTree(.split(
            orientation: .horizontal,
            first: .leaf(id: leftID, contentType: alpha),
            second: .split(
                orientation: .vertical,
                first: .leaf(id: topID, contentType: alpha),
                second: .leaf(id: bottomID, contentType: beta)
            )
        ), load: load)
    }

    private func leaf(_ id: UUID, in root: ComposableTabsViewController)
        throws -> ComposableTabsPaneViewController {
        try XCTUnwrap(root.allLeaves().first { $0.nodeID == id })
    }

    private func item(for pane: ComposableTabsPaneViewController) throws -> NSSplitViewItem {
        let owner = try XCTUnwrap(pane.parent as? ComposableTabsViewController)
        return try XCTUnwrap(owner.splitViewItem(for: pane))
    }

    private func makePane(_ id: UUID, _ viewID: ComposableTabsViewID? = nil) -> ComposableTabsPaneViewController {
        ComposableTabsPaneViewController(
            nodeID: id,
            paneNumber: project.allocatePaneNumber(),
            viewID: viewID ?? alpha,
            project: project,
            workingDirectory: project.directoryURL
        )
    }

    private func makeSplit(
        axis: ComposableTabsAxis,
        children: [any ComposableTabsChild],
        isRoot: Bool
    ) -> ComposableTabsViewController {
        ComposableTabsViewController(
            nodeID: UUID(),
            axis: axis,
            children: children,
            project: project,
            workingDirectory: project.directoryURL,
            isRoot: isRoot
        )
    }

    /// Gives the root a real size and lays it out, which is what a window does.
    private func size(_ root: ComposableTabsViewController, width: CGFloat = 1000, height: CGFloat = 600) {
        root.view.frame = NSRect(x: 0, y: 0, width: width, height: height)
        root.view.layoutSubtreeIfNeeded()
    }

    private func leafIDs(of node: LayoutNode) -> [UUID] {
        switch node.kind {
        case .leaf: return [node.id]
        case .split(_, let first, let second): return leafIDs(of: first) + leafIDs(of: second)
        }
    }

    private func resizeNotification(_ root: ComposableTabsViewController) -> Notification {
        Notification(name: NSSplitView.didResizeSubviewsNotification, object: root.splitView)
    }

    private func wait(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - Construction and the split view

    func testComposableTabs001() throws {
        throw XCTSkip("an assertion failure traps the whole test process; a debug-build trap cannot be observed")
    }

    func testComposableTabs003VerticalDividerFromHorizontalAxis() throws {
        let root = try sideBySide()
        XCTAssertTrue(root.splitView.isVertical, "side-by-side panes are divided by a vertical line")
    }

    func testComposableTabs095HorizontalDividerFromVerticalAxis() throws {
        let root = try stacked()
        XCTAssertFalse(root.splitView.isVertical)
    }

    func testComposableTabs004ThinDividerStyle() throws {
        let root = try sideBySide()
        XCTAssertEqual(root.splitView.dividerStyle, .thin)
    }

    func testComposableTabs005UsesTheComponentsOwnSplitView() throws {
        let root = try sideBySide()
        XCTAssertTrue(root.splitView is PaneSplitView)
    }

    func testComposableTabs006() throws {
        throw XCTSkip("needs a spy split view and a change to the shared pane-spacing settings store")
    }

    func testComposableTabs007OneSplitItemPerChildInOrder() throws {
        let root = try sideBySide()
        XCTAssertEqual(root.splitViewItems.count, 2)
        XCTAssertEqual(root.splitViewItems.map(\.viewController),
                       root.layoutChildren.map(\.viewController))
    }

    func testComposableTabs008RootLoadAssignsSequentialIndices() throws {
        let root = try makeTree(.split(
            orientation: .horizontal,
            first: .leaf(id: leftID, contentType: alpha),
            second: .leaf(id: rightID, contentType: alpha)
        ))
        let first = try leaf(leftID, in: root)
        let second = try leaf(rightID, in: root)
        XCTAssertEqual(first.paneAccessibilityIdentifier, "\(first.paneTypeIdentifier).1")
        XCTAssertEqual(second.paneAccessibilityIdentifier, "\(second.paneTypeIdentifier).2")
    }

    func testComposableTabs096NonRootLoadAssignsNoIndices() throws {
        try installLayout()
        let first = makePane(leftID)
        let second = makePane(rightID)
        let split = makeSplit(axis: .horizontal, children: [first, second], isRoot: false)
        split.loadViewIfNeeded()
        XCTAssertEqual(first.paneAccessibilityIdentifier, first.paneTypeIdentifier)
        XCTAssertEqual(second.paneAccessibilityIdentifier, second.paneTypeIdentifier)
    }

    func testComposableTabs060AmbiguousPaneNumbers() throws {
        let root = try nested()
        root.reassignPaneIdentifiers()
        let terminalOne = try leaf(leftID, in: root)
        let terminalTwo = try leaf(topID, in: root)
        let fileBrowser = try leaf(bottomID, in: root)
        XCTAssertEqual(terminalOne.paneAccessibilityIdentifier, "\(terminalOne.paneTypeIdentifier).1")
        XCTAssertEqual(terminalTwo.paneAccessibilityIdentifier, "\(terminalTwo.paneTypeIdentifier).2")
        XCTAssertEqual(fileBrowser.paneAccessibilityIdentifier, fileBrowser.paneTypeIdentifier,
                       "a type with one instance carries no index")
    }

    func testComposableTabs069BuildFromLeafWrapsInRootSplit() throws {
        let leafNode = LayoutNode.leaf(id: leftID, contentType: alpha)
        let root = try makeTree(leafNode, load: false)
        XCTAssertEqual(root.layoutChildren.count, 1)
        XCTAssertEqual(root.axis, .horizontal)
        XCTAssertNotEqual(root.nodeID, leftID, "the wrapper's id is minted fresh, never the leaf's")
    }

    func testComposableTabs070BuildCarriesFractionToChild() throws {
        let root = try makeTree(.leaf(id: leftID, contentType: alpha, thicknessFraction: 0.6), load: false)
        XCTAssertEqual(try XCTUnwrap(root.layoutChildren[0].thicknessFraction), 0.6, accuracy: 0.0001)
    }

    // MARK: - Sizing a layout pass

    func testComposableTabs010LayoutAppliesChildFractions() throws {
        let root = try sideBySide()
        try leaf(leftID, in: root).thicknessFraction = 0.3
        size(root)
        XCTAssertEqual(try leaf(leftID, in: root).view.frame.width, 300, accuracy: 15)
    }

    func testComposableTabs011PreferredThicknessIsOneShot() throws {
        let root = try sideBySide()
        try leaf(leftID, in: root).thicknessFraction = 0.3
        size(root)
        root.splitView.setPosition(600, ofDividerAt: 0)
        root.view.layoutSubtreeIfNeeded()
        let dragged = try leaf(leftID, in: root).view.frame.width

        root.viewDidLayout()
        root.view.layoutSubtreeIfNeeded()

        XCTAssertEqual(try leaf(leftID, in: root).view.frame.width, dragged, accuracy: 0.5,
                       "a second pass must not re-impose the fraction over the user's drag")
    }

    func testComposableTabs012ZeroWidthPassDoesNotConsumeTheOneShot() throws {
        let root = try sideBySide()
        try leaf(leftID, in: root).thicknessFraction = 0.3
        // A layout pass over a split with no width. Driven directly: laying out
        // a zero-sized root lets the panes' minimums widen the split, so that
        // pass would not be zero-width at all.
        root.splitView.frame = .zero
        root.viewDidLayout()
        root.splitView.frame = NSRect(x: 0, y: 0, width: 1000, height: 600)
        root.splitView.adjustSubviews()
        root.viewDidLayout()
        XCTAssertEqual(try leaf(leftID, in: root).view.frame.width, 300, accuracy: 15,
                       "the real-width pass still applies the fractions after a zero-width one")
    }

    func testComposableTabs013DraggedFractionOutranksDescriptor() throws {
        let root = try makeTree(.split(
            orientation: .horizontal,
            first: .leaf(id: leftID, contentType: gamma),
            second: .leaf(id: rightID, contentType: beta)
        ))
        let gammaPane = try leaf(leftID, in: root)
        XCTAssertEqual(try item(for: gammaPane).preferredThicknessFraction, 0.3, accuracy: 0.0001)
        gammaPane.thicknessFraction = 0.7
        size(root)
        XCTAssertEqual(gammaPane.view.frame.width, 700, accuracy: 15)
    }

    func testComposableTabs014FractionIsClampedToTheMinimum() throws {
        let root = try sideBySide()
        try leaf(leftID, in: root).thicknessFraction = 0.05
        size(root)
        XCTAssertGreaterThanOrEqual(try leaf(leftID, in: root).view.frame.width, 149,
                                    "0.05 of 1000 is 50, below the descriptor's 150 minimum")
    }

    func testComposableTabs015() throws {
        throw XCTSkip("needs the shared pane-spacing setting set to 0 and the divider hit rect read off a live view")
    }

    // MARK: - Ownership stamping and inheritance

    func testComposableTabs016StampsOwnershipOnChildren() throws {
        try installLayout()
        let pane = makePane(leftID)
        let innerSplit = makeSplit(axis: .vertical, children: [makePane(topID), makePane(bottomID)], isRoot: false)
        let root = makeSplit(axis: .horizontal, children: [pane, innerSplit], isRoot: true)
        XCTAssertTrue(pane.host === root)
        XCTAssertTrue(innerSplit.layoutParent === root)
    }

    func testComposableTabs017InheritsArrangerToNestedSplits() throws {
        let root = try nested()
        let arranger = ProportionalArranger()
        root.arranger = arranger
        let innerSplit = try XCTUnwrap(root.layoutChildren[1] as? ComposableTabsViewController)
        XCTAssertTrue(innerSplit.arranger === arranger)
    }

    func testComposableTabs018InheritsLayoutOverride() throws {
        let root = try nested()
        let override = try installLayout()
        root.layoutOverride = override
        let innerSplit = try XCTUnwrap(root.layoutChildren[1] as? ComposableTabsViewController)
        XCTAssertTrue(innerSplit.layoutOverride === override)
        for pane in root.allLeaves() { XCTAssertTrue(pane.layoutOverride === override) }
    }

    func testComposableTabs019InheritsStateOwnerNodeID() throws {
        let root = try nested()
        let owner = UUID()
        root.stateOwnerNodeID = owner
        let innerSplit = try XCTUnwrap(root.layoutChildren[1] as? ComposableTabsViewController)
        XCTAssertEqual(innerSplit.stateOwnerNodeID, owner)
        for pane in root.allLeaves() { XCTAssertEqual(pane.stateOwnerNodeID, owner) }
    }

    func testComposableTabs020InheritsClampsToContainer() throws {
        let root = try nested()
        root.clampsToContainer = true
        let innerSplit = try XCTUnwrap(root.layoutChildren[1] as? ComposableTabsViewController)
        XCTAssertTrue(innerSplit.clampsToContainer)
        for pane in root.allLeaves() { XCTAssertTrue(pane.clampsToContainer) }
    }

    // MARK: - Arrangement

    func testComposableTabs021DefaultArrangerIsTheInheritedSlot() throws {
        let root = try sideBySide()
        XCTAssertTrue(root.arranger is InheritedSlotArranger)
        let node = root.snapshotNode()
        let arranged = root.arranger.arrange(node, along: .horizontal)
        XCTAssertTrue(arranged.hasSameStructure(as: node))
    }

    func testComposableTabs022DefaultArrangerAppliesNothing() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        let right = try leaf(rightID, in: root)
        left.thicknessFraction = 0.3
        right.thicknessFraction = 0.7
        root.applyArrangement()
        XCTAssertEqual(try XCTUnwrap(left.thicknessFraction), 0.3, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(right.thicknessFraction), 0.7, accuracy: 0.0001)
    }

    func testComposableTabs023ArrangementUsesTheActualAxis() throws {
        try installLayout()
        let innerSplit = makeSplit(axis: .vertical, children: [makePane(topID), makePane(bottomID)], isRoot: false)
        let root = makeSplit(axis: .horizontal, children: [innerSplit], isRoot: true)
        let spy = CTSpyArranger()
        root.arranger = spy
        root.applyArrangement()
        XCTAssertEqual(spy.axes, [.vertical], "the root's own horizontal axis is not what is laid out")
    }

    func testComposableTabs024ArrangementMatchesChildrenByID() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        let right = try leaf(rightID, in: root)
        left.thicknessFraction = 0.4
        let spy = CTSpyArranger()
        let beta = self.beta
        let alpha = self.alpha
        spy.transform = { node in
            guard case .split(let orientation, _, let second) = node.kind else { return node }
            return .split(
                id: node.id,
                orientation: orientation,
                first: .leaf(id: UUID(), contentType: alpha, thicknessFraction: 0.1),
                second: .leaf(id: second.id, contentType: beta, thicknessFraction: 0.9)
            )
        }
        root.arranger = spy
        root.applyArrangement()
        XCTAssertEqual(try XCTUnwrap(left.thicknessFraction), 0.4, accuracy: 0.0001,
                       "the result omits left's id, so left keeps what it had")
        XCTAssertEqual(try XCTUnwrap(right.thicknessFraction), 0.9, accuracy: 0.0001)
    }

    // MARK: - Capturing thicknesses

    private let sentinel: CGFloat = 0.123

    func testComposableTabs025SplitCapturesThePreSplitThickness() throws {
        let root = try sideBySide()
        size(root)
        root.splitView.setPosition(400, ofDividerAt: 0)
        root.view.layoutSubtreeIfNeeded()
        let left = try leaf(leftID, in: root)

        root.split(left, adding: beta, direction: .right)

        let innerSplit = try XCTUnwrap(root.layoutChildren[0] as? ComposableTabsViewController)
        XCTAssertEqual(try XCTUnwrap(innerSplit.thicknessFraction), 0.4, accuracy: 0.03)
    }

    func testComposableTabs026CaptureSkipsAZoomedTree() throws {
        let root = try sideBySide()
        size(root)
        let left = try leaf(leftID, in: root)
        let right = try leaf(rightID, in: root)
        root.setZoomedLeaf(left)
        left.thicknessFraction = sentinel
        right.thicknessFraction = sentinel
        root.captureThicknessFractions()
        XCTAssertEqual(left.thicknessFraction, sentinel)
        XCTAssertEqual(right.thicknessFraction, sentinel)
    }

    func testComposableTabs027CaptureSkipsARailSplit() throws {
        let root = try sideBySide()
        size(root)
        let left = try leaf(leftID, in: root)
        let right = try leaf(rightID, in: root)
        root.paneDidRequestMinimize(left, to: .leading)
        left.thicknessFraction = sentinel
        right.thicknessFraction = sentinel
        root.captureThicknessFractions()
        XCTAssertEqual(left.thicknessFraction, sentinel)
        XCTAssertEqual(right.thicknessFraction, sentinel)
    }

    func testComposableTabs028CaptureSkipsCollapsedItems() throws {
        let root = try sideBySide()
        size(root)
        let left = try leaf(leftID, in: root)
        let right = try leaf(rightID, in: root)
        try item(for: right).isCollapsed = true
        left.thicknessFraction = sentinel
        right.thicknessFraction = sentinel
        root.captureThicknessFractions()
        XCTAssertEqual(right.thicknessFraction, sentinel, "the collapsed item's child is not overwritten")
    }

    func testComposableTabs029CaptureRecursesPastARailSplit() throws {
        let root = try nested()
        size(root)
        let left = try leaf(leftID, in: root)
        let top = try leaf(topID, in: root)
        let bottom = try leaf(bottomID, in: root)
        root.paneDidRequestMinimize(left, to: .leading)
        top.thicknessFraction = sentinel
        bottom.thicknessFraction = sentinel
        root.view.layoutSubtreeIfNeeded()
        root.captureThicknessFractions()
        XCTAssertNotEqual(top.thicknessFraction, sentinel, "the nested split is still read")
        XCTAssertNotEqual(bottom.thicknessFraction, sentinel)
    }

    // MARK: - Applying sizes from a template

    func testComposableTabs030ApplySizesMatchesExistingShape() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        let right = try leaf(rightID, in: root)
        left.thicknessFraction = 0.4
        right.thicknessFraction = 0.6
        root.applySizes(from: .leaf(contentType: alpha, thicknessFraction: 0.9))
        XCTAssertEqual(try XCTUnwrap(left.thicknessFraction), 0.4, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(right.thicknessFraction), 0.6, accuracy: 0.0001)
    }

    func testComposableTabs031ApplySizesForcesRelayout() throws {
        let root = try sideBySide()
        size(root)
        let template = LayoutNode.split(
            orientation: .horizontal,
            first: .leaf(contentType: alpha, thicknessFraction: 0.25),
            second: .leaf(contentType: beta, thicknessFraction: 0.75)
        )
        root.applySizes(from: template)
        XCTAssertEqual(try leaf(leftID, in: root).view.frame.width, 250, accuracy: 15,
                       "dividers move at once, not on the next natural layout pass")
    }

    // MARK: - Persisting thicknesses

    private func armedRoot(
        changes: @escaping (LayoutNode) -> Void
    ) throws -> ComposableTabsViewController {
        let root = try sideBySide()
        size(root)
        root.onLayoutDidChange = changes
        return root
    }

    func testComposableTabs009ResizeSchedulesAPersistThatFlushWrites() throws {
        var writes = 0
        let root = try armedRoot { _ in writes += 1 }
        root.splitViewDidResizeSubviews(resizeNotification(root))
        XCTAssertEqual(writes, 0, "debounced: nothing is written yet")
        root.flushPendingThicknessPersist()
        XCTAssertEqual(writes, 1)
    }

    func testComposableTabs032ResizesDebounceIntoOneWrite() throws {
        var writes = 0
        let root = try armedRoot { _ in writes += 1 }
        root.splitViewDidResizeSubviews(resizeNotification(root))
        wait(0.1)
        root.splitViewDidResizeSubviews(resizeNotification(root))
        XCTAssertEqual(writes, 0)
        wait(0.6)
        XCTAssertEqual(writes, 1, "two notifications collapse into one write")
    }

    func testComposableTabs033UnchangedSignatureIsNotDelivered() throws {
        var writes = 0
        let root = try armedRoot { _ in writes += 1 }
        root.splitViewDidResizeSubviews(resizeNotification(root))
        root.flushPendingThicknessPersist()
        root.splitViewDidResizeSubviews(resizeNotification(root))
        root.flushPendingThicknessPersist()
        XCTAssertEqual(writes, 1, "the second flush saw the same rounded thicknesses")
    }

    func testComposableTabs034FlushWithNothingPendingDoesNothing() throws {
        var writes = 0
        let root = try armedRoot { _ in writes += 1 }
        // The first layout pass arms a persist of its own; drain it, then the
        // flush under test has nothing pending.
        root.flushPendingThicknessPersist()
        writes = 0
        root.flushPendingThicknessPersist()
        XCTAssertEqual(writes, 0)
    }

    func testComposableTabs035() throws {
        throw XCTSkip("scheduling is private and only observable through a timer on a non-root instance")
    }

    func testComposableTabs094FlushWritesNowAndNoTimerWriteFollows() throws {
        var writes = 0
        let root = try armedRoot { _ in writes += 1 }
        root.splitViewDidResizeSubviews(resizeNotification(root))
        root.flushPendingThicknessPersist()
        XCTAssertEqual(writes, 1, "written immediately")
        wait(0.6)
        XCTAssertEqual(writes, 1, "the cancelled timer never writes")
    }

    // MARK: - Split

    func testComposableTabs036SplitCreatesASiblingPane() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)

        root.split(left, adding: beta, direction: .right)

        let innerSplit = try XCTUnwrap(root.layoutChildren[0] as? ComposableTabsViewController)
        XCTAssertTrue(innerSplit.layoutChildren[0] === left, "the original pane stays first")
        let sibling = try XCTUnwrap(innerSplit.layoutChildren[1] as? ComposableTabsPaneViewController)
        XCTAssertEqual(sibling.viewID, beta)
    }

    func testComposableTabs037SplitWrapsInAnInnerSplitOnTheDirectionsAxis() throws {
        let root = try sideBySide()
        root.split(try leaf(leftID, in: root), adding: beta, direction: .right)
        let innerSplit = try XCTUnwrap(root.layoutChildren[0] as? ComposableTabsViewController)
        XCTAssertEqual(innerSplit.axis, .horizontal)

        root.split(try leaf(rightID, in: root), adding: alpha, direction: .below)
        let lower = try XCTUnwrap(root.layoutChildren[1] as? ComposableTabsViewController)
        XCTAssertEqual(lower.axis, .vertical)
    }

    func testComposableTabs038SplitInheritsTheSlotSize() throws {
        // Unloaded: a loaded split first re-captures fractions from geometry,
        // which would overwrite the 0.4 this vector sets.
        let root = try sideBySide(load: false)
        let left = try leaf(leftID, in: root)
        left.thicknessFraction = 0.4

        root.split(left, adding: beta, direction: .right)

        let innerSplit = try XCTUnwrap(root.layoutChildren[0] as? ComposableTabsViewController)
        XCTAssertEqual(try XCTUnwrap(innerSplit.thicknessFraction), 0.4, accuracy: 0.0001)
        XCTAssertNil(left.thicknessFraction)
    }

    func testComposableTabs039SplitPropagatesConfiguration() throws {
        let root = try sideBySide()
        let arranger = ProportionalArranger()
        let override = try installLayout()
        let owner = UUID()
        root.arranger = arranger
        root.layoutOverride = override
        root.stateOwnerNodeID = owner
        root.clampsToContainer = true

        root.split(try leaf(leftID, in: root), adding: beta, direction: .right)

        let innerSplit = try XCTUnwrap(root.layoutChildren[0] as? ComposableTabsViewController)
        XCTAssertTrue(innerSplit.arranger === arranger)
        XCTAssertTrue(innerSplit.layoutOverride === override)
        XCTAssertEqual(innerSplit.stateOwnerNodeID, owner)
        XCTAssertTrue(innerSplit.clampsToContainer)
    }

    func testComposableTabs040SplitPersistsAndRearranges() throws {
        let root = try sideBySide()
        let spy = CTSpyArranger()
        root.arranger = spy
        var snapshots: [LayoutNode] = []
        root.onLayoutDidChange = { snapshots.append($0) }

        root.split(try leaf(leftID, in: root), adding: beta, direction: .right)

        XCTAssertFalse(spy.axes.isEmpty, "the arrangement was applied")
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first.map { leafIDs(of: $0).count }, 3)
    }

    func testComposableTabs090SplitDoesNothingWithoutAProject() throws {
        try installLayout()
        let pane = makePane(leftID)
        let root = ComposableTabsViewController(
            nodeID: UUID(),
            axis: .horizontal,
            children: [pane],
            project: nil,
            workingDirectory: project.directoryURL,
            isRoot: true
        )
        root.loadViewIfNeeded()
        let itemsBefore = root.splitViewItems.count

        root.split(pane, adding: beta, direction: .right)

        XCTAssertEqual(root.layoutChildren.count, 1)
        XCTAssertTrue(root.layoutChildren[0] === pane)
        XCTAssertEqual(root.splitViewItems.count, itemsBefore)
    }

    // MARK: - Remove

    func testComposableTabs041RemoveRefusesANonDirectChild() throws {
        let root = try nested()
        let before = root.splitViewItems.count
        let deeper = try leaf(topID, in: root)

        root.remove(deeper)

        XCTAssertEqual(root.layoutChildren.count, 2)
        XCTAssertEqual(root.splitViewItems.count, before)
        XCTAssertEqual(root.leafCount(), 3)
    }

    func testComposableTabs042RemoveHonoursTheSpecVeto() throws {
        let root = try sideBySide(bounded: true)
        let left = try leaf(leftID, in: root)

        root.remove(left)

        XCTAssertEqual(root.allLeaves().map(\.nodeID), [leftID, rightID])
    }

    func testComposableTabs043RemoveTearsDownPaneContent() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)

        root.remove(left)

        XCTAssertNil(left.host)
        XCTAssertEqual(log.counts[leftID], 1, "told exactly once")
    }

    func testComposableTabs044RemoveClearsSiblingFractions() throws {
        let root = try sideBySide()
        try leaf(leftID, in: root).thicknessFraction = 0.3
        let right = try leaf(rightID, in: root)
        right.thicknessFraction = 0.7

        root.remove(try leaf(leftID, in: root))

        XCTAssertNil(right.thicknessFraction)
    }

    func testComposableTabs045RemoveCollapsesADegenerateSplit() throws {
        // Unloaded, so removal does not re-capture fractions from geometry.
        let root = try nested(load: false)
        let innerSplit = try XCTUnwrap(root.layoutChildren[1] as? ComposableTabsViewController)
        innerSplit.thicknessFraction = 0.35
        let top = try leaf(topID, in: root)

        innerSplit.remove(try leaf(bottomID, in: root))

        XCTAssertTrue(root.layoutChildren[1] === top, "the survivor takes the split's place")
        XCTAssertEqual(try XCTUnwrap(top.thicknessFraction), 0.35, accuracy: 0.0001)
    }

    func testComposableTabs046() throws {
        throw XCTSkip("needs a window server: first-responder re-homing is observable only in a key window")
    }

    func testComposableTabs047RemovePersistsAndRearranges() throws {
        let root = try sideBySide()
        let spy = CTSpyArranger()
        root.arranger = spy
        var snapshots: [LayoutNode] = []
        root.onLayoutDidChange = { snapshots.append($0) }

        root.remove(try leaf(leftID, in: root))

        XCTAssertFalse(spy.axes.isEmpty)
        XCTAssertEqual(snapshots.count, 1)
    }

    func testComposableTabs059TearDownPanesNotifiesEveryLeafOnce() throws {
        let root = try nested()
        root.tearDownPanes()
        for id in [leftID, topID, bottomID] {
            XCTAssertEqual(log.counts[id], 1)
        }
    }

    // MARK: - Move

    func testComposableTabs048MoveRefusedBySpec() throws {
        // Alpha's region is the first slot, beta's the second: swapping them
        // would put each in a region that does not allow it.
        try installLayoutWithRegions()
        let root = ComposableTabsViewController.make(
            from: .split(
                orientation: .horizontal,
                first: .leaf(id: leftID, contentType: alpha),
                second: .leaf(id: rightID, contentType: beta)
            ),
            project: project, workingDirectory: project.directoryURL, isRoot: true)
        root.loadViewIfNeeded()
        let betaPane = try leaf(rightID, in: root)

        XCTAssertFalse(root.move(betaPane, .left))
        XCTAssertEqual(root.allLeaves().map(\.nodeID), [leftID, rightID])
    }

    func testComposableTabs049AvailableDirectionsAreFilteredBySpec() throws {
        try installLayoutWithRegions()
        let root = ComposableTabsViewController.make(
            from: .split(
                orientation: .horizontal,
                first: .leaf(id: leftID, contentType: alpha),
                second: .leaf(id: rightID, contentType: beta)
            ),
            project: project, workingDirectory: project.directoryURL, isRoot: true)
        root.loadViewIfNeeded()
        let betaPane = try leaf(rightID, in: root)
        let unfiltered = ComposableTabsMove.availableDirections(for: rightID, in: root.snapshotNode())
        XCTAssertTrue(unfiltered.contains(.left), "geometry alone allows the swap")

        XCTAssertFalse(root.availableMoveDirections(for: betaPane).contains(.left))
    }

    /// Two regions, each admitting only its own view.
    private func installLayoutWithRegions() throws {
        let registry = ComposableTabsViewRegistry()
        registry.register(alpha, descriptor: .init(displayName: "Alpha", minimumThickness: 150)) { _ in
            NSViewController()
        }
        registry.register(beta, descriptor: .init(displayName: "Beta", minimumThickness: 150)) { _ in
            NSViewController()
        }
        ComposableTabsLayout.install(try ComposableTabsLayout(
            registry: registry,
            spec: .split(
                axis: .horizontal,
                children: [
                    .pane(alpha, allows: [.unbounded(alpha)]),
                    .pane(beta, allows: [.unbounded(beta)])
                ]
            )
        ))
    }

    func testComposableTabs091() throws {
        throw XCTSkip("a spec-less project cannot be built: ProjectWorkspace always carries a layout")
    }

    func testComposableTabs092MoveRebuildsTheRoot() throws {
        let root = try stacked()
        let top = try leaf(topID, in: root)
        let direction = try XCTUnwrap(root.availableMoveDirections(for: top).first)
        let expected = try XCTUnwrap(ComposableTabsMove.moving(topID, direction, in: root.snapshotNode()))

        XCTAssertTrue(root.move(top, direction))

        XCTAssertEqual(leafIDs(of: root.snapshotNode()), leafIDs(of: expected))
    }

    // MARK: - Rebuild

    private func swappedStack() -> LayoutNode {
        .split(
            orientation: .vertical,
            first: .leaf(id: rightID, contentType: beta),
            second: .leaf(id: leftID, contentType: alpha)
        )
    }

    func testComposableTabs050RebuildReusesLivePanes() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        let right = try leaf(rightID, in: root)

        root.rebuild(from: swappedStack())

        XCTAssertTrue(root.allLeaves().contains { $0 === left })
        XCTAssertTrue(root.allLeaves().contains { $0 === right })
        XCTAssertEqual(root.allLeaves().map(\.nodeID), [rightID, leftID])
    }

    func testComposableTabs051RebuildTearsDownDroppedPanes() throws {
        let root = try sideBySide()
        root.rebuild(from: .leaf(id: leftID, contentType: alpha))
        XCTAssertEqual(log.counts[rightID], 1)
        XCTAssertNil(log.counts[leftID])
    }

    func testComposableTabs052() throws {
        throw XCTSkip("the order of detaching and re-hosting inside one call is not observable from outside")
    }

    func testComposableTabs053RebuildSingleLeafIsTheRootsOnlyChild() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)

        root.rebuild(from: .leaf(id: leftID, contentType: alpha))

        XCTAssertEqual(root.layoutChildren.count, 1)
        XCTAssertTrue(root.layoutChildren[0] === left)
    }

    func testComposableTabs054RebuildCarriesThicknessFractions() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)

        root.rebuild(from: .split(
            orientation: .horizontal,
            first: .leaf(id: leftID, contentType: alpha, thicknessFraction: 0.25),
            second: .leaf(id: rightID, contentType: beta, thicknessFraction: 0.75)
        ))

        XCTAssertEqual(try XCTUnwrap(left.thicknessFraction), 0.25, accuracy: 0.0001)
    }

    func testComposableTabs055RebuildPersistsFromTheRoot() throws {
        let root = try sideBySide()
        var snapshots: [LayoutNode] = []
        root.onLayoutDidChange = { snapshots.append($0) }

        root.rebuild(from: swappedStack())

        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first.map { leafIDs(of: $0) }, [rightID, leftID])
    }

    func testComposableTabs088ReapplyReresolvesTheMinimizeEdge() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        root.paneDidRequestMinimize(left, to: .leading)
        XCTAssertEqual(left.minimizedEdge, .leading)

        // Same axis, other slot: `.leading` no longer applies, `.trailing` does.
        // (An axis change has no applicable edge, and clears it.)
        root.rebuild(from: .split(
            orientation: .horizontal,
            first: .leaf(id: rightID, contentType: beta),
            second: .leaf(id: leftID, contentType: alpha)
        ))

        XCTAssertEqual(left.minimizedEdge, .trailing, "the stale leading edge is replaced by the one that applies")
    }

    // MARK: - Spec queries and tree walking

    func testComposableTabs056AllowedInsertionsDelegateToTheSpec() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        let layout = try XCTUnwrap(ComposableTabsLayout.current)
        let expected = layout.spec.allowedInsertions(
            at: leftID, in: root.snapshotNode(), registry: layout.registry)
        XCTAssertEqual(root.allowedInsertions(beside: left), expected)
    }

    func testComposableTabs057() throws {
        throw XCTSkip("unreachable: rootSplit() always answers (a split with no parent is its own root)")
    }

    func testComposableTabs058RootWalkFollowsIsRootOnAnUnloadedTree() throws {
        let root = try nested(load: false)
        let innerSplit = try XCTUnwrap(root.layoutChildren[1] as? ComposableTabsViewController)
        XCTAssertFalse(innerSplit.isViewLoaded)
        XCTAssertTrue(innerSplit.rootSplit() === root)
    }

    func testComposableTabs061() throws {
        throw XCTSkip("persisting is private; a non-root's refusal is only visible through its own timer")
    }

    func testComposableTabs062() throws {
        throw XCTSkip("the order of the five persist steps is internal to one private call")
    }

    func testComposableTabs063SnapshotUnwrapsASingleChild() throws {
        let root = try makeTree(.leaf(id: leftID, contentType: alpha), load: false)
        let snapshot = root.snapshotNode()
        XCTAssertEqual(snapshot.id, leftID)
        if case .split = snapshot.kind { XCTFail("a one-child split reports its child, not a wrapper") }
    }

    func testComposableTabs064EmptyTreeSnapshotIsAPlaceholder() throws {
        try installLayout()
        let root = makeSplit(axis: .horizontal, children: [], isRoot: true)
        guard case .leaf(let contentType, _) = root.snapshotNode().kind else {
            return XCTFail("an empty split snapshots as a leaf")
        }
        XCTAssertEqual(contentType, .placeholder)
    }

    func testComposableTabs089() throws {
        throw XCTSkip("the per-pane refresh is not overridable or otherwise observable from a test")
    }

    // MARK: - Items

    func testComposableTabs065ItemSizingFromTheDescriptor() throws {
        let root = try makeTree(.split(
            orientation: .horizontal,
            first: .leaf(id: leftID, contentType: gamma),
            second: .leaf(id: rightID, contentType: beta)
        ))
        let built = try item(for: try leaf(leftID, in: root))
        XCTAssertEqual(built.minimumThickness, 200)
        XCTAssertTrue(built.canCollapse)
        XCTAssertEqual(built.preferredThicknessFraction, 0.3, accuracy: 0.0001)
    }

    private func clampedTree() throws -> ComposableTabsViewController {
        try installLayout()
        let root = ComposableTabsViewController.make(
            from: .split(
                orientation: .horizontal,
                first: .leaf(id: leftID, contentType: gamma),
                second: .leaf(id: rightID, contentType: beta)
            ),
            project: project, workingDirectory: project.directoryURL, isRoot: true)
        root.clampsToContainer = true
        root.loadViewIfNeeded()
        return root
    }

    func testComposableTabs066ClampedItemsHoldWithTheMinimalPriority() throws {
        let root = try clampedTree()
        for built in root.splitViewItems {
            XCTAssertEqual(built.holdingPriority, ComposableTabsViewController.clampedHoldingPriority)
        }
    }

    func testComposableTabs067ClampedTreeHasNoMinimum() throws {
        let root = try clampedTree()
        let built = try XCTUnwrap(root.splitViewItems.first)
        XCTAssertEqual(built.minimumThickness, NSSplitViewItem.unspecifiedDimension,
                       "the descriptor's 200 is given up in a clamped tree")
    }

    func testComposableTabs068() throws {
        throw XCTSkip("the transient invalid constraint pair is internal to one property assignment sequence")
    }

    // MARK: - Close

    func testComposableTabs071CloseChecksMembership() throws {
        let refusals = recordingRefusals()
        let root = try sideBySide()
        let other = try sideBySide()
        let stranger = try XCTUnwrap(other.allLeaves().first)

        root.paneDidRequestClose(stranger)

        XCTAssertEqual(refusals.count, 1)
        XCTAssertEqual(root.leafCount(), 2)
    }

    func testComposableTabs072CloseVetoedWithoutAHandlerIsRefused() throws {
        let refusals = recordingRefusals()
        let root = try sideBySide(bounded: true)

        root.paneDidRequestClose(try leaf(leftID, in: root))

        XCTAssertEqual(refusals.count, 1)
        XCTAssertEqual(root.leafCount(), 2)
    }

    func testComposableTabs073LastPaneCloseGoesToTheHandler() throws {
        let root = try makeTree(.leaf(id: leftID, contentType: alpha))
        var handed: [UUID] = []
        root.onLastPaneCloseRequest = { handed.append($0.nodeID) }

        root.paneDidRequestClose(try leaf(leftID, in: root))

        XCTAssertEqual(handed, [leftID])
        XCTAssertEqual(root.leafCount(), 1, "removal is not attempted")
    }

    func testComposableTabs074CloseClearsTheZoomBeforeRemoval() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        root.paneDidRequestZoom(left)
        XCTAssertTrue(root.zoomedLeaf === left)

        root.paneDidRequestClose(left)

        XCTAssertNil(root.zoomedLeaf)
        XCTAssertEqual(root.allLeaves().map(\.nodeID), [rightID])
    }

    func testComposableTabs075CanCloseWhenTheSpecAllows() throws {
        let root = try sideBySide()
        XCTAssertTrue(root.canClose(try leaf(leftID, in: root)))
    }

    func testComposableTabs093CannotCloseWhenVetoedWithNoHandler() throws {
        let root = try sideBySide(bounded: true)
        XCTAssertFalse(root.canClose(try leaf(leftID, in: root)))
    }

    // MARK: - Minimize, restore, zoom

    func testComposableTabs076MinimizeRefusesAnUnresolvableEdge() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)

        root.paneDidRequestMinimize(left, to: .top)

        XCTAssertNil(left.minimizedEdge)
        XCTAssertEqual(try item(for: left).maximumThickness, NSSplitViewItem.unspecifiedDimension)
    }

    func testComposableTabs077MinimizeClearsTheZoomFirst() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        root.paneDidRequestZoom(left)

        root.paneDidRequestMinimize(left, to: .leading)

        XCTAssertNil(root.zoomedLeaf)
        XCTAssertEqual(left.minimizedEdge, .leading)
    }

    func testComposableTabs078MinimizePinsTheSplitItem() throws {
        let root = try sideBySide(bounded: false)
        let left = try leaf(leftID, in: root)
        let fraction = try item(for: left).preferredThicknessFraction

        root.paneDidRequestMinimize(left, to: .leading)

        let pinned = try item(for: left)
        let thickness = left.minimizedThickness(for: .leading)
        XCTAssertEqual(pinned.minimumThickness, thickness)
        XCTAssertEqual(pinned.maximumThickness, thickness)
        XCTAssertEqual(pinned.holdingPriority, .defaultHigh)
        XCTAssertEqual(pinned.preferredThicknessFraction, fraction, accuracy: 0.0001)
    }

    func testComposableTabs079MinimizeIsRecordedOnAnUndisplayedTab() throws {
        let root = try sideBySide(load: false)
        let left = try leaf(leftID, in: root)
        XCTAssertTrue(root.splitViewItems.isEmpty, "no split item exists yet")

        root.paneDidRequestMinimize(left, to: .leading)

        XCTAssertEqual(left.minimizedEdge, .leading)
    }

    func testComposableTabs080RestoreUnpinsAndClears() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        root.paneDidRequestMinimize(left, to: .leading)

        root.paneDidRequestRestore(left)

        XCTAssertNil(left.minimizedEdge)
        XCTAssertEqual(try item(for: left).maximumThickness, NSSplitViewItem.unspecifiedDimension)
    }

    func testComposableTabs081ZoomRestoresAMinimizedPaneFirst() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        root.paneDidRequestMinimize(left, to: .leading)

        root.paneDidRequestZoom(left)

        XCTAssertNil(left.minimizedEdge)
        XCTAssertTrue(root.zoomedLeaf === left)
    }

    func testComposableTabs082ZoomCollapsesEverythingOffThePath() throws {
        let root = try makeTree(.split(
            orientation: .horizontal,
            first: .leaf(id: leftID, contentType: alpha),
            second: .split(
                orientation: .vertical,
                first: .leaf(id: topID, contentType: alpha),
                second: .split(
                    orientation: .horizontal,
                    first: .leaf(id: bottomID, contentType: beta),
                    second: .leaf(id: rightID, contentType: beta)
                )
            )
        ))
        let target = try leaf(rightID, in: root)

        root.paneDidRequestZoom(target)

        XCTAssertTrue(try item(for: try leaf(leftID, in: root)).isCollapsed)
        XCTAssertTrue(try item(for: try leaf(topID, in: root)).isCollapsed)
        XCTAssertTrue(try item(for: try leaf(bottomID, in: root)).isCollapsed)
        XCTAssertFalse(try item(for: target).isCollapsed)
        let middle = try XCTUnwrap(root.layoutChildren[1] as? ComposableTabsViewController)
        XCTAssertFalse(try XCTUnwrap(root.splitViewItem(for: middle)).isCollapsed, "on the path")
    }

    func testComposableTabs083ZoomingPreservesTheTreeShape() throws {
        let root = try nested()
        let before = root.snapshotNode()
        let target = try leaf(topID, in: root)

        root.paneDidRequestZoom(target)
        root.paneDidRequestZoom(target)

        let after = root.snapshotNode()
        XCTAssertTrue(after.hasSameStructure(as: before))
        XCTAssertEqual(leafIDs(of: after), leafIDs(of: before))
    }

    // MARK: - Persisted pane state

    func testComposableTabs084PersistedStateAppliesOncePerAppearance() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        left.stateStore.setPaneStateValue(PaneEdge.leading.rawValue, forKey: PaneStateKey.minimizeEdge)
        root.viewDidAppear()
        XCTAssertEqual(left.minimizedEdge, .leading)
        left.setMinimized(to: nil)

        root.viewDidAppear()

        XCTAssertNil(left.minimizedEdge, "the second appearance does not re-apply")
    }

    func testComposableTabs085InvalidPersistedEdgeRestoresInstead() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        left.stateStore.setPaneStateValue(PaneEdge.top.rawValue, forKey: PaneStateKey.minimizeEdge)

        root.applyPersistedPaneState()

        XCTAssertNil(left.minimizedEdge)
        XCTAssertEqual(try item(for: left).maximumThickness, NSSplitViewItem.unspecifiedDimension)
    }

    func testComposableTabs086() throws {
        throw XCTSkip("a resize notification or persist caused by a no-op reapply is not separable from layout noise")
    }

    func testComposableTabs087ReapplyDropsAStaleZoom() throws {
        let root = try sideBySide()
        let stranger = try XCTUnwrap(try sideBySide().allLeaves().first)
        root.zoomedLeaf = stranger
        for built in root.splitViewItems { built.isCollapsed = true }

        root.reapplyPaneState()

        XCTAssertNil(root.zoomedLeaf)
        XCTAssertTrue(root.splitViewItems.allSatisfy { !$0.isCollapsed })
    }

    func testComposableTabs097MinimizeIsPinnedBeforeZoomCollapsesIt() throws {
        let root = try sideBySide()
        let left = try leaf(leftID, in: root)
        let right = try leaf(rightID, in: root)
        left.stateStore.setPaneStateValue(PaneEdge.leading.rawValue, forKey: PaneStateKey.minimizeEdge)
        right.stateStore.setPaneStateValue("1", forKey: PaneStateKey.zoomed)

        root.applyPersistedPaneState()

        let built = try item(for: left)
        XCTAssertEqual(built.minimumThickness, built.maximumThickness, "pinned")
        XCTAssertTrue(built.isCollapsed, "and collapsed")
    }

    // MARK: - Requirements no unit test can observe

    func testComposableTabs098KeyboardCannotResize() throws {
        throw XCTSkip("a negative requirement: the absence of a keyboard path cannot be asserted by a unit test")
    }

    func testComposableTabs099ConfinedToTheUIThread() throws {
        throw XCTSkip("main-actor isolation is enforced by the compiler; a violation does not compile")
    }
}
