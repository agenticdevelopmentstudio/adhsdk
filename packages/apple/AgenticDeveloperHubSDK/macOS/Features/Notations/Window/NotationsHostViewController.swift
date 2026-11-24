import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// The Notations window's content: an Active | Archived switcher over a split
/// of the list and the selected notation's details, as the AI Oversight
/// window switches Findings | Scripts.
@MainActor
final class NotationsHostViewController: NSViewController {

    private let segmented = NSSegmentedControl(
        labels: ["Active", "Archived"], trackingMode: .selectOne, target: nil, action: nil)
    private let split = ThemedSplitViewController()
    private let listVC: NotationsListViewController
    private let detailVC: NotationsDetailViewController
    private var themeObserver: ThemePaletteObserver?

    init(store: NotationsStore, goToProject: @escaping (Notation) -> Void) {
        listVC = NotationsListViewController(store: store)
        detailVC = NotationsDetailViewController(store: store)
        super.init(nibName: nil, bundle: nil)
        listVC.onGoToProject = goToProject
        listVC.onSelectionChange = { [weak detailVC] notation in
            detailVC?.show(notation)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 560))
        root.wantsLayer = true

        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.target = self
        segmented.action = #selector(segmentChanged)
        segmented.selectedSegment = 0
        segmented.setAccessibilityIdentifier("notations.state")

        let listItem = NSSplitViewItem(sidebarWithViewController: listVC)
        listItem.minimumThickness = 220
        listItem.maximumThickness = 420
        listItem.canCollapse = false
        let detailItem = NSSplitViewItem(viewController: detailVC)
        detailItem.minimumThickness = 360
        split.addSplitViewItem(listItem)
        split.addSplitViewItem(detailItem)
        addChild(split)
        let splitView = split.view
        splitView.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(segmented)
        root.addSubview(splitView)
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            segmented.centerXAnchor.constraint(equalTo: root.centerXAnchor),

            splitView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 6),
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        themeObserver = ThemePaletteObserver { [weak self] palette in
            self?.view.layer?.backgroundColor = palette.windowBackgroundColor.cgColor
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        listVC.focusFilter()
    }

    @objc private func segmentChanged() {
        listVC.state = segmented.selectedSegment == 0 ? .active : .archived
    }
}
