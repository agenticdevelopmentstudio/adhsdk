import AppKit
import AgenticToolkitCore

/// The partner's tab: the Partner chat pane and the Notifications pane, split the way a Projects window
/// splits its panes.
///
/// The split view is the shared ``PaneSplitView``, so the gap between the two panes is the app-wide gutter
/// and follows Appearance > Spacing as it changes. Both panes are fixed: neither has a close button, and
/// ``PartnerSplitViewController`` refuses to close either. Arrange mode moves them: Notifications can sit
/// to either side of the Partner pane, above it or below it, and the choice is remembered in
/// ``UserSettings/partnerNotificationsSide``.
@MainActor
final class PartnerPanesViewController: ThemedSplitViewController, PartnerPaneArranging {

    typealias Direction = ComposableTabsViewController.Direction

    /// The Notifications pane's width (side by side) or height (stacked) when it is placed, and the
    /// least either pane can be dragged to.
    static let notificationsInitialWidth: CGFloat = 340
    static let notificationsInitialHeight: CGFloat = 220
    static let notificationsMinimumWidth: CGFloat = 260
    static let partnerMinimumWidth: CGFloat = 360
    static let minimumHeight: CGFloat = 120

    let partnerPane: PartnerPaneViewController
    let notificationsPane: PartnerPaneViewController
    private var spacingObservers: [UserSettingObserver<Int>] = []
    private let settings: SettingsStore

    /// Where Notifications sits relative to the Partner pane.
    private(set) var notificationsSide: Direction

    init(partner: PartnerPaneViewController, notifications: PartnerPaneViewController,
         settings: SettingsStore) {
        partnerPane = partner
        notificationsPane = notifications
        self.settings = settings
        notificationsSide = Self.direction(named: settings.get(UserSettings.partnerNotificationsSide)) ?? .right
        super.init(nibName: nil, bundle: nil)
        partner.arrangeHost = self
        notifications.arrangeHost = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func makeSplitView() -> ThemedSplitView { PaneSplitView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.dividerStyle = .thin
        // Same observers a project window's split installs: the gutter is computed, so AppKit must be told.
        spacingObservers = PaneSpacing.gutterSettings.values.map { setting in
            UserSettingObserver(setting) { [weak self] _ in
                (self?.splitView as? PaneSplitView)?.spacingDidChange()
            }
        }
        applySide()
    }

    private var didPlaceDivider = false

    override func viewDidLayout() {
        super.viewDidLayout()
        // Once per arrangement, when there is room to divide: Notifications starts at its initial size.
        guard !didPlaceDivider, splitViewItems.count == 2 else { return }
        let horizontal = notificationsSide.axis == .horizontal
        let total = horizontal ? view.bounds.width : view.bounds.height
        let wanted = horizontal ? Self.notificationsInitialWidth : Self.notificationsInitialHeight
        let least = horizontal ? Self.partnerMinimumWidth + Self.notificationsMinimumWidth : 2 * Self.minimumHeight
        guard total > least else { return }
        didPlaceDivider = true
        let notificationsFirst = notificationsSide == .left || notificationsSide == .above
        let position = notificationsFirst ? wanted : total - wanted - splitView.dividerThickness
        splitView.setPosition(position, ofDividerAt: 0)
    }

    // MARK: - Arranging

    func availableMoveDirections(for pane: PartnerPaneViewController) -> Set<Direction> {
        guard isFixedPane(pane) else { return [] }
        return Set(Direction.allCases.filter { side(after: pane, moves: $0) != notificationsSide })
    }

    func move(_ pane: PartnerPaneViewController, _ direction: Direction) -> Bool {
        guard isFixedPane(pane) else { return false }
        let side = side(after: pane, moves: direction)
        guard side != notificationsSide else { return false }
        notificationsSide = side
        settings.set(Self.name(of: side), for: UserSettings.partnerNotificationsSide)
        applySide()
        // The pane that moved stays the one selected, so the next arrow key moves it again.
        if let window = view.window {
            ComposableTabsActivePane.shared.activate(nodeID: pane.nodeID, in: window)
        }
        for each in [partnerPane, notificationsPane] { each.refreshArrangeAvailability() }
        return true
    }

    private func isFixedPane(_ pane: PartnerPaneViewController) -> Bool {
        pane === partnerPane || pane === notificationsPane
    }

    /// Where Notifications ends up when `pane` moves toward `direction`: Notifications moving goes there;
    /// the Partner pane moving puts Notifications on the opposite side.
    private func side(after pane: PartnerPaneViewController, moves direction: Direction) -> Direction {
        guard pane === partnerPane else { return direction }
        switch direction {
        case .left: return .right
        case .right: return .left
        case .above: return .below
        case .below: return .above
        }
    }

    /// Lays the two panes out for `notificationsSide`.
    private func applySide() {
        let horizontal = notificationsSide.axis == .horizontal
        splitView.isVertical = horizontal
        let notificationsFirst = notificationsSide == .left || notificationsSide == .above
        let order = notificationsFirst ? [notificationsPane, partnerPane] : [partnerPane, notificationsPane]
        if splitViewItems.map(\.viewController) != order {
            for item in splitViewItems { removeSplitViewItem(item) }
            for pane in order { addSplitViewItem(NSSplitViewItem(viewController: pane)) }
        }
        for item in splitViewItems {
            let isPartner = item.viewController === partnerPane
            item.minimumThickness = horizontal
                ? (isPartner ? Self.partnerMinimumWidth : Self.notificationsMinimumWidth)
                : Self.minimumHeight
            // The chat takes what the window gains; Notifications keeps its size.
            item.holdingPriority = isPartner ? .defaultLow : .defaultLow + 1
        }
        didPlaceDivider = false
        view.needsLayout = true
    }

    static func name(of side: Direction) -> String {
        switch side {
        case .left: return "left"
        case .right: return "right"
        case .above: return "above"
        case .below: return "below"
        }
    }

    static func direction(named name: String) -> Direction? {
        Direction.allCases.first { self.name(of: $0) == name }
    }
}
