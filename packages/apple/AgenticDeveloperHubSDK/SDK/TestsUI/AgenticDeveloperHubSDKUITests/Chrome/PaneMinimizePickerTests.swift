import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The four-arrow cross, and the popover that carries it.
@MainActor
@Suite("PaneMinimizePicker")
struct PaneMinimizePickerTests {

    @Test("every edge has a tagged, labelled arrow")
    func everyEdgeHasAButton() {
        let cross = PaneMinimizeCrossView(availableEdges: Set(PaneEdge.allCases))
        for edge in PaneEdge.allCases {
            let button = cross.button(for: edge)
            #expect(button.accessibilityIdentifier() == "pane.minimize.\(edge.rawValue)")
            #expect(button.accessibilityLabel() == edge.displayName)
            #expect(button.toolTip == edge.displayName)
            #expect(button.image != nil)
        }
    }

    /// The cross is a cross: the arrows are laid out around a centre, not in a
    /// row. `NSGridView` says so structurally, which is why it is used instead
    /// of nested stacks.
    @Test("the arrows are laid out as a three-by-three cross")
    func layoutIsACross() {
        let cross = PaneMinimizeCrossView(availableEdges: Set(PaneEdge.allCases))
        let grid = cross.subviews.compactMap { $0 as? NSGridView }.first
        #expect(grid != nil)
        #expect(grid?.numberOfRows == 3)
        #expect(grid?.numberOfColumns == 3)
        #expect(grid?.cell(atColumnIndex: 1, rowIndex: 0).contentView === cross.button(for: .top))
        #expect(grid?.cell(atColumnIndex: 0, rowIndex: 1).contentView === cross.button(for: .leading))
        #expect(grid?.cell(atColumnIndex: 2, rowIndex: 1).contentView === cross.button(for: .trailing))
        #expect(grid?.cell(atColumnIndex: 1, rowIndex: 2).contentView === cross.button(for: .bottom))
    }

    @Test("only the offered edges are clickable")
    func unofferedEdgesAreDisabled() {
        let cross = PaneMinimizeCrossView(availableEdges: [.leading, .trailing])
        #expect(cross.button(for: .leading).isEnabled)
        #expect(cross.button(for: .trailing).isEnabled)
        #expect(cross.button(for: .top).isEnabled == false)
        #expect(cross.button(for: .bottom).isEnabled == false)
    }

    /// The set is settable because the legal edges change when the layout tree
    /// does — a sibling split turns a horizontal pair into a vertical one — and
    /// rebuilding the whole cross to say so would drop the popover.
    @Test("changing the offered set re-applies enablement")
    func offeredSetIsSettable() {
        let cross = PaneMinimizeCrossView(availableEdges: [.leading, .trailing])
        cross.availableEdges = [.top, .bottom]
        #expect(cross.button(for: .top).isEnabled)
        #expect(cross.button(for: .leading).isEnabled == false)
    }

    /// The cross is put in a window first, and it is not decoration:
    /// `performClick` runs through `NSCell`, which does nothing at all for a
    /// cell whose control view has no window — so the version of this test
    /// without one watched two clicks report no edges and called it a pass.
    /// The window is never ordered front (`quiet-development`); it exists so
    /// the button has somewhere to be.
    @Test("clicking an arrow reports its edge")
    func clickReportsTheEdge() {
        let cross = PaneMinimizeCrossView(availableEdges: Set(PaneEdge.allCases))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView?.addSubview(cross)
        var picked: [PaneEdge] = []
        cross.onPick = { picked.append($0) }

        cross.button(for: .leading).performClick(nil)
        cross.button(for: .bottom).performClick(nil)
        #expect(picked == [.leading, .bottom])
    }

    // MARK: The popover

    @Test("the picker starts closed and carries the cross as its content")
    func pickerWrapsTheCross() {
        let picker = PaneMinimizePicker(availableEdges: [.top, .bottom]) { _ in }
        #expect(picker.isShown == false)
        #expect(picker.crossView.button(for: .top).isEnabled)
    }

    // MARK: Leaving without picking

    /// Escape has to put the picker away, and it does not come free.
    /// `NSPopover` closes a `.transient` popover when the user interacts with
    /// something *outside* it, and a key press is not that — escape is
    /// `cancelOperation:`, sent down the responder chain of whichever window
    /// is key. A popover whose content accepts no first responder never puts
    /// itself in a responder chain at all, so the press goes to the window
    /// underneath and the picker stays up over it, swallowing the next click
    /// meant for the pane behind.
    @Test("the cross takes first responder, so escape has somewhere to land")
    func crossTakesFirstResponder() {
        let cross = PaneMinimizeCrossView(availableEdges: [.leading])
        #expect(cross.acceptsFirstResponder)
    }

    /// Cancelling is not picking. Reporting an edge here would minimize a pane
    /// the user was backing out of touching.
    @Test("escape reports a cancel and no edge")
    func escapeCancels() {
        let cross = PaneMinimizeCrossView(availableEdges: Set(PaneEdge.allCases))
        var picked: [PaneEdge] = []
        var cancels = 0
        cross.onPick = { picked.append($0) }
        cross.onCancel = { cancels += 1 }

        cross.cancelOperation(nil)

        #expect(cancels == 1)
        #expect(picked.isEmpty)
    }

    @Test("the picker answers a cancel by closing, and reports nothing")
    func cancellingClosesWithoutPicking() {
        var picked: [PaneEdge] = []
        let picker = PaneMinimizePicker(availableEdges: [.leading]) { picked.append($0) }

        #expect(picker.crossView.onCancel != nil)
        picker.crossView.onCancel?()

        #expect(picker.isShown == false)
        #expect(picked.isEmpty)
    }

    /// Picking closes the popover before the host acts on it: the pane is about
    /// to change shape, and a popover anchored to a button inside it would be
    /// left pointing at a view that moved.
    @Test("picking closes the popover, then reports")
    func pickingClosesFirst() {
        var wasShownAtCallback: Bool?
        let picker = PaneMinimizePicker(availableEdges: [.leading]) { _ in }
        let observed = PaneMinimizePicker(availableEdges: [.leading]) { _ in
            wasShownAtCallback = picker.isShown
        }
        observed.crossView.button(for: .leading).performClick(nil)
        #expect(observed.isShown == false)
        #expect(wasShownAtCallback != true)
    }
}
