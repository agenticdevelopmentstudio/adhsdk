import UIKit
import AgenticDeveloperHubSDK

/// The iOS twin of `InlineChatView`: a full-screen chat surface bound to
/// `any ChatViewModel`, with `open(animated:)`/`close(animated:)` — a phone
/// has exactly one chat surface, presented and dismissed, where the desktop
/// keeps its box always on screen. A scrolling transcript of
/// `MobileMessageBubbleView`s (committed messages plus any live
/// `activeDrafts`, both rendered through the same bubble view), a
/// persistent `MobileThinkingIndicatorView` in a status row above the
/// composer, and a single-line composer that submits on Return.
///
/// `localParticipantID` — not anything on `viewModel` itself, since
/// `ChatViewModel` has no notion of "me" — decides which side each bubble
/// renders on; see `MessageBubbleView`'s doc for why (this view mirrors that
/// reasoning exactly).
///
/// `ToolCallPillView` gets no iOS twin here: command-activity pills are
/// deferred on mobile, per Task 8's amendment (a customer wanting them
/// files that as a follow-up rather than getting a half-parity port).
@MainActor
public final class MobileChatViewController: UIViewController, ChatStateObserver, Themeable, UITextFieldDelegate {

    public let viewModel: any ChatViewModel
    public let localParticipantID: String

    private let transcriptScroll = UIScrollView()
    private let transcriptStack = UIStackView()
    private let statusRow = UIView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let divider = UIView()

    /// The status line, held for the life of the controller rather than
    /// rebuilt with the transcript — the same rule `InlineChatView` follows,
    /// for the same reason: `ThinkingPhase.Machine` has to outlive a single
    /// message arriving, and an indicator built inside `rebuildTranscript()`
    /// and thrown away on the next `ChatUpdate` can never advance a phase or
    /// accumulate an elapsed time.
    ///
    /// Public because the vocabulary is the host's to author: a host calls
    /// `thinkingIndicator.configure(_:)` with its own `ChatStatusWordPair`s
    /// and glyph frames. Left unconfigured it draws the three pulsing dots,
    /// which is the documented fallback.
    public let thinkingIndicator = MobileThinkingIndicatorView()

    private var themeObserver: ThemePaletteObserver?
    private var isAtBottom = true
    private var lastTranscriptWidth: CGFloat = 0

    /// Whether the surface is currently presented. Internal rather than
    /// public: it exists so tests can assert on `open`/`close` without
    /// depending on a host's presentation context.
    private(set) var isOpen = false

    private static let maxBubbleWidthFraction: CGFloat = 0.75
    private static let minBubbleWidth: CGFloat = 200
    private static let bubbleSideInset: CGFloat = 16

