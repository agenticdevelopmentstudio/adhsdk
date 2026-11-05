import XCTest
import AppKit
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKUI

/// The selected topic is always outlined: no AppKit focus ring (it vanishes in a
/// non-key window) and a row view that draws its own outline.
@MainActor
final class TopicListSelectionTests: XCTestCase {

    private func makeLoaded() -> TopicListViewController {
        let controller = TopicListViewController()
        _ = controller.view
        controller.setItems([TopicListItem(id: "1", title: "A")])
        return controller
    }

    private func findOutline(in view: NSView) -> NSOutlineView? {
        if let outline = view as? NSOutlineView { return outline }
        for sub in view.subviews { if let found = findOutline(in: sub) { return found } }
        return nil
    }

    func testTopicListOutlineViewHasNoFocusRing() throws {
        let controller = makeLoaded()
        let outline = try XCTUnwrap(findOutline(in: controller.view))
        XCTAssertEqual(outline.focusRingType, .none)
    }

    func testTopicListRowsDrawSelectionOutline() throws {
        let controller = makeLoaded()
        let outline = try XCTUnwrap(findOutline(in: controller.view))
        let delegate = try XCTUnwrap(outline.delegate)
        let row = delegate.outlineView?(outline, rowViewForItem: outline.item(atRow: 0) as Any)
        XCTAssertEqual((row as? ThemedTableRowView)?.drawsSelectionOutline, true)
    }
}
