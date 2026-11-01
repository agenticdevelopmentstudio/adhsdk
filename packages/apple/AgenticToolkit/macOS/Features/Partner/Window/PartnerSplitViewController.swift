import AppKit
import Combine
import AgenticToolkitCore
import os

/// The Coding Partner window: tab cards and one content pane, built from the same shared components as the
/// Projects window, and "Notifications" as the inspector.
///
/// The content item is a ``MultiTabbedViewController`` with only its left edge on. Its first tab is the
/// partner, which cannot be closed; each live session the partner opened adds another after it. Selecting a
/// card shows that tab's pane in the center.
///
/// Turns the attention pane's buttons into controller calls, and keeps the one piece of window state the
/// controller does not: which attention item, if any, the owner is discussing. The next line the composer
/// sends goes to the partner as the reply to that item, and ends the discussion.
@MainActor
public final class PartnerSplitViewController: NSSplitViewController {

    public let attention: AttentionPaneViewController
    /// The partner's transcript, for prefilling and focusing the composer.
    let chat: PartnerChatViewController
    let tabbed = MultiTabbedViewController()
    /// The partner's tab. Fixed, so a selection can name it.
    let partnerTabID = UUID()

    /// A reference link in the attention pane was clicked that is not a live or closed session of this
    /// window. The app decides what opening it means.
    public var onOpenReference: (([String: String]) -> Void)?

    private let controller: PartnerController
    private var attentionItem: NSSplitViewItem!
    private var notificationsPane: PartnerPaneViewController!
    private var cards: [UUID: (card: TabPaneViewController, source: TabPaneDataSource)] = [:]
    /// The attention item the owner pressed Discuss on and has not replied to yet.
    private var discussionItemID: String?
    private var subscriptions: Set<AnyCancellable> = []
    private var sessionSubscriptions: Set<AnyCancellable> = []
    private var spacingObservers: [UserSettingObserver<Int>] = []
    private var backdropObserver: ThemePaletteObserver?
    private var paneVisibleObserver: UserSettingObserver<Bool>?
    private var collapseObservation: NSKeyValueObservation?

    public init(controller: PartnerController) {
        self.controller = controller
        attention = AttentionPaneViewController(model: AttentionPaneModel(
            store: controller.store,
            retentionDays: { UserSettings.partnerAttentionRetentionDays.value }))
        // The route needs `self`, which does not exist yet: the chat is told where to send afterwards.
        var route: (@MainActor (String) -> Void)?
        chat = PartnerChatViewController(controller: controller) { text in route?(text) }
        super.init(nibName: nil, bundle: nil)
        route = { [weak self] text in self?.sendFromComposer(text) }
        wireAttention()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // No split autosave: it would also restore the inspector's collapsed state, a second source of truth
        // beside `partnerAttentionPaneVisible`.
        configureTabs()
        let contentItem = NSSplitViewItem(viewController: tabbed)
        contentItem.minimumThickness = 500
        addSplitViewItem(contentItem)

        notificationsPane = PartnerPaneViewController(
            title: "Notifications", content: attention, showsCloseButton: false)
        notificationsPane.host = self
        let attentionItem = NSSplitViewItem(inspectorWithViewController: notificationsPane)
        attentionItem.minimumThickness = 260
        attentionItem.canCollapse = true
        attentionItem.isCollapsed = !UserSettings.partnerAttentionPaneVisible.value
        addSplitViewItem(attentionItem)
        self.attentionItem = attentionItem
        bindAttentionVisibility()

        observeTabs()
        syncTabs()
        tabbed.selectTab(id: partnerTabID, on: .left)
    }

    // MARK: - Tabs

    /// Left edge only, and the Projects window's spacing and backdrop: the same shared setters it calls.
    private func configureTabs() {
        tabbed.delegate = self
        tabbed.setEdgeEnabled(.top, false)
        tabbed.setEdgeEnabled(.left, true)
        ComposableTabsWindowController.applyPaneSpacing(PaneSpacing.contentInsets, to: tabbed)
        spacingObservers = PaneSpacing.edgeSettings.values.map { setting in
            UserSettingObserver(setting) { [weak self] _ in
                guard let tabbed = self?.tabbed else { return }
                ComposableTabsWindowController.applyPaneSpacing(PaneSpacing.contentInsets, to: tabbed)
            }
        }
        backdropObserver = ThemePaletteObserver(host: tabbed.view) { [weak self] palette in
            self?.tabbed.centerBackgroundColor = NSColor(palette.projectPaneBackdrop)
            self?.tabbed.centerOutlineColor = NSColor(palette.projectPaneOutline)
            self?.view.window?.backgroundColor = NSColor(palette.projectPaneBackdrop)
        }
        addTab(id: partnerTabID, source: PartnerCardSource(controller: controller),
               pane: PartnerPaneViewController(
                   title: "Partner", content: chat, showsCloseButton: false), closable: false)
    }

