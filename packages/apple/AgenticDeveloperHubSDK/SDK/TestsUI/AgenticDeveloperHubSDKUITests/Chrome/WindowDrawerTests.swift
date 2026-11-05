import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The drawer that slides out beside a window. It knows about tabs and about
/// NSDrawer's two sharp edges; it does not know what any tab contains.
///
/// This suite constructs `WindowDrawer` directly, and `WindowDrawer` is
/// deliberately `@available(macOS, deprecated: 10.13)` so it can wrap
/// `NSDrawer` warning-free — the deprecation warnings that raises at the
/// call sites below are expected, not a defect. Annotating this suite the
/// same way does not work: swift-testing's `@Suite`/`@Test` macros refuse
/// to expand on a declaration already marked `@available(deprecated:)`, and
/// the file stops compiling. `NSDrawer` itself is still named in exactly
/// one file. See R4a in `.superpowers/sdd/2026-09-06-panes-and-project-window/rulings.md`.
@MainActor
@Suite("WindowDrawer")
struct WindowDrawerTests {

    private func makeWindow() -> NSWindow {
        NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)
    }

    private func tab(_ id: String, _ title: String) -> DrawerTab {
        DrawerTab(id: id, title: title, symbolName: "questionmark.circle") {
            let view = NSView()
            view.accessibilityID("drawer.body.\(id)")
            return view
        }
    }

    @Test("a drawer starts closed and selects its first tab")
    func startsClosed() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        #expect(drawer.isOpen == false)
        #expect(drawer.selectedTabID == "help")
    }

    @Test("opening while naming a tab selects it")
    func openSelects() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help"), tab("outline", "Outline")])
        drawer.open(selecting: "outline")
        #expect(drawer.selectedTabID == "outline")
    }

    /// The help button's contract: clicking it discloses the drawer *and*
    /// lands on the help tab, whichever tab was showing last.
    @Test("toggling to a named tab opens on that tab even if another was showing")
    func toggleSwitchesTabs() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help"), tab("outline", "Outline")])

        drawer.open(selecting: "outline")
        drawer.toggle(selecting: "help")
        #expect(drawer.selectedTabID == "help")

        // Already open on help — a second toggle closes it.
        drawer.toggle(selecting: "help")
        #expect(drawer.selectedTabID == "help")
    }

    @Test("an unknown tab id is ignored rather than blanking the drawer")
    func unknownTabIgnored() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        drawer.open(selecting: "nonexistent")
        #expect(drawer.selectedTabID == "help")
    }

    /// A segmented control with one segment is a button that does nothing.
    @Test("the tab strip is hidden while there is only one tab")
    func singleTabHidesTheStrip() {
        let one = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        #expect(one.tabStripIsHidden == true)

        let two = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help"), tab("outline", "Outline")])
        #expect(two.tabStripIsHidden == false)
    }

    @Test("each tab's view is made once and kept")
    func viewsAreMadeOnceAndKept() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        let first = drawer.view(forTab: "help")
        let second = drawer.view(forTab: "help")
        #expect(first != nil)
        #expect(first === second)
        #expect(drawer.view(forTab: "nope") == nil)
    }

    @Test("visibility changes are announced")
    func announcesVisibility() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        var announcements = 0
        drawer.onVisibilityChange = { announcements += 1 }
        drawer.open(selecting: nil)
        drawer.close()
        #expect(announcements == 2)
    }

    /// A drawer the *user* drags shut never goes through `close()`, and AppKit
    /// reports it only to `NSDrawerDelegate`. Without forwarding it, an owner
    /// that remembers "disclosed" never learns the reader put it away.
    @Test("a move the drawer did not make is announced too")
    func announcesUserDrivenMoves() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        var announcements = 0
        drawer.onVisibilityChange = { announcements += 1 }

        // What AppKit sends when the drag finishes. The notification's contents
        // are not read — the fact of it is the whole message.
        drawer.drawerDidOpen(Notification(name: Notification.Name("drawerDidOpen")))
        drawer.drawerDidClose(Notification(name: Notification.Name("drawerDidClose")))

        #expect(announcements == 2)
    }

    @Test("the tab strip is addressable")
    func stripIsIdentified() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help"), tab("outline", "Outline")])
        #expect(drawer.tabStrip.accessibilityIdentifier() == "project.drawer.tabs")
    }

    /// A UI test has to find the drawer itself, not only its tab strip — and
    /// with one tab the strip is hidden, so it is the only handle there is.
    @Test("the drawer's own content is addressable")
    func drawerIsIdentified() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        #expect(drawer.contentView.accessibilityIdentifier() == "project.drawer")
    }

    /// Which tab is showing is a fact about the drawer, so the drawer states
    /// it — rather than leaving a UI test to infer it from whatever the tab's
    /// own view happened to tag itself.
    @Test("the body says which tab it is showing")
    func bodyNamesTheSelectedTab() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help"), tab("outline", "Outline")])
        #expect(drawer.bodyView.accessibilityIdentifier() == "project.drawer.tab.help")

        drawer.open(selecting: "outline")
        #expect(drawer.bodyView.accessibilityIdentifier() == "project.drawer.tab.outline")
    }

    // MARK: - Who shut it

    /// AppKit shuts a drawer when its parent window is miniaturized, and
    /// announces that through exactly the same `drawerDidClose(_:)` a drag on
    /// the outer edge produces. An owner that reads every unexplained close as
    /// "the reader put it away" therefore forgets the drawer the moment the
    /// window is minimised — which is the one thing remembering it was for.
    @Test("a close while the window is miniaturized is not the reader's")
    func miniaturizedCloseIsNotTheReaders() {
        let drawer = WindowDrawer(
            parentWindow: MiniaturizedWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])

        #expect(drawer.closeIsAttributableToTheReader == false)
    }

    /// The other side of it: on a window the reader is actually looking at, a
    /// shut drawer is one they could have shut.
    @Test("a close on a plain visible window is the reader's")
    func plainCloseIsTheReaders() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        #expect(drawer.closeIsAttributableToTheReader == true)

        drawer.open(selecting: "help")
        #expect(
            drawer.closeIsAttributableToTheReader == false,
            "An open drawer has no close to attribute to anyone")
    }

    /// `NSDrawer.delegate` is declared `assign` —
    /// `AppKit.framework/Headers/NSDrawer.h:41` — which ARC imports as
    /// `unowned(unsafe)`, not as a zeroing weak reference. The parent window
    /// keeps its own drawers alive (`NSWindow.drawers`, line 65 of the same
    /// header), so the `NSDrawer` outlives the wrapper that made it whenever
    /// the window does, and a wrapper that went away without clearing the
    /// pointer leaves AppKit free to message freed memory during teardown.
    @Test("the delegate is cleared when the wrapper goes away")
    func delegateIsClearedWhenTheWrapperGoes() {
        let window = makeWindow()
        var wrapper: WindowDrawer? = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        #expect(wrapper != nil)

        // The parent window is the seam that outlives the wrapper: it is what
        // holds the `NSDrawer` after the last reference to the wrapper goes.
        let drawer = window.drawers?.first
        #expect(drawer != nil)

        wrapper = nil
        #expect(drawer?.delegate == nil)
    }

    /// The owner persists the width, so the owner has to be able to read it
    /// back after the user has dragged the outer edge.
    @Test("content width round-trips, clamped to the draggable range")
    func contentWidthRoundTrips() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        #expect(drawer.contentWidth == WindowDrawer.defaultContentWidth)

        drawer.contentWidth = 400
        #expect(drawer.contentWidth == 400)

        // Below the minimum the drawer cannot be dragged to, and above the
        // maximum, a remembered value is nonsense — clamp rather than obey.
        drawer.contentWidth = 10
        #expect(drawer.contentWidth == 220)
        drawer.contentWidth = 10_000
        #expect(drawer.contentWidth == 520)
    }

    /// The initialiser's width goes straight into `NSDrawer(contentSize:)`,
    /// which happens before `minContentSize`/`maxContentSize` exist to police
    /// it — so a remembered width has to be clamped by the drawer itself or a
    /// stored `0` produces a drawer with no content at all.
    @Test("a width handed to init is clamped the same way the setter clamps")
    func initClampsTheRememberedWidth() {
        for (given, expected) in [(CGFloat(0), CGFloat(220)), (-50, 220), (10_000, 520)] {
            let drawer = WindowDrawer(
                parentWindow: makeWindow(),
                accessibilityPrefix: "project.drawer",
                tabs: [tab("help", "Help")],
                contentWidth: given)
            #expect(drawer.contentWidth == expected)
        }
    }

    /// A remembered width is parsed from a string, and `Double("nan")` and
    /// `Double("inf")` both succeed. `min(max(.nan, 220), 520)` is `.nan` —
    /// every comparison against NaN is false, so both `min` and `max` hand it
    /// straight back — and a NaN size makes AppKit lay out nothing.
    @Test("a width that is not a finite number falls back to the default")
    func nonFiniteWidthsFallBackToTheDefault() {
        for given in [CGFloat.nan, .infinity, -.infinity] {
            let drawer = WindowDrawer(
                parentWindow: makeWindow(),
                accessibilityPrefix: "project.drawer",
                tabs: [tab("help", "Help")],
                contentWidth: given)
            #expect(drawer.contentWidth == WindowDrawer.defaultContentWidth)

            drawer.contentWidth = given
            #expect(drawer.contentWidth == WindowDrawer.defaultContentWidth)
        }
    }

    // MARK: - Reaching the drawer from outside

    /// Every test here exists because an open drawer used to be unreachable.
    /// `NSDrawer` puts its content in a window of its own, and that window is
    /// in neither `NSApplication`'s `AXWindows` nor the parent window's
    /// `AXChildren` — so the help it discloses was on screen and absent from
    /// the accessibility tree at the same time. Three UI tests asserted on it
    /// and all three were skipped for an unrelated reason, which is how it
    /// went unnoticed.
    private func proxy(in window: NSWindow) -> DrawerAccessibilityProxy? {
        window.contentView?.subviews.compactMap { $0 as? DrawerAccessibilityProxy }.first
    }

    @Test("an open drawer is reachable from its parent window")
    func openDrawerIsReachable() {
        let window = makeWindow()
        let drawer = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])

        drawer.open()

        let proxy = self.proxy(in: window)
        #expect(proxy != nil)
        #expect(proxy?.isAccessibilityElement() == true)
        #expect(proxy?.accessibilityRole() == .group)
        #expect(proxy?.accessibilityChildren() as? [NSView] == [drawer.contentView])
    }

    /// The other half, and the one a UI test asserting "the drawer closed"
    /// depends on: a closed drawer must take its content back out of the tree
    /// rather than leaving help for VoiceOver to walk into.
    @Test("a closed drawer vends nothing")
    func closedDrawerVendsNothing() {
        let window = makeWindow()
        let drawer = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])

        drawer.open()
        drawer.close()

        #expect(self.proxy(in: window)?.accessibilityChildren() == nil)
    }

    /// AppKit flattens a plain `NSView` out of the accessibility tree and
    /// hands its children to its parent — taking the identifier with it. Both
    /// of these carry identifiers a UI test queries by, so both have to stay.
    @Test("the container and the body survive as addressable groups")
    func containerAndBodyAreGroups() {
        let drawer = WindowDrawer(
            parentWindow: makeWindow(),
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])

        for view in [drawer.contentView, drawer.bodyView] {
            #expect(view.isAccessibilityElement() == true)
            #expect(view.accessibilityRole() == .group)
        }
    }

    /// A published child needs a published parent: `container` lives in a
    /// window nothing walks, so an assistive technology moving *up* out of the
    /// drawer would otherwise arrive somewhere no reader can get back down to.
    @Test("the drawer's content points back at the proxy")
    func containerPointsAtTheProxy() {
        let window = makeWindow()
        let drawer = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        drawer.open()

        #expect(drawer.contentView.accessibilityParent() as? NSView === self.proxy(in: window))
    }

    /// The parent window's content view owns the proxy and outlives the
    /// drawer, so a proxy left behind is a permanent empty group in a window
    /// that has no drawer any more.
    @Test("the proxy goes when the drawer does")
    func proxyIsRemovedWithTheDrawer() {
        let window = makeWindow()
        var drawer: WindowDrawer? = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        drawer?.open()
        #expect(self.proxy(in: window) != nil)

        drawer = nil
        #expect(self.proxy(in: window) == nil)
    }

    /// A window controller that swaps its `contentView` after the drawer was
    /// built takes the proxy away with the old one. The install guard is keyed
    /// to *this* content view for that reason — a `superview != nil` check
    /// reads a stranded proxy as installed and never repairs it.
    @Test("swapping the window's content view reinstalls the proxy")
    func contentViewSwapReinstallsTheProxy() {
        let window = makeWindow()
        let drawer = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        drawer.open()
        let first = self.proxy(in: window)
        #expect(first != nil)

        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        #expect(self.proxy(in: window) == nil)

        drawer.open()
        #expect(self.proxy(in: window) === first)
    }

    /// And it repairs itself, without waiting for an `open()` that is never
    /// coming.
    ///
    /// `contentViewSwapReinstallsTheProxy` above pins the *guard* — that a
    /// stranded proxy is not mistaken for an installed one — and it reinstalls
    /// by opening the drawer a second time. A drawer that is already open is
    /// never opened again, so for the case that actually happens that test
    /// proves nothing: the window keeps a visible drawer that VoiceOver and
    /// every `XCUIElement` query cannot see, for as long as it stays open.
    ///
    /// The repair is asynchronous because during the swap the window's
    /// `contentView` is still the old one, so this waits a turn of the main
    /// queue the same way the fix does. Enqueueing behind it is enough: the
    /// main queue is FIFO, so by the time this resumes the repair has run or
    /// has decided not to.
    @Test("a content view swap under an open drawer repairs itself")
    func contentViewSwapRepairsItselfWhileOpen() async {
        let window = makeWindow()
        let drawer = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        drawer.open()
        let first = self.proxy(in: window)
        #expect(first != nil)

        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        await nextMainQueueTurn()

        #expect(self.proxy(in: window) === first)
    }

    /// A drawer the user has closed has nothing to reach, so a swap under it
    /// must leave the new content view alone — reinstalling there would put an
    /// `AXGroup` for a drawer that is not on screen into every window that
    /// swaps its content view.
    @Test("a content view swap under a closed drawer installs nothing")
    func contentViewSwapUnderAClosedDrawerInstallsNothing() async {
        let window = makeWindow()
        let drawer = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])
        drawer.open()
        #expect(self.proxy(in: window) != nil)
        drawer.close()

        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        await nextMainQueueTurn()

        #expect(self.proxy(in: window) == nil)
    }

    /// Resumes after everything already on the main queue has run.
    private func nextMainQueueTurn() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    /// A drawer is built while its window is still being assembled — before a
    /// toolbar has grown the titlebar, before a saved frame is restored — so
    /// the height captured at init is not the height the window ends up with.
    @Test("opening re-reads the parent window's height")
    func openTracksTheParentWindowHeight() {
        let window = makeWindow()
        let drawer = WindowDrawer(
            parentWindow: window,
            accessibilityPrefix: "project.drawer",
            tabs: [tab("help", "Help")])

        // Not an exact number: `NSDrawer` takes the titlebar and its own edge
        // offsets out of whatever height it is handed, so what it settles on
        // is AppKit's business. That it moved at all is ours — without the
        // re-read this is still, exactly, the height captured in `init`.
        let before = drawer.contentHeight
        window.setFrame(NSRect(x: 0, y: 0, width: 600, height: 900), display: false)
        drawer.open()
        #expect(drawer.contentHeight > before)
        #expect(drawer.contentHeight <= window.frame.height)
        // The width is the owner's to remember, so opening leaves it alone.
        #expect(drawer.contentWidth == WindowDrawer.defaultContentWidth)
    }
}

/// A window that says it is minimised, because AppKit will not minimise one
/// that was never ordered on screen and `isMiniaturized` is read-only.
@MainActor
private final class MiniaturizedWindow: NSWindow {
    override var isMiniaturized: Bool { true }
}
