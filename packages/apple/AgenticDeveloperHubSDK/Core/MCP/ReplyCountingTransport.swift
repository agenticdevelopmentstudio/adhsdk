// Core/MCP/ReplyCountingTransport.swift
import Foundation
import Logging
import MCP

/// Passes everything through to another transport, and keeps track of the
/// requests that have arrived but not yet been answered. That lets a server
/// whose input has closed wait for the answers it still owes.
///
/// The pinned swift-sdk (0.12.1) handles every request in its own
/// unstructured `Task`. `Server.waitUntilCompleted()` waits only for the
/// receive loop, and that loop ends at the input's EOF. Without this,
/// stopping the server at that point throws away every reply still being
/// worked on. `printf '…' | olylo mcp` gets nothing back, for example.
///
/// How a request is counted:
/// - A message with both an `id` and a `method` is a request that is owed a
///   reply. It is counted as soon as it arrives, before the server sees it.
/// - The debt is paid when `send` writes a response (an `id` and no `method`)
///   with the same id.
/// - A `notifications/cancelled` for an owed id also pays it: the client has
///   given up, and MCP says the server need not answer a cancelled request.
/// - Batches (JSON arrays) are not counted. The SDK answers a batch inside
///   the receive loop, so its reply is sent before the loop ends.
actor ReplyCountingTransport: Transport {
    nonisolated let logger = Logger(label: "mcp.transport.reply-counting",
                                    factory: { _ in SwiftLogNoOpLogHandler() })

    private let inner: any Transport
    /// The ids of requests that have arrived and are still waiting for a reply.
    /// A string id `"1"` and a number id `1` are different ids, so each key
    /// records which kind it was.
    private var owed: Set<String> = []
    private var drainWaiters: [CheckedContinuation<Void, Never>] = []

    init(wrapping inner: any Transport) {
        self.inner = inner
    }

    var owedCount: Int { owed.count }

    func connect() async throws { try await inner.connect() }

    func disconnect() async {
        await inner.disconnect()
        releaseWaiters()
    }

    func send(_ data: Data) async throws {
        defer { noteOutgoing(data) }
        try await inner.send(data)
    }

    func receive() -> AsyncThrowingStream<Data, Swift.Error> {
        let (stream, continuation) = AsyncThrowingStream<Data, Swift.Error>.makeStream()
        let inner = inner
        let pump = Task {
            do {
                for try await data in await inner.receive() {
                    // Count the request before the server can see it, and so
                    // before the server can answer it.
                    self.noteIncoming(data)
                    continuation.yield(data)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in pump.cancel() }
        return stream
    }

    /// Waits until no request is owed a reply, or until `deadline` has passed.
    /// Returns whether everything was answered.
    func waitUntilNothingOwed(deadline: Duration) async -> Bool {
        guard !owed.isEmpty else { return true }
        let timer = Task {
            try? await Task.sleep(for: deadline)
            self.releaseWaiters()
        }
        defer { timer.cancel() }
        await withCheckedContinuation { drainWaiters.append($0) }
        return owed.isEmpty
    }

    // MARK: - Bookkeeping

    private func noteIncoming(_ data: Data) {
        guard let message = Self.object(data), let method = message["method"] as? String else { return }
        if let id = Self.idKey(message["id"]) {
            owed.insert(id)
        } else if method == "notifications/cancelled",
                  let params = message["params"] as? [String: Any],
                  let id = Self.idKey(params["requestId"]) {
            pay(id)
        }
    }

    private func noteOutgoing(_ data: Data) {
        guard let message = Self.object(data), message["method"] == nil,
              let id = Self.idKey(message["id"]) else { return }
        pay(id)
    }

    private func pay(_ id: String) {
        owed.remove(id)
        if owed.isEmpty { releaseWaiters() }
    }

    private func releaseWaiters() {
        let waiters = drainWaiters
        drainWaiters = []
        for waiter in waiters { waiter.resume() }
    }

    private static func object(_ data: Data) -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private static func idKey(_ id: Any?) -> String? {
        switch id {
        case let string as String: return "s:" + string
        case let number as NSNumber: return "n:" + number.stringValue
        default: return nil
        }
    }
}
