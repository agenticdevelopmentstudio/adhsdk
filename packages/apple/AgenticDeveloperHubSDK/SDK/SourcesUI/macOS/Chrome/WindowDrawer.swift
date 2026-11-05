import AppKit
import AgenticDeveloperHubSDK

/// A view that paints whatever it wraps and never takes a click.
///
/// `hitTest(_:)` returning `nil` ends AppKit's search for this branch outright,
/// children included — which is the point: this exists to lay colour over a
/// view that owns the mouse, not to take the mouse from it.
///
/// Composition rather than a subclass of `ThemedBackgroundView` because that
/// type is `final`, and rightly so: "what colour am I" and "do I take clicks"
/// are two concerns, and this way either can be swapped without the other.
@MainActor
final class MouseTransparentView: NSView {

    init(containing content: NSView) {
        super.init(frame: .zero)
        content.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: self.topAnchor),
            content.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// Stands in for an open drawer inside its parent window's accessibility tree.
///
/// `NSDrawer` puts its content in a window of its own, and that window is in
/// neither `NSApplication`'s `AXWindows` nor the parent window's `AXChildren`.
/// The drawer is therefore *on screen and not in the accessibility hierarchy
/// at all*: VoiceOver cannot reach the help it discloses, and neither can a UI
/// test — `app.descendants(matching: .any)` walks the same tree and comes back
/// empty however healthy the drawer is. AppKit exposed drawers itself once;
/// that stopped somewhere along the twelve years `NSDrawer` has been
/// deprecated, and it is not coming back.
///
/// A proxy rather than `contentView.setAccessibilityChildren(defaults + [container])`
/// on the parent window, which also works: setting that array *replaces* the
/// window's computed children with a snapshot, so every pane added or removed
/// while the drawer is open would be invisible until it was closed. A view of
/// our own answers `accessibilityChildren()` afresh each time it is asked and
/// leaves everyone else's children to AppKit.
///
/// It is zero-sized and takes no clicks, so it is inert as a *view*; the frame
/// it reports to accessibility is the drawer's own, on screen, which is where
/// the children it vends actually are.
@available(macOS, deprecated: 10.13, message: "Stands in for a WindowDrawer, which wraps NSDrawer")
@MainActor
final class DrawerAccessibilityProxy: NSView {

    /// Weak, and not only for the cycle: the parent window's content view owns
    /// this proxy, and a window outlives the drawer hanging off it whenever the
    /// drawer's owner is torn down first.
    weak var drawer: WindowDrawer?

    override func isAccessibilityElement() -> Bool { true }

    override func accessibilityRole() -> NSAccessibility.Role? { .group }

    /// The drawer's content while it is open, and nothing at all while it is
    /// not — a closed drawer must not leave its help in the tree for VoiceOver
    /// to walk into, and a UI test asserting the drawer closed is asserting on
    /// exactly this.
    override func accessibilityChildren() -> [Any]? {
        guard let drawer = self.drawer, drawer.isOpen else { return nil }
        return [drawer.contentView]
    }

    /// Where the children really are. Without this the proxy reports the
    /// zero-sized frame it occupies in its superview, which puts a group at the
    /// window's corner claiming to contain views hundreds of points to the
    /// right of it.
    override func accessibilityFrame() -> NSRect {
        guard let drawer = self.drawer, drawer.isOpen,
              let window = drawer.contentView.window else {
            return super.accessibilityFrame()
        }
        return window.convertToScreen(
            drawer.contentView.convert(drawer.contentView.bounds, to: nil))
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    /// Notices being carried out of the window, and asks the drawer to put the
    /// proxy back where it now belongs.
    ///
    /// **A content view swap strands the proxy, and nothing else would say
    /// so.** The proxy is a subview of the parent window's content view, so a
    /// window controller that assigns a new `contentView` takes the old one —
    /// and this proxy with it — out of the window entirely. The drawer stays
    /// open and on screen, and the only thing that reinstalls the proxy is the
    /// *next* `open()`, which for a drawer that is already open never comes.
    /// The window is then back to having a visible drawer that VoiceOver and
    /// `XCUIElement` queries cannot see at all, which is precisely the state
    /// this proxy exists to prevent.
    ///
    /// AppKit sends this to the whole removed subtree, so it is the one signal
    /// that fires for the swap without observing anything. Asynchronously,
    /// because during the swap the window's `contentView` may still be the old
    /// one; by the next turn of the run loop it is the new one. The reinstall
    /// is a no-op when the proxy is already in the right place, which is what
    /// makes the ordinary `removeFromSuperview()` in `install…IfNeeded()` — and
    /// the one in `WindowDrawer.deinit`, where `drawer` is already nil — cost
    /// nothing here *(idempotency)*.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard self.window == nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, let drawer = self.drawer, drawer.isOpen else { return }
            drawer.reinstallAccessibilityProxyIfNeeded()
        }
    }
}

