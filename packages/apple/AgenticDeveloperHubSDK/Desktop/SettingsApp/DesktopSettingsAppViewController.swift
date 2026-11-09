import AppKit
import Combine

/// The Settings App's window content: a System Settings-style sidebar of panes, and the
/// selected pane beside it under its title.
@MainActor
final class DesktopSettingsAppViewController: NSViewController {
    /// The panes, in sidebar order.
    enum Pane: Int, CaseIterable {
        case appearance, menuBar

        var title: String {
            switch self {
            case .appearance: return "Appearance"
            case .menuBar: return "Menu Bar"
            }
        }

        var symbol: (name: String, tint: String) {
            switch self {
            case .appearance: return ("circle.lefthalf.filled", "#0A84FF")
            case .menuBar: return ("menubar.rectangle", "#5E5CE6")
            }
        }
    }

    private static let sidebarWidth: CGFloat = 190
    private static let rowIconSize: CGFloat = 20

    private let settings: DesktopSettings
    private var subscription: AnyCancellable?
    let appearance: DesktopAppearanceControls
    let menuStyle: DesktopMenuStyleControl
    let sidebar = NSTableView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let paneContainer = NSView()
    private(set) var selectedPane: Pane = .appearance

    init(settings: DesktopSettings) {
        self.settings = settings
        appearance = DesktopAppearanceControls(settings: settings, thumbnailSize: CGSize(width: 160, height: 100))
        menuStyle = DesktopMenuStyleControl(settings: settings)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        appearance.sheetWindow = { [weak self] in self?.view.window }
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 680, height: 460))
        let sidebarView = makeSidebar()
        let divider = NSBox()
        divider.boxType = .separator
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        for subview in [sidebarView, divider, titleLabel, paneContainer] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            sidebarView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            sidebarView.topAnchor.constraint(equalTo: root.topAnchor),
            sidebarView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            sidebarView.widthAnchor.constraint(equalToConstant: Self.sidebarWidth),
            divider.leadingAnchor.constraint(equalTo: sidebarView.trailingAnchor),
            divider.topAnchor.constraint(equalTo: root.topAnchor),
            divider.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            divider.widthAnchor.constraint(equalToConstant: 1),
            titleLabel.leadingAnchor.constraint(equalTo: divider.trailingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
            paneContainer.leadingAnchor.constraint(equalTo: divider.trailingAnchor, constant: 20),
            paneContainer.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            paneContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            paneContainer.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -20)
        ])
        view = root
        refresh()
        select(selectedPane)
        // Read-only: refreshing controls never writes.
        subscription = settings.changes.sink { [weak self] in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    /// Shows `pane` and selects its sidebar row.
    func select(_ pane: Pane) {
        selectedPane = pane
        if sidebar.selectedRow != pane.rawValue {
            sidebar.selectRowIndexes(IndexSet(integer: pane.rawValue), byExtendingSelection: false)
        }
        titleLabel.stringValue = pane.title
        paneContainer.subviews.forEach { $0.removeFromSuperview() }
        let content = makePane(pane)
        content.translatesAutoresizingMaskIntoConstraints = false
        paneContainer.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: paneContainer.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: paneContainer.trailingAnchor),
            content.topAnchor.constraint(equalTo: paneContainer.topAnchor),
            content.bottomAnchor.constraint(equalTo: paneContainer.bottomAnchor)
        ])
    }

    private func refresh() {
        appearance.refresh()
        menuStyle.refresh()
    }

    // MARK: Sidebar

    private func makeSidebar() -> NSView {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("pane"))
        sidebar.addTableColumn(column)
        sidebar.headerView = nil
        sidebar.style = .sourceList
        sidebar.rowHeight = 28
        sidebar.backgroundColor = .clear
        // A pane is always selected: a click on empty space never clears the selection.
        sidebar.allowsEmptySelection = false
        sidebar.dataSource = self
        sidebar.delegate = self
        sidebar.setAccessibilityLabel("Settings panes")
        sidebar.reloadData()
        let scroll = NSScrollView()
        scroll.documentView = sidebar
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        let material = NSVisualEffectView()
        material.material = .sidebar
        material.blendingMode = .withinWindow
        scroll.translatesAutoresizingMaskIntoConstraints = false
        material.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: material.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: material.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: material.topAnchor, constant: 8),
            scroll.bottomAnchor.constraint(equalTo: material.bottomAnchor)
        ])
        return material
    }

    // MARK: Panes

    private func makePane(_ pane: Pane) -> NSView {
        switch pane {
        case .appearance:
            return Self.paneStack([
                Self.group([
                    ("Desktop color", appearance.colorWell),
                    ("Desktop picture", appearance.photoColumn)
                ])
            ])
        case .menuBar:
            let note = NSTextField(wrappingLabelWithString:
                "macOS shows the front window's menus in one menu bar across the top of the Desktop. "
                + "Windows shows a menu bar in each window, under its title.")
            note.font = .systemFont(ofSize: 11)
            note.textColor = .secondaryLabelColor
            return Self.paneStack([Self.group([("Menu style", menuStyle.popUp)]), note])
        }
    }

    private static func paneStack(_ views: [NSView]) -> NSView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        for view in views {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        return stack
    }

    /// A rounded group of rows, each a label on the left and its control on the right,
    /// with separators between, the way System Settings lays a pane out.
    private static func group(_ rows: [(String, NSView)]) -> NSView {
        let box = NSBox()
        box.boxType = .custom
        box.cornerRadius = 8
        box.borderColor = .separatorColor
        box.fillColor = .quaternaryLabelColor.withAlphaComponent(0.06)
        box.contentViewMargins = .zero
        box.titlePosition = .noTitle
        var views: [NSView] = []
        for (index, row) in rows.enumerated() {
            if index > 0 {
                let separator = NSBox()
                separator.boxType = .separator
                views.append(separator)
            }
            let label = NSTextField(labelWithString: row.0)
            label.font = .systemFont(ofSize: 13)
            // The label takes the row's slack so the control sits at the trailing edge, as in
            // System Settings. A stack-view control (the picture column) has its own hugging,
            // which defaults to the label's 250 and would otherwise split the slack.
            label.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
            row.1.setContentHuggingPriority(.required, for: .horizontal)
            (row.1 as? NSStackView)?.setHuggingPriority(.required, for: .horizontal)
            let line = NSStackView(views: [label, row.1])
            line.alignment = .centerY
            line.distribution = .fill
            line.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            views.append(line)
        }
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 0
        for view in views {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])
        box.contentView = content
        return box
    }
}

extension DesktopSettingsAppViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int { Pane.allCases.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let pane = Pane(rawValue: row) else { return nil }
        let cell = NSTableCellView()
        let icon = NSImageView(image: DesktopAppIconRenderer.symbolImage(
            name: pane.symbol.name, tint: pane.symbol.tint, pointSize: Self.rowIconSize
        ))
        let label = NSTextField(labelWithString: pane.title)
        label.font = .systemFont(ofSize: 13)
        cell.textField = label
        cell.imageView = icon
        let stack = NSStackView(views: [icon, label])
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(stack)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: Self.rowIconSize),
            icon.heightAnchor.constraint(equalToConstant: Self.rowIconSize),
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let pane = Pane(rawValue: sidebar.selectedRow), pane != selectedPane else { return }
        select(pane)
    }

}
