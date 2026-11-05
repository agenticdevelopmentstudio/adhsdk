import Foundation

public protocol Orchestrator: ChatViewModel {
    var permissionStore: any PermissionStore { get }
}