    private func addTab(id: UUID, source: TabPaneDataSource, pane: PartnerPaneViewController, closable: Bool,
                        at index: Int? = nil) {
        let card = TabPaneViewController(edge: .left, tabID: id)
        card.dataSource = source
        card.showsCloseButton = closable
        card.reload()
        pane.host = self
        cards[id] = (card, source)
        let tab = MultiTabbedViewController.Tab(id: id, item: .viewController(card), viewController: pane)
        if let index { tabbed.insertTab(tab, at: index, on: .left) } else { tabbed.addTab(tab, on: .left) }
    }

    /// Selects the tab for the session with `sessionID`; nil, or a session no longer open, selects the partner.
    public func select(sessionID: UUID?) {
        loadViewIfNeeded()
        let id = sessionID.flatMap { cards[$0] != nil ? $0 : nil } ?? partnerTabID
        tabbed.selectTab(id: id, on: .left)
    }

    /// Puts `text` in the partner's composer with the cursor at its end, showing the partner first.
    public func prefillComposer(_ text: String) {
        select(sessionID: nil)
        let chatView = chat.chatView
        guard let field = chatView.composerField as? NSTextField else { return }
        field.stringValue = text
        // The send button follows the delegate's text-changed call, which a programmatic set does not make.
        chatView.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        chatView.focusInput()
        field.currentEditor()?.selectedRange = NSRange(location: (text as NSString).length, length: 0)
    }

    /// Adds a tab for each session that opened and removes the tab of each that closed; when the selected tab
    /// goes, the partner is selected.
    private func syncTabs() {
        let live = controller.sessions.sessions
        let liveIDs = Set(live.map(\.id))
        for id in cards.keys where id != partnerTabID && !liveIDs.contains(id) {
            // Select the partner first, so the neighbouring session is never mounted for a moment.
            if tabbed.activeTabID == id { tabbed.selectTab(id: partnerTabID, on: .left) }
            tabbed.removeTab(id: id)
            cards[id] = nil
        }
        for (offset, session) in live.enumerated() where cards[session.id] == nil {
            let store = controller.store
            let source = SessionCardSource(session: session) { id in
                do { return try store.review(id: id) } catch {
                    Self.logger.error("Loading review \(id) failed: \(error.localizedDescription)")
                    return nil
                }
            }
            let pane = PartnerPaneViewController(
                title: "Terminal", content: session.viewController, sessionID: session.id)
            addTab(id: session.id, source: source, pane: pane, closable: true,
                   at: min(offset + 1, tabbed.tabs(on: .left).count))
        }
        reloadCards()
    }

    private func reloadCards() {
        for entry in cards.values { entry.card.reload() }
    }

