import AppKit
import Combine
import AgenticDeveloperHubSDKIntegrations

/// The mail window's sidebar: each account as a group, its mailboxes beneath it.
@MainActor
final class MailSidebarViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    /// One outline row. A class because `NSOutlineView` tracks items by identity.
    private final class Node: NSObject {
        let account: MailAccount?
        let mailbox: MailBrowserModel.Mailbox?
        let children: [Node]

        init(account: MailAccount, children: [Node]) {
            self.account = account
            self.mailbox = nil
            self.children = children
        }

        init(mailbox: MailBrowserModel.Mailbox) {
            self.account = nil
            self.mailbox = mailbox
            self.children = []
        }
    }

    private let model: MailBrowserModel
    private let outlineView = NSOutlineView()
    private var roots: [Node] = []
    private var observers: Set<AnyCancellable> = []
    /// True while the outline's selection is being set from the model, so the change is not sent back.
    private var applyingSelection = false

    init(model: MailBrowserModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("mailbox"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.style = .sourceList
        outlineView.floatsGroupRows = false
        outlineView.rowSizeStyle = .default
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.setAccessibilityIdentifier("mail.sidebar")

        let scroll = NSScrollView()
        scroll.documentView = outlineView
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        view = scroll
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        model.$mailboxes.combineLatest(model.$accounts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rebuild() }
            .store(in: &observers)
        model.$selectedMailbox
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applySelection() }
            .store(in: &observers)
    }

    private func rebuild() {
        roots = model.accounts.map { account in
            Node(account: account, children: (model.mailboxes[account.id] ?? []).map(Node.init(mailbox:)))
        }
        outlineView.reloadData()
        roots.forEach { outlineView.expandItem($0) }
        applySelection()
    }

    private func applySelection() {
        guard let selected = model.selectedMailbox else { return }
        for root in roots {
            for child in root.children where child.mailbox?.accountId == selected.accountId
                && child.mailbox?.labelId == selected.labelId {
                let row = outlineView.row(forItem: child)
                guard row >= 0, outlineView.selectedRow != row else { return }
                applyingSelection = true
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                applyingSelection = false
                return
            }
        }
    }

    // MARK: - NSOutlineViewDataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        (item as? Node)?.children.count ?? roots.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        (item as? Node)?.children[index] ?? roots[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !((item as? Node)?.children.isEmpty ?? true)
    }

    // MARK: - NSOutlineViewDelegate

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        (item as? Node)?.account != nil
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        (item as? Node)?.mailbox != nil
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? Node else { return nil }
        if let account = node.account {
            let cell = NSTableCellView()
            let label = NSTextField(labelWithString: account.email)
            label.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            label.textColor = .secondaryLabelColor
            label.lineBreakMode = .byTruncatingTail
            cell.textField = label
            Self.pin(label, in: cell, leading: 0)
            return cell
        }
        guard let mailbox = node.mailbox else { return nil }
        return MailboxCell(mailbox: mailbox)
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !applyingSelection,
              let mailbox = (outlineView.item(atRow: outlineView.selectedRow) as? Node)?.mailbox else { return }
        let id = MailBrowserModel.MailboxID(accountId: mailbox.accountId, labelId: mailbox.labelId)
        Task { await model.select(mailbox: id) }
    }

    fileprivate static func pin(_ label: NSView, in cell: NSView, leading: CGFloat) {
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: leading),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.trailingAnchor, constant: -4),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
    }
}

/// A mailbox row: symbol, title (indented by nesting depth) and unread count.
@MainActor
private final class MailboxCell: NSTableCellView {
    init(mailbox: MailBrowserModel.Mailbox) {
        super.init(frame: .zero)
        let symbol = NSImageView(image: NSImage(
            systemSymbolName: Self.symbolName(mailbox.labelId), accessibilityDescription: nil) ?? NSImage())
        symbol.contentTintColor = .controlAccentColor
        let title = NSTextField(labelWithString: mailbox.title)
        title.lineBreakMode = .byTruncatingTail
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let stack = NSStackView(views: [symbol, title])
        stack.spacing = 6
        if let unread = mailbox.unread, unread > 0 {
            let count = NSTextField(labelWithString: "\(unread)")
            count.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            count.textColor = .secondaryLabelColor
            stack.addView(count, in: .trailing)
        }
        imageView = symbol
        textField = title
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: CGFloat(mailbox.depth) * 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        setAccessibilityLabel(mailbox.title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func symbolName(_ labelId: String?) -> String {
        switch labelId {
        case "INBOX": return "tray"
        case "STARRED": return "star"
        case "IMPORTANT": return "exclamationmark.circle"
        case "SENT": return "paperplane"
        case "DRAFT": return "doc"
        case nil: return "tray.full"
        case "SPAM": return "xmark.bin"
        case "TRASH": return "trash"
        default: return "tag"
        }
    }
}
