import AppKit
import Combine
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKUI

/// The right side of the Notations window: the selected notation's details,
/// then its content in the Notes markdown editor. Edits are saved to that
/// notation, off the main thread, a moment after typing stops.
@MainActor
final class NotationsDetailViewController: NSViewController {

    private let store: NotationsStore
    private let editorController = MarkdownEditorController(palette: ThemeScope.app.palette)
    private let grid = NSGridView()
    private var values: [String: ThemedLabel] = [:]
    private var notation: Notation?
    private var pendingSave: DispatchWorkItem?
    private var pendingContent: String?
    private var savesInFlight = 0
    private var changesSubscription: AnyCancellable?
    private let saveQueue = DispatchQueue(label: "com.agenticdeveloperhubsdk.notations.window.save", qos: .utility)

    private static let fields: [(key: String, title: String)] = [
        ("project", "Project"), ("branch", "Branch"), ("path", "Path"), ("forkPoint", "Fork point"),
        ("created", "Created"), ("modified", "Modified"), ("archived", "Archived")
    ]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(store: NotationsStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    isolated deinit {
        pendingSave?.cancel()
        if let content = pendingContent, let id = notation?.id {
            let store = store
            saveQueue.async { _ = try? store.updateContent(id: id, content: content) }
        }
    }

    override func loadView() {
        let container = ThemedBackgroundView(role: .windowBackground)

        grid.rowSpacing = 4
        grid.columnSpacing = 10
        grid.translatesAutoresizingMaskIntoConstraints = false
        for field in Self.fields {
            let title = ThemedLabel(string: field.title, role: .secondaryText, textRole: .caption)
            let value = ThemedLabel(string: "", role: .primaryText, textRole: .caption)
            value.lineBreakMode = .byTruncatingMiddle
            value.cell?.usesSingleLineMode = true
            value.isSelectable = true
            value.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            value.accessibilityID("notations.detail.\(field.key)")
            values[field.key] = value
            grid.addRow(with: [title, value])
        }
        grid.column(at: 0).xPlacement = .trailing

        editorController.showsHelpButton = false
        editorController.showsImportButton = false
        addChild(editorController)
        let editorView = editorController.view
        editorView.translatesAutoresizingMaskIntoConstraints = false

        let separator = ThemedSeparatorView(role: .divider)
        separator.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(grid)
        container.addSubview(separator)
        container.addSubview(editorView)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            grid.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -14),

            separator.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 10),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            editorView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            editorView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            editorView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        editorController.onContentChange = { [weak self] content in
            self?.contentChanged(content)
        }
        editorController.view.observeTheme { [weak editorController] _, palette in
            editorController?.palette = palette
        }
        changesSubscription = store.changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.storeChanged() }
            }
        show(nil)
    }

    /// Shows `notation`, or nothing. Saves whatever the previous one had
    /// waiting first.
    func show(_ notation: Notation?) {
        if notation?.id != self.notation?.id { flushPendingSave() }
        self.notation = notation
        grid.isHidden = notation == nil
        editorController.view.isHidden = notation == nil
        guard let notation else {
            editorController.content = ""
            editorController.isEditable = false
            return
        }
        values["project"]?.stringValue = notation.projectName
        values["branch"]?.stringValue = notation.branch
        values["path"]?.stringValue = notation.projectPath
        values["forkPoint"]?.stringValue = notation.forkPoint
        values["created"]?.stringValue = Self.dateFormatter.string(from: notation.createdAt)
        values["modified"]?.stringValue = Self.dateFormatter.string(from: notation.modifiedAt)
        values["archived"]?.stringValue = notation.archivedAt.map { Self.dateFormatter.string(from: $0) } ?? "—"
        if pendingContent == nil, editorController.content != notation.content {
            editorController.content = notation.content
        }
        editorController.isEditable = true
    }

    private func contentChanged(_ content: String) {
        guard notation != nil else { return }
        pendingContent = content
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.flushPendingSave() }
        }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + NotationsPaneViewController.saveDebounce, execute: work)
    }

    private func flushPendingSave() {
        pendingSave?.cancel()
        pendingSave = nil
        guard let content = pendingContent, let id = notation?.id else { return }
        pendingContent = nil
        let store = store
        savesInFlight += 1
        saveQueue.async { [weak self] in
            do {
                try store.updateContent(id: id, content: content)
            } catch {
                NotationsDetailViewController.logger.error(
                    "Saving notation \(id.uuidString) failed: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.savesInFlight -= 1 }
            }
        }
    }

    /// Another writer changed the store: re-read the notation on show, unless
    /// an edit of this window's is on its way.
    private func storeChanged() {
        guard let id = notation?.id, pendingContent == nil, savesInFlight == 0 else { return }
        let store = store
        Task { [weak self] in
            let current = await Task.detached(priority: .utility) { try? store.notation(id: id) }.value
            guard let self, self.notation?.id == id, self.pendingContent == nil, self.savesInFlight == 0 else {
                return
            }
            if let current { self.show(current) }
        }
    }
}

extension NotationsDetailViewController: Loggable {
    nonisolated static let logger = makeLogger()
}
