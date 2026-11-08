import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The strip across the top of a pane. It arranges four things and holds no
/// opinions about any of them.
@MainActor
@Suite("PaneTitleBarView")
struct PaneTitleBarViewTests {

    @Test("it holds a control cluster and a tagged title")
    func partsArePresent() {
        let bar = PaneTitleBarView()
        #expect(bar.subviews.contains { $0 === bar.controls })
        #expect(bar.subviews.contains { $0 === bar.titleLabel })
        #expect(bar.titleLabel.accessibilityIdentifier() == "pane.title")
    }

    /// The title truncates in the middle rather than pushing the gear off the
    /// end: the gear's *position* is the convention, and a long pane title is
    /// not a reason to move it.
    @Test("the title yields horizontally and truncates in the middle")
    func titleYields() {
        let bar = PaneTitleBarView()
        #expect(bar.titleLabel.cell?.lineBreakMode == .byTruncatingMiddle)
        #expect(bar.titleLabel.contentCompressionResistancePriority(for: .horizontal) == .defaultLow)
    }

    /// The icon sits between the controls and the title, and a pane without
    /// one closes the gap rather than leaving an empty square.
    @Test("the icon shows when set and hides when cleared, and the title follows it")
    func iconTogglesAndLeadsTheTitle() {
        let bar = PaneTitleBarView()
        #expect(bar.icon == nil)
        #expect(bar.iconView.isHidden)
        #expect(bar.iconView.accessibilityIdentifier() == "pane.icon")

        bar.frame = NSRect(x: 0, y: 0, width: 400, height: PaneTitleBarView.height)
        bar.title = "Files"
        bar.icon = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        bar.layoutSubtreeIfNeeded()
        #expect(!bar.iconView.isHidden)
        #expect(bar.iconView.frame.minX >= bar.controls.frame.maxX)
        #expect(bar.titleLabel.frame.minX >= bar.iconView.frame.maxX)

        bar.icon = nil
        bar.layoutSubtreeIfNeeded()
        #expect(bar.iconView.isHidden)
        #expect(abs(bar.titleLabel.frame.minX - (bar.controls.frame.maxX + 8)) < 1)
    }

    @Test("setting the title updates the label and its tooltip")
    func titleRoundTrips() {
        let bar = PaneTitleBarView()
        bar.title = "src/main.swift"
        #expect(bar.title == "src/main.swift")
        #expect(bar.titleLabel.stringValue == "src/main.swift")
        #expect(bar.titleLabel.toolTip == "src/main.swift")
    }

    /// The middle of the bar is the pane's to fill — a file browser's filter,
    /// a terminal's shell name. Replacing the array replaces what is shown, so
    /// content whose controls change does not leak the old ones.
    @Test("accessory views are installed and fully replaced")
    func accessoriesAreReplaceable() {
        let bar = PaneTitleBarView()
        let first = NSButton()
        bar.accessoryViews = [first]
        #expect(bar.accessoryViews == [first])
        #expect(first.superview != nil)

        let second = NSButton()
        bar.accessoryViews = [second]
        #expect(bar.accessoryViews == [second])
        #expect(first.superview == nil, "the replaced accessory is off the view tree, not just unlisted")
    }

    @Test("the gear slot takes a view and swaps it")
    func gearSlotSwaps() {
        let bar = PaneTitleBarView()
        #expect(bar.gearView == nil)

        let gear = NSButton()
        bar.gearView = gear
        #expect(bar.gearView === gear)
        #expect(gear.superview != nil)

        bar.gearView = nil
        #expect(gear.superview == nil)
    }

    /// Trailing-most, always. Everything else in the bar is variable; this is
    /// the one thing a reader can rely on finding in the same place.
    @Test("the gear sits trailing of the accessory area")
    func gearIsTrailingMost() {
        let bar = PaneTitleBarView()
        let gear = NSButton()
        let accessory = NSButton()
        bar.gearView = gear
        bar.accessoryViews = [accessory]
        bar.frame = NSRect(x: 0, y: 0, width: 400, height: PaneTitleBarView.height)
        bar.layoutSubtreeIfNeeded()

        let accessoryFrame = accessory.convert(accessory.bounds, to: bar)
        #expect(gear.frame.minX > accessoryFrame.maxX)
        #expect(accessoryFrame.minX > bar.titleLabel.frame.minX)
        #expect(bar.titleLabel.frame.minX > bar.controls.frame.maxX - 1)
    }

    // MARK: - Yielding width to the container

    /// A pane whose tree divides whatever width its container has cannot let its
    /// chrome insist on more. An intrinsic width in here reaches the enclosing
    /// split through this bar's required chain and lands there as a floor the
    /// container never asked for — one per pane, so a tab holding four editors
    /// acquires four of them, and the pane the tab lives in is dragged wider.
    ///
    /// Depth-first, because a stack view's own priority says nothing about what
    /// its children ask for: relaxing only the labels measurably left the floor
    /// where it was.
    @Test("yielding width relaxes the whole subtree, the dots included")
    func yieldingRelaxesTheWholeSubtree() {
        let bar = PaneTitleBarView()
        bar.yieldWidthToContainer()

        func demandsWidth(_ view: NSView) -> Bool {
            view.contentCompressionResistancePriority(for: .horizontal)
                > NSLayoutConstraint.Priority(rawValue: 1)
                || view.subviews.contains(where: demandsWidth)
        }

        #expect(!bar.controls.subviews.isEmpty, "the cluster has buttons to relax")
        #expect(!demandsWidth(bar), "a demand nested three deep reaches the split just the same")
    }

    /// The gear arrives after `init` and the accessories are replaced whenever
    /// the content's controls change, so the bar re-applies this itself. A rule
    /// a caller has to remember is a rule that gets forgotten.
    @Test("chrome installed after yielding yields too")
    func lateChromeYieldsToo() {
        let bar = PaneTitleBarView()
        bar.yieldWidthToContainer()

        let gear = NSButton()
        let accessory = NSTextField(labelWithString: "a filter field's worth of text")
        bar.gearView = gear
        bar.accessoryViews = [accessory]

        let yielding = NSLayoutConstraint.Priority(rawValue: 1)
        #expect(gear.contentCompressionResistancePriority(for: .horizontal) == yielding)
        #expect(accessory.contentCompressionResistancePriority(for: .horizontal) == yielding)
    }

    /// What the relaxation is for, measured rather than asserted: the same
    /// chrome, asked how much width it needs, answers with a fraction of it.
    /// Below that width the title truncates to nothing and the dots squeeze —
    /// the same bargain the middle truncation already makes.
    @Test("a yielding bar asks for a fraction of the width the same chrome demands")
    func aYieldingBarAsksForLess() {
        func bar(yielding: Bool) -> PaneTitleBarView {
            let bar = PaneTitleBarView()
            if yielding { bar.yieldWidthToContainer() }
            bar.title = "a pane title long enough to matter at any width"
            bar.gearView = NSButton()
            bar.accessoryViews = [NSTextField(labelWithString: "a filter field's worth of text")]
            return bar
        }

        let demanding = bar(yielding: false).fittingSize.width
        let yielding = bar(yielding: true).fittingSize.width

        #expect(demanding > 0)
        #expect(
            yielding < demanding / 2,
            "anything close to the demanding width is still a floor under the enclosing pane")
    }

    @Test("it is a fixed-height strip with a hairline under it")
    func heightAndHairline() {
        let bar = PaneTitleBarView()
        #expect(PaneTitleBarView.height == 26)
        #expect(bar.subviews.contains { $0 is ThemedSeparatorView })
    }
}
