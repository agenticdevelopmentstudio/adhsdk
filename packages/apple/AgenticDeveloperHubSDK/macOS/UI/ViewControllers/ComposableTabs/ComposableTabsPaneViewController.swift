import AppKit

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

/// One leaf of a tab: registry-vended content under a pane title bar, plus —
/// while arrange mode is on — the scrim and toolbar that change the layout
/// around it.
///
/// The chrome, the controls, the gear and the spacing all come from
/// `PaneViewController`; what is left here is the three things only a project
/// window knows — which registry vends the content, which background draws the
/// active-pane outline, and what arrange mode does over the top.
///
/// The layout can be rearranged two ways, and they answer different needs. The
/// gear menu carries `Move` always, for the user who knows exactly which pane
/// goes where. Arrange mode dims the content and puts the same four directions
/// in a toolbar in the middle of the pane, for the user who is looking at the
/// window deciding — which is why it can also add and remove, and why the
/// affordance is big and central rather than a corner pull-down. Both ask
/// `ComposableTabsMoveMenu` for the directions, so there is one answer to what
/// `Move` means.
@MainActor
public final class ComposableTabsPaneViewController: PaneViewController {

    public let nodeID: UUID
    public let paneNumber: Int
    public let viewID: ComposableTabsViewID
    /// The directory this pane's content is rooted in — shared by every pane
    /// in the same split tree. See `ComposableTabsViewController.workingDirectory`.
    public let workingDirectory: URL
    /// See `ComposableTabsChild.thicknessFraction`.
    public var thicknessFraction: CGFloat?
    private weak var project: ProjectWorkspace?

    private lazy var arrange: PaneArrangeOverlayController = makeArrangeController()

    /// The four directions, for the gear menu. Held rather than made per click
    /// because `NSMenuItem` keeps its target unowned — the items would fire
    /// into nothing if the thing that made them died with the call.
    private lazy var moveMenu: ComposableTabsMoveMenu = {
        let menu = ComposableTabsMoveMenu()
        menu.availableDirections = { [weak self] in
            guard let self else { return [] }
            return self.enclosingSplitOnScreen?.availableMoveDirections(for: self) ?? []
        }
        menu.onMove = { [weak self] direction in self?.move(direction) }
        return menu
    }()

    /// Set by the enclosing tree when a tab holds more than one pane of this
    /// kind. `nil` — the common case — leaves the identifier unnumbered.
    private var paneIndex: Int?

    /// Set by the enclosing split when it is itself overridden.
    public var layoutOverride: ComposableTabsLayout?

    /// Set by the enclosing split when this pane is nested inside another
    /// pane's content, naming the layout node whose lifetime this pane's
    /// remembered state shares — see `ProjectPaneStateStore.ownerNodeID`.
    ///
    /// The chrome's own store is retargeted here rather than at `init`,
    /// because a pane is built before the tree that knows who owns it.
    public var stateOwnerNodeID: UUID? {
        didSet { (stateStore as? ProjectPaneStateStore)?.ownerNodeID = stateOwnerNodeID }
    }

