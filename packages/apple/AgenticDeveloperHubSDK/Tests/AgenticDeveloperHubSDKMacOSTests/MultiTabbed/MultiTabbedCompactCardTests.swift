import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// A hosted bar item taller than the bar's default, in a window, where AppKit
/// solves each constraint as it is activated. The bar used to pin the item
/// across itself while it still had its 28pt default thickness and grow to
/// fit only afterwards, so the pins could not be satisfied and AppKit broke
/// one of the item's own constraints (a compact tab pane card's status icon
/// height) to recover.
@MainActor
final class MultiTabbedCompactCardTests: XCTestCase {
    /// Records the enclosing bar's thickness when it joins the window, the
    /// moment its pins across the bar are first solved.
    private final class ItemView: NSView {
        var thicknessOnJoining: CGFloat?
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil, thicknessOnJoining == nil else { return }
            var ancestor = superview
            while let view = ancestor, !(view is TabBarView) { ancestor = view.superview }
            thicknessOnJoining = (ancestor as? TabBarView)?.thicknessConstraint?.constant
        }
    }

    private final class TallItem: NSViewController, TabBarHostedItem {
        var isHighlighted = false
        var onClose: (() -> Void)?
        override func loadView() {
            view = ItemView()
            preferredContentSize = NSSize(width: 240, height: 34)
        }
    }

    func testTheBarIsThickEnoughBeforeATallItemIsPinnedAcrossIt() throws {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let controller = MultiTabbedViewController()
        window.contentViewController = controller

        let item = TallItem()
        item.loadViewIfNeeded()
        let content = NSViewController()
        content.view = NSView()
        controller.addTab(.init(item: .viewController(item), viewController: content), on: .top)

        let itemView = try XCTUnwrap(item.view as? ItemView)
        // 34 plus the bar's single 6pt outer padding.
        XCTAssertEqual(itemView.thicknessOnJoining, 40,
                       "the item was pinned across the bar before the bar grew to fit it")
        XCTAssertEqual(controller.tabBars[.top]?.thicknessConstraint?.constant, 40)
    }
}
