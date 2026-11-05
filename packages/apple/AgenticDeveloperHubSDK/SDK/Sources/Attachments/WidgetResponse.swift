import Foundation

public protocol WidgetResponse: Sendable {
    var widgetID: String { get }
    var respondingParticipantID: String { get }
    var payloadJSON: String { get }
}
