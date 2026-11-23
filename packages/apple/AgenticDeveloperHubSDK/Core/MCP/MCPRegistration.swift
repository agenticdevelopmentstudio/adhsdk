import Foundation

/// How a Claude Code install learns about adhd's MCP endpoint: one
/// `claude mcp add-json` the user runs once, naming the channel's fixed
/// address and a `headersHelper` that asks adhd for the bearer header each
/// time Claude Code connects, so no token is ever written into
/// `~/.claude.json` or a pane's environment.
///
/// Each channel has an entry of its own (`adhd-dev`, `adhd`), so a dev build
/// never takes over the release entry.
///
/// In Core, not macOS, so adhd itself prints the same line (`adhd mcp
/// command`) that a pane shows. adh-daemon's installer writes the same entry
/// into `~/.claude.json` from Python (`tools/daemon_install/claude_json.py`),
/// and the three agree byte for byte: keys sorted, no spaces, slashes
/// unescaped, and the path quoted by ``shellQuoted(_:)``'s rule.
public enum MCPRegistration {

    /// The one path adhd serves MCP on.
    public static let path = "/mcp"

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
        public var url: String { MCPRegistration.url(port: port) }
    }

    /// The subcommand of adhd that prints `{"Authorization":"Bearer <token>"}`.
    public static let headersSubcommand = "mcp headers"

    /// `http://127.0.0.1:<port>/mcp`.
    public static func url(port: UInt16) -> String {
        "http://127.0.0.1:\(port)\(path)"
    }

    /// The `headersHelper` command line: the path as one shell word, then
    /// ``headersSubcommand``.
    public static func headersHelper(adhdPath: String) -> String {
        shellQuoted(adhdPath) + " " + headersSubcommand
    }

    /// The entry's JSON: `type`, `url` and `headersHelper`, keys sorted. The
    /// helper is a shell command line, so the path is one shell word.
    public static func entryJSON(channel: Channel, adhdPath: String) -> String {
        entryJSON(port: channel.port, adhdPath: adhdPath)
    }

    /// The entry's JSON for an adhd on `port`.
    public static func entryJSON(port: UInt16, adhdPath: String) -> String {
        let entry: [String: String] = [
            "type": "http",
            "url": url(port: port),
            "headersHelper": headersHelper(adhdPath: adhdPath)
        ]
        let data = (try? JSONSerialization.data(withJSONObject: entry,
                                                options: [.sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return String(bytes: data, encoding: .utf8) ?? ""
    }

    /// `claude mcp add-json --scope user <name> '<entry>'`, the line the
    /// user runs once.
    public static func claudeCommand(channel: Channel, adhdPath: String) -> String {
        claudeCommand(serverName: channel.serverName, port: channel.port, adhdPath: adhdPath)
    }

    /// The same line for an entry named `serverName` on `port`.
    public static func claudeCommand(serverName: String, port: UInt16, adhdPath: String) -> String {
        "claude mcp add-json --scope user \(serverName) "
            + shellQuoted(entryJSON(port: port, adhdPath: adhdPath))
    }

    /// `value` as one POSIX shell word: as it is when every character is a
    /// plain word character, otherwise single-quoted with each `'` written
    /// `'\''`. `PartnerStepTemplate.shellQuoted`'s rule, which the installer's
    /// Python copy matches.
    public static func shellQuoted(_ value: String) -> String {
        PartnerStepTemplate.shellQuoted(value)
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
