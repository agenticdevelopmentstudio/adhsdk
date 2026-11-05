import Foundation

public protocol HookContext: Sendable {
    var conversationID: String { get }
    var payloadJSON: String { get }
}
