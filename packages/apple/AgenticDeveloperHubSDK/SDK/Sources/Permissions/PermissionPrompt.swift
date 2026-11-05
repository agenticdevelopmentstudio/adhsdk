import Foundation

public protocol PermissionPrompt: Sendable {
    var id: String { get }
    var permission: any Permission { get }
    var requesterID: String { get }
    var displayPrompt: String { get }
    var requestedAt: Date { get }
}
