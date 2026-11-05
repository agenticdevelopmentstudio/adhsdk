import Foundation

/// Implements the `persona-chat-coordinator` ingredient.
/// See `docs/specs/ingredients/persona-chat-coordinator.md` — the requirement
/// ids in the comments below (`ci-*`) refer to that spec, and the conformance
/// vectors (`pcc-*`) are the tests. The TypeScript coordinator
/// (`packages/web/packages/chat/src/backends/PersonaChatBackend.ts`) is derived
/// from the same spec; the two are meant to read alike, and a change to the
/// behaviour of one belongs in the spec and then in both.
///
/// adh orchestrates the turn: it resolves the persona from its slug, assembles
/// the prompt, reads and writes history, calls the provider, and streams the
/// reply back. This actor holds no history, no prompt, and no credentials.

/// Turn phase, for the status line. Not a transcript event
/// (ci-status-out-of-band).
public enum TurnStatus: String, Sendable {
    case thinking
    case responding
    case retrying
}

/// A response in the shape the coordinator needs: a status code, and a body it
/// can read incrementally.
///
/// Chunks rather than lines, deliberately. `URLSession.AsyncBytes.lines`
/// collapses the blank line that SSE uses to separate blocks, so a coordinator
/// built on it silently loses every block boundary.
public struct AuthorizedResponse: Sendable {
    public let statusCode: Int
    public let body: AsyncThrowingStream<Data, any Error>

    public init(statusCode: Int, body: AsyncThrowingStream<Data, any Error>) {
        self.statusCode = statusCode
        self.body = body
    }
}

/// Credential-attaching transport, INJECTED by the host. Importing an auth
/// module here would close an `auth -> chat -> auth` cycle in every consumer
/// that builds auth on top of chat.
public typealias Authorize = @Sendable (URLRequest) async throws -> AuthorizedResponse

public enum PersonaChatError: Error, CustomStringConvertible {
    case destroyed
    case attachmentsUnsupported
    case widgetsUnsupported
    case conversationFailed(status: Int)

    public var description: String {
        switch self {
        case .destroyed:
            return "PersonaChatCoordinator has been destroyed."
        case .attachmentsUnsupported:
            return "PersonaChatCoordinator does not support attachments."
        case .widgetsUnsupported:
            return "PersonaChatCoordinator does not support widgets."
        case let .conversationFailed(status):
            return "Couldn't start the conversation (\(status))."
        }
    }
}

public struct PersonaChatCoordinatorOptions: Sendable {
    /// Persona to converse with. adh resolves everything else from this.
    public var personaSlug: String
    /// Root of the adh chat API, e.g. `https://adh.example.com/api`.
    public var baseURL: URL
    public var authorize: Authorize
    /// Overrides the persona's configured model when set.
    public var model: String?
    /// Identifies the persona in emitted events. Defaults to `personaSlug`.
    public var participantID: String?
    /// Receives turn-phase transitions. Cleared with `nil` when a turn ends.
    public var onStatus: (@Sendable (TurnStatus?) -> Void)?

    public init(
        personaSlug: String,
        baseURL: URL,
        authorize: @escaping Authorize,
        model: String? = nil,
        participantID: String? = nil,
        onStatus: (@Sendable (TurnStatus?) -> Void)? = nil
    ) {
        self.personaSlug = personaSlug
        self.baseURL = baseURL
        self.authorize = authorize
        self.model = model
        self.participantID = participantID
        self.onStatus = onStatus
    }
}

