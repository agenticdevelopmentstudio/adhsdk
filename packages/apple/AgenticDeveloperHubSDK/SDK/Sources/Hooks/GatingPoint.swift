import Foundation

public enum GatingPoint: Sendable, Hashable {
    case willSubmitMessage
    case willExecuteCommand
    case willEmitUpdate
    case willRequestPermission
    case willAcceptInboundMessage
}
