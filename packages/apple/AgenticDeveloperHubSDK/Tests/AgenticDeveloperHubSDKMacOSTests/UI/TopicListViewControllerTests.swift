import XCTest
import AppKit
import AgenticDeveloperHubSDKMacOS

/// `preferredWidth` drives the content-sized settings sidebar: it must reflect
/// the widest row so every topic title is fully disclosed and the width is
/// deterministic (never a remembered drag).
@MainActor
final class TopicListViewControllerTests: XCTestCase {

    private func makeLoaded() -> TopicListViewController {
        let controller = TopicListViewController()
        _ = controller.view // force loadView so the outline exists
        return controller
    }

    func testPreferredWidthGrowsWithTheLongestTitle() {
        let controller = makeLoaded()

        controller.setItems([TopicListItem(id: "1", title: "Hi")])
        let narrow = controller.preferredWidth()

        controller.setItems([TopicListItem(id: "1", title: "A considerably longer topic title")])
        let wide = controller.preferredWidth()

        XCTAssertGreaterThan(wide, narrow,
            "the sidebar width must expand to fit the longest row")
    }

    func testPreferredWidthUsesTheWidestRowNotTheFirst() {
        let controller = makeLoaded()
        controller.setItems([
            TopicListItem(id: "1", title: "A"),
            TopicListItem(id: "2", title: "The widest row of them all"),
            TopicListItem(id: "3", title: "B")
        ])
        let widest = controller.preferredWidth()

        controller.setItems([TopicListItem(id: "1", title: "The widest row of them all")])
        let single = controller.preferredWidth()

        XCTAssertEqual(widest, single, accuracy: 0.5,
            "width must be driven by the widest row regardless of its position")
    }

    func testPreferredWidthIsPositiveWhenEmpty() {
        let controller = makeLoaded()
        controller.setItems([])
        XCTAssertGreaterThan(controller.preferredWidth(), 0,
            "even an empty list reserves its chrome padding")
    }

    private func cell(_ controller: TopicListViewController, row: Int) throws -> NSTableCellView {
        let outline = try XCTUnwrap(findOutline(in: controller.view))
        let delegate = try XCTUnwrap(outline.delegate)
        let view = delegate.outlineView?(outline, viewFor: nil, item: outline.item(atRow: row) as Any)
        return try XCTUnwrap(view as? NSTableCellView)
    }

    private func findOutline(in view: NSView) -> NSOutlineView? {
        if let outline = view as? NSOutlineView { return outline }
        for sub in view.subviews { if let found = findOutline(in: sub) { return found } }
        return nil
    }

    private func badgeLabel(in cell: NSTableCellView) -> NSTextField? {
        cell.subviews.compactMap { $0 as? NSTextField }.first { $0 !== cell.textField }
    }

    private func isBold(_ field: NSTextField?) -> Bool {
        guard let font = field?.font else { return false }
        return NSFontManager.shared.traits(of: font).contains(.boldFontMask)
    }

    /// topic-list-030: a badge trails the label; an emphasized label is bold.
    func testBadgeAndEmphasisAreRendered() throws {
        let controller = makeLoaded()
        controller.setItems([
            TopicListItem(id: "1", title: "main", badge: "↑2 ↓1", isEmphasized: true),
            TopicListItem(id: "2", title: "dev")
        ])

        let main = try cell(controller, row: 0)
        let mainBadge = try XCTUnwrap(badgeLabel(in: main))
        XCTAssertEqual(mainBadge.stringValue, "↑2 ↓1")
        XCTAssertFalse(mainBadge.isHidden)
        XCTAssertEqual(mainBadge.accessibilityIdentifier(), "topic-list.item.main.badge")
        XCTAssertTrue(isBold(main.textField))

        let dev = try cell(controller, row: 1)
        XCTAssertEqual(badgeLabel(in: dev)?.isHidden, true)
        XCTAssertFalse(isBold(dev.textField))
    }

    /// topic-list-031: the preferred width makes room for a badge.
    func testPreferredWidthIncludesTheBadge() {
        let controller = makeLoaded()
        controller.setItems([TopicListItem(id: "1", title: "main")])
        let plain = controller.preferredWidth()

        controller.setItems([TopicListItem(id: "1", title: "main", badge: "↑12 ↓34")])
        XCTAssertGreaterThan(controller.preferredWidth(), plain)
    }

    /// Review V13-c: a selection made before the view loads is not lost.
    func testASelectionMadeBeforeTheViewLoadsIsApplied() {
        let controller = TopicListViewController()
        var reported = 0
        controller.onSelect = { _ in reported += 1 }
        controller.setItems([TopicListItem(id: "1", title: "A"), TopicListItem(id: "2", title: "B")])
        controller.selectItem(withId: "2")
        controller.setItems([TopicListItem(id: "1", title: "A"), TopicListItem(id: "2", title: "Bee")])

        _ = controller.view

        XCTAssertEqual(controller.selectedItem?.id, "2")
        XCTAssertEqual(reported, 0, "a programmatic selection fires no callback")
    }
}