    public init(
        nodeID: UUID,
        paneNumber: Int,
        viewID: ComposableTabsViewID,
        project: ProjectWorkspace,
        workingDirectory: URL
    ) {
        self.nodeID = nodeID
        self.paneNumber = paneNumber
        self.viewID = viewID
        self.project = project
        self.workingDirectory = workingDirectory
        // The parameters, not `self` — stored properties are set, but `self` is
        // not usable until `super.init` returns.
        super.init(stateStore: ProjectPaneStateStore(project: project, nodeID: nodeID))
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// The backdrop that draws the active-pane outline. Unchanged — it is the
    /// reason this pane has a container of its own at all.
    public override func makeContainerView() -> NSView {
        ComposableTabsPaneBackgroundView(nodeID: nodeID)
    }

    /// `nil` only if the project went away first.
    public override func makeContentViewController() -> NSViewController? {
        guard let project else { return nil }
        let registry = (layoutOverride ?? project.layout).registry
        return registry.makeContentViewController(
            for: viewID,
            nodeID: nodeID,
            project: project,
            workingDirectory: workingDirectory,
            paneNumber: paneNumber,
            ownerNodeID: stateOwnerNodeID,
            // `host` is stamped by the enclosing split at its own `init`, before
            // any pane's view loads, so the walk to the root is already possible
            // the first time this runs — see `stampOwnershipOnChildren()`.
            treeID: (host as? ComposableTabsViewController)?.rootSplit()?.nodeID
        )
    }

    /// The active-pane border is drawn on the backdrop's own layer, so the
    /// chrome is held off its edge by that much or the border lands under it.
    public override var contentInset: CGFloat { Self.borderInset }

    /// What this pane is called, as the registry names it. The same string the
    /// Add popup offers, so a pane and the choice that made it match — and only
    /// used when the content does not name itself.
    public override var fallbackTitle: String { paneName }

    /// `pane.<content-type>`, numbered only when the tab holds more than one of
    /// this kind. The number comes from the tree, which is the only thing that
    /// can know.
    public override var paneAccessibilityIdentifier: String {
        paneIndex.map { "\(paneTypeIdentifier).\($0)" } ?? paneTypeIdentifier
    }

    /// `pane.terminal` from `whippet.terminal` — the identifier is about the
    /// kind of pane, so the vendor prefix that keeps registry keys unique
    /// between apps is not part of it.
    public var paneTypeIdentifier: String {
        let kind = viewID.rawValue.split(separator: ".").last.map(String.init) ?? viewID.rawValue
        return "pane.\(AccessibilityID.slug(kind))"
    }

    /// Called by the root after any change to the tree. Re-stamping the view is
    /// safe at any time and is what makes a *move* renumber both panes.
    public func assignPaneIndex(_ index: Int?) {
        guard paneIndex != index else { return }
        paneIndex = index
        guard isViewLoaded else { return }
        view.accessibilityID(paneAccessibilityIdentifier)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        arrange.attach(to: view)
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        // Also the re-entry point after a move: `rebuild(from:)` re-hosts this
        // controller, and the pane has to come back with the scrim it left with.
        arrange.update()
    }

    /// The active-pane border is drawn on the backdrop's own layer, so the
    /// content is held off its edge by that much or the border lands under it.
    /// One number, spelled where the border is drawn (`dry`).
    private static var borderInset: CGFloat { ComposableTabsPaneBackgroundView.borderInset }

    /// How far below a pane's own top edge its title bar ends: the border
    /// inset the chrome is held off by, plus the title bar itself.
    ///
    /// A tab bar standing beside the workspace lines its first tab up with
    /// this, so the tab reads as belonging to the pane rather than floating
    /// above it.
    public static var titleBarBottom: CGFloat { borderInset + PaneTitleBarView.height }

    /// Called by the enclosing split when this pane leaves the tree for good.
    /// The pane's content may be holding shells or file-system watchers, and
    /// "released at some point after the last reference drops" is not good
    /// enough for a child process.
    public func paneWillBeRemoved() {
        arrange.remove()
        (contentViewController as? PaneContentTeardown)?.paneContentWillBeDiscarded()
    }

    // MARK: - Arrange mode

    /// The split holding this pane, as AppKit knows it. Deliberately not
    /// `host`: everything under this MARK is the arrange overlay, and the
    /// overlay is installed only on a pane whose view is in a window, so
    /// `parent` is set by definition and asking the screen is asking the right
    /// question. Named apart from `ComposableTabsViewController.enclosingSplit`,
    /// which answers the same question about a tree nobody has displayed —
    /// three rounds of this task were spent on readers picking the wrong one of
    /// several spellings of "the split holding this".
    private var enclosingSplitOnScreen: ComposableTabsViewController? {
        parent as? ComposableTabsViewController
    }

    /// What this pane is called, as the registry names it. The same string the
    /// Add popup offers, so a pane and the choice that made it match.
    ///
    /// Resolved against the same layout `makeContentViewController()` vends the
    /// content from: a pane nested inside another pane's tree — a Document
    /// editor — is registered only in the override, and asking the project's
    /// registry about it answers `.unknown`.
    var paneName: String {
        let layout = layoutOverride ?? project?.layout ?? ComposableTabsLayout.placeholderOnly()
        return layout.registry.descriptor(for: viewID).displayName
    }

    private func makeArrangeController() -> PaneArrangeOverlayController {
        let arrange = PaneArrangeOverlayController(nodeID: nodeID)
        arrange.paneName = { [weak self] in self?.paneName ?? "" }
        arrange.canAdd = { [weak self] in self?.addChoices().isEmpty == false }
        arrange.canRemove = { [weak self] in
            guard let self else { return false }
            return self.enclosingSplitOnScreen?.canRemoveLeaf(self) ?? false
        }
        arrange.availableDirections = { [weak self] in
            guard let self else { return [] }
            return self.enclosingSplitOnScreen?.availableMoveDirections(for: self) ?? []
        }
        arrange.onAdd = { [weak self] in self?.presentAddSheet() }
        arrange.onRemove = { [weak self] in self?.confirmAndRemove() }
        arrange.onMove = { [weak self] direction in self?.move(direction) }
        return arrange
    }

    private func move(_ direction: ComposableTabsViewController.Direction) {
        guard let split = enclosingSplitOnScreen, split.move(self, direction) else {
            RefusalFeedback.announce()
            return
        }
    }

    // MARK: - The gear menu

    /// `Move ▸`, above the pane's `Settings…`.
    ///
    /// Built fresh with the menu that holds it, so the four items are enabled
    /// against the tree as it stands at the click — and the parent is disabled
    /// outright when this pane is the only one there is, rather than opening
    /// onto four dead items.
    public override func makeMenuItems() -> [NSMenuItem] {
        let items = moveMenu.makeItems(accessibilityPrefix: "pane.options.move")

        let submenu = NSMenu()
        submenu.autoenablesItems = false
        for item in items { submenu.addItem(item) }

        let move = NSMenuItem(title: "Move", action: nil, keyEquivalent: "")
        move.submenu = submenu
        move.isEnabled = items.contains { $0.isEnabled }
        move.accessibilityID("pane.options.move")
        return [move] + super.makeMenuItems()
    }

    /// The distinct views the spec will let this pane sit beside, named for the
    /// popup. Distinct, because the same view offered on two axes is one thing
    /// to add — the axis is the sheet's *other* question.
    private func addChoices() -> [ComposableTabsAddPaneViewController.Choice] {
        guard let split = enclosingSplitOnScreen else { return [] }
        let registry = split.layout.registry
        var seen = Set<ComposableTabsViewID>()
        return split.allowedInsertions(beside: self).compactMap { insertion in
            // The placeholder is the fallback for content this build does not
            // have, not something anyone means to add. Offering it puts an
            // empty pane one click away in a menu of real ones.
            guard insertion.viewID != .placeholder else { return nil }
            guard seen.insert(insertion.viewID).inserted else { return nil }
            let descriptor = registry.descriptor(for: insertion.viewID)
            return ComposableTabsAddPaneViewController.Choice(
                viewID: insertion.viewID,
                displayName: descriptor.displayName,
                symbolName: descriptor.symbolName
            )
        }
    }

    private func presentAddSheet() {
        let choices = addChoices()
        guard !choices.isEmpty else {
            RefusalFeedback.announce()
            return
        }
        let picker = ComposableTabsAddPaneViewController(choices: choices) { [weak self] viewID, direction in
            guard let self else { return }
            self.enclosingSplitOnScreen?.split(self, adding: viewID, direction: direction)
        }
        // A popover over the button that opened it, not a sheet off the title
        // bar: the question is about *this* pane, and a sheet drops it at the
        // top of a window that may hold five others.
        guard let anchor = arrange.overlay?.addButtonView else {
            presentAsSheet(picker)
            return
        }
        present(picker, asPopoverRelativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY, behavior: .transient)
    }

    /// Removing a pane can throw work away — a running shell, an unsaved edit —
    /// and the pane's content is the only thing that knows whether it would.
    private func confirmAndRemove() {
        guard let split = enclosingSplitOnScreen, split.canRemoveLeaf(self) else {
            RefusalFeedback.announce()
            return
        }
        guard let warning = (contentViewController as? PaneContentRemovalConfirmation)?
            .removalConfirmationMessage else {
            split.remove(self)
            return
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Remove this pane?"
        alert.informativeText = warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")

        guard let window = view.window else {
            if alert.runModal() == .alertFirstButtonReturn { split.remove(self) }
            return
        }
        alert.beginSheetModal(for: window) { response in
            MainActor.assumeIsolated {
                guard response == .alertFirstButtonReturn else { return }
                // Re-resolved: the sheet was up while the tree could change.
                self.enclosingSplitOnScreen?.remove(self)
            }
        }
    }

    /// Whether the window's first responder lives inside this pane, so a
    /// removal can re-home focus rather than leaving the window without one.
    var containsFirstResponder: Bool {
        // A pane that was never shown has no view, and asking for one here
        // would build the whole content graph — on the removal path, purely to
        // throw it away. It also cannot hold the first responder, so the
        // answer is already known (`assignPaneIndex(_:)` guards the same way).
        guard isViewLoaded else { return false }
        guard let responder = view.window?.firstResponder as? NSView else { return false }
        var current: NSView? = responder
        while let candidate = current {
            if candidate === view { return true }
            current = candidate.superview
        }
        return false
    }
}
