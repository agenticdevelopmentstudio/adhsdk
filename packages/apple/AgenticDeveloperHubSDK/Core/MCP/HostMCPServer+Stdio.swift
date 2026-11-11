import Foundation
import MCP

extension HostMCPServer {
    /// How long a server whose stdin has closed keeps waiting for the replies it
    /// still owes. A tool call can be slow: temporal's mail sign-in waits up to 300 s
    /// for the browser, plus an XPC timeout above that.
    public static let stdioDrainDeadline: Duration = .seconds(360)

    /// Serves over this process's stdin and stdout. Returns once stdin has
    /// closed and every request that arrived before that has been answered, or
    /// once `stdioDrainDeadline` has passed.
    public func serveStdio() async throws {
        try await serveUntilDrained(over: StdioTransport())
    }

    /// Serves over `transport` until its input ends, then waits for the replies
    /// still owed and stops.
    ///
    /// The pinned swift-sdk (0.12.1) answers each request in an unstructured
    /// `Task`. `waitUntilServerCompleted()` waits only for the receive loop,
    /// which ends at EOF, so stopping at that point would drop every reply
    /// still in flight. `ReplyCountingTransport` counts those replies so this
    /// method can wait for them. The deadline counts from the moment the input
    /// ends; a reply still missing then is abandoned.
    func serveUntilDrained(over transport: any Transport,
                           deadline: Duration = HostMCPServer.stdioDrainDeadline) async throws {
        let counting = ReplyCountingTransport(wrapping: transport)
        try await serve(over: counting)
        await waitUntilServerCompleted()
        if !(await counting.waitUntilNothingOwed(deadline: deadline)) {
            let owed = await counting.owedCount
            log.warning("MCP input closed; \(owed, privacy: .public) request(s) unanswered at the deadline")
        }
        await stop()
    }
}
