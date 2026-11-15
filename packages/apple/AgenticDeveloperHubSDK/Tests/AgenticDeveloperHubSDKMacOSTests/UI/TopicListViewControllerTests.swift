import XCTest
import AppKit
@testable import AgenticDeveloperHubSDKMacOS

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

    // MARK: - Context menus and double-click

    private func menuWith(_ title: String) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: title, action: nil, keyEquivalent: ""))
        return menu
    }

    private func loadedWithSections() -> TopicListViewController {
        let controller = makeLoaded()
        controller.setSections([
            TopicListSection(title: "Branches", items: [TopicListItem(id: "b1", title: "main")]),
            TopicListSection(title: "Tags", items: [TopicListItem(id: "t1", title: "v1")])
        ])
        return controller
    }

    /// topic-list-032: an item row's menu is itemMenuProvider's, a header row's is
    /// headerMenuProvider's, each given what the row shows.
    func testContextMenuAsksTheProviderForTheRowsKind() {
        let controller = loadedWithSections()
        var askedItems: [String] = []
        var askedHeaders: [String] = []
        controller.itemMenuProvider = { item in
            askedItems.append(item.id)
            return self.menuWith("item \(item.id)")
        }
        controller.headerMenuProvider = { title in
            askedHeaders.append(title)
            return title == "Tags" ? self.menuWith("header \(title)") : nil
        }

        XCTAssertNil(controller.contextMenu(forRow: 0), "the provider declined the Branches header")
        XCTAssertEqual(controller.contextMenu(forRow: 1)?.items.map(\.title), ["item b1"])
        XCTAssertEqual(controller.contextMenu(forRow: 2)?.items.map(\.title), ["header Tags"])
        XCTAssertEqual(controller.contextMenu(forRow: 3)?.items.map(\.title), ["item t1"])
        XCTAssertNil(controller.contextMenu(forRow: 4))
        XCTAssertNil(controller.contextMenu(forRow: -1))
        XCTAssertEqual(askedItems, ["b1", "t1"])
        XCTAssertEqual(askedHeaders, ["Branches", "Tags"])
    }

    /// topic-list-033: with no providers set, no row has a menu.
    func testNoProvidersMeansNoMenus() {
        let controller = loadedWithSections()
        for row in 0..<4 { XCTAssertNil(controller.contextMenu(forRow: row)) }
    }

    /// topic-list-034: a double-clicked item row reaches onDoubleClick; a header row does not.
    func testDoubleClickReportsItemRowsOnly() {
        let controller = loadedWithSections()
        var clicked: [String] = []
        controller.onDoubleClick = { clicked.append($0.id) }
        for row in [0, 1, 2, 3, 9] { controller.doubleClick(row: row) }
        XCTAssertEqual(clicked, ["b1", "t1"])
    }

    /// topic-list-035: the outline view carries the menu the providers fill and sends its
    /// double-click to the list; opening the menu with no row clicked leaves it empty.
    func testOutlineCarriesTheMenuAndTheDoubleClick() throws {
        let controller = loadedWithSections()
        controller.itemMenuProvider = { _ in self.menuWith("unused") }
        let outline = try XCTUnwrap(findOutline(in: controller.view))
        let menu = try XCTUnwrap(outline.menu)
        XCTAssertTrue(outline.target === controller)
        XCTAssertNotNil(outline.doubleAction)
        controller.menuNeedsUpdate(menu)
        XCTAssertTrue(menu.items.isEmpty, "clickedRow is -1 outside a click")
    }

    // MARK: - Drag and drop

    private func pasteboard(with payload: String?) -> NSPasteboard {
        let board = NSPasteboard(name: NSPasteboard.Name("topic-list-test-\(UUID().uuidString)"))
        board.clearContents()
        if let payload { board.setString(payload, forType: TopicListViewController.itemPasteboardType) }
        return board
    }

    /// topic-list-036: an item row the provider gives a payload is dragged with it under
    /// the list's pasteboard type; a declined item, a header and a row outside give none.
    func testDragWritesThePayloadForDraggableItemsOnly() {
        let controller = loadedWithSections()
        XCTAssertNil(controller.pasteboardWriter(forRow: 1), "no provider, nothing is draggable")
        controller.dragPayloadProvider = { $0.id == "b1" ? "payload-\($0.id)" : nil }

        let writer = controller.pasteboardWriter(forRow: 1)
        XCTAssertEqual(writer?.string(forType: TopicListViewController.itemPasteboardType), "payload-b1")
        XCTAssertNil(controller.pasteboardWriter(forRow: 3), "the provider declined t1")
        XCTAssertNil(controller.pasteboardWriter(forRow: 0), "a header row is never dragged")
        XCTAssertNil(controller.pasteboardWriter(forRow: 7))
    }

    /// topic-list-037: a drop is offered only on an item row the validator accepts, and
    /// delivering it hands onDrop the payload and the row's item.
    func testDropIsValidatedAndDelivered() {
        let controller = loadedWithSections()
        let board = pasteboard(with: "refs/heads/x")
        XCTAssertFalse(controller.canDrop(pasteboard: board, onRow: 1), "no validator, no drop")

        var validated: [String] = []
        controller.dropValidator = { payload, target in
            validated.append("\(payload)>\(target.id)")
            return target.id == "b1"
        }
        var dropped: [String] = []
        controller.onDrop = { payload, target in dropped.append("\(payload)>\(target.id)") }

        XCTAssertTrue(controller.canDrop(pasteboard: board, onRow: 1))
        XCTAssertFalse(controller.canDrop(pasteboard: board, onRow: 3), "the validator refused t1")
        XCTAssertFalse(controller.canDrop(pasteboard: board, onRow: 0), "a header takes no drop")
        XCTAssertFalse(controller.canDrop(pasteboard: pasteboard(with: nil), onRow: 1), "no payload")
        XCTAssertFalse(controller.drop(pasteboard: board, onRow: 3))
        XCTAssertTrue(controller.drop(pasteboard: board, onRow: 1))
        XCTAssertEqual(dropped, ["refs/heads/x>b1"])
        XCTAssertTrue(validated.contains("refs/heads/x>t1"))
    }

    /// topic-list-038: the outline accepts the list's pasteboard type once loaded.
    func testOutlineRegistersForTheItemType() throws {
        let controller = loadedWithSections()
        let outline = try XCTUnwrap(findOutline(in: controller.view))
        XCTAssertTrue(outline.registeredDraggedTypes.contains(TopicListViewController.itemPasteboardType))
    }
}