public actor PersonaChatCoordinator: Backend {
    public nonisolated let inboundEvents: AsyncStream<InboundEvent>

    private nonisolated let events: AsyncStream<InboundEvent>.Continuation
    private nonisolated let participantID: String
    private nonisolated let conversationsURL: URL
    /// Cancellation lives outside the actor on purpose; see `destroy`.
    private nonisolated let control = TurnControl()

    private let options: PersonaChatCoordinatorOptions
    private var conversationID: String?
    /// Open invocations, oldest first, keyed by command name (ci-invocation-ids).
    private var openInvocations: [String: [String]] = [:]

    public init(options: PersonaChatCoordinatorOptions) {
        self.options = options
        self.participantID = options.participantID ?? options.personaSlug
        self.conversationsURL = options.baseURL
            .appendingPathComponent("chat")
            .appendingPathComponent("conversations")
        let (stream, continuation) = AsyncStream<InboundEvent>.makeStream(
            of: InboundEvent.self,
            bufferingPolicy: .unbounded
        )
        self.inboundEvents = stream
        self.events = continuation
    }

    /// Submit a message and start its turn. Returns immediately with the
    /// `localID`; the reply arrives on `inboundEvents`.
    ///
    /// No history is sent (ci-no-history) — adh owns it. That is why the
    /// `Backend` contract has no history parameter to begin with.
    public func send(text: String, attachments: [any Attachment]) async throws -> String {
        // Reuse after destroy fails fast rather than silently reconnecting
        // onto a conversation the caller believes is gone.
        guard !control.destroyed else { throw PersonaChatError.destroyed }
        guard attachments.isEmpty else {
            // adh's chat endpoint carries a message and nothing else. Dropping
            // attachments silently would send a message the user believes had
            // a file on it.
            throw PersonaChatError.attachmentsUnsupported
        }

        let localID = UUID().uuidString
        // Detached from the caller: the turn outlives the `send` that started
        // it, so tying it to the caller's task would cancel the reply the
        // moment the sender's work finished.
        // `weak`: the control block holds this task and the actor holds the
        // control block, so a strong capture would keep the coordinator alive
        // for as long as a turn it is no longer wanted for.
        let turn = Task { [weak self] in
            guard let self else { return }
            await self.runTurn(text: text, localID: localID)
        }
        guard control.adopt(turn) else {
            turn.cancel()
            throw PersonaChatError.destroyed
        }
        return localID
    }

    /// adh has no typing channel for the local participant; nothing to report.
    public func setLocalTyping(_ isTyping: Bool) async throws {}

    public func submitWidgetResponse(_ response: any WidgetResponse) async throws {
        throw PersonaChatError.widgetsUnsupported
    }

    /// Cancel any in-flight turn and close the event stream. Authoritative:
    /// the cancellation handle is ours, never the caller's
    /// (ci-destroy-authoritative).
    ///
    /// `nonisolated` so teardown is immediate and ordered. Hopping onto the
    /// actor first would let a queued `send` start a turn after the caller
    /// believed the coordinator was gone.
    public nonisolated func destroy() {
        let turn = control.destroy()
        turn?.cancel()
        // Emitted here rather than left to the turn's own cleanup: cancellation
        // is asynchronous, and the stream below closes now. A consumer still
        // rendering would otherwise keep a half-typed draft on screen forever.
        events.yield(.draftCleared(participantID: participantID))
        events.finish()
    }

    /// Create the backing conversation once, then reuse it
    /// (ci-lazy-conversation, ci-conversation-reuse).
    private func ensureConversation() async throws -> String {
        if let conversationID { return conversationID }

        var request = URLRequest(url: conversationsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        // adh resolves model as persona.model || conversation.model, so
        // passing the persona's model keeps an unset persona.model working
        // (ci-conversation-pinning).
        request.httpBody = try JSONEncoder().encode(
            CreateConversationBody(personaSlug: options.personaSlug, model: options.model)
        )

        let response = try await options.authorize(request)
        guard (200..<300).contains(response.statusCode) else {
            throw PersonaChatError.conversationFailed(status: response.statusCode)
        }
        var body = Data()
        for try await chunk in response.body { body.append(chunk) }
        let created = try JSONDecoder().decode(CreatedConversation.self, from: body)
        conversationID = created.id
        return created.id
    }

    /// Drive one turn end to end. Every exit path clears the status line and
    /// the draft, so an aborted or failed turn never leaves the UI pinned
    /// mid-reply.
    private func runTurn(text: String, localID: String) async {
        let status = options.onStatus
        var committed = false
        defer {
            // A stream that ended without `done` left a draft behind. Truncated
            // replies must not commit as though complete (ci-no-commit-on-abort).
            if !committed { emit(.draftCleared(participantID: participantID)) }
            openInvocations.removeAll()
            report(nil, via: status)
        }

        report(.thinking, via: status)

        let id: String
        do {
            id = try await ensureConversation()
        } catch {
            // Nothing reached adh, so this is the message's failure, not the
            // transport's (ci-transport-vs-message).
            emit(.messageFailed(
                localID: localID,
                reason: describe(error, fallback: "Couldn't start the conversation.")
            ))
            return
        }

        var request = URLRequest(
            url: conversationsURL.appendingPathComponent(id).appendingPathComponent("messages")
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = try? JSONEncoder().encode(SendMessageBody(message: text))

        let response: AuthorizedResponse
        do {
            response = try await options.authorize(request)
        } catch {
            emit(.messageFailed(
                localID: localID,
                reason: describe(error, fallback: "The chat request failed.")
            ))
            return
        }

        committed = await consumeStream(response.body, localID: localID, status: status)
    }

    /// Read SSE blocks and translate them. Returns whether the turn committed
    /// a message, so the caller knows whether a draft is still outstanding.
    private func consumeStream(
        _ body: AsyncThrowingStream<Data, any Error>,
        localID: String,
        status: (@Sendable (TurnStatus?) -> Void)?
    ) async -> Bool {
        var parser = SSEParser()
        // adh streams fragments; `draftUpdated.text` is the accumulation
        // (ci-accumulate), so we hold the running text here.
        var accumulated = ""
        var responded = false

        do {
            for try await chunk in body {
                for block in parser.consume(chunk) {
                    switch block.event {
                    // Connection heartbeat, not a transcript event (ci-drop-open).
                    case "open":
                        break

                    // Out-of-band progress. A retry is not something that
                    // happened in the conversation (ci-status-out-of-band).
                    case "status":
                        if decode(StatusPayload.self, block.data)?.phase == "retrying" {
                            report(.retrying, via: status)
                        }

                    case "token":
                        let fragment = decode(TokenPayload.self, block.data)?.text ?? ""
                        if !responded {
                            responded = true
                            report(.responding, via: status)
                        }
                        accumulated += fragment
                        emit(.draftUpdated(
                            participantID: participantID,
                            text: accumulated,
                            attachments: []
                        ))

                    case "tool_call_started":
                        guard let started = decode(ToolStartedPayload.self, block.data) else { break }
                        emit(.commandInvoked(
                            participantID: participantID,
                            invocation: openInvocation(
                                commandName: started.name,
                                argumentsJSON: started.arguments ?? ""
                            )
                        ))

                    case "tool_call_completed":
                        guard let completed = decode(ToolCompletedPayload.self, block.data) else { break }
                        // A completion for a call we never saw start is dropped
                        // rather than invented.
                        guard let invocationID = closeInvocation(commandName: completed.name) else { break }
                        let result = completed.result ?? ""
                        emit(.commandCompleted(
                            participantID: participantID,
                            result: CoordinatorCommandResult(
                                invocationID: invocationID,
                                ok: completed.ok,
                                resultJSON: completed.ok ? result : nil,
                                errorMessage: completed.ok ? nil : result,
                                completedAt: Date()
                            )
                        ))

                    case "done":
                        // Commit exactly once, then clear the draft
                        // (ci-commit-once). An empty reply still commits, so
                        // the transcript records that the turn happened.
                        emit(.messageReceived(CoordinatorMessage(
                            id: nil,
                            localID: UUID().uuidString,
                            senderID: participantID,
                            text: accumulated,
                            timestamp: Date(),
                            attachments: [],
                            deliveryStatus: .delivered
                        )))
                        emit(.draftCleared(participantID: participantID))
                        return true

                    case "error":
                        // adh answers 200 and reports failure in-band, so status
                        // codes prove nothing (ci-in-band-errors).
                        emit(.messageFailed(
                            localID: localID,
                            reason: decode(ErrorPayload.self, block.data)?.message ?? "Chat failed."
                        ))
                        return false

                    // Unknown events are ignored so adh can add some without
                    // breaking older clients (ci-unknown-events).
                    default:
                        break
                    }
                }
            }
        } catch {
            // A cancellation lands here too; the turn simply ends without
            // committing.
            if !control.destroyed {
                emit(.transportError(message: describe(error, fallback: "The chat stream failed.")))
            }
        }
        return false
    }

    /// Assign a fresh id per invocation (ci-invocation-ids). adh's
    /// `tool_call_completed` carries a name and no id, so correlation is by
    /// name and arrival order — oldest open call of that name wins.
    private func openInvocation(commandName: String, argumentsJSON: String) -> CommandInvocation {
        let id = UUID().uuidString
        openInvocations[commandName, default: []].append(id)
        return CoordinatorCommandInvocation(
            id: id,
            commandName: commandName,
            invokerID: participantID,
            // CommandInvoker is user | other; the persona is not the local user.
            invokerKind: .other,
            argumentsJSON: argumentsJSON,
            requestedAt: Date()
        )
    }

    private func closeInvocation(commandName: String) -> String? {
        guard var open = openInvocations[commandName], !open.isEmpty else { return nil }
        let id = open.removeFirst()
        if open.isEmpty { openInvocations.removeValue(forKey: commandName) }
        else { openInvocations[commandName] = open }
        return id
    }

    private nonisolated func emit(_ event: InboundEvent) {
        events.yield(event)
    }

    /// Reports a turn-phase transition through both channels: the existing
    /// `onStatus` callback (kept for its existing callers) and the
    /// out-of-band `statusChanged` event (ci-status-out-of-band).
    private nonisolated func report(_ status: TurnStatus?, via callback: (@Sendable (TurnStatus?) -> Void)?) {
        callback?(status)
        emit(.statusChanged(
            participantID: participantID,
            status: status.map { ChatStatus(kind: ChatStatusKind($0)) }
        ))
    }

    private nonisolated func decode<T: Decodable>(_ type: T.Type, _ data: String) -> T? {
        guard let raw = data.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: raw)
    }

    private nonisolated func describe(_ error: any Error, fallback: String) -> String {
        if error is CancellationError { return fallback }
        // `any Error` bridges to `NSError` on Apple platforms, and `NSError`
        // itself conforms to `CustomStringConvertible` — so `error as?
        // CustomStringConvertible` always succeeds, for every error, not just
        // ours. That silently skipped the `NSError.localizedDescription`
        // fallback below for every non-`PersonaChatError`, surfacing whatever
        // raw Swift dump `String(describing:)` produces (a verbose
        // `DecodingError` case, say) instead of the friendlier message this
        // function exists to prefer. Naming the concrete type we actually
        // authored a description for fixes both the warning and the bug.
        if let personaError = error as? PersonaChatError {
            return personaError.description
        }
        let text = (error as NSError).localizedDescription
        return text.isEmpty ? fallback : text
    }
}

public extension PersonaChatCoordinator {
    /// `URLSession`-backed transport with no credentials attached. A host that
    /// needs auth wraps this rather than the coordinator reaching for a
    /// credential store it should not know about.
    static func urlSessionAuthorize(session: URLSession = .shared) -> Authorize {
        { request in
            let (bytes, response) = try await session.bytes(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = AsyncThrowingStream<Data, any Error> { continuation in
                let pump = Task {
                    var line = Data()
                    do {
                        for try await byte in bytes {
                            line.append(byte)
                            // Chunked by line, keeping the newline: SSE's block
                            // separator is a blank line, and it has to survive.
                            if byte == 0x0A {
                                continuation.yield(line)
                                line.removeAll(keepingCapacity: true)
                            }
                        }
                        if !line.isEmpty { continuation.yield(line) }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { _ in pump.cancel() }
            }
            return AuthorizedResponse(statusCode: status, body: body)
        }
    }
}

/// The in-flight turn and the destroyed flag, reachable without the actor.
///
/// `destroy` has to be able to cancel a turn NOW, from any context, including
/// one holding no async capability at all — a `deinit`, a SwiftUI
/// `onDisappear`. Actor isolation would make it a request to cancel rather
/// than a cancellation.
private final class TurnControl: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Never>?
    private var isDestroyed = false

    var destroyed: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isDestroyed
    }

    /// Take ownership of a turn. Returns `false` if the coordinator was
    /// destroyed first, in which case the turn must not run.
    func adopt(_ task: Task<Void, Never>) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if isDestroyed { return false }
        self.task = task
        return true
    }

    func destroy() -> Task<Void, Never>? {
        lock.lock()
        defer { lock.unlock() }
        isDestroyed = true
        let inFlight = task
        task = nil
        return inFlight
    }
}

private struct CoordinatorMessage: Message {
    let id: String?
    let localID: String
    let senderID: String
    let text: String
    let timestamp: Date?
    let attachments: [any Attachment]
    let deliveryStatus: MessageDeliveryStatus
}

private struct CoordinatorCommandInvocation: CommandInvocation {
    let id: String
    let commandName: String
    let invokerID: String
    let invokerKind: CommandInvoker
    let argumentsJSON: String
    let requestedAt: Date
}

private struct CoordinatorCommandResult: CommandResult {
    let invocationID: String
    let ok: Bool
    let resultJSON: String?
    let errorMessage: String?
    let completedAt: Date
}

private struct CreateConversationBody: Encodable {
    let personaSlug: String
    let model: String?
}

private struct SendMessageBody: Encodable {
    let message: String
}

private struct CreatedConversation: Decodable {
    let id: String
}

private struct TokenPayload: Decodable {
    let text: String?
}

private struct ToolStartedPayload: Decodable {
    let name: String
    let arguments: String?
}

private struct ToolCompletedPayload: Decodable {
    let name: String
    let ok: Bool
    let result: String?
}

private struct ErrorPayload: Decodable {
    let message: String?
}

private struct StatusPayload: Decodable {
    let phase: String?
}
