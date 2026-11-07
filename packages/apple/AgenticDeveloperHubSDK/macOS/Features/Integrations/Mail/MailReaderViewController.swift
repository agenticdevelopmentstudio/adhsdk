import AppKit
import Combine
import WebKit
import AgenticDeveloperHubSDKIntegrations

/// The mail window's reader: the open message's headers above its body.
///
/// The body is shown in a web view with JavaScript off and every remote load blocked, so
/// opening a message never tells its sender it was read (tracking pixels) or runs its
/// scripts. "Load Remote Images" lifts the block for the message on screen only. Links open
/// in the default browser, never inside the reader.
@MainActor
final class MailReaderViewController: NSViewController, WKNavigationDelegate {
    private let model: MailBrowserModel
    private let subject = NSTextField(wrappingLabelWithString: "")
    private let from = NSTextField(labelWithString: "")
    private let recipients = NSTextField(labelWithString: "")
    private let date = NSTextField(labelWithString: "")
    private let remoteBar = NSStackView()
    private let header = NSStackView()
    private let placeholder = NSTextField(labelWithString: "No message selected")
    private var webView: WKWebView!
    private var observers: Set<AnyCancellable> = []
    /// Compiled once per process; `nil` until compiled, or if compiling failed.
    private static var blockRemote: WKContentRuleList?
    /// The message on screen has its remote content allowed.
    private var remoteAllowed = false
    private var shownMessageId: String?

    init(model: MailBrowserModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.setAccessibilityIdentifier("mail.reader.body")

        subject.font = .systemFont(ofSize: 18, weight: .semibold)
        subject.isSelectable = true
        for field in [from, recipients, date] {
            field.lineBreakMode = .byTruncatingTail
            field.isSelectable = true
            field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        recipients.textColor = .secondaryLabelColor
        date.textColor = .secondaryLabelColor
        date.font = .systemFont(ofSize: NSFont.smallSystemFontSize)

        let remoteNote = NSTextField(labelWithString: "Remote images are blocked to protect your privacy.")
        remoteNote.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        remoteNote.textColor = .secondaryLabelColor
        let loadButton = NSButton(title: "Load Remote Images", target: self, action: #selector(loadRemote))
        loadButton.controlSize = .small
        remoteBar.setViews([remoteNote, loadButton], in: .leading)
        remoteBar.spacing = 8

        header.orientation = .vertical
        header.alignment = .leading
        header.spacing = 4
        header.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 10, right: 16)
        header.setViews([subject, from, recipients, date, remoteBar], in: .top)
        header.setCustomSpacing(8, after: subject)
        header.setCustomSpacing(8, after: date)

        let separator = NSBox()
        separator.boxType = .separator
        placeholder.textColor = .secondaryLabelColor

        let container = NSView()
        for view in [header, separator, webView!, placeholder] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(view)
        }
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: container.topAnchor),
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            subject.widthAnchor.constraint(lessThanOrEqualTo: header.widthAnchor, constant: -32),
            separator.topAnchor.constraint(equalTo: header.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            placeholder.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            placeholder.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        model.$openedMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self else { return }
                Task { await self.show(message) }
            }
            .store(in: &observers)
    }

    private func show(_ message: MailMessage?) async {
        let isNew = message?.id != shownMessageId
        shownMessageId = message?.id
        header.isHidden = message == nil
        webView.isHidden = message == nil
        placeholder.isHidden = message != nil
        guard let message else {
            webView.loadHTMLString("", baseURL: nil)
            return
        }
        subject.stringValue = message.subject.isEmpty ? "(no subject)" : message.subject
        from.stringValue = message.from
        let copied = message.cc.isEmpty ? "" : "   Cc: " + message.cc.joined(separator: ", ")
        recipients.stringValue = "To: " + message.to.joined(separator: ", ") + copied
        date.stringValue = MailBrowserModel.fullDate(message.date)
        // A label change (marking read) republishes the message; only a different one reloads the body.
        guard isNew else { return }
        remoteAllowed = false
        remoteBar.isHidden = message.bodyHtml == nil
        await loadBody(message)
    }

    private func loadBody(_ message: MailMessage) async {
        let controller = webView.configuration.userContentController
        controller.removeAllContentRuleLists()
        if !remoteAllowed, let rules = await Self.remoteBlockingRules() {
            controller.add(rules)
        }
        // The message may have changed while the rules compiled.
        guard message.id == shownMessageId else { return }
        webView.loadHTMLString(Self.document(for: message), baseURL: nil)
    }

    @objc private func loadRemote() {
        guard let message = model.openedMessage else { return }
        remoteAllowed = true
        remoteBar.isHidden = true
        Task { await loadBody(message) }
    }

    /// The HTML body as sent, or the text body escaped into a page that follows light and dark mode.
    static func document(for message: MailMessage) -> String {
        if let html = message.bodyHtml, !html.isEmpty { return html }
        let text = message.bodyText ?? message.snippet
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return """
            <!doctype html><html><head><meta charset="utf-8"><style>
            :root { color-scheme: light dark; }
            body { font: 13px -apple-system, sans-serif; margin: 16px; }
            pre { white-space: pre-wrap; word-wrap: break-word; font: inherit; margin: 0; }
            </style></head><body><pre>\(escaped)</pre></body></html>
            """
    }

    private static func remoteBlockingRules() async -> WKContentRuleList? {
        if let blockRemote { return blockRemote }
        let rules = #"[{"trigger":{"url-filter":"^(https?|ftp|wss?)://"},"action":{"type":"block"}}]"#
        let compiled = try? await WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "mail-reader-block-remote", encodedContentRuleList: rules)
        blockRemote = compiled
        return compiled
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard navigationAction.navigationType == .linkActivated || navigationAction.targetFrame == nil,
              let url = navigationAction.request.url else { return .allow }
        NSWorkspace.shared.open(url)
        return .cancel
    }
}
