import AgenticDeveloperHubSDKUI
import AppKit
import Combine

import AgenticDeveloperHubSDKCore

/// A pane: a title bar, some content, and enough memory to come back the way it
/// was left.
///
/// It knows nothing about split views, layout trees, tabs, projects or SQLite.
/// Three seams are the whole of it — a `PaneHost` it sends requests to, a
/// `PaneStateStore` it remembers itself through, and content it *probes* for
/// six optional capabilities. Every one of those is supplied from outside
/// (`dependency-injection`), which is what makes "deploy the same pane in a
/// different kind of view" a matter of supplying a different host rather than a
/// matter of editing this class.
///
/// Subclass hooks, all `open`: `makeContentViewController()`,
/// `makeContainerView()`, `makeOptionRows()`, `makeMenuItems()`,
/// `fallbackTitle`, `contentInset` and `paneAccessibilityIdentifier`. A
/// subclass that overrides none of them still gets a working, empty pane.
///
/// Content that implements none of the six capability protocols is a supported
/// case, not a degraded one: it gets `fallbackTitle`, no accessories, no
/// pane-specific options, the generic minimized glyph, a search field that
/// stays disabled and a display path that stops at the pane.
@MainActor
open class PaneViewController: NSViewController {

    /// Weak: the host owns the pane, always.
    public weak var host: PaneHost? {
        didSet { refreshControlAvailability() }
    }

    public let stateStore: PaneStateStore

    public let titleBar = PaneTitleBarView()

    /// Whether this pane's width is its container's to decide rather than its
    /// own — set by the split holding it, for a tree living inside one pane of
    /// a bigger tree.
    ///
    /// All it means here is that the chrome stops asking for width. A title
    /// bar's contents reach the enclosing split through a required chain, so
    /// they land there as a floor under the *enclosing* pane — one per pane in
    /// the tab, which is how opening a fourth editor widened a Document pane
    /// the user had sized. The split gives up its own half of that through
    /// `minimumThickness` and `holdingPriority`; this is the other half.
    ///
    /// One way, like the split's own flag: a pane does not stop being clamped,
    /// and the bar cannot un-yield.
    public var clampsToContainer = false {
        didSet {
            guard clampsToContainer else { return }
            titleBar.yieldWidthToContainer()
        }
    }

    /// The content this pane wraps, held as a child so AppKit keeps it alive,
    /// routes appearance callbacks to it, and puts it in the responder chain.
    public private(set) var contentViewController: NSViewController?

    /// Which edge this pane is currently docked to, or `nil` when it is whole.
    public private(set) var minimizedEdge: PaneEdge?

    public private(set) var isZoomed = false

    /// Fires when the content's selection changed. The window listens, so the
    /// footer's display path is recomputed by whoever knows the rest of the path.
    public var onSelectionChange: (() -> Void)?

    /// Fires when `resolvedTitle` changed. The pane's own title bar is not the
    /// only thing that shows it — the window's footer names the pane too — so
    /// the change is published rather than only painted here.
    public var onTitleChange: (() -> Void)?

    /// Internal rather than private so a test can check which edges the picker
    /// was opened with, without opening a popover.
    private(set) var minimizePicker: PaneMinimizePicker?

    private let contentContainer = NSView()
    private var minimizedStrip: PaneMinimizedStripView?

    /// Which edge the live strip was built for. The dock constraint and the
    /// strip's own hairline side are both decided at construction, so a strip
    /// built for one horizontal edge is wrong for the other and has to be
    /// replaced rather than re-shown.
    private var builtStripEdge: PaneEdge?

    /// Held so the rail can switch it off. A pane minimized to a side is pinned
    /// narrower than the title bar's own controls can fit, and a hidden view
    /// still takes part in Auto Layout — so leaving both sides pinned makes the
    /// item's 32pt maximum unsatisfiable, and AppKit recovers by breaking a
    /// constraint inside the title bar it happens to pick.
    private var titleBarTrailing: NSLayoutConstraint?
    /// The gear itself, drawn by the chrome that draws every other gear. What
    /// it *raises* is this pane's business — a menu — but what it looks like is
    /// the window chrome's single answer, and asking for it rather than
    /// respelling it keeps it that way (`dry`).
    private let gearButton = WindowOptionsDialog.makeGearButton(tooltip: "Pane options")

