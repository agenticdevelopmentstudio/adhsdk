import Testing
import AppKit
@testable import AgenticDeveloperHubSDKUI

/// The divider-hiding guard, which is the one method `ThemedSplitViewController`
/// overrides for correctness rather than for appearance.
///
/// `NSSplitViewController`'s own implementation answers for divider `i` by
/// consulting the items on *both* sides of it — `i` and `i + 1` — and indexes
/// `splitViewItems` unguarded. So the interesting indices are the two the
/// override has to refuse before super sees them: the empty array AppKit asks
/// about while it measures a split view inside `viewDidLoad`, and the
/// `i == count - 1` that a pane removal produces, where AppKit still asks about
/// the divider whose second item has just gone away. A removal caught one beat
/// earlier produces a third: divider `-1`, which super indexes unsigned.
@MainActor
@Suite("ThemedSplitViewController divider hiding")
struct ThemedSplitViewControllerTests {

    /// A loaded controller holding `count` plain items. Loaded, because
    /// `splitViewItems` is only meaningful once the split view exists, and
    /// `ThemedSplitViewController` installs its themed split view in
    /// `loadView()`.
    private func makeController(items count: Int) -> ThemedSplitViewController {
        let controller = ThemedSplitViewController()
        controller.loadViewIfNeeded()
        for _ in 0..<count {
            controller.addSplitViewItem(NSSplitViewItem(viewController: NSViewController()))
        }
        return controller
    }

    @Test("An empty split refuses every divider rather than letting super index nothing")
    func noItems() {
        let controller = makeController(items: 0)
        #expect(controller.splitView(controller.splitView, shouldHideDividerAt: 0) == false)
    }

    /// The regression. One item means zero dividers, but AppKit asks about
    /// divider 0 anyway while it re-derives its stack constraints after a pane
    /// is removed from a two-item split. `dividerIndex < count` admitted that
    /// index and super threw an `NSRangeException` from inside it, killing the
    /// app.
    @Test("A solo item refuses divider 0 — the index a pane removal produces")
    func soloItem() {
        let controller = makeController(items: 1)
        #expect(controller.splitView(controller.splitView, shouldHideDividerAt: 0) == false)
    }

    /// The second half of the same regression, and the one that took the app
    /// down on closing the notes pane: with the removed pane's view already out
    /// of `arrangedSubviews` and its item still in `splitViewItems`, AppKit's
    /// divider walk runs one short and asks about `-1`. Super indexes with it
    /// unsigned, so the array reports `index 18446744073709551615`.
    @Test("A negative divider is refused rather than indexed unsigned")
    func negativeDivider() {
        for count in 0...3 {
            let controller = makeController(items: count)
            #expect(controller.splitView(controller.splitView, shouldHideDividerAt: -1) == false)
        }
    }

    /// And the guard is not so tight that it swallows the real question: a
    /// two-item split has one divider, and that one is super's to answer.
    @Test("A two-item split still gets super's answer for the divider it really has")
    func healthyPair() {
        let controller = makeController(items: 2)
        #expect(controller.splitView(controller.splitView, shouldHideDividerAt: 0) == false)
        #expect(controller.splitView(controller.splitView, shouldHideDividerAt: 1) == false,
                "one past the last divider is still out of bounds")
    }
}
