import AppKit
import Combine
import AgenticDeveloperHubSDKIntegrations

/// The mail window's content: mailboxes, the selected mailbox's messages, and the open
/// message, side by side. Host apps put it in a window; it needs only a `MailClient`.
///
/// While on screen it looks for finished syncs every `refreshInterval` (a read of the
/// local store, never a Gmail call) and reloads when one has landed, so new mail appears
/// on its own.
@MainActor
public final class MailBrowserViewController: NSSplitViewController {
    public let model: MailBrowserModel
    private let refreshInterval: Duration
    private var refreshTask: Task<Void, Never>?
    private var observers: Set<AnyCancellable> = []

    public init(client: MailClient, refreshInterval: Duration = .seconds(30)) {
        self.model = MailBrowserModel(client: client)
        self.refreshInterval = refreshInterval
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        splitView.autosaveName = "MailBrowserSplit"

        let sidebar = NSSplitViewItem(sidebarWithViewController: MailSidebarViewController(model: model))
        sidebar.minimumThickness = 180
        sidebar.maximumThickness = 320
        let list = NSSplitViewItem(contentListWithViewController: MailMessageListViewController(model: model))
        list.minimumThickness = 280
        let reader = NSSplitViewItem(viewController: MailReaderViewController(model: model))
        reader.minimumThickness = 360
        [sidebar, list, reader].forEach(addSplitViewItem)

        model.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] message in self?.presentError(message) }
            .store(in: &observers)
        Task { await model.reload() }
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        refreshTask?.cancel()
        let interval = refreshInterval
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled, let self else { return }
                await self.model.refreshIfSynced()
            }
        }
    }

    public override func viewDidDisappear() {
        super.viewDidDisappear()
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Mail"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        guard let window = view.window else {
            alert.runModal()
            model.dismissError()
            return
        }
        alert.beginSheetModal(for: window) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.dismissError() }
        }
    }
}
