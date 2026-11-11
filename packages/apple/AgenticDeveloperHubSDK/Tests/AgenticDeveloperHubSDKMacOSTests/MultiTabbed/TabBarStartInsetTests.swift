import AgenticDeveloperHubSDKCore
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Where a bar's first tab begins, and what a host can do about it.
@MainActor
final class TabBarStartInsetTests: XCTestCase {

    private func makeController() -> MultiTabbedViewController {
        let controller = MultiTabbedViewController()
        controller.loadViewIfNeeded()
        controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        return controller
    }

    private func makeContent() -> NSViewController {
        let content = NSViewController()
        content.view = NSView()
        return content
    }

    /// A hosted item with a size of its own, so the bar has something to lay
    /// out and the measurement is not of an empty view.
    private final class Item: NSViewController, TabBarHostedItem {
        var isHighlighted = false
        var onClose: (() -> Void)?
        override func loadView() {
            view = NSView()
            preferredContentSize = NSSize(width: 120, height: 80)
        }
    }

    /// How far the first tab's top sits below the top of its bar.
    private func firstTabTop(of controller: MultiTabbedViewController, on edge: Edge) -> CGFloat {
        controller.view.layoutSubtreeIfNeeded()
        guard let bar = controller.tabBars[edge],
              let item = bar.subviews.first?.subviews.first else {
            XCTFail("the bar laid out no tab")
            return .nan
        }
        let frame = bar.convert(item.frame, from: item.superview)
        return bar.bounds.maxY - frame.maxY
    }

    func testABarsFirstTabStartsAtTheDefaultEndPadding() {
        let controller = makeController()
        controller.addTab(.init(item: .viewController(Item()), viewController: makeContent()), on: .left)
        XCTAssertEqual(firstTabTop(of: controller, on: .left), TabBarView.endPadding, accuracy: 0.5)
    }

    func testTheStartInsetIsWhereTheFirstTabBegins() {
        let controller = makeController()
        controller.addTab(.init(item: .viewController(Item()), viewController: makeContent()), on: .right)
        controller.setTabStartInset(37, for: .right)
        XCTAssertEqual(firstTabTop(of: controller, on: .right), 37, accuracy: 0.5)
        XCTAssertEqual(controller.tabStartInset(for: .right), 37)
    }

    /// Each bar keeps its own: the alignment a side bar needs says nothing
    /// about where a top bar's tabs should begin.
    func testSettingOneBarsStartInsetLeavesTheOthersAlone() {
        let controller = makeController()
        controller.setTabStartInset(37, for: .left)
        XCTAssertEqual(controller.tabStartInset(for: .right), TabBarView.endPadding)
        XCTAssertEqual(controller.tabStartInset(for: .top), TabBarView.endPadding)
    }

    /// The reason the inset exists: a side tab's top meets the bottom of the
    /// title bar of the pane it belongs to, wherever the spacing puts it.
    func testProjectSpacingLinesTheSideTabsUpWithAPanesTitleBar() {
        let controller = makeController()
        let insets = NSEdgeInsets(top: 12, left: 4, bottom: 4, right: 4)
        ComposableTabsWindowController.applyPaneSpacing(insets, to: controller)

        let expected = 12 + ComposableTabsPaneViewController.titleBarBottom
        XCTAssertEqual(controller.tabStartInset(for: .left), expected)
        XCTAssertEqual(controller.tabStartInset(for: .right), expected)
        XCTAssertEqual(controller.contentInsets.top, 12)
        // A top bar lays its tabs out along the other axis, where a title bar
        // sits below every one of them and there is nothing to line up with.
        XCTAssertEqual(controller.tabStartInset(for: .top), TabBarView.endPadding)
    }

    // MARK: - Leading accessory

    private func accessory() -> NSButton {
        let button = NSButton(title: "+", target: nil, action: nil)
        button.bezelStyle = .texturedRounded
        return button
    }

    /// The first tab, in the bar's coordinates.
    private func firstTabFrame(in bar: TabBarView) -> NSRect {
        guard let item = bar.subviews.first?.subviews.first else {
            XCTFail("the bar laid out no tab")
            return .zero
        }
        return bar.convert(item.frame, from: item.superview)
    }

    /// The accessory sits where the first tab would have, the tabs start
    /// after it, and it is centred on them across the bar.
    func testALeadingAccessoryLeadsTheTabsCentredOnThem() throws {
        let controller = makeController()
        controller.addTab(.init(item: .viewController(Item()), viewController: makeContent()), on: .top)
        let plus = accessory()
        controller.setLeadingAccessory(plus, for: .top)
        controller.view.layoutSubtreeIfNeeded()

        let bar = try XCTUnwrap(controller.tabBars[.top])
        XCTAssertTrue(plus.superview === bar)
        let tab = firstTabFrame(in: bar)
        XCTAssertEqual(plus.frame.minX, TabBarView.endPadding, accuracy: 0.5)
        XCTAssertEqual(tab.minX, plus.frame.maxX + TabBarView.itemSpacing, accuracy: 0.5)
        XCTAssertEqual(plus.frame.midY, tab.midY, accuracy: 0.5)
    }

    func testTheStartInsetMovesTheAccessoryAndTheTabsWithIt() throws {
        let controller = makeController()
        controller.addTab(.init(item: .viewController(Item()), viewController: makeContent()), on: .top)
        let plus = accessory()
        controller.setLeadingAccessory(plus, for: .top)
        controller.setTabStartInset(30, for: .top)
        controller.view.layoutSubtreeIfNeeded()

        let bar = try XCTUnwrap(controller.tabBars[.top])
        XCTAssertEqual(plus.frame.minX, 30, accuracy: 0.5)
        XCTAssertEqual(firstTabFrame(in: bar).minX, plus.frame.maxX + TabBarView.itemSpacing, accuracy: 0.5)
    }

    func testRemovingTheAccessoryGivesTheTabsTheirPlaceBack() throws {
        let controller = makeController()
        controller.addTab(.init(item: .viewController(Item()), viewController: makeContent()), on: .top)
        let plus = accessory()
        controller.setLeadingAccessory(plus, for: .top)
        controller.setLeadingAccessory(nil, for: .top)
        controller.view.layoutSubtreeIfNeeded()

        let bar = try XCTUnwrap(controller.tabBars[.top])
        XCTAssertNil(plus.superview)
        XCTAssertEqual(firstTabFrame(in: bar).minX, TabBarView.endPadding, accuracy: 0.5)
    }
}
