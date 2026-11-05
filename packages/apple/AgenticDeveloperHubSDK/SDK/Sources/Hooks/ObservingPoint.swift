import Foundation

public enum ObservingPoint: Sendable, Hashable {
    case didComposeMessage
    case messageSent
    case messageReceived
    case messageRead
    case didExecuteCommand
    case willEmitUpdate
    case didEmitUpdate
    case participantJoined
    case participantDeparted
    case permissionResolved
}
