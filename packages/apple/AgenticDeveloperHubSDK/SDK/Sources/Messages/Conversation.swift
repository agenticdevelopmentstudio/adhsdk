import Foundation

public protocol Conversation: Sendable {
    var id: String { get }
    var createdAt: Date { get }
    var title: String? { get }
    var participants: [any Participant] { get }
}
