import Foundation
@testable import AgenticDeveloperHubSDK

/// Requests the fake transport saw, in order.
final class RequestLog: @unchecked Sendable {
    private let lock = NSLock()
    private var requests: [URLRequest] = []

    func record(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        requests.append(request)
    }

    var all: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return requests
    }

    func requests(matching suffix: String) -> [URLRequest] {
        all.filter { $0.url?.path.hasSuffix(suffix) == true }
    }
}

/// Turn phases the coordinator reported, in order. `nil` means cleared.
final class StatusLog: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [TurnStatus?] = []

    func record(_ status: TurnStatus?) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(status)
    }

    var all: [TurnStatus?] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }
}

/// Whether a stream was torn down rather than reaching its end.
final class CancellationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    func set() {
        lock.lock()
        defer { lock.unlock() }
        value = true
    }

    var wasCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

/// Collects `inboundEvents` so a test can assert on the sequence.
///
/// `inboundEvents` is single-consumer by contract, so exactly one of these
/// drains it and the test reads from here instead.
actor EventCollector {
    private var events: [InboundEvent] = []
    private var finished = false

    func consume(_ stream: AsyncStream<InboundEvent>) async {
        for await event in stream { events.append(event) }
        finished = true
    }

    var all: [InboundEvent] { events }

    /// Wait until at least `count` events have arrived, or give up.
    @discardableResult
    func wait(for count: Int, timeout: TimeInterval = 2) async -> [InboundEvent] {
        let deadline = Date().addingTimeInterval(timeout)
        while events.count < count, !finished, Date() < deadline {
            try? await Task.sleep(nanoseconds: 500_000)
        }
        return events
    }

    /// Wait for the event that ends a turn, then let anything trailing land.
    /// Tests that assert something did NOT happen need the turn to be over
    /// first, or they pass by arriving early.
    @discardableResult
    func waitForTurnEnd(timeout: TimeInterval = 2) async -> [InboundEvent] {
        let deadline = Date().addingTimeInterval(timeout)
        while !events.contains(where: \.isDraftCleared), !finished, Date() < deadline {
            try? await Task.sleep(nanoseconds: 500_000)
        }
        try? await Task.sleep(nanoseconds: 20_000_000)
        return events
    }

    /// Let the coordinator do whatever it was going to do, then report.
    @discardableResult
    func quiesce(_ seconds: TimeInterval = 0.1) async -> [InboundEvent] {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return events
    }
}

extension InboundEvent {
    var draftText: String? {
        if case let .draftUpdated(_, text, _) = self { return text }
        return nil
    }

    var receivedMessage: (any Message)? {
        if case let .messageReceived(message) = self { return message }
        return nil
    }

    var isDraftCleared: Bool {
        if case .draftCleared = self { return true }
        return false
    }

    var failureReason: String? {
        if case let .messageFailed(_, reason) = self { return reason }
        return nil
    }

    var transportErrorMessage: String? {
        if case let .transportError(message) = self { return message }
        return nil
    }

    var invocation: (any CommandInvocation)? {
        if case let .commandInvoked(_, invocation) = self { return invocation }
        return nil
    }

    var commandResult: (any CommandResult)? {
        if case let .commandCompleted(_, result) = self { return result }
        return nil
    }

    var isStatusChanged: Bool {
        if case .statusChanged = self { return true }
        return false
    }
}

/// An SSE body delivered as one chunk. Chunk boundaries are the parser's
/// problem, not this fixture's — `SSEParserTests` cover splitting.
func sse(_ blocks: [(String, String)]) -> AsyncThrowingStream<Data, any Error> {
    AsyncThrowingStream { continuation in
        var text = ""
        for (event, data) in blocks {
            text += "event: \(event)\ndata: \(data)\n\n"
        }
        continuation.yield(Data(text.utf8))
        continuation.finish()
    }
}

/// An SSE body that emits, then dies without `done` — a truncated reply.
func truncatedSse(_ blocks: [(String, String)]) -> AsyncThrowingStream<Data, any Error> {
    AsyncThrowingStream { continuation in
        var text = ""
        for (event, data) in blocks {
            text += "event: \(event)\ndata: \(data)\n\n"
        }
        continuation.yield(Data(text.utf8))
        continuation.finish(throwing: URLError(.networkConnectionLost))
    }
}

/// An SSE body that emits, then hangs until the reader goes away.
func hangingSse(
    _ blocks: [(String, String)],
    cancelled: CancellationFlag
) -> AsyncThrowingStream<Data, any Error> {
    AsyncThrowingStream { continuation in
        var text = ""
        for (event, data) in blocks {
            text += "event: \(event)\ndata: \(data)\n\n"
        }
        continuation.yield(Data(text.utf8))
        continuation.onTermination = { termination in
            if case .cancelled = termination { cancelled.set() }
        }
    }
}

struct Fixture {
    let coordinator: PersonaChatCoordinator
    let requests: RequestLog
    let statuses: StatusLog
    let collector: EventCollector
    let pump: Task<Void, Never>

    func tearDown() {
        coordinator.destroy()
        pump.cancel()
    }
}

/// Builds a coordinator over a fake adh: the conversation POST answers with an
/// id, and the message POST answers with whatever stream the test supplies.
@MainActor
func makeFixture(
    conversationStatus: Int = 200,
    stream: @escaping @Sendable () -> AsyncThrowingStream<Data, any Error>
) -> Fixture {
    let requests = RequestLog()
    let statuses = StatusLog()
    let coordinator = PersonaChatCoordinator(options: PersonaChatCoordinatorOptions(
        personaSlug: "aria",
        baseURL: URL(string: "https://adh.test/api")!,
        authorize: { request in
            requests.record(request)
            if request.url?.path.hasSuffix("/conversations") == true {
                return AuthorizedResponse(
                    statusCode: conversationStatus,
                    body: AsyncThrowingStream { continuation in
                        continuation.yield(Data(#"{"id":"conv-1"}"#.utf8))
                        continuation.finish()
                    }
                )
            }
            // adh answers 200 even when the turn fails; the failure is in-band
            // (ci-in-band-errors).
            return AuthorizedResponse(statusCode: 200, body: stream())
        },
        model: "claude-opus-5",
        onStatus: { statuses.record($0) }
    ))
    let collector = EventCollector()
    let pump = Task { await collector.consume(coordinator.inboundEvents) }
    return Fixture(
        coordinator: coordinator,
        requests: requests,
        statuses: statuses,
        collector: collector,
        pump: pump
    )
}
