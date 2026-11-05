import Foundation

public enum ParticipantConversationState: Sendable, Hashable {
    case joining
    case joined
    case departing
    case departed
}