/// One tab in a `WindowDrawer`.
///
/// A value, not a view: the drawer makes the view the first time the tab is
/// shown and keeps it, so a tab that is never opened costs nothing.
@MainActor
public struct DrawerTab {

    /// Stable, and the suffix of the tab's accessibility identifier — so a UI
    /// test names the tab the same way the code selects it.
    public let id: String
    public let title: String
    public let symbolName: String
    public let makeView: @MainActor () -> NSView

    public init(
        id: String,
        title: String,
        symbolName: String,
        makeView: @escaping @MainActor () -> NSView
    ) {
        self.id = id
        self.title = title
        self.symbolName = symbolName
        self.makeView = makeView
    }
}

/// A tabbed drawer on a window's trailing edge.
///
/// A drawer slides out *beside* the window instead of taking width from it,
/// which is the whole point — disclosing help must not reflow the thing it is
/// explaining, and closing it must not leave a gap where prose used to be.
/// AppKit animates the slide, tracks the window and flips the drawer to the
/// other edge when the screen has no room; none of that is ours to write.
///
/// `NSDrawer` has been deprecated since 10.13, and AppKit's suggested
/// replacement is `NSSplitViewController` — precisely the pane-that-steals-width
/// this is not. It is still in the SDK and still works. This type carries the
/// deprecation on purpose: a deprecated declaration is a warning-free zone for
/// the API it wraps, so AppKit's drawer vocabulary stays inside this one file
/// and every window sees only `WindowDrawer`.
///
/// Two things the drawer deliberately does **not** do:
///
/// - It does not remember whether it was open. Settings remembers its drawer in
///   `UserSettings`; the project window remembers its own per repository. A
///   preference belongs to whoever the preference is about.
/// - It does not know what a tab contains. A tab is an id, a title, a symbol and
///   a `() -> NSView`, which is what lets this live below the code that has help
///   to show.
///
/// `@preconcurrency` on the `NSDrawerDelegate` conformance because that
/// protocol predates the SDK's concurrency audit and so is un-isolated, while
/// this type is `@MainActor` — AppKit only ever calls a drawer delegate on the
/// main thread, and the attribute is how that promise is stated. Without it the
/// conformance is a data-race warning today and an error under the Swift 6
/// language mode. Sibling delegates here need no such attribute: `NSToolbarDelegate`
/// and friends are already `@MainActor` in the SDK.
@available(macOS, deprecated: 10.13, message: "Wraps NSDrawer, deprecated since macOS 10.13")
@MainActor
public final class WindowDrawer: NSObject, @preconcurrency NSDrawerDelegate {

    /// Wide enough for a comfortable measure at explanation size; the user can
    /// drag the outer edge between the min and max below from there.
    ///
    /// `nonisolated` because it is used as a default argument value below: a
    /// default-argument expression compiles as a standalone, non-isolated
    /// function regardless of the initializer's own actor, so referencing a
    /// `@MainActor`-isolated static from one is a warning today and an error
    /// under the Swift 6 language mode. The property is a `CGFloat` literal —
    /// `Sendable` and safe to read from any isolation — so `nonisolated` costs
    /// nothing.
    public static nonisolated let defaultContentWidth: CGFloat = 300
    private static let minContentWidth: CGFloat = 220
    private static let maxContentWidth: CGFloat = 520

