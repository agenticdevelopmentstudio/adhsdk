import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The three buttons on the left of a pane's title bar. They report; they
/// decide nothing.
@MainActor
@Suite("PaneControlCluster")
struct PaneControlClusterTests {

    @Test("all three buttons are tagged, labelled and wired")
    func buttonsAreAddressable() {
        let cluster = PaneControlCluster()
        #expect(cluster.closeButton.accessibilityIdentifier() == "pane.close")
        #expect(cluster.minimizeButton.accessibilityIdentifier() == "pane.minimize")
        #expect(cluster.zoomButton.accessibilityIdentifier() == "pane.zoom")

        for button in [cluster.closeButton, cluster.minimizeButton, cluster.zoomButton] {
            #expect(button.image != nil)
            #expect(button.toolTip?.isEmpty == false)
            #expect(button.accessibilityLabel()?.isEmpty == false)
            #expect(button.target != nil)
            #expect(button.action != nil)
        }
    }

    @Test("the buttons sit in close, minimize, zoom order")
    func orderMatchesTheWindowConvention() {
        let cluster = PaneControlCluster()
        #expect(cluster.arrangedSubviews == [cluster.closeButton, cluster.minimizeButton, cluster.zoomButton])
    }

    @Test("clicking each button fires its own closure and no other")
    func clicksAreRouted() {
        let cluster = PaneControlCluster()
        var closed = 0, minimized = 0, zoomed = 0, restored = 0
        cluster.onClose = { closed += 1 }
        cluster.onMinimize = { _ in minimized += 1 }
        cluster.onZoom = { zoomed += 1 }
        cluster.onRestore = { restored += 1 }

        cluster.closeButton.performClick(nil)
        #expect((closed, minimized, zoomed, restored) == (1, 0, 0, 0))

        cluster.minimizeButton.performClick(nil)
        #expect((closed, minimized, zoomed, restored) == (1, 1, 0, 0))

        cluster.zoomButton.performClick(nil)
        #expect((closed, minimized, zoomed, restored) == (1, 1, 1, 0))
    }

    /// The minimize button is the popover's anchor, so the cluster hands it to
    /// the host rather than making the host go looking for it.
    @Test("minimize reports the button the picker should hang off")
    func minimizePassesItsAnchor() {
        let cluster = PaneControlCluster()
        var anchor: NSButton?
        cluster.onMinimize = { anchor = $0 }
        cluster.minimizeButton.performClick(nil)
        #expect(anchor === cluster.minimizeButton)
    }

    /// Minimized, the same button means the opposite thing — so it changes its
    /// identifier too. A UI test asserting `pane.restore` is present is
    /// asserting the pane is minimized.
    @Test("minimized swaps the middle button for restore, identifier and all")
    func minimizedBecomesRestore() {
        let cluster = PaneControlCluster()
        let before = cluster.minimizeButton.image

        cluster.isMinimized = true
        #expect(cluster.minimizeButton.accessibilityIdentifier() == "pane.restore")
        #expect(cluster.minimizeButton.image !== before)
        #expect(cluster.minimizeButton.toolTip == "Restore Pane")

        var restored = 0
        cluster.onRestore = { restored += 1 }
        cluster.minimizeButton.performClick(nil)
        #expect(restored == 1)

        cluster.isMinimized = false
        #expect(cluster.minimizeButton.accessibilityIdentifier() == "pane.minimize")
    }

    @Test("zoomed flips the zoom glyph and its tooltip")
    func zoomedFlipsTheGlyph() {
        let cluster = PaneControlCluster()
        let before = cluster.zoomButton.image
        #expect(cluster.zoomButton.toolTip == "Zoom Pane")

        cluster.isZoomed = true
        #expect(cluster.zoomButton.image !== before)
        #expect(cluster.zoomButton.toolTip == "Unzoom Pane")
    }

    /// A pane that fills its tab has no sibling to give its space to, so the
    /// control is visible and disabled rather than absent — a button that
    /// comes and goes is harder to find than one that is dimmed.
    @Test("a pane with nowhere to minimize shows a disabled control")
    func minimizeDisablesRatherThanDisappears() {
        let cluster = PaneControlCluster()
        #expect(cluster.minimizeButton.isEnabled)

        cluster.canMinimize = false
        #expect(cluster.minimizeButton.isEnabled == false)
        #expect(cluster.minimizeButton.isHidden == false)

        cluster.canMinimize = true
        #expect(cluster.minimizeButton.isEnabled)
    }

    /// Restore has to stay reachable even where minimizing was never offered:
    /// a pane can be restored into a tree that has since changed shape.
    @Test("restore is enabled even when minimize would not have been")
    func restoreIgnoresCanMinimize() {
        let cluster = PaneControlCluster()
        cluster.canMinimize = false
        cluster.isMinimized = true
        #expect(cluster.minimizeButton.isEnabled)
    }

    /// `isBordered = false` buys the borderless look the title bar wants and
    /// costs AppKit's own dimming of a disabled control: a borderless button
    /// draws its template image in `contentTintColor` whether or not it is
    /// enabled. So a pane that fills its tab would show a minimize button that
    /// looks live and does nothing unless the tint is resolved from
    /// `isEnabled` — which is what the sibling `PaneMinimizePicker` does.
    @Test("a disabled minimize button is tinted as disabled, not as live")
    func disabledMinimizeLooksDisabled() {
        let cluster = PaneControlCluster()
        let palette = cluster.resolvedThemeScope.palette

        cluster.canMinimize = true
        #expect(cluster.minimizeButton.contentTintColor == palette.nsColor(.secondaryText))

        cluster.canMinimize = false
        #expect(cluster.minimizeButton.contentTintColor == palette.nsColor(.tertiaryText))

        // Restore is always enabled, so it always looks it.
        cluster.isMinimized = true
        #expect(cluster.minimizeButton.contentTintColor == palette.nsColor(.secondaryText))
    }
}