    /// The options dialog, while it is on screen.
    ///
    /// Weak, and internal rather than private: the presenter owns a sheet for
    /// exactly as long as it is up, and a pane still holding a dismissed one
    /// would answer `refreshTitle()` by renaming a heading nobody can see.
    private(set) weak var optionsSheet: OptionsDialogViewController?

    /// What the pane is *itself* holding the content off its edges by. Zero
    /// when the content applies the gap instead — which is the invariant this
    /// property exists to make testable.
    public private(set) var contentSpacingInsets = NSEdgeInsets()

    private var contentEdgeConstraints: (top: NSLayoutConstraint,
                                         leading: NSLayoutConstraint,
                                         bottom: NSLayoutConstraint,
                                         trailing: NSLayoutConstraint)?

    /// Re-insets the content when the app-wide pane-content spacing changes.
    private var spacingObservation: AnyCancellable?

    public init(stateStore: PaneStateStore = EphemeralPaneStateStore()) {
        self.stateStore = stateStore
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Subclass hooks

    /// The content. Called once, during `loadView()`.
    open func makeContentViewController() -> NSViewController? { nil }

    /// The pane's own background. A subclass with a selection border or a
    /// backdrop overrides this.
    open func makeContainerView() -> NSView { ThemedBackgroundView(role: .windowBackground) }

    /// What the title bar says when the content does not name itself.
    open var fallbackTitle: String { "Pane" }

    /// The icon the title bar shows when the content has none of its own;
    /// `nil` shows none.
    open var fallbackIcon: NSImage? { nil }

    /// How far the content is held off the container's edges. A subclass that
    /// draws a border on the container needs room for it.
    open var contentInset: CGFloat { 0 }

    /// The identifier on the pane's container view. Subclasses that know what
    /// kind of content they hold make it specific, so a UI test can address one
    /// pane among several.
    open var paneAccessibilityIdentifier: String { "pane" }

    /// How far this pane holds its content off its edges: the app-wide pane
    /// content spacing (Settings > Appearance > Spacing). No pane has spacing
    /// of its own, so every pane in every window is spaced alike.
    public var paneContentSpacing: Spacing { PaneSpacing.contentSpacing }

    /// The rows in the options dialog: the content's own. Empty means the
    /// gear menu offers no `Settings…` item at all.
    open func makeOptionRows() -> [NSView] {
        (contentViewController as? PaneOptionsProviding)?.makePaneOptionRows() ?? []
    }

    /// The pane's own items in the gear menu, above `Settings…`.
    ///
    /// Only the content's here (`PaneMenuProviding`), and deliberately so: a
    /// bare pane has nothing to offer but its settings, and it must not learn
    /// about split views to say so. A pane that lives in a layout knows which
    /// ways it can move, and that knowledge belongs to *that* pane (`srp`) —
    /// an override puts its own items first and then calls `super`.
    open func makeMenuItems() -> [NSMenuItem] {
        (contentViewController as? PaneMenuProviding)?.makePaneMenuItems() ?? []
    }

    /// What the title bar's Move button drops down: the directions this pane
    /// may move in, each enabled against the layout at the click. Empty — the
    /// default — hides the button, for a pane whose host cannot rearrange.
    open func makeMoveMenuItems() -> [NSMenuItem] { [] }

    /// Whether this pane offers Move at all. Asked once, at load, to decide
    /// whether the button is shown; which directions are open is asked per
    /// click, through `makeMoveMenuItems()`.
    open var offersMove: Bool { false }

    // MARK: - Loading

    open override func loadView() {
        let container = makeContainerView()
        container.frame = NSRect(x: 0, y: 0, width: 300, height: 200)
        container.accessibilityID(paneAccessibilityIdentifier)

        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleBar)
        container.addSubview(contentContainer)

        let titleBarTrailing = container.trailingAnchor.constraint(
            equalTo: titleBar.trailingAnchor, constant: contentInset)
        self.titleBarTrailing = titleBarTrailing

        NSLayoutConstraint.activate([
            titleBar.topAnchor.constraint(equalTo: container.topAnchor, constant: contentInset),
            titleBar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: contentInset),
            titleBarTrailing,

            contentContainer.topAnchor.constraint(equalTo: titleBar.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: contentInset),
            container.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: contentInset),
            container.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: contentInset)
        ])

        if let content = makeContentViewController() {
            addChild(content)
            contentViewController = content
            let view = content.view
            view.translatesAutoresizingMaskIntoConstraints = false
            contentContainer.addSubview(view)
            let top = view.topAnchor.constraint(equalTo: contentContainer.topAnchor)
            let leading = view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor)
            let bottom = contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            let trailing = contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            NSLayoutConstraint.activate([top, leading, bottom, trailing])
            contentEdgeConstraints = (top, leading, bottom, trailing)
        }

        self.view = container
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        wireControls()
        wireContentCallbacks()
        spacingObservation = UserSettings.shared.changes
            .filter { PaneSpacing.contentSettingKeys.contains($0) }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyResolvedSpacing() }
        applyResolvedSpacing()
        installGear()
        refreshTitle()
        refreshAccessories()
        refreshControlAvailability()
        restorePersistedState()
    }

    // MARK: - Wiring

    private func wireControls() {
        titleBar.controls.onClose = { [weak self] in
            guard let self else { return }
            host?.paneDidRequestClose(self)
        }
        titleBar.controls.onZoom = { [weak self] in
            guard let self else { return }
            host?.paneDidRequestZoom(self)
        }
        titleBar.controls.onRestore = { [weak self] in
            guard let self else { return }
            host?.paneDidRequestRestore(self)
        }
        titleBar.controls.onMinimize = { [weak self] anchor in
            self?.presentMinimizePicker(from: anchor)
        }
        if offersMove {
            titleBar.controls.onMove = { [weak self] anchor in
                self?.presentMoveMenu(from: anchor)
            }
        }
    }

    /// Drops the directions below the button, the way a pull-down does.
    /// `autoenablesItems` is off for the same reason as the gear's menu.
    private func presentMoveMenu(from anchor: NSButton) {
        let menu = NSMenu()
        menu.autoenablesItems = false
        for item in makeMoveMenuItems() { menu.addItem(item) }
        guard !menu.items.isEmpty else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: anchor.bounds.maxY + 2), in: anchor)
    }

    /// The two capabilities that push rather than being pulled. Both are
    /// installed once, here, so the content never has to know who is listening.
    private func wireContentCallbacks() {
        (contentViewController as? PaneTitleProviding)?.onPaneTitleChange = { [weak self] in
            self?.refreshTitle()
        }
        (contentViewController as? PaneSelectionDescribing)?.onPaneSelectionChange = { [weak self] in
            self?.onSelectionChange?()
        }
    }

    private func installGear() {
        gearButton.target = self
        gearButton.action = #selector(showOptionsMenu)
        gearButton.accessibilityID("pane.options")
        gearButton.setAccessibilityLabel("Pane Options")
        titleBar.gearView = gearButton
    }

    /// What the gear raises: the pane's own items, then `Settings…` when the
    /// content has rows for it. Empty when neither has anything to offer, and
    /// then the gear is not shown at all — see `refreshGearVisibility()`.
    ///
    /// Built fresh on every click, because what a pane may legally do — which
    /// ways it can move, above all — changes with the layout around it, and a
    /// menu built once at `viewDidLoad` would be answering for a layout that no
    /// longer exists.
    ///
    /// `autoenablesItems` is off deliberately. A menu raised from a button has
    /// no validation chain, so AppKit would grey out every item whose action
    /// nothing claims to validate; each item states its own availability
    /// instead (`explicit-over-implicit`).
    ///
    /// Internal rather than private so a test can read the menu without
    /// raising it — clicking a gear is not something a unit test can do.
    func makeOptionsMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let items = makeMenuItems()
        for item in items { menu.addItem(item) }
        guard hasOptionRows else { return menu }
        if !items.isEmpty { menu.addItem(.separator()) }

        let settings = NSMenuItem(
            title: "Settings…",
            action: #selector(showOptionsDialog),
            keyEquivalent: ""
        )
        settings.target = self
        settings.image = NSImage(
            systemSymbolName: "slider.horizontal.3",
            accessibilityDescription: "Settings")
        settings.accessibilityID("pane.options.settings")
        menu.addItem(settings)

        return menu
    }

    /// Whether the content has anything for a `Settings…` dialog to show, asked without building the rows:
    /// the gear asks on every pane-tree refresh, and building a pane's rows has side effects (a persona chat
    /// re-points its model popups and fetches the model list). A subclass overriding `makeOptionRows()`
    /// overrides this too.
    open var hasOptionRows: Bool {
        (contentViewController as? PaneOptionsProviding)?.hasPaneOptionRows ?? false
    }

    /// Whether the gear has a menu to raise. Internal so a test can read it.
    var hasOptionsMenu: Bool { makeOptionsMenu().numberOfItems > 0 }

    /// Hides the gear when its menu would be empty — only UI with content is
    /// shown. What a pane's menu holds can change with the layout around it,
    /// so the host calls this along with `refreshControlAvailability()`.
    public func refreshGearVisibility() {
        guard isViewLoaded else { return }
        gearButton.isHidden = !hasOptionsMenu
    }

    @objc private func showOptionsMenu(_ sender: NSButton) {
        // `(0, 0)` is the button's own bottom-left — its content is unflipped —
        // and `popUp` lands the menu's top-left there, so the menu hangs below
        // the gear instead of covering it.
        makeOptionsMenu().popUp(positioning: nil, at: .zero, in: sender)
    }

    @objc private func showOptionsDialog() {
        let sheet = OptionsDialogViewController(
            heading: resolvedTitle,
            rows: makeOptionRows(),
            width: 340,
            accessibilityPrefix: "pane.options"
        )
        sheet.onDone = { [weak sheet, weak self] in
            guard let sheet else { return }
            self?.dismiss(sheet)
        }
        optionsSheet = sheet
        presentAsSheet(sheet)
    }

    /// Closes the options dialog, when it is up — for a row whose action
    /// carries on somewhere the sheet would be in the way of, such as picking
    /// another pane in the window.
    public func dismissOptionsDialog() {
        guard let optionsSheet else { return }
        dismiss(optionsSheet)
    }

    private func presentMinimizePicker(from anchor: NSButton) {
        let edges = host?.availableMinimizeEdges(for: self) ?? []
        let picker = PaneMinimizePicker(availableEdges: edges) { [weak self] edge in
            guard let self else { return }
            host?.paneDidRequestMinimize(self, to: edge)
        }
        minimizePicker = picker
        picker.show(relativeTo: anchor)
    }

    // MARK: - Spacing

    /// Hands the gap to whichever of the two is applying it, and takes it back
    /// off the other. Safe to call repeatedly — it assigns, it does not
    /// accumulate (`idempotency`).
    public func applyResolvedSpacing() {
        let spacing = paneContentSpacing
        if let consumer = contentViewController as? PaneContentSpacingConsuming {
            consumer.applyPaneSpacing(spacing)
            contentSpacingInsets = NSEdgeInsets()
        } else {
            contentSpacingInsets = NSEdgeInsets(
                top: CGFloat(spacing.top), left: CGFloat(spacing.leading),
                bottom: CGFloat(spacing.bottom), right: CGFloat(spacing.trailing))
        }

        contentEdgeConstraints?.top.constant = contentSpacingInsets.top
        contentEdgeConstraints?.leading.constant = contentSpacingInsets.left
        contentEdgeConstraints?.bottom.constant = contentSpacingInsets.bottom
        contentEdgeConstraints?.trailing.constant = contentSpacingInsets.right
    }

    // MARK: - Reading the content

    public var resolvedTitle: String {
        (contentViewController as? PaneTitleProviding)?.paneTitle ?? fallbackTitle
    }

    public var resolvedIcon: NSImage? {
        (contentViewController as? PaneIconProviding)?.paneIcon ?? fallbackIcon
    }

    /// What the content has selected, or `nil` — in which case a display path
    /// stops at this pane rather than showing an empty trailing segment.
    public var selectionDescription: String? {
        (contentViewController as? PaneSelectionDescribing)?.paneSelectionDescription
    }

    public var isSearchable: Bool { contentViewController is PaneSearchable }

    public var searchPlaceholder: String? {
        (contentViewController as? PaneSearchable)?.paneSearchPlaceholder
    }

    public func search(for query: String) {
        (contentViewController as? PaneSearchable)?.paneSearch(for: query)
    }

    /// The pane's name has three readers: its own title bar, the options
    /// dialog's heading, and — through `onTitleChange` — the window footer.
    /// Content that renames itself calls this, so all three are re-read
    /// together rather than leaving the dialog showing whatever the pane was
    /// called when it opened.
    public func refreshTitle() {
        titleBar.title = resolvedTitle
        titleBar.icon = resolvedIcon
        optionsSheet?.heading = resolvedTitle
        onTitleChange?()
    }

    /// Re-asks the content for its title-bar controls. Content whose controls
    /// depend on its own state calls this by changing, and the pane replaces
    /// the whole array rather than diffing it.
    public func refreshAccessories() {
        titleBar.accessoryViews =
            (contentViewController as? PaneAccessoryProviding)?.makePaneAccessoryViews() ?? []
    }

    /// Re-asks the host which controls are legal. Both answers change whenever
    /// the layout around this pane does, which is why this is a call and not two
    /// properties set once.
    ///
    /// A pane with no host yet keeps both buttons live: the answer arrives with
    /// the host, and a pane that greyed its controls while being wired up would
    /// have to be re-asked by whatever wired it — which is the bug this method
    /// exists to avoid.
    public func refreshControlAvailability() {
        guard isViewLoaded else { return }
        let edges = host?.availableMinimizeEdges(for: self) ?? []
        titleBar.controls.canMinimize = !edges.isEmpty
        titleBar.controls.canClose = host?.canClose(self) ?? true
        if offersMove {
            // A pane not yet on screen cannot ask its split, and answers no
            // directions; leave the button live until it can really ask.
            let items = makeMoveMenuItems()
            titleBar.controls.canMove = items.isEmpty || items.contains { $0.isEnabled }
        }
        refreshGearVisibility()
    }

    // MARK: - State the host hands back

    /// How thick this pane is once it is minimized along `edge` — the rail's
    /// width for a side, the title bar's height for a top or bottom. The
    /// border allowance is counted twice because it sits on both sides of
    /// whichever chrome is left showing.
    ///
    /// The host pins the pane to this. It is a method on the pane because the
    /// answer is a fact about the pane's own chrome: a subclass with a taller
    /// title bar overrides `contentInset`, and this follows.
    public func minimizedThickness(for edge: PaneEdge) -> CGFloat {
        let chrome = edge.isHorizontal
            ? PaneMinimizedStripView.thickness
            : PaneTitleBarView.height
        return chrome + contentInset * 2
    }

    /// Called by the host once it has actually minimized (or restored) this
    /// pane. Never called from a click: a click is a request.
    public func setMinimized(to edge: PaneEdge?) {
        minimizedEdge = edge
        stateStore.setPaneStateValue(edge?.rawValue, forKey: PaneStateKey.minimizeEdge)
        applyMinimizedAppearance()
    }

    public func setZoomed(_ zoomed: Bool) {
        isZoomed = zoomed
        titleBar.controls.isZoomed = zoomed
        stateStore.setPaneStateValue(zoomed ? "1" : nil, forKey: PaneStateKey.zoomed)
    }

    // MARK: - Persistence

    /// What the store says this pane was left as. The host reads these to work
    /// out what the *tree* has to do about it — collapsing a split item,
    /// collapsing an ancestor chain — which is not this class's business.
    public var persistedMinimizeEdge: PaneEdge? {
        stateStore.paneStateValue(forKey: PaneStateKey.minimizeEdge).flatMap(PaneEdge.init(rawValue:))
    }

    public var persistedZoomed: Bool {
        stateStore.paneStateValue(forKey: PaneStateKey.zoomed) == "1"
    }

    /// A value that no longer parses — a key written by an older build, or a
    /// hand-edited row — is treated as absent rather than as a reason to stop.
    /// The cost of being wrong is a pane that opens whole.
    private func restorePersistedState() {
        if let edge = persistedMinimizeEdge {
            minimizedEdge = edge
            applyMinimizedAppearance()
        }
        if persistedZoomed {
            isZoomed = true
            titleBar.controls.isZoomed = true
        }
    }

    // MARK: - Appearance

    /// The content's four pins to `contentContainer`, on or off together.
    /// Nothing to do for a pane whose content view controller declined to
    /// exist — there is no content to pin.
    private func setContentEdgeConstraints(active: Bool) {
        guard let edges = contentEdgeConstraints else { return }
        let all = [edges.top, edges.leading, edges.bottom, edges.trailing]
        if active {
            NSLayoutConstraint.activate(all)
        } else {
            NSLayoutConstraint.deactivate(all)
        }
    }

    /// The three shapes a pane can be in, in one place, so they cannot disagree.
    ///
    /// - whole: title bar over content.
    /// - minimized top or bottom: the title bar, and nothing under it.
    /// - minimized leading or trailing: a rail one icon wide, instead of both.
    ///
    /// Does nothing until the view exists, the same guard
    /// `refreshControlAvailability()` makes and for a sharper reason: every
    /// branch below touches `view`, so on an unloaded pane this method *loads*
    /// it — and `viewDidLoad` ends by calling `restorePersistedState()`, which
    /// re-enters here. The rail built by the inner call is the one
    /// `minimizedStrip` ends up holding; the outer call then adds a second
    /// rail to the same view that nothing tracks and nothing can remove.
    /// `minimizedEdge` and the store are already written by the time this is
    /// called, so skipping is lossless: whenever the view does load,
    /// `restorePersistedState()` applies exactly this.
    private func applyMinimizedAppearance() {
        guard isViewLoaded else { return }
        titleBar.controls.isMinimized = minimizedEdge != nil
        // Only the rail is narrower than the title bar; every other shape shows
        // it, so it goes back to spanning the pane.
        titleBarTrailing?.isActive = !(minimizedEdge?.isHorizontal ?? false)

        guard let edge = minimizedEdge else {
            titleBar.isHidden = false
            contentContainer.isHidden = false
            contentViewController?.view.isHidden = false
            setContentEdgeConstraints(active: true)
            minimizedStrip?.removeFromSuperview()
            minimizedStrip = nil
            builtStripEdge = nil
            return
        }

        contentContainer.isHidden = true
        contentViewController?.view.isHidden = true
        // Hidden is not un-laid-out: AppKit still solves for a hidden view, so
        // content with its own minimum size goes on demanding it from a
        // container the host has just squeezed to a rail's width, and the
        // engine breaks whichever constraint it likes to get out. Releasing
        // the four pins takes the content out of the pane's layout entirely
        // while it has no space to be in, and `setMinimized(to: nil)` puts
        // them back before it is visible again.
        setContentEdgeConstraints(active: false)

        guard edge.isHorizontal else {
            titleBar.isHidden = false
            minimizedStrip?.removeFromSuperview()
            minimizedStrip = nil
            builtStripEdge = nil
            return
        }

        titleBar.isHidden = true
        if builtStripEdge != edge {
            minimizedStrip?.removeFromSuperview()
            minimizedStrip = nil
            builtStripEdge = nil
        }
        if minimizedStrip == nil {
            let representing = contentViewController as? PaneMinimizedRepresenting
            let strip = PaneMinimizedStripView(
                edge: edge,
                symbolName: representing?.paneMinimizedSymbolName ?? PaneMinimizedStripView.defaultSymbolName,
                tooltip: representing?.paneMinimizedTooltip ?? resolvedTitle
            )
            strip.onRestore = { [weak self] in
                guard let self else { return }
                host?.paneDidRequestRestore(self)
            }
            view.addSubview(strip)
            // The strip owns its own 28pt width. Pinning both sides as well
            // makes that width unsatisfiable at every container size but one,
            // so the pane docks the rail to the edge it minimized toward and
            // lets the rail's own width settle the other side. At the
            // thickness the host pins a minimized split item to, the two
            // agree exactly; at any other width the rail hugs its edge
            // instead of fighting.
            let dockedSide = edge == .leading
                ? strip.leadingAnchor.constraint(equalTo: view.leadingAnchor)
                : strip.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            NSLayoutConstraint.activate([
                strip.topAnchor.constraint(equalTo: view.topAnchor),
                strip.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                dockedSide
            ])
            minimizedStrip = strip
            builtStripEdge = edge
        }
    }
}
