import Foundation

public protocol PermissionStore: AnyObject, Sendable {
    func decision(for permission: any Permission, requesterID: String) -> PermissionDecision?
    func remember(decision: PermissionDecision, for permission: any Permission, requesterID: String)
}
