import AgenticDeveloperHubSDKCore
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The slot between the top tab bar and the content: a browser's address bar
/// sits under its tabs and over its page.
@MainActor
final class MultiTabbedAccessoryBelowBarTests: XCTestCase {

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

    /// A row with a fixed height of its own, as an address bar has.
    private func makeAccessory(height: CGFloat = 30) -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    /// `view`'s frame in the controller's root, which is not flipped: a
    /// greater y is higher on screen.
    private func frame(of view: NSView, in controller: MultiTabbedViewController) -> NSRect {
        controller.view.layoutSubtreeIfNeeded()
        return controller.view.convert(view.bounds, from: view)
    }

    func testTheAccessorySitsBetweenTheTopBarAndTheContent() throws {
        let controller = makeController()
        let content = makeContent()
        controller.addTab(.init(title: "One", viewController: content), on: .top)
        let accessory = makeAccessory()
        controller.setAccessoryBelowBar(accessory, for: .top)

        let bar = try XCTUnwrap(controller.tabBars[.top])
        let barFrame = frame(of: bar, in: controller)
        let accessoryFrame = frame(of: accessory, in: controller)
        let contentFrame = frame(of: content.view, in: controller)

        XCTAssertEqual(accessoryFrame.height, 30, accuracy: 0.5)
        XCTAssertEqual(accessoryFrame.maxY, barFrame.minY, accuracy: 0.5, "the accessory starts under the bar")
        XCTAssertEqual(contentFrame.maxY, accessoryFrame.minY, accuracy: 0.5, "the content starts under it")
        XCTAssertEqual(accessoryFrame.width, contentFrame.width, accuracy: 0.5, "it spans the content's width")
        XCTAssertTrue(controller.accessoryBelowBar(for: .top) === accessory)
    }

    /// Set before the view loads — the way a host builds it — the slot is
    /// filled when the view comes up.
    func testAnAccessorySetBeforeLoadIsInstalledOnLoad() {
        let controller = MultiTabbedViewController()
        let accessory = makeAccessory()
        controller.setAccessoryBelowBar(accessory, for: .top)
        let content = makeContent()
        controller.addTab(.init(title: "One", viewController: content), on: .top)
        controller.loadViewIfNeeded()
        controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 600)

        XCTAssertTrue(accessory.isDescendant(of: controller.view))
        let accessoryFrame = frame(of: accessory, in: controller)
        let contentFrame = frame(of: content.view, in: controller)
        XCTAssertEqual(contentFrame.maxY, accessoryFrame.minY, accuracy: 0.5)
    }

    /// Taking the accessory away gives the content the whole centre back.
    func testRemovingTheAccessoryReturnsTheSpace() throws {
        let controller = makeController()
        let content = makeContent()
        controller.addTab(.init(title: "One", viewController: content), on: .top)
        let accessory = makeAccessory()
        controller.setAccessoryBelowBar(accessory, for: .top)
        controller.setAccessoryBelowBar(nil, for: .top)

        let bar = try XCTUnwrap(controller.tabBars[.top])
        XCTAssertNil(accessory.superview)
        XCTAssertEqual(frame(of: content.view, in: controller).maxY,
                       frame(of: bar, in: controller).minY, accuracy: 0.5)
    }

    /// A row that collapses to nothing (a stack whose controls are all hidden,
    /// the browser's bar under Chrome's own toolbar) leaves no gap.
    func testACollapsedAccessoryLeavesNoGap() throws {
        let controller = makeController()
        let content = makeContent()
        controller.addTab(.init(title: "One", viewController: content), on: .top)
        let hidden = NSButton(title: "Back", target: nil, action: nil)
        hidden.isHidden = true
        let stack = NSStackView(views: [hidden])
        stack.detachesHiddenViews = true
        stack.edgeInsets = NSEdgeInsets()
        controller.setAccessoryBelowBar(stack, for: .top)

        let bar = try XCTUnwrap(controller.tabBars[.top])
        XCTAssertEqual(frame(of: content.view, in: controller).maxY,
                       frame(of: bar, in: controller).minY, accuracy: 0.5)
    }
}