    private let drawer: NSDrawer
    private let tabs: [DrawerTab]
    private let accessibilityPrefix: String

    /// The window this drawer hangs off, held rather than read back off
    /// `NSDrawer.parentWindow` — that property is `assign` too
    /// (`AppKit.framework/Headers/NSDrawer.h:38`), so a window that has gone
    /// away leaves it dangling where this one simply becomes `nil`. And `nil`
    /// is the answer `closeIsAttributableToTheReader` below wants: a window
    /// that is gone is teardown, not a drag.
    private weak var parentWindow: NSWindow?

    /// The drawer's ground, and the colour its AppKit-drawn border is painted
    /// over below.
    ///
    /// `.windowBackground` rather than `.surface`: a drawer is a piece of its
    /// window, not a card floating above one, and what it holds is built from
    /// the same views the window's own content is — which paint that role.
    /// Two near-identical greys meeting at the drawer's edge only read as a
    /// misprint.
    private static let groundRole: ThemeRole = .windowBackground

    private let container = ThemedBackgroundView(role: WindowDrawer.groundRole)
    private let body = NSView()

    /// Paints AppKit's own drawer border in the theme's colour.
    ///
    /// `NSDrawer` puts the content view inside an `NSDrawerFrame` a few points
    /// larger on every side, and that frame draws itself opaquely in the
    /// *system* appearance — which is a white rim around a dark drawer
    /// whenever the app's theme and the system's do not agree. The frame is
    /// AppKit's and cannot be told what colour to be; a subview can, and a
    /// subview draws after its superview's `drawRect`. So this is laid over
    /// the frame, under the content, and is transparent to the mouse so the
    /// drag on the outer edge that resizes the drawer still reaches the frame.
    private let bezel = MouseTransparentView(
        containing: ThemedBackgroundView(role: WindowDrawer.groundRole))

    /// Publishes the drawer into the parent window's accessibility tree — see
    /// `DrawerAccessibilityProxy`, and `installAccessibilityProxyIfNeeded()`
    /// for why it is installed at open time rather than in `init`.
    private let accessibilityProxy = DrawerAccessibilityProxy()

    /// The drawer's own content, and the view its body swaps into. Exposed for
    /// the identifiers on them — a test, and a UI test, need a handle on both.
    public var contentView: NSView { self.container }
    public var bodyView: NSView { self.body }

    /// Exposed so a test — and a UI test, through its identifier — can find the
    /// strip. Hidden when there is only one tab: a segmented control with one
    /// segment is a button that does nothing.
    public let tabStrip = NSSegmentedControl()

    private var madeViews: [String: NSView] = [:]

    public private(set) var selectedTabID: String?

    public var isOpen: Bool {
        self.drawer.state == NSDrawer.State.openState.rawValue
            || self.drawer.state == NSDrawer.State.openingState.rawValue
    }

    /// Whether a close this drawer has just announced can be attributed to the
    /// reader — that is, whether it is the drag on the outer edge that
    /// `drawerDidClose(_:)` is mostly there to catch, rather than AppKit
    /// tidying up.
    ///
    /// AppKit shuts a drawer along with its parent window: minimise the window
    /// and the drawer closes, close the window and it closes, and both arrive
    /// through the very same delegate callback a drag produces. An owner that
    /// persists "the reader put the drawer away" on every announced close
    /// therefore forgets the drawer the moment the window is minimised, which
    /// is precisely what remembering it was for. This is the half of that
    /// judgement `WindowDrawer` can make on its own — an owner still has to add
    /// what only it knows, such as whether it is mid-teardown or applying a
    /// remembered state.
    ///
    /// A `nil` `parentWindow` counts as *not* the reader: a window that has
    /// gone away is teardown.
    public var closeIsAttributableToTheReader: Bool {
        guard !self.isOpen, let window = self.parentWindow else { return false }
        return !window.isMiniaturized
    }

