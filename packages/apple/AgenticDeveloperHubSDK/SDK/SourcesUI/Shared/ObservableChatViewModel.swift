import Foundation
import AgenticDeveloperHubSDK

/// A `ChatViewModel` driven by a `Backend`'s inbound event stream.
///
/// Consumes `backend.inboundEvents` on a `Task` started at `init`, applying
/// each `InboundEvent` on the main actor and notifying registered
/// `ChatStateObserver`s via `ChatUpdate`. Foundation-only — no AppKit/UIKit —
/// so it compiles for both the macOS and iOS `SourcesUI` targets; a UIKit
/// view can bind to it exactly as an AppKit one does.
///
/// Two invariants this type exists to hold, each covered by a test in
/// `ObservableChatViewModelTests` that fails without the fix described:
///
/// - `InboundEvent.draftUpdated`'s `text` is the whole draft so far.
///   `handle(_:)` **assigns** the draft's text (`upsertDraft` rebuilds the
///   draft from the event's `text` verbatim); it never appends fragments.
/// - Status (`statusChanged`) is out-of-band: it updates `statuses` and
///   notifies `.statusChanged(participantID:)`, but never produces a
///   `Message` and never commits a draft (`ci-status-out-of-band`). The
///   notification is what lets a view draw the line at all — see
///   `ChatUpdate.statusChanged`'s doc for why "out-of-band" was never meant
///   to mean "unobservable".
@MainActor
public final class ObservableChatViewModel: ChatViewModel {

    // MARK: ChatViewModel

    public var conversation: any Conversation { storedConversation }
    public private(set) var participants: [any Participant] = []
    public private(set) var messages: [any Message] = []
    public var displayConfig: any DisplayConfig { storedDisplayConfig }
    public private(set) var pendingPermissions: [any PermissionPrompt] = []
    public private(set) var pendingWidgets: [any InteractiveWidget] = []
    public private(set) var typingParticipants: [String] = []
    public private(set) var readMarkers: [any ReadReceipt] = []
    public private(set) var activeDrafts: [any ActiveDraft] = []
    public private(set) var commandActivity: [CommandActivity] = []

    // MARK: Extra state (outside the `ChatViewModel` contract)

    /// The most recent status per participant, keyed by participant id.
    /// Out-of-band in the sense that matters — no `Message`, no draft — but
    /// observed like everything else: `.statusChanged(participantID:)` fires
    /// and the observer re-reads this map.
    public private(set) var statuses: [String: ChatStatus] = [:]

    /// The local participant this view model submits messages as, used to
    /// tag optimistic local echoes in `submitMessage` and to resolve
    /// `markRead`'s implicit "my" cursor.
    public let localParticipantID: String

    // MARK: Dependencies

    private let backend: any Backend
    private var storedConversation: LocalConversation
    private var storedDisplayConfig: LocalDisplayConfig
    private var eventTask: Task<Void, Never>?
    private let observers = NSHashTable<AnyObject>.weakObjects()

    public init(
        backend: any Backend,
        localParticipantID: String,
        conversationID: String = UUID().uuidString,
        displayConfig: (any DisplayConfig)? = nil
    ) {
        self.backend = backend
        self.localParticipantID = localParticipantID
        self.storedConversation = LocalConversation(
            id: conversationID, createdAt: Date(), title: nil, participants: [])
        self.storedDisplayConfig = displayConfig.map(LocalDisplayConfig.init(from:)) ?? LocalDisplayConfig()
        // Captures `backend` (the parameter), not `self.backend` — and is the
        // last statement in `init`, after every other stored property is set
        // — so this is safe to form even though it captures `self` weakly.
        //
        // `Task.init`'s operation closure inherits the actor isolation of
        // where it's written (`@_inheritActorContext`), and this `init` runs
        // on `@MainActor` (the class is `@MainActor`), so the whole closure
        // body — including after each `for await` resumes — already runs on
        // the main actor. `handle(_:)` is a `@MainActor` method too, so
        // calling it here never hops actors: `await self.handle(event)` is
        // provably a same-actor call, which is exactly what the compiler
        // warns about ("no 'async' operations occur within 'await'
        // expression"). Dropping the `await` removes the warning without
        // changing behavior; only the `for await` on the async sequence
        // itself is genuinely asynchronous.
        self.eventTask = Task { [weak self] in
            guard let self else { return }
            for await event in backend.inboundEvents {
                self.handle(event)
            }
        }
    }

