import Foundation
import MCP

extension HostMCPServer {
    /// Serves over this process's stdin and stdout, and returns when stdin closes.
    ///
    /// The pinned swift-sdk (0.12.1) has `Server.waitUntilCompleted()`, which awaits the server's
    /// message loop; that loop ends when the transport's receive stream does, i.e. at EOF on stdin.
    public func serveStdio() async throws {
        try await serve(over: StdioTransport())
        await waitUntilServerCompleted()
    }
}
