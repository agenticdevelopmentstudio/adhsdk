import AppKit
import Combine
import AgenticDeveloperHubSDKIntegrations

/// The mail window's message list: sender, date, subject and snippet per row, unread in bold.
/// Reaching the last row loads the next page.
@MainActor
final class MailMessageListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let model: MailBrowserModel
    private let tableView = NSTableView()
    private let emptyLabel = NSTextField(labelWithString: "No messages")
    private var observers: Set<AnyCancellable> = []
    private var applyingSelection = false

    init(model: MailBrowserModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("message")))
        tableView.headerView = nil
        tableView.style = .inset
        tableView.rowHeight = 68
        tableView.usesAutomaticRowHeights = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setAccessibilityIdentifier("mail.messages")

        let scroll = NSScrollView()
        scroll.documentView = tableView
        scroll.hasVerticalScroller = true

        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(scroll)
        container.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: container.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        model.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &observers)
        model.$selectedMessageId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applySelection() }
            .store(in: &observers)
        model.$loading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateEmptyLabel() }
            .store(in: &observers)
    }

    private func reload() {
        tableView.reloadData()
        applySelection()
        updateEmptyLabel()
    }

    private func updateEmptyLabel() {
        emptyLabel.stringValue = model.loading ? "Loading…" : "No messages"
        emptyLabel.isHidden = !model.messages.isEmpty
    }

    private func applySelection() {
        let row = model.messages.firstIndex { $0.id == model.selectedMessageId } ?? -1
        guard row != tableView.selectedRow else { return }
        applyingSelection = true
        if row >= 0 {
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        } else {
            tableView.deselectAll(nil)
        }
        applyingSelection = false
    }

    // MARK: - NSTableViewDataSource / Delegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        model.messages.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row == model.messages.count - 1, model.hasMore {
            Task { await model.loadMore() }
        }
        let identifier = NSUserInterfaceItemIdentifier("MessageRow")
        let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? MessageRowView
            ?? MessageRowView(identifier: identifier)
        cell.show(model.messages[row])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !applyingSelection else { return }
        let row = tableView.selectedRow
        let id = row >= 0 && row < model.messages.count ? model.messages[row].id : nil
        Task { await model.select(messageId: id) }
    }
}

/// One message row.
@MainActor
private final class MessageRowView: NSTableCellView {
    private let unreadDot = NSView()
    private let sender = NSTextField(labelWithString: "")
    private let date = NSTextField(labelWithString: "")
    private let subject = NSTextField(labelWithString: "")
    private let snippet = NSTextField(labelWithString: "")

    init(identifier: NSUserInterfaceItemIdentifier) {
        super.init(frame: .zero)
        self.identifier = identifier
        unreadDot.wantsLayer = true
        unreadDot.layer?.cornerRadius = 4
        unreadDot.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        [sender, subject, snippet].forEach {
            $0.lineBreakMode = .byTruncatingTail
            $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        date.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        date.textColor = .secondaryLabelColor
        date.setContentCompressionResistancePriority(.required, for: .horizontal)
        snippet.textColor = .secondaryLabelColor
        snippet.font = .systemFont(ofSize: NSFont.smallSystemFontSize)

        for view in [unreadDot, sender, date, subject, snippet] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            unreadDot.widthAnchor.constraint(equalToConstant: 8),
            unreadDot.heightAnchor.constraint(equalToConstant: 8),
            unreadDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            unreadDot.centerYAnchor.constraint(equalTo: sender.centerYAnchor),

            sender.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            sender.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            sender.trailingAnchor.constraint(lessThanOrEqualTo: date.leadingAnchor, constant: -8),
            date.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            date.firstBaselineAnchor.constraint(equalTo: sender.firstBaselineAnchor),

            subject.leadingAnchor.constraint(equalTo: sender.leadingAnchor),
            subject.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            subject.topAnchor.constraint(equalTo: sender.bottomAnchor, constant: 2),

            snippet.leadingAnchor.constraint(equalTo: sender.leadingAnchor),
            snippet.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            snippet.topAnchor.constraint(equalTo: subject.bottomAnchor, constant: 2)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ message: MailMessage) {
        let unread = MailBrowserModel.isUnread(message)
        unreadDot.isHidden = !unread
        sender.stringValue = MailBrowserModel.senderName(message.from)
        sender.font = .systemFont(ofSize: NSFont.systemFontSize, weight: unread ? .bold : .regular)
        date.stringValue = MailBrowserModel.listDate(message.date)
        subject.stringValue = message.subject.isEmpty ? "(no subject)" : message.subject
        subject.font = .systemFont(ofSize: NSFont.systemFontSize, weight: unread ? .semibold : .regular)
        snippet.stringValue = message.snippet
        setAccessibilityLabel("\(sender.stringValue), \(subject.stringValue)")
    }
}
