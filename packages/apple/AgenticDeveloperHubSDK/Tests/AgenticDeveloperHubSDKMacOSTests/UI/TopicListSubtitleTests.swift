import XCTest
import AppKit
@testable import AgenticDeveloperHubSDKMacOS

/// A row's optional second line (topic-list vectors 039–041): drawn under the
/// title only when there is one, counted in the sidebar's width, and the only
/// thing that makes a row taller.
@MainActor
final class TopicListSubtitleTests: XCTestCase {

    private func makeLoaded() -> TopicListViewController {
        let controller = TopicListViewController()
        _ = controller.view
        return controller
    }

    private func findOutline(in view: NSView) -> NSOutlineView? {
        if let outline = view as? NSOutlineView { return outline }
        for sub in view.subviews { if let found = findOutline(in: sub) { return found } }
        return nil
    }

    private func cell(_ controller: TopicListViewController, row: Int) throws -> NSTableCellView {
        let outline = try XCTUnwrap(findOutline(in: controller.view))
        let delegate = try XCTUnwrap(outline.delegate)
        let view = delegate.outlineView?(outline, viewFor: nil, item: outline.item(atRow: row) as Any)
        return try XCTUnwrap(view as? NSTableCellView)
    }

    private func rowHeight(_ controller: TopicListViewController, row: Int) throws -> CGFloat {
        let outline = try XCTUnwrap(findOutline(in: controller.view))
        let delegate = try XCTUnwrap(outline.delegate)
        return try XCTUnwrap(delegate.outlineView?(outline, heightOfRowByItem: outline.item(atRow: row) as Any))
    }

    private func subtitleLabel(in cell: NSTableCellView) -> NSTextField? {
        cell.subviews.compactMap { $0 as? NSTextField }
            .first { $0.accessibilityIdentifier().hasSuffix(".subtitle") }
    }

    /// topic-list-039
    func testASubtitleIsDrawnUnderTheTitleInTheSecondaryColor() throws {
        let controller = makeLoaded()
        controller.setItems([TopicListItem(id: "1", title: "Claude", subtitle: "Anthropic - API Key")])

        let label = try XCTUnwrap(subtitleLabel(in: try cell(controller, row: 0)))

        XCTAssertFalse(label.isHidden)
        XCTAssertEqual(label.stringValue, "Anthropic - API Key")
        XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)
        XCTAssertEqual(label.textColor, ThemePaletteObserver.currentPalette.secondaryTextColor)
        XCTAssertEqual(label.font, ThemePaletteObserver.currentPalette.font(.caption))
    }

    func testADisabledRowsSubtitleIsTertiary() throws {
        let controller = makeLoaded()
        controller.setItems([TopicListItem(id: "1", title: "Off", subtitle: "Gone", isDisabled: true)])
        let label = try XCTUnwrap(subtitleLabel(in: try cell(controller, row: 0)))
        XCTAssertEqual(label.textColor, ThemePaletteObserver.currentPalette.tertiaryTextColor)
    }

    /// topic-list-040: no subtitle, or an empty one, is the single-line row it always was.
    func testARowWithoutASubtitleIsUnchanged() throws {
        let controller = makeLoaded()
        controller.setItems([
            TopicListItem(id: "1", title: "Plain"),
            TopicListItem(id: "2", title: "Empty", subtitle: "")
        ])
        let outline = try XCTUnwrap(findOutline(in: controller.view))

        for row in 0..<2 {
            let label = subtitleLabel(in: try cell(controller, row: row))
            XCTAssertTrue(label?.isHidden ?? true)
            XCTAssertEqual(try rowHeight(controller, row: row), outline.rowHeight)
        }
    }

    func testASubtitledRowIsTallerThanAStandardRow() throws {
        let controller = makeLoaded()
        controller.setItems([TopicListItem(id: "1", title: "Claude", subtitle: "Anthropic")])
        let outline = try XCTUnwrap(findOutline(in: controller.view))
        XCTAssertGreaterThan(try rowHeight(controller, row: 0), outline.rowHeight)
    }

    func testAReusedCellDropsASubtitleItNoLongerHas() throws {
        let controller = makeLoaded()
        controller.setItems([TopicListItem(id: "1", title: "A", subtitle: "sub")])
        _ = try cell(controller, row: 0)
        controller.setItems([TopicListItem(id: "1", title: "A")])
        let label = subtitleLabel(in: try cell(controller, row: 0))
        XCTAssertTrue(label?.isHidden ?? true)
    }

    /// topic-list-041: a subtitle wider than its title widens the sidebar.
    func testPreferredWidthCountsAWideSubtitle() {
        let controller = makeLoaded()
        controller.setItems([TopicListItem(id: "1", title: "A")])
        let narrow = controller.preferredWidth()

        controller.setItems([TopicListItem(
            id: "1", title: "A", subtitle: "A considerably longer subtitle than the title")])
        let wide = controller.preferredWidth()

        XCTAssertGreaterThan(wide, narrow)
    }

    func testANarrowSubtitleDoesNotWidenTheSidebar() {
        let controller = makeLoaded()
        controller.setItems([TopicListItem(id: "1", title: "A fairly long title")])
        let titleOnly = controller.preferredWidth()

        controller.setItems([TopicListItem(id: "1", title: "A fairly long title", subtitle: "x")])

        XCTAssertEqual(controller.preferredWidth(), titleOnly, accuracy: 0.5)
    }
}
