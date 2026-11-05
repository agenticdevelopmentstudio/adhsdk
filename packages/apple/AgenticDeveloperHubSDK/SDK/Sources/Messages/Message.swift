import Foundation

public protocol Message: Sendable {
    var id: String? { get }
    var localID: String { get }
    var senderID: String { get }
    var text: String { get }
    var timestamp: Date? { get }
    var attachments: [any Attachment] { get }
    var deliveryStatus: MessageDeliveryStatus { get }
}
