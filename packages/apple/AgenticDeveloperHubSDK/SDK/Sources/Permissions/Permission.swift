import Foundation

public protocol Permission: Sendable {
    var id: String { get }
    var displayPromptTemplate: String { get }
    var defaultDecision: PermissionDecision? { get }
}
