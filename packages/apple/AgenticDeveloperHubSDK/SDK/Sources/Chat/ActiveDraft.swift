import Foundation

/// A participant's in-progress, uncommitted message. Drafts are a
/// view-model concept — they exist only while a streaming responder is
/// producing tokens or a human is composing. On commit, the draft is
/// replaced by an immutable `Message`; on abort, it is discarded. Drafts
/// never appear in `ChatViewModel.messages`.
public protocol ActiveDraft: Sendable {
    var participantID: String { get }
    var text: String { get }
    var attachments: [any Attachment] { get }
}
