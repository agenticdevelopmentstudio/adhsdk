import Foundation

public protocol Backend: AnyObject, Sendable {
    /// Submit a message to the bus. Returns the `localID` assigned by the
    /// backend at submission time. The server-assigned id (if any) arrives
    /// later as `InboundEvent.messageAccepted(localID:, serverID:, at:)`.
    func send(text: String, attachments: [any Attachment]) async throws -> String

    func setLocalTyping(_ isTyping: Bool) async throws
    func submitWidgetResponse(_ response: any WidgetResponse) async throws

    /// Cancellable stream of events from the bus. Each platform binds this
    /// to its native cold-async-sequence type (Swift `AsyncStream`, Kotlin
    /// `Flow`, JS async iterator, etc.). The orchestrator is the single
    /// consumer; multiplexing to multiple observers is the orchestrator's
    /// responsibility, not the backend's.
    var inboundEvents: AsyncStream<InboundEvent> { get }
}
