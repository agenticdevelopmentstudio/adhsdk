import Foundation
import Combine
import AgenticDeveloperHubSDKCore

/// What the CLI settings panel shows about adhd's MCP endpoint, and what
/// the Coding Partner's MCP config is written from: filled by the host from
/// its adhd connection (the channel's fixed port and client token), read by
/// the panel and the partner.
@MainActor
public final class AutomationServerStatus: ObservableObject {
    /// adhd's port once it answers; nil until then, or when it failed.
    @Published public var port: UInt16?
    /// The bearer token the Coding Partner's MCP config carries (adhd's
    /// client token).
    @Published public var token: String?
    /// The line that registers the endpoint with Claude Code
    /// (`MCPRegistration.claudeCommand(channel:adhdPath:)`, or what
    /// `adhd mcp command` prints); nil until it is known.
    @Published public var command: String?
    /// Whether `~/.claude.json` lists adhd's entry for this channel at its
    /// address (`MCPRegistration.isRegistered(claudeConfig:channel:)`).
    @Published public var isRegistered = false
    /// Why the endpoint is not running, when it is not.
    @Published public var failureReason: String?

    public init() {}

    /// The URL a caller posts to, once there is a port.
    public var url: String? {
        port.map { MCPRegistration.url(port: $0) }
    }

    /// One sentence for the panel.
    public var line: String {
        Self.line(port: port, isRegistered: isRegistered, failureReason: failureReason)
    }

    /// The sentence for these values. The panel renders from the values a
    /// `@Published` property publishes, which arrive before the property
    /// itself changes, so the sentence cannot be read back off `self` there.
    public static func line(port: UInt16?, isRegistered: Bool, failureReason: String?) -> String {
        if let failureReason { return "Not reachable: \(failureReason)" }
        guard let port else { return "Connecting to adhd." }
        return "adhd serves MCP at 127.0.0.1:\(port)\(MCPRegistration.path). "
            + "\(isRegistered ? "Registered" : "Not registered") with Claude Code."
    }
}