    deinit {
        eventTask?.cancel()
    }

    // MARK: Observer registry

    public func addObserver(_ observer: any ChatStateObserver) {
        observers.add(observer as AnyObject)
    }

    public func removeObserver(_ observer: any ChatStateObserver) {
        observers.remove(observer as AnyObject)
    }

    private func notify(_ update: ChatUpdate) {
        for case let observer as any ChatStateObserver in observers.allObjects {
            observer.chatDidUpdate(update)
        }
    }

    // MARK: ChatViewModel methods

    public func submitMessage(text: String, attachments: [any Attachment]) async throws -> String {
        let localID = try await backend.send(text: text, attachments: attachments)
        // Optimistic local echo: shows immediately as `.sending`, then a
        // later `messageAccepted`/`messageDelivered`/`messageFailed` event
        // resolves it in place via `updateMessage(localID:)`.
        let message = LocalMessage(
            localID: localID,
            senderID: localParticipantID,
            text: text,
            attachments: attachments,
            deliveryStatus: .sending)
        messages.append(message)
        notify(.messagesChanged)
        return localID
    }

    /// Advances the local participant's own read cursor. `Backend` has no
    /// method to push a read marker to the wire — only `InboundEvent
    /// .readMarkerAdvanced` reports one arriving — so this is local-only
    /// bookkeeping today; a host wanting server-synced read receipts needs
    /// its own bridge until `Backend` grows one.
    public func markRead(messageID: String) async throws {
        upsertReadMarker(participantID: localParticipantID, upToMessageID: messageID, at: Date())
        notify(.readMarkersChanged)
    }

    public func setLocalTyping(_ isTyping: Bool) async throws {
        try await backend.setLocalTyping(isTyping)
    }

    public func respondToWidget(_ response: any WidgetResponse) async throws {
        try await backend.submitWidgetResponse(response)
    }

    /// `InboundEvent` carries no permission-request case, so nothing ever
    /// populates `pendingPermissions` from the wire today — a contract gap,
    /// not an oversight (see the type doc's gap list in the Task 6b report).
    /// Kept host-callable, and still removes a matching local entry, so a
    /// future event or an app-level bridge can populate `pendingPermissions`
    /// without a signature change here.
    public func respondToPermission(promptID: String, decision: PermissionDecision) async throws {
        pendingPermissions.removeAll { $0.id == promptID }
        notify(.pendingPermissionsChanged)
    }

    /// `Backend` exposes no way to list available commands, so this is
    /// always empty today — the same class of contract gap as
    /// `pendingPermissions` above.
    public func listCommands() -> [any Command] { [] }

    // MARK: Event handling

