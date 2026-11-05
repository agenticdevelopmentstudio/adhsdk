import Foundation

public protocol Participant: Sendable {
    var id: String { get }
    var displayName: String { get }
    var avatarURL: URL? { get }
    var profileURL: URL? { get }
    var address: String { get }
    var kinds: Set<ParticipantKind> { get }
    var conversationState: ParticipantConversationState { get }
}