    private func observeTabs() {
        controller.$state
            .sink { [weak self] _ in self?.scheduleSync(sessionsChanged: false) }
            .store(in: &subscriptions)
        controller.sessions.$sessions
            .sink { [weak self] sessions in self?.observe(sessions) }
            .store(in: &subscriptions)
        controller.store.changes
            // Main first: the filter closure is main-actor isolated, and writes arrive from MCP calls off it.
            .receive(on: DispatchQueue.main)
            // A review's state and summary are on its session's card, and the queue is on the partner's.
            .filter { $0 == .sessions || $0 == .reviews }
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.reloadCards() } }
            .store(in: &subscriptions)
        // The partner's card names the provider and model chosen in Settings.
        controller.settings.changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.reloadCards() } }
            .store(in: &subscriptions)
    }

    /// A session's state is on its card, so each live session's changes reload the cards too.
    private func observe(_ sessions: [PartnerSession]) {
        sessionSubscriptions = []
        for session in sessions {
            session.$state
                .sink { [weak self] _ in self?.scheduleSync(sessionsChanged: false) }
                .store(in: &sessionSubscriptions)
        }
        scheduleSync(sessionsChanged: true)
    }

    /// `@Published` sends before the value changes, so the tabs are read on the next main-queue turn.
    private func scheduleSync(sessionsChanged: Bool) {
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                if sessionsChanged { self?.syncTabs() } else { self?.reloadCards() }
            }
        }
    }

    // MARK: - Show session

    /// A reference link was clicked. One that names a session selects its tab, or shows a closed session's
    /// final screen; anything else goes to the app.
    private func open(reference: [String: String]) {
        guard let raw = AttentionCard.sessionID(reference), !raw.isEmpty else {
            onOpenReference?(reference)
            return
        }
        if let id = UUID(uuidString: raw), cards[id] == nil, controller.sessions.session(id: id) != nil {
            syncTabs()
        }
        if let id = UUID(uuidString: raw), cards[id] != nil {
            select(sessionID: id)
        } else if let record = storedRecord(id: raw) {
            let pane = PartnerPaneViewController(title: "Final screen",
                                                 content: PartnerFinalScreenViewController(record: record))
            pane.host = self
            tabbed.overlayContentViewController = pane
        } else {
            onOpenReference?(reference)
        }
    }

    private func storedRecord(id: String) -> PartnerStore.SessionRecord? {
        do { return try controller.store.sessions().first { $0.id == id } } catch {
            Self.logger.error("Loading partner sessions failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Composer

    /// The owner's reply to the item under discussion: an owner line carrying the item id, so the partner
    /// can close it with `partner_attention_update`.
    static func discussionReply(itemID: String, text: String) -> PartnerInbound {
        let attribution = ChatMessage.Attribution(
            sourceID: PartnerController.attentionSourcePrefix + itemID, context: [], name: "Discuss",
            iconSymbol: "bubble.left.and.bubble.right")
        return .owner(text: "Regarding attention item \(itemID):\n\(text)", attribution: attribution)
    }

    private func sendFromComposer(_ text: String) {
        guard let itemID = discussionItemID else {
            controller.chatSession.send(text)
            return
        }
        discussionItemID = nil
        controller.enqueue(Self.discussionReply(itemID: itemID, text: text))
    }

    // MARK: - Attention

    private func wireAttention() {
        let model = attention.model
        model.onDiscuss = { [weak self] id in self?.discuss(itemID: id) }
        model.onResolved = { [weak self] id in self?.press(.resolved, itemID: id) }
        model.onConfirm = { [weak self] id in self?.press(.confirm, itemID: id) }
        model.onOpenReference = { [weak self] reference in self?.open(reference: reference) }
    }

    private func discuss(itemID: String) {
        do {
            let quoted = try controller.beginDiscussion(itemID: itemID)
            discussionItemID = itemID
            prefillComposer(quoted)
        } catch {
            Self.logger.error("Discuss on \(itemID) failed: \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    private func press(_ action: AttentionActionKind, itemID: String) {
        do {
            try controller.performButton(action, itemID: itemID)
            // A Resolved on the item being discussed settles it: the next composer line is ordinary again.
            if discussionItemID == itemID { discussionItemID = nil }
        } catch {
            Self.logger.error("\(action.rawValue) on \(itemID) failed: \(error.localizedDescription)")
            // Nothing was written, so no reload is coming: redraw the card from the store now.
            attention.model.reload()
            NSSound.beep()
        }
    }

    /// The inspector follows the setting, and a toggle in the window writes it back.
    private func bindAttentionVisibility() {
        paneVisibleObserver = UserSettingObserver(UserSettings.partnerAttentionPaneVisible) { [weak self] visible in
            guard let item = self?.attentionItem, item.isCollapsed == visible else { return }
            item.animator().isCollapsed = !visible
        }
        collapseObservation = attentionItem.observe(\.isCollapsed, options: [.new]) { [weak self] _, _ in
            MainActor.assumeIsolated {
                guard let item = self?.attentionItem else { return }
                let visible = !item.isCollapsed
                if UserSettings.partnerAttentionPaneVisible.value != visible {
                    UserSettings.partnerAttentionPaneVisible.value = visible
                }
            }
        }
    }
}

extension PartnerSplitViewController: MultiTabbedViewControllerDelegate {
    /// A card's close closes its session; the partner's card cannot close.
    public func multiTabbedViewController(_ controller: MultiTabbedViewController,
                                          didRequestCloseTab id: UUID, on edge: Edge) {
        guard id != partnerTabID else { return }
        self.controller.sessions.close(id: id)
    }
}

extension PartnerSplitViewController: PaneHost {
    public func paneDidRequestClose(_ pane: PaneViewController) {
        if let sessionID = (pane as? PartnerPaneViewController)?.sessionID {
            controller.sessions.close(id: sessionID)
        } else if pane === tabbed.overlayContentViewController {
            tabbed.overlayContentViewController = nil
        }
    }

    public func paneDidRequestZoom(_ pane: PaneViewController) {}
    public func paneDidRequestMinimize(_ pane: PaneViewController, to edge: PaneEdge) {}
    public func paneDidRequestRestore(_ pane: PaneViewController) {}
    public func availableMinimizeEdges(for pane: PaneViewController) -> Set<PaneEdge> { [] }

    /// The partner and Notifications stay; a session, and a final screen, close.
    public func canClose(_ pane: PaneViewController) -> Bool {
        (pane as? PartnerPaneViewController)?.sessionID != nil || pane === tabbed.overlayContentViewController
    }
}

extension PartnerSplitViewController: Loggable {
    public static nonisolated let logger = makeLogger()
}
