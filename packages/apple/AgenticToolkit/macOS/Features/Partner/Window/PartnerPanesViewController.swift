import AppKit
import AgenticToolkitCore

/// The partner's tab: the Partner chat pane and the Notifications pane side by side, split the way a Projects
/// window splits its panes.
///
/// The split view is the shared ``PaneSplitView``, so the gap between the two panes is the app-wide gutter
/// and follows Appearance > Spacing as it changes. Both panes are fixed: neither has a close button, and
/// ``PartnerSplitViewController`` refuses to close either.
@MainActor
final class PartnerPanesViewController: ThemedSplitViewController {

    /// The Notifications pane's width when the window first opens, and the narrowest it can be dragged.
    static let notificationsInitialWidth: CGFloat = 340
    static let notificationsMinimumWidth: CGFloat = 260
    static let partnerMinimumWidth: CGFloat = 360

    let partnerPane: PartnerPaneViewController
    let notificationsPane: PartnerPaneViewController
    private var spacingObservers: [UserSettingObserver<Int>] = []

    init(partner: PartnerPaneViewController, notifications: PartnerPaneViewController) {
        partnerPane = partner
        notificationsPane = notifications
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func makeSplitView() -> ThemedSplitView { PaneSplitView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        // Same observers a project window's split installs: the gutter is computed, so AppKit must be told.
        spacingObservers = PaneSpacing.gutterSettings.values.map { setting in
            UserSettingObserver(setting) { [weak self] _ in
                (self?.splitView as? PaneSplitView)?.spacingDidChange()
            }
        }
        let partnerItem = NSSplitViewItem(viewController: partnerPane)
        partnerItem.minimumThickness = Self.partnerMinimumWidth
        partnerItem.holdingPriority = .defaultLow
        let notificationsItem = NSSplitViewItem(viewController: notificationsPane)
        notificationsItem.minimumThickness = Self.notificationsMinimumWidth
        // The chat takes what the window gains; Notifications keeps its width.
        notificationsItem.holdingPriority = .defaultLow + 1
        addSplitViewItem(partnerItem)
        addSplitViewItem(notificationsItem)
    }

    private var didPlaceDivider = false

    override func viewDidLayout() {
        super.viewDidLayout()
        // Once, when there is a width to divide: Notifications starts at its initial width.
        guard !didPlaceDivider, view.bounds.width > Self.partnerMinimumWidth + Self.notificationsMinimumWidth
        else { return }
        didPlaceDivider = true
        splitView.setPosition(
            view.bounds.width - Self.notificationsInitialWidth - splitView.dividerThickness, ofDividerAt: 0)
    }
}