    /// Applies one inbound event to held state and notifies observers.
    /// Internal (not `private`) so `ObservableChatViewModelTests` can drive
    /// it directly and assert each `InboundEvent` case's effect
    /// deterministically, without racing the `inboundEvents` consumer `Task`
    /// started in `init`; a couple of tests still go through the real
    /// `Backend.inboundEvents` stream end-to-end to prove that `Task` is
    /// actually wired up.
    func handle(_ event: InboundEvent) {
        switch event {
        case .messageAccepted(let localID, let serverID, let at):
            updateMessage(localID: localID) { message in
                message.id = serverID
                message.timestamp = at
                message.deliveryStatus = .sent
            }
            notify(.messagesChanged)

        case .messageDelivered(let messageID, let at):
            updateMessage(id: messageID) { message in
                message.timestamp = message.timestamp ?? at
                message.deliveryStatus = .delivered
            }
            notify(.messagesChanged)

        case .messageFailed(let localID, let reason):
            updateMessage(localID: localID) { message in
                message.deliveryStatus = .failed(reason: reason)
            }
            notify(.messagesChanged)

        case .messageReceived(let message):
            upsertMessage(LocalMessage(message))
            notify(.messagesChanged)

        case .readMarkerAdvanced(let participantID, let upToMessageID, let at):
            upsertReadMarker(participantID: participantID, upToMessageID: upToMessageID, at: at)
            notify(.readMarkersChanged)

        case .draftUpdated(let participantID, let text, let attachments):
            // `text` is the whole draft so far. Appending here would
            // duplicate every token; the contract is replace. `upsertDraft`
            // rebuilds the draft from `text` verbatim rather than mutating
            // the previous one in place — see `ObservableChatViewModelTests
            // .draftUpdatedReplacesRatherThanAppends`, which fails against an
            // appending implementation.
            upsertDraft(participantID: participantID, text: text, attachments: attachments)
            notify(.activeDraftsChanged)

        case .draftCleared(let participantID):
            activeDrafts.removeAll { $0.participantID == participantID }
            notify(.activeDraftsChanged)

        case .participantJoined(let participant):
            upsertParticipant(participant)
            notify(.participantsChanged)

        case .participantDeparted(let participantID):
            participants.removeAll { $0.id == participantID }
            storedConversation.participants = participants
            notify(.participantsChanged)

        case .typing(let participantID, let isTyping):
            if isTyping {
                if !typingParticipants.contains(participantID) {
                    typingParticipants.append(participantID)
                }
            } else {
                typingParticipants.removeAll { $0 == participantID }
            }
            notify(.typingChanged)

        case .statusChanged(let participantID, let status):
            // Out-of-band: no `Message` is produced and no draft is touched —
            // `ObservableChatViewModelTests.statusChangedIsOutOfBand` fails if
            // this ever reaches `messages` or `activeDrafts`. It does notify,
            // because a status nobody can observe is a status that does not
            // render; that was the actual defect, not the invariant.
            if let status {
                statuses[participantID] = status
            } else {
                statuses.removeValue(forKey: participantID)
            }
            notify(.statusChanged(participantID: participantID))

        case .widgetPresented(let messageID, let widget):
            // Task 7/8 seam: `messageID` isn't retained anywhere yet, so a
            // consumer can't associate this widget with the message it was
            // presented under. Threading that through needs either a stored
            // `[messageID: [widget]]` map or a `ChatUpdate` payload change.
            _ = messageID
            pendingWidgets.append(widget)
            notify(.pendingWidgetsChanged)

        case .commandInvoked(_, let invocation):
            commandActivity.append(CommandActivity(invocation: invocation))
            notify(.commandActivityChanged)

        case .commandCompleted(_, let result):
            // Matched on `invocation.id`, never on `commandName`: two
            // parallel invocations of the same command would otherwise
            // resolve each other. A result whose invocation was never seen is
            // dropped rather than synthesised into an activity with no
            // invocation to name — see `orphanResultIsDropped`. The
            // notification still fires either way, matching
            // `respondToPermission`'s "notifies even with nothing pending":
            // a rebuild from an unchanged array is idempotent, and a
            // conditional notification would make the handler lie about
            // whether it saw the event.
            if let index = commandActivity.firstIndex(where: { $0.invocation.id == result.invocationID }) {
                commandActivity[index] = CommandActivity(
                    invocation: commandActivity[index].invocation, result: result)
            }
            notify(.commandActivityChanged)

        case .transportError(let message):
            notify(.error(message: message))
        }
    }

    // MARK: Mutation helpers

