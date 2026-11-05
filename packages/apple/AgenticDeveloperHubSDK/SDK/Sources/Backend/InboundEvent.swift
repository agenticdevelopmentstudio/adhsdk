import Foundation

public enum InboundEvent: Sendable {
    case messageAccepted(localID: String, serverID: String, at: Date)
    case messageDelivered(messageID: String, at: Date)
    case messageFailed(localID: String, reason: String)
    case messageReceived(any Message)

    /// A participant has advanced their read cursor to `upToMessageID`.
    /// Everything before that point is considered read. There is exactly
    /// one cursor per (conversation, participant). This event replaces
    /// per-message read acks — see Matrix `m.read`, XMPP XEP-0333
    /// `displayed`, Slack `conversations.mark`, Discord `READ_STATE`.
    case readMarkerAdvanced(participantID: String, upToMessageID: String, at: Date)

    /// A streaming participant (typically an LLM persona) has updated their
    /// in-progress draft. The draft is NOT a message — it lives in
    /// `ChatViewModel.activeDrafts` until it commits as an immutable
    /// `Message` via `messageReceived`. This keeps `Message` immutable
    /// while preserving the token-by-token UX.
    ///
    /// `text` is the WHOLE draft so far, not the newest fragment. Each event
    /// REPLACES the previous text rather than appending to it. A backend that
    /// emits fragments produces a transcript with every reply's prefix
    /// missing, with no error to catch it.
    case draftUpdated(participantID: String, text: String, attachments: [any Attachment])

    /// The participant has aborted or finalized their draft. If finalized,
    /// a `messageReceived` event will follow carrying the immutable
    /// `Message`. If aborted, no message arrives.
    case draftCleared(participantID: String)

    case participantJoined(any Participant)
    case participantDeparted(participantID: String)
    case typing(participantID: String, isTyping: Bool)

    /// A participant's work phase changed — thinking, searching, calling a
    /// tool. `nil` clears the line.
    ///
    /// Out-of-band, deliberately (`ci-status-out-of-band`). Status is NOT a
    /// transcript event: folding it into `draftUpdated` would commit a
    /// spinner's text into a user-visible `Message`.
    case statusChanged(participantID: String, status: ChatStatus?)

    case widgetPresented(messageID: String, widget: any InteractiveWidget)
    /// A participant invoked a command (tool call). Carries the whole
    /// `argumentsJSON` rather than streamed fragments, so there is no
    /// accumulation to get wrong. `invocation.id` is per-invocation and MUST
    /// NOT be derived from `commandName` — two parallel invocations of the
    /// same command would collide.
    ///
    /// Command activity is its own channel. It MUST NOT be folded into
    /// `draftUpdated`, where it would commit into the user-visible `Message`.
    case commandInvoked(participantID: String, invocation: CommandInvocation)

    /// A previously invoked command finished. `result.invocationID` matches
    /// the `invocation.id` it completes.
    case commandCompleted(participantID: String, result: CommandResult)

    case transportError(message: String)
}