    /// How wide the drawer is, in points. The drawer does not remember this
    /// across launches — its owner does — so the owner needs to read what the
    /// user dragged it to and write back what it remembered.
    ///
    /// Clamped on the way in to the same range the drag itself is clamped to: a
    /// remembered value outside it is either corrupt or from a build with
    /// different limits, and either way obeying it produces a drawer the user
    /// cannot drag back.
    public var contentWidth: CGFloat {
        get { self.drawer.contentSize.width }
        set {
            self.drawer.contentSize = NSSize(
                width: Self.clampedContentWidth(newValue),
                height: self.drawer.contentSize.height)
        }
    }

    /// The one place a width from outside becomes a width the drawer will
    /// accept, so `init` and the setter cannot disagree — the initialiser
    /// hands its width straight to `NSDrawer(contentSize:)`, which happens
    /// before `minContentSize`/`maxContentSize` are set and so is not clamped
    /// by anything else.
    ///
    /// The `isFinite` guard is not decoration: a remembered width is parsed
    /// from a string, and `Double("nan")` and `Double("inf")` both succeed.
    /// `min(max(.nan, 220), 520)` is `.nan` in Swift — comparisons against NaN
    /// are all false, so both `min` and `max` return it — and a NaN size makes
    /// AppKit's layout produce nothing at all. Anything not finite falls back
    /// to the default rather than to a bound, because it carries no
    /// information about which end the user meant.
    private static func clampedContentWidth(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return Self.defaultContentWidth }
        return min(max(value, Self.minContentWidth), Self.maxContentWidth)
    }

    /// The height the drawer is currently sized to. Read-only — height is the
    /// window's to decide, which is why `minContentSize`/`maxContentSize`
    /// leave it at zero — and public for the same reason `tabStrip` is: it is
    /// the only way from outside this file to see that `open()` re-read the
    /// parent window.
    public var contentHeight: CGFloat { self.drawer.contentSize.height }

    public var tabStripIsHidden: Bool { self.tabStrip.isHidden }

    /// Fired after the drawer opens or closes, so a help button can restyle
    /// itself — and so an owner that remembers the state can correct itself
    /// when the reader drags the drawer shut by hand rather than clicking that
    /// button.
    ///
    /// **Make the handler idempotent.** One move can be announced twice: once
    /// from `open()`/`close()` and once from `NSDrawer`'s own delegate. Both
    /// are kept on purpose — see `open()` for why neither is enough alone.
    public var onVisibilityChange: (() -> Void)?

    /// - Parameter accessibilityPrefix: namespaces the drawer's own controls —
    ///   `<prefix>.tabs` for the strip, `<prefix>.tab.<id>` for each segment.
    public init(
        parentWindow: NSWindow,
        accessibilityPrefix: String,
        tabs: [DrawerTab],
        contentWidth: CGFloat = WindowDrawer.defaultContentWidth
    ) {
        self.drawer = NSDrawer(
            contentSize: NSSize(
                width: WindowDrawer.clampedContentWidth(contentWidth),
                height: parentWindow.frame.height),
            preferredEdge: .maxX)
        self.tabs = tabs
        self.accessibilityPrefix = accessibilityPrefix
        self.selectedTabID = tabs.first?.id

        super.init()

        self.buildTabStrip(prefix: accessibilityPrefix)
        self.buildContainer()

        self.drawer.parentWindow = parentWindow
        self.parentWindow = parentWindow
        self.drawer.contentView = self.container
        self.installBezelIfNeeded()
        // So a drawer the *user* moves is announced too — see the delegate
        // methods below. This object owns the drawer, so pointing the delegate
        // back at ourselves makes no cycle — but it is not zeroing-weak
        // either: the SDK declares it `assign`
        // (`AppKit.framework/Headers/NSDrawer.h:41`), which ARC imports as
        // `unowned(unsafe)`. The `deinit` below is what keeps that pointer
        // from dangling.
        self.drawer.delegate = self
        // Height is the window's to decide; only the width is draggable.
        self.drawer.minContentSize = NSSize(width: Self.minContentWidth, height: 0)
        self.drawer.maxContentSize = NSSize(width: Self.maxContentWidth, height: 0)

        self.showSelectedTab()
        self.observeParentWindow(parentWindow)
    }

    /// Undoes the `delegate` assignment above, and nothing else — the
    /// `NotificationCenter` registration in `observeParentWindow(_:)` is
    /// zeroing-weak and needs no undoing.
    ///
    /// It has to be undone because `NSDrawer.delegate` is `assign`
    /// (`AppKit.framework/Headers/NSDrawer.h:41`), so it is `unowned(unsafe)`
    /// on this side, and because the parent window keeps its own drawers alive
    /// (`NSWindow.drawers`, line 65 of the same header) — which means the
    /// `NSDrawer` outlives this wrapper whenever the window does. Left set, the
    /// pointer dangles and AppKit is free to message freed memory on the way
    /// out.
    ///
    /// `isolated` because the drawer is `@MainActor` state and a plain `deinit`
    /// runs nonisolated: mutating `delegate` from one warns today
    /// ("main actor-isolated property 'delegate' can not be mutated from a
    /// nonisolated context") and is an error under Swift 6.
    isolated deinit {
        self.drawer.delegate = nil
        // The parent window's content view owns the proxy and outlives this
        // object, so a proxy left behind is a permanent accessibility group in
        // a window that no longer has a drawer. Its `drawer` reference is weak,
        // so it would vend nothing — an empty group is still noise VoiceOver
        // reads out.
        self.accessibilityProxy.removeFromSuperview()
    }

    private func buildTabStrip(prefix: String) {
        self.tabStrip.segmentStyle = .texturedRounded
        self.tabStrip.trackingMode = .selectOne
        self.tabStrip.segmentCount = self.tabs.count
        for (index, tab) in self.tabs.enumerated() {
            self.tabStrip.setLabel(tab.title, forSegment: index)
            self.tabStrip.setImage(
                NSImage(systemSymbolName: tab.symbolName, accessibilityDescription: tab.title),
                forSegment: index)
            self.tabStrip.setToolTip(tab.title, forSegment: index)
        }
        self.tabStrip.selectedSegment = self.tabs.isEmpty ? -1 : 0
        self.tabStrip.target = self
        self.tabStrip.action = #selector(self.tabStripChanged)
        self.tabStrip.accessibilityID("\(prefix).tabs")
        // One segment is a button that does nothing. Keep it in the hierarchy
        // so a second tab later needs no layout change — just unhide it.
        self.tabStrip.isHidden = self.tabs.count < 2
    }

    /// Lays the bezel over `NSDrawerFrame`, once.
    ///
    /// Called from `init` *and* from both sides of `open()` because the frame
    /// view is AppKit's to make: it exists as soon as `contentView` is assigned
    /// in every case seen so far, but a drawer whose window is still being
    /// assembled may not have one until it opens, and a white rim is not worth
    /// an assumption.
    ///
    /// The idempotence check is "already in *this* frame view", not "already in
    /// some superview". `NSDrawer` rebuilds its `NSDrawerFrame` when the edge
    /// changes or `contentView` is reassigned, and after that the bezel is
    /// stranded in the old, orphaned frame — which a `superview == nil` check
    /// reads as installed and never repairs, so the rim comes back for good.
    ///
    /// Autoresized rather than constrained: `NSDrawerFrame` is not ours and
    /// lays its one subview out by frame, so a constraint against it would be
    /// a second, competing layout pass on a view AppKit owns.
    private func installBezelIfNeeded() {
        guard let frameView = self.container.superview,
              self.bezel.superview !== frameView else { return }
        self.bezel.removeFromSuperview()
        self.bezel.frame = frameView.bounds
        self.bezel.autoresizingMask = [.width, .height]
        frameView.addSubview(self.bezel, positioned: .below, relativeTo: self.container)
    }

    /// The one way into `installAccessibilityProxyIfNeeded()` from outside the
    /// drawer: what `DrawerAccessibilityProxy.viewDidMoveToWindow()` calls once
    /// the content view it was living in has been taken out of the window.
    ///
    /// A separate name rather than relaxing the private one's, so that the only
    /// caller is the one this exists for, and so that reading either of them
    /// says which direction the repair came from.
    func reinstallAccessibilityProxyIfNeeded() {
        self.installAccessibilityProxyIfNeeded()
    }

    /// Puts the accessibility proxy in the parent window's content view, once.
    ///
    /// At open time and not in `init`, for the same reason `installBezelIfNeeded()`
    /// is: a drawer is routinely built while its window is still being
    /// assembled, and a window controller that swaps its `contentView`
    /// afterwards takes the proxy with the old one. The guard is "already in
    /// *this* content view", so a swap reinstalls rather than reading a
    /// stranded proxy as installed.
    private func installAccessibilityProxyIfNeeded() {
        guard let content = self.parentWindow?.contentView,
              self.accessibilityProxy.superview !== content else { return }
        self.accessibilityProxy.removeFromSuperview()
        self.accessibilityProxy.drawer = self
        self.accessibilityProxy.frame = .zero
        self.accessibilityProxy.autoresizingMask = []
        content.addSubview(self.accessibilityProxy)
    }

    private func buildContainer() {
        self.container.accessibilityID(self.accessibilityPrefix)
        // Both are plain `NSView`s, and AppKit flattens a plain view out of the
        // accessibility tree and hands its children to its parent — carrying
        // the identifier off with it. A drawer whose container and body have
        // identifiers nothing can query is the same as one with none.
        for view in [self.container, self.body] {
            view.setAccessibilityElement(true)
            view.setAccessibilityRole(.group)
        }
        // The published parent, to match the published child: `container` is a
        // subview of a window nothing walks, so an assistive technology moving
        // *up* out of the drawer would otherwise arrive somewhere no reader can
        // get back down to.
        self.container.setAccessibilityParent(self.accessibilityProxy)
        for child in [self.tabStrip, self.body] {
            child.translatesAutoresizingMaskIntoConstraints = false
            self.container.addSubview(child)
        }

        let stripHeight: CGFloat = self.tabStrip.isHidden ? 0 : 32
        NSLayoutConstraint.activate([
            self.tabStrip.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 8),
            self.tabStrip.centerXAnchor.constraint(equalTo: self.container.centerXAnchor),

            self.body.topAnchor.constraint(
                equalTo: self.container.topAnchor, constant: stripHeight),
            self.body.leadingAnchor.constraint(equalTo: self.container.leadingAnchor),
            self.body.trailingAnchor.constraint(equalTo: self.container.trailingAnchor),
            self.body.bottomAnchor.constraint(equalTo: self.container.bottomAnchor)
        ])
    }

    // MARK: - Tabs

    /// The view for a tab, made on first ask and kept. `nil` for an id that is
    /// not one of this drawer's tabs.
    @discardableResult
    public func view(forTab id: String) -> NSView? {
        if let existing = self.madeViews[id] { return existing }
        guard let tab = self.tabs.first(where: { $0.id == id }) else { return nil }
        let view = tab.makeView()
        self.madeViews[id] = view
        return view
    }

    @objc private func tabStripChanged() {
        let index = self.tabStrip.selectedSegment
        guard index >= 0, index < self.tabs.count else { return }
        self.selectedTabID = self.tabs[index].id
        self.showSelectedTab()
    }

    private func showSelectedTab() {
        guard let id = self.selectedTabID, let view = self.view(forTab: id) else { return }
        self.body.accessibilityID("\(self.accessibilityPrefix).tab.\(id)")
        guard view.superview !== self.body else { return }

        for subview in self.body.subviews { subview.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        self.body.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.body.topAnchor),
            view.leadingAnchor.constraint(equalTo: self.body.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.body.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: self.body.bottomAnchor)
        ])
    }

    /// Selects a tab without changing whether the drawer is open. An id that
    /// names no tab is ignored — better a stale tab than a blank drawer.
    private func select(_ id: String?) {
        guard let id, let index = self.tabs.firstIndex(where: { $0.id == id }) else { return }
        self.selectedTabID = id
        self.tabStrip.selectedSegment = index
        self.showSelectedTab()
    }

    // MARK: - Open and close

    /// Announces the change here as well as from `drawerDidOpen(_:)`, and for
    /// a reason the delegate cannot cover: `NSDrawer` does not reliably notify
    /// for a programmatic move made while the parent window is still off
    /// screen, which is the exact case `reapplyVisibility` exists for. The
    /// price is that one open can be announced twice, so a consumer of
    /// `onVisibilityChange` has to be idempotent.
    /// The height is re-read here rather than trusted from `init`, because a
    /// drawer is routinely built while its window is still being assembled —
    /// before a toolbar has grown the titlebar, before a saved frame has been
    /// restored — and the height captured then is not the height the window
    /// ends up with. Reading it at open time makes the construction order stop
    /// mattering. Width is left alone: that one is the owner's to remember.
    public func open(selecting id: String? = nil) {
        self.installBezelIfNeeded()
        self.installAccessibilityProxyIfNeeded()
        self.select(id)
        if let height = self.parentWindow?.frame.height, height > 0 {
            self.drawer.contentSize = NSSize(
                width: self.drawer.contentSize.width, height: height)
        }
        self.drawer.open()
        // Again, after the fact: `NSDrawer` creates its frame view as part of
        // opening, so the call above this one cannot see a frame that did not
        // exist yet — which is the very case that call was added for. With the
        // guard keyed to the current frame view, this costs one pointer
        // comparison whenever the bezel is already where it belongs.
        self.installBezelIfNeeded()
        self.onVisibilityChange?()
    }

    /// Announces the change here as well as from `drawerDidClose(_:)`, for the
    /// same reason `open()` does — and with the same requirement that the
    /// consumer be idempotent.
    public func close() {
        self.drawer.close()
        self.onVisibilityChange?()
    }

    // MARK: - NSDrawerDelegate

    /// The drawer moved, and it was not `open()` or `close()` that moved it —
    /// the user can drag a drawer open and shut by its outer edge, and AppKit
    /// reports that nowhere else. Without this, an owner that remembers
    /// "disclosed" never learns the reader put it away, and re-opens it the
    /// next time the window becomes key.
    public func drawerDidOpen(_ notification: Notification) {
        self.onVisibilityChange?()
    }

    /// The other half of `drawerDidOpen(_:)`, and the half that matters: a
    /// hand-dragged *close* is the one an owner's remembered state gets wrong.
    public func drawerDidClose(_ notification: Notification) {
        self.onVisibilityChange?()
    }

    /// Closes if it is already open *on that tab*; otherwise opens on it. That
    /// is the help button's contract: one click discloses help, a second click
    /// puts it away, and a click while some other tab is showing switches to
    /// help rather than closing a drawer the reader is still using.
    public func toggle(selecting id: String? = nil) {
        if self.isOpen, id == nil || id == self.selectedTabID {
            self.close()
        } else {
            self.open(selecting: id)
        }
    }

    // MARK: - NSDrawer's other sharp edge

    /// A drawer can only open on a window that is already on screen, and a
    /// window's first content is chosen while it is still being made visible —
    /// so an opening call at that moment is silently dropped. Re-applying when
    /// the window arrives is what makes "remembered open" actually open on
    /// launch rather than on the second try.
    ///
    /// Registered by selector rather than by block so the observation is
    /// zeroing-weak — unlike the `delegate` assignment in `init`, it is not
    /// what the `deinit` above is there to undo.
    private func observeParentWindow(_ window: NSWindow) {
        let center = NotificationCenter.default
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didBecomeMainNotification] {
            center.addObserver(
                self,
                selector: #selector(self.parentWindowDidAppear),
                name: name,
                object: window)
        }
    }

    /// Re-asserts whatever the owner last asked for. The owner sets this when
    /// it restores its remembered state; the drawer itself remembers nothing.
    public var reapplyVisibility: (() -> Void)?

    @objc private func parentWindowDidAppear() {
        self.reapplyVisibility?()
    }
}
