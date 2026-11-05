import Foundation

/// `@MainActor` because this is a view model: every property here is read
/// during a view's layout pass and every method is called from a control's
/// action handler. Leaving it nonisolated would promise callers they may read
/// `messages` from any thread while every conformer mutates it on the main
/// one — a promise `ObservableChatViewModel` could only keep by declaring
/// `@unchecked Sendable`, which silences the compiler rather than the race.
@MainActor
public protocol ChatViewModel: AnyObject, Sendable {
    var conversation: any Conversation { get }
    var participants: [any Participant] { get }
    var messages: [any Message] { get }
    var displayConfig: any DisplayConfig { get }
    var pendingPermissions: [any PermissionPrompt] { get }
    var pendingWidgets: [any InteractiveWidget] { get }
    var typingParticipants: [String] { get }

    /// One cursor per participant who has read something in this
    /// conversation. Absence of a participant means they have read
    /// nothing yet. UIs derive unread state by comparing each cursor's
    /// `upToMessageID` against `messages`.
    var readMarkers: [any ReadReceipt] { get }

    /// In-progress, uncommitted drafts. One per participant who is
    /// currently composing or streaming. Drafts commit into `messages`
    /// as immutable `Message` values; they never live in `messages`
    /// themselves.
    var activeDrafts: [any ActiveDraft] { get }

    /// Commands invoked in this conversation, in invocation order. An entry
    /// whose `result` is still `nil` is running; a finished one keeps its
    /// place rather than moving, so a transcript's pills stay where the user
    /// last saw them.
    var commandActivity: [CommandActivity] { get }

    /// The most recent status per participant, keyed by participant id. A
    /// participant absent from the map is doing nothing right now.
    ///
    /// On the protocol, not just on `ObservableChatViewModel`, because the
    /// status line is part of the chat surface every conformer has to be able
    /// to drive: `InlineChatView` reads this on `ChatUpdate.statusChanged`,
    /// and it holds `any ChatViewModel`.
    var statuses: [String: ChatStatus] { get }

    func addObserver(_ observer: any ChatStateObserver)
    func removeObserver(_ observer: any ChatStateObserver)

    func submitMessage(text: String, attachments: [any Attachment]) async throws -> String

    /// Advance the local participant's read cursor to `messageID`.
    /// Implicitly marks everything earlier as read.
    func markRead(messageID: String) async throws

    func setLocalTyping(_ isTyping: Bool) async throws
    func respondToWidget(_ response: any WidgetResponse) async throws
    func respondToPermission(promptID: String, decision: PermissionDecision) async throws

    func listCommands() -> [any Command]
}
