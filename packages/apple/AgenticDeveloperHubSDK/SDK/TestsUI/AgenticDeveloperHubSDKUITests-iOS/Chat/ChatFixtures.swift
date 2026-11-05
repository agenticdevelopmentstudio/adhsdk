import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

// Local, test-scoped fixtures for the Chat suite. `FakeBackend` stays even
// though `ScriptedBackend` (Sources/Backend/) now exists: this suite drives
// events by hand mid-test (`emit(_:)` after the view model is already
// constructed), which a fixed-script replayer doesn't support, and
// duplicated test doubles per test target is the established pattern here
// (mirrors `InMemoryThemeStorage` existing once in each of
// `AgenticDeveloperHubSDKTests` and `AgenticDeveloperHubSDKUITests`) —
// `@testable import` doesn't cross the framework boundary.


/// A `Backend` whose `inboundEvents` stream is driven by hand via `emit(_:)`,
/// and which records everything sent through it.
@MainActor
final class FakeBackend: Backend {
    private(set) var sentMessages: [(text: String, attachments: [any Attachment])] = []
    private(set) var typingCalls: [Bool] = []
    private(set) var widgetResponses: [any WidgetResponse] = []

    /// What `send(text:attachments:)` returns/throws next call.
    var sendResult: Result<String, Error> = .success("local-1")

    let inboundEvents: AsyncStream<InboundEvent>
    private let continuation: AsyncStream<InboundEvent>.Continuation

    init() {
        var continuation: AsyncStream<InboundEvent>.Continuation!
        self.inboundEvents = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    func send(text: String, attachments: [any Attachment]) async throws -> String {
        sentMessages.append((text, attachments))
        switch sendResult {
        case .success(let id): return id
        case .failure(let error): throw error
        }
    }

    func setLocalTyping(_ isTyping: Bool) async throws {
        typingCalls.append(isTyping)
    }

    func submitWidgetResponse(_ response: any WidgetResponse) async throws {
        widgetResponses.append(response)
    }

    /// Pushes an event onto `inboundEvents` for whatever is consuming it
    /// (typically `ObservableChatViewModel`'s `init`-time `Task`).
    func emit(_ event: InboundEvent) {
        continuation.yield(event)
    }
}

struct FakeSendError: Error, Equatable {
    let message: String
}

/// Records every `ChatUpdate` delivered to it, in order.
@MainActor
final class RecordingObserver: ChatStateObserver {
    private(set) var updates: [ChatUpdate] = []

    func chatDidUpdate(_ update: ChatUpdate) {
        updates.append(update)
    }
}

struct FixtureMediaType: MediaType {
    let identifier: String
    static let text = FixtureMediaType(identifier: "text/plain")
}

struct FixtureAttachment: Attachment {
    var id: String = UUID().uuidString
    var mediaType: any MediaType = FixtureMediaType.text
    var source: AttachmentSource = .inline(Data())
    var presentation: AttachmentPresentation = .attached
    var displayName: String? = "attachment"
    var byteSize: Int? = 0
}

struct FixtureMessage: Message {
    var id: String?
    var localID: String
    var senderID: String
    var text: String
    var timestamp: Date?
    var attachments: [any Attachment] = []
    var deliveryStatus: MessageDeliveryStatus = .received
}

struct FixtureParticipant: Participant {
    var id: String
    var displayName: String
    var avatarURL: URL?
    var profileURL: URL?
    var address: String
    var kinds: Set<ParticipantKind>
    var conversationState: ParticipantConversationState = .joined

    static func user(id: String = "user-1") -> FixtureParticipant {
        FixtureParticipant(id: id, displayName: "You", address: id, kinds: [.user])
    }

    static func persona(id: String = "persona-1") -> FixtureParticipant {
        FixtureParticipant(id: id, displayName: "Persona", address: id, kinds: [.persona])
    }
}

struct FixturePermission: Permission {
    var id: String = UUID().uuidString
    var displayPromptTemplate: String = "Allow {action}?"
    var defaultDecision: PermissionDecision? = nil
}

struct FixturePermissionPrompt: PermissionPrompt {
    var id: String
    var permission: any Permission = FixturePermission()
    var requesterID: String
    var displayPrompt: String
    var requestedAt: Date = Date()
}

struct FixtureWidget: InteractiveWidget {
    var id: String = UUID().uuidString
    var mediaType: any MediaType = FixtureMediaType.text
    var source: AttachmentSource = .inline(Data())
    var presentation: AttachmentPresentation = .inline
    var displayName: String? = nil
    var byteSize: Int? = nil
    var hasResponse: Bool = false
}

struct FixtureWidgetResponse: WidgetResponse {
    var widgetID: String
    var respondingParticipantID: String
    var payloadJSON: String = "{}"
}

struct FixtureCommandInvocation: CommandInvocation {
    var id: String = UUID().uuidString
    var commandName: String
    var invokerID: String
    var invokerKind: CommandInvoker = .other
    var argumentsJSON: String = "{}"
    var requestedAt: Date = Date()
}

struct FixtureCommandResult: CommandResult {
    var invocationID: String
    var ok: Bool = true
    var resultJSON: String? = nil
    var errorMessage: String? = nil
    var completedAt: Date = Date()
}