    public init(viewModel: any ChatViewModel, localParticipantID: String) {
        self.viewModel = viewModel
        self.localParticipantID = localParticipantID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    deinit {
        // Mirrors `InlineChatView.deinit` exactly: no
        // `viewModel.removeObserver(self)` here, for the same soundness
        // reason (`deinit` is nonisolated, `ChatStateObserver` is
        // `@MainActor`) — `ObservableChatViewModel` holds observers weakly,
        // so this entry zeroes itself out on its own.
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        viewModel.addObserver(self)
        themeObserver = ThemePaletteObserver(host: view) { [weak self] palette in self?.applyTheme(palette) }
        rebuildTranscript()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = transcriptScroll.bounds.width
        if width > 0, abs(width - lastTranscriptWidth) > 1 {
            lastTranscriptWidth = width
            rebuildTranscript()
        }
    }

    private func setupViews() {
        transcriptStack.axis = .vertical
        transcriptStack.spacing = 12
        transcriptStack.alignment = .leading
        transcriptStack.isLayoutMarginsRelativeArrangement = true
        transcriptStack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        transcriptStack.translatesAutoresizingMaskIntoConstraints = false

        transcriptScroll.addSubview(transcriptStack)
        transcriptScroll.translatesAutoresizingMaskIntoConstraints = false
        transcriptScroll.delegate = self

        inputField.placeholder = "Type a message..."
        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        let inputRow = UIStackView(arrangedSubviews: [inputField, sendButton])
        inputRow.axis = .horizontal
        inputRow.spacing = 10
        inputRow.isLayoutMarginsRelativeArrangement = true
        inputRow.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        inputRow.translatesAutoresizingMaskIntoConstraints = false

        divider.translatesAutoresizingMaskIntoConstraints = false

        // Its own row between the transcript and the composer, outside the
        // scroll view — web's `.pc-typing`, a sibling of `.pc-transcript`
        // rather than a child of it. Inside the transcript the line scrolled
        // away with the history; here it is always just above where the user
        // types, which on a phone is the only part of the screen the keyboard
        // leaves in view.
        statusRow.translatesAutoresizingMaskIntoConstraints = false
        thinkingIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusRow.addSubview(thinkingIndicator)

        view.addSubview(transcriptScroll)
        view.addSubview(statusRow)
        view.addSubview(divider)
        view.addSubview(inputRow)

        NSLayoutConstraint.activate([
            transcriptScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            transcriptScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            transcriptScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            transcriptStack.topAnchor.constraint(equalTo: transcriptScroll.contentLayoutGuide.topAnchor),
            transcriptStack.leadingAnchor.constraint(equalTo: transcriptScroll.contentLayoutGuide.leadingAnchor),
            transcriptStack.trailingAnchor.constraint(equalTo: transcriptScroll.contentLayoutGuide.trailingAnchor),
            transcriptStack.bottomAnchor.constraint(equalTo: transcriptScroll.contentLayoutGuide.bottomAnchor),
            transcriptStack.widthAnchor.constraint(equalTo: transcriptScroll.frameLayoutGuide.widthAnchor),

            statusRow.topAnchor.constraint(equalTo: transcriptScroll.bottomAnchor),
            statusRow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusRow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thinkingIndicator.leadingAnchor.constraint(equalTo: statusRow.leadingAnchor, constant: 16),
            thinkingIndicator.trailingAnchor.constraint(lessThanOrEqualTo: statusRow.trailingAnchor, constant: -16),
            thinkingIndicator.topAnchor.constraint(equalTo: statusRow.topAnchor),
            thinkingIndicator.bottomAnchor.constraint(equalTo: statusRow.bottomAnchor),

            divider.topAnchor.constraint(equalTo: statusRow.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            inputRow.topAnchor.constraint(equalTo: divider.bottomAnchor),
            inputRow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputRow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputRow.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    /// The chat surface is drawn exactly once, on the controller's own
    /// view, and nothing inside the chat repaints it — web carries
    /// `--pc-surface` on `.persona-chat` alone, and a theme whose surface is
    /// translucent (`old-school-terminal` is `rgba(5, 8, 5, 0.8)`) makes
    /// every extra copy visible as a lighter band.
    public func applyTheme(_ palette: SemanticPalette) {
        view.backgroundColor = palette.uiColor(.chatSurface)
        statusRow.backgroundColor = .clear
        divider.backgroundColor = palette.uiColor(.border)
    }

    // MARK: Open / close

    /// Presents the surface. A host embeds this controller (e.g. inside a
    /// navigation stack or a custom presentation) and calls this once its
    /// view is on screen; tracked here as `isOpen` so a test — or a host —
    /// can tell whether the surface is currently the one showing.
    public func open(animated: Bool) {
        guard !isOpen else { return }
        isOpen = true
        guard animated, isViewLoaded else { return }
        view.alpha = 0
        UIView.animate(withDuration: 0.25) { self.view.alpha = 1 }
    }

    /// Dismisses the surface. Mirrors `open(animated:)`: this only flips the
    /// tracked state and (optionally) animates the view out — actually
    /// removing the controller from its host's hierarchy is the host's job,
    /// same as any other `UIViewController`.
    public func close(animated: Bool) {
        guard isOpen else { return }
        isOpen = false
        guard animated, isViewLoaded else { return }
        UIView.animate(withDuration: 0.25) { self.view.alpha = 0 }
    }

    // MARK: ChatStateObserver

    public func chatDidUpdate(_ update: ChatUpdate) {
        switch update {
        case .messagesChanged, .activeDraftsChanged, .commandActivityChanged:
            rebuildTranscript()
        case .typingChanged:
            rebuildTranscript()
            refreshStatus()
        case .statusChanged:
            // Deliberately *not* a transcript rebuild, exactly as on macOS: a
            // status is not a message, and rebuilding the whole stack several
            // times a turn to repaint one line is what made the old transient
            // indicator impossible to animate.
            refreshStatus()
        case .participantsChanged, .readMarkersChanged, .pendingPermissionsChanged,
             .pendingWidgetsChanged, .displayConfigChanged, .error:
            // Same Task 8 seams `InlineChatView` calls out: a participant
            // rail, unread badges, permission prompts, inline widgets, and
            // surfaced transport errors all attach here.
            break
        }
    }

    // MARK: Transcript

    private func rebuildTranscript() {
        transcriptStack.arrangedSubviews.forEach {
            transcriptStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let scrollWidth = transcriptScroll.bounds.width
        let maxBubbleWidth = max(scrollWidth * Self.maxBubbleWidthFraction, Self.minBubbleWidth)

        for message in viewModel.messages {
            addBubbleRow(for: message, isLocalUser: message.senderID == localParticipantID, maxBubbleWidth: maxBubbleWidth)
        }
        for draft in viewModel.activeDrafts where !draft.text.isEmpty {
            let adapter = MobileDraftMessageAdapter(draft: draft)
            addBubbleRow(for: adapter, isLocalUser: draft.participantID == localParticipantID, maxBubbleWidth: maxBubbleWidth)
        }

        // Pills are deferred on mobile (see the type doc comment), so
        // `commandActivity` renders nothing here; the thinking indicator it
        // usually drives lives in `statusRow`, not in this stack.

        if isAtBottom {
            DispatchQueue.main.async { [weak self] in self?.scrollToBottom() }
        }
    }

    /// Pushes the current remote status into the persistent status line —
    /// `InlineChatView.refreshStatus()`, verbatim in behaviour.
    ///
    /// The local participant is skipped: a status is what someone *else* is
    /// doing. With several remote participants the map has no ordering, so
    /// the ids are sorted — an arbitrary but stable pick beats a line that
    /// flickers as the dictionary rehashes. `typingParticipants` stays as a
    /// fallback rather than the driver it used to be: a backend that reports
    /// typing but emits no `statusChanged` still gets a spinning line, while
    /// one that emits real statuses gets its own authored words.
    private func refreshStatus() {
        let remote = viewModel.statuses
            .filter { $0.key != localParticipantID }
            .sorted { $0.key < $1.key }
        if let status = remote.first?.value {
            thinkingIndicator.update(status: status)
        } else if viewModel.typingParticipants.contains(where: { $0 != localParticipantID }) {
            thinkingIndicator.update(status: ChatStatus(kind: .think))
        } else {
            thinkingIndicator.update(status: nil)
        }
    }

    /// Lays a single bubble into the transcript, aligned right (with a
    /// leading spacer) for the local user and left otherwise — mirrors
    /// `InlineChatView.addBubbleRow(for:isLocalUser:maxBubbleWidth:)`
    /// exactly, just in UIKit.
    private func addBubbleRow(for message: any Message, isLocalUser: Bool, maxBubbleWidth: CGFloat) {
        let bubble = MobileMessageBubbleView(message: message, maxWidth: maxBubbleWidth, isLocalUser: isLocalUser)
        bubble.setContentHuggingPriority(.required, for: .horizontal)

        if isLocalUser {
            let spacer = UIView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            let row = UIStackView(arrangedSubviews: [spacer, bubble])
            row.axis = .horizontal
            row.alignment = .top
            row.spacing = 0
            row.translatesAutoresizingMaskIntoConstraints = false
            transcriptStack.addArrangedSubview(row)
            row.widthAnchor.constraint(
                equalTo: transcriptStack.widthAnchor, constant: -Self.bubbleSideInset * 2
            ).isActive = true
        } else {
            transcriptStack.addArrangedSubview(bubble)
        }
    }

    private func scrollToBottom() {
        let targetY = max(transcriptScroll.contentSize.height - transcriptScroll.bounds.height, 0)
        transcriptScroll.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
    }

    // MARK: Composer

    @objc private func sendTapped() {
        let text = inputField.text ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        inputField.text = ""
        let viewModel = viewModel
        Task { @MainActor in
            do {
                _ = try await viewModel.submitMessage(text: text, attachments: [])
            } catch {
                // Task 7/8 seam: surface send failures in the composer
                // (inline error text, retry affordance) rather than dropping
                // them silently — same as `InlineChatView`.
            }
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField === inputField else { return true }
        sendTapped()
        return true
    }
}

extension MobileChatViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleMaxY = scrollView.contentOffset.y + scrollView.bounds.height
        isAtBottom = scrollView.contentSize.height - visibleMaxY < 40
    }
}

/// Adapts an in-progress `ActiveDraft` to `Message` so
/// `MobileChatViewController` can render a streaming draft through the same
/// `MobileMessageBubbleView` it uses for committed messages, rather than a
/// second bubble implementation. Mirrors `InlineChatView`'s
/// `DraftMessageAdapter` exactly, duplicated rather than shared because it is
/// `private` there and each platform's chat surface owns its own transcript
/// glue.
private struct MobileDraftMessageAdapter: Message {
    let draft: any ActiveDraft

    var id: String? { nil }
    var localID: String { draft.participantID }
    var senderID: String { draft.participantID }
    var text: String { draft.text }
    var timestamp: Date? { nil }
    var attachments: [any Attachment] { draft.attachments }
    var deliveryStatus: MessageDeliveryStatus { .composing }
}
