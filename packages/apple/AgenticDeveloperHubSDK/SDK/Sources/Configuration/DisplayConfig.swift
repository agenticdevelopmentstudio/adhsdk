import Foundation

public protocol DisplayConfig: Sendable {
    var showAvatars: Bool { get }
    var showReadReceipts: Bool { get }
    var showTypingIndicators: Bool { get }
    var maxParticipants: Int? { get }
    var allowJoining: Bool { get }
    var allowDeparting: Bool { get }
    var themeIdentifier: String? { get }
    var reducedMotion: Bool { get }
}
