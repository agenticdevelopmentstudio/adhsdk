import Foundation

/// A participant's read cursor in a conversation. There is one
/// `ReadReceipt` per (conversation, participant) — advancing
/// `upToMessageID` implicitly marks everything prior as read.
///
/// Mirrors Matrix `m.read`, XMPP XEP-0333 `displayed`,
/// Slack `conversations.mark`, Discord `READ_STATE.last_read_id`.
public protocol ReadReceipt: Sendable {
    var participantID: String { get }
    var upToMessageID: String { get }
    var at: Date { get }
}