    private func updateMessage(localID: String, mutate: (inout LocalMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.localID == localID }) else { return }
        guard var local = messages[index] as? LocalMessage else { return }
        mutate(&local)
        messages[index] = local
    }

    private func updateMessage(id: String, mutate: (inout LocalMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        guard var local = messages[index] as? LocalMessage else { return }
        mutate(&local)
        messages[index] = local
    }

    private func upsertMessage(_ message: LocalMessage) {
        if let index = messages.firstIndex(where: { $0.localID == message.localID }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
    }

    private func upsertDraft(participantID: String, text: String, attachments: [any Attachment]) {
        let draft = LocalActiveDraft(participantID: participantID, text: text, attachments: attachments)
        if let index = activeDrafts.firstIndex(where: { $0.participantID == participantID }) {
            activeDrafts[index] = draft
        } else {
            activeDrafts.append(draft)
        }
    }

    private func upsertReadMarker(participantID: String, upToMessageID: String, at: Date) {
        let marker = LocalReadReceipt(participantID: participantID, upToMessageID: upToMessageID, at: at)
        if let index = readMarkers.firstIndex(where: { $0.participantID == participantID }) {
            readMarkers[index] = marker
        } else {
            readMarkers.append(marker)
        }
    }

    private func upsertParticipant(_ participant: any Participant) {
        if let index = participants.firstIndex(where: { $0.id == participant.id }) {
            participants[index] = participant
        } else {
            participants.append(participant)
        }
        storedConversation.participants = participants
    }
}

// MARK: - Local storage types

/// A mutable, concrete `Message` every entry in `ObservableChatViewModel
/// .messages` is guaranteed to be — including ones that arrived as `any
/// Message` via `InboundEvent.messageReceived` — so in-place delivery-status
/// transitions (`updateMessage(localID:)`/`updateMessage(id:)`) have a
/// concrete type to cast to and mutate.
private struct LocalMessage: Message {
    var id: String?
    var localID: String
    var senderID: String
    var text: String
    var timestamp: Date?
    var attachments: [any Attachment]
    var deliveryStatus: MessageDeliveryStatus

    init(_ message: any Message) {
        id = message.id
        localID = message.localID
        senderID = message.senderID
        text = message.text
        timestamp = message.timestamp
        attachments = message.attachments
        deliveryStatus = message.deliveryStatus
    }

    init(localID: String, senderID: String, text: String, attachments: [any Attachment], deliveryStatus: MessageDeliveryStatus) {
        self.id = nil
        self.localID = localID
        self.senderID = senderID
        self.text = text
        self.timestamp = nil
        self.attachments = attachments
        self.deliveryStatus = deliveryStatus
    }
}

private struct LocalActiveDraft: ActiveDraft {
    var participantID: String
    var text: String
    var attachments: [any Attachment]
}

private struct LocalReadReceipt: ReadReceipt {
    var participantID: String
    var upToMessageID: String
    var at: Date
}

private struct LocalConversation: Conversation {
    var id: String
    var createdAt: Date
    var title: String?
    var participants: [any Participant]
}

private struct LocalDisplayConfig: DisplayConfig {
    var showAvatars: Bool
    var showReadReceipts: Bool
    var showTypingIndicators: Bool
    var maxParticipants: Int?
    var allowJoining: Bool
    var allowDeparting: Bool
    var themeIdentifier: String?
    var reducedMotion: Bool

    init(
        showAvatars: Bool = true,
        showReadReceipts: Bool = true,
        showTypingIndicators: Bool = true,
        maxParticipants: Int? = nil,
        allowJoining: Bool = false,
        allowDeparting: Bool = false,
        themeIdentifier: String? = nil,
        reducedMotion: Bool = false
    ) {
        self.showAvatars = showAvatars
        self.showReadReceipts = showReadReceipts
        self.showTypingIndicators = showTypingIndicators
        self.maxParticipants = maxParticipants
        self.allowJoining = allowJoining
        self.allowDeparting = allowDeparting
        self.themeIdentifier = themeIdentifier
        self.reducedMotion = reducedMotion
    }

    init(from other: any DisplayConfig) {
        self.init(
            showAvatars: other.showAvatars,
            showReadReceipts: other.showReadReceipts,
            showTypingIndicators: other.showTypingIndicators,
            maxParticipants: other.maxParticipants,
            allowJoining: other.allowJoining,
            allowDeparting: other.allowDeparting,
            themeIdentifier: other.themeIdentifier,
            reducedMotion: other.reducedMotion
        )
    }
}
