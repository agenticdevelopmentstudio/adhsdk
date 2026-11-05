import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The icon-width rail a pane shrinks to when it minimizes sideways.
@MainActor
@Suite("PaneMinimizedStripView")
struct PaneMinimizedStripViewTests {

    @Test("it carries a tagged restore button and the pane's glyph")
    func partsArePresent() {
        let strip = PaneMinimizedStripView(edge: .leading, symbolName: "folder", tooltip: "Files")
        #expect(strip.restoreButton.accessibilityIdentifier() == "pane.restore")
        #expect(strip.restoreButton.accessibilityLabel() == "Restore Pane")
        #expect(strip.restoreButton.toolTip == "Restore Pane")
        #expect(strip.glyphView.accessibilityIdentifier() == "pane.minimized.glyph")
        #expect(strip.glyphView.image != nil)
        #expect(strip.glyphView.toolTip == "Files")
    }

    /// Content that says nothing about how it looks minimized still gets a
    /// rail — a generic one. The alternative, an empty strip, is a control the
    /// user cannot identify.
    @Test("content with no representation of its own falls back to a generic glyph")
    func fallbackGlyph() {
        let strip = PaneMinimizedStripView(edge: .trailing)
        #expect(PaneMinimizedStripView.defaultSymbolName == "square.dashed")
        #expect(strip.symbolName == "square.dashed")
        #expect(strip.glyphView.image != nil)
    }

    @Test("the glyph and tooltip can be replaced after construction")
    func glyphIsSettable() {
        let strip = PaneMinimizedStripView(edge: .leading)
        let before = strip.glyphView.image
        strip.symbolName = "terminal"
        strip.tooltip = "zsh"
        #expect(strip.glyphView.image !== before)
        #expect(strip.glyphView.toolTip == "zsh")
    }

    @Test("clicking restore reports it")
    func restoreReports() {
        let strip = PaneMinimizedStripView(edge: .leading)
        var restored = 0
        strip.onRestore = { restored += 1 }
        strip.restoreButton.performClick(nil)
        #expect(restored == 1)
    }

    /// The hairline goes on the side facing the rest of the layout, not on the
    /// window edge the strip is docked against — a rule that needs the vertical
    /// separator Task 3 added.
    @Test("the hairline sits on the inward-facing side")
    func hairlineFacesInward() {
        let leading = PaneMinimizedStripView(edge: .leading)
        leading.frame = NSRect(x: 0, y: 0, width: PaneMinimizedStripView.thickness, height: 200)
        leading.layoutSubtreeIfNeeded()
        let leadingHairline = leading.subviews.compactMap { $0 as? ThemedSeparatorView }.first
        #expect(leadingHairline != nil)
        #expect((leadingHairline?.frame.minX ?? 0) > leading.bounds.midX)

        let trailing = PaneMinimizedStripView(edge: .trailing)
        trailing.frame = NSRect(x: 0, y: 0, width: PaneMinimizedStripView.thickness, height: 200)
        trailing.layoutSubtreeIfNeeded()
        let trailingHairline = trailing.subviews.compactMap { $0 as? ThemedSeparatorView }.first
        #expect((trailingHairline?.frame.maxX ?? .greatestFiniteMagnitude) < trailing.bounds.midX)
    }

    @Test("it is exactly one icon wide")
    func thickness() {
        #expect(PaneMinimizedStripView.thickness == 28)
        let strip = PaneMinimizedStripView(edge: .leading)
        #expect(strip.fittingSize.width == PaneMinimizedStripView.thickness)
    }
}
