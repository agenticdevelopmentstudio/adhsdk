import Foundation

public enum MessageDeliveryStatus: Sendable, Hashable {
    case composing
    case sending
    case sent
    case delivered
    case failed(reason: String)
    case received
}
