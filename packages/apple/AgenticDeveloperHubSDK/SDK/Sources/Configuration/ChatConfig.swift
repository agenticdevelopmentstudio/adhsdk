import Foundation

public protocol ChatConfig: Sendable {
    var conversationID: String { get }
    var localParticipantID: String { get }
    var initialParticipants: [any Participant] { get }
    var commands: [any Command] { get }
    var observingHooks: [any ObservingHook] { get }
    var gatingHooks: [any GatingHook] { get }
    var permissionStore: any PermissionStore { get }
    var backend: any Backend { get }
    var display: any DisplayConfig { get }
}
