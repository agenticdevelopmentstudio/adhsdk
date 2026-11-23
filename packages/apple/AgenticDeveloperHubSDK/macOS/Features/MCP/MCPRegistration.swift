import Foundation
import AgenticDeveloperHubSDKCore

/// How a Claude Code install learns about adhd's MCP endpoint: one
/// `claude mcp add-json` the user runs once, naming the channel's fixed
/// address and a `headersHelper` that asks adhd for the bearer header each
/// time Claude Code connects, so no token is ever written into
/// `~/.claude.json` or a pane's environment.
///
/// Each channel has an entry of its own (`adhd-dev`, `adhd`), so a dev build
/// never takes over the release entry.
public enum MCPRegistration {

    /// Which adhd an entry points at.
    public enum Channel: Sendable, CaseIterable {
        case dev
        case release

        /// The `mcpServers` key.
        public var serverName: String {
            switch self {
            case .dev: return "adhd-dev"
            case .release: return "adhd"
            }
        }

        /// The port adhd listens on for this channel.
        public var port: UInt16 {
            switch self {
            case .dev: return 22871
            case .release: return 22850
            }
        }

        /// The endpoint's URL.
        public var url: String { "http://127.0.0.1:\(port)\(MCPHTTPEndpoint.path)" }
    }

    /// The subcommand of adhd that prints `{"Authorization":"Bearer <token>"}`.
    public static let headersSubcommand = "mcp headers"

    /// The entry's JSON: `type`, `url` and `headersHelper`, keys sorted. The
    /// helper is a shell command line, so the path is one shell word.
    public static func entryJSON(channel: Channel, adhdPath: String) -> String {
        let entry: [String: String] = [
            "type": "http",
            "url": channel.url,
            "headersHelper": PartnerStepTemplate.shellQuoted(adhdPath) + " " + headersSubcommand
        ]
        let data = (try? JSONSerialization.data(withJSONObject: entry,
                                                options: [.sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    /// `claude mcp add-json --scope user <name> '<entry>'`, the line the
    /// user runs once.
    public static func claudeCommand(channel: Channel, adhdPath: String) -> String {
        "claude mcp add-json --scope user \(channel.serverName) "
            + PartnerStepTemplate.shellQuoted(entryJSON(channel: channel, adhdPath: adhdPath))
    }

    /// Whether `claudeConfig` (normally `~/.claude.json`) has an `mcpServers`
    /// entry named for `channel` whose `url` is the channel's.
    public static func isRegistered(claudeConfig: URL, channel: Channel) -> Bool {
        guard let data = try? Data(contentsOf: claudeConfig),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let servers = root["mcpServers"] as? [String: Any],
              let entry = servers[channel.serverName] as? [String: Any],
              let url = entry["url"] as? String else { return false }
        return url == channel.url
    }
}
