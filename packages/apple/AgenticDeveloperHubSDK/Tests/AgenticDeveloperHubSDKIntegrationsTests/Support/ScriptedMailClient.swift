import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

/// A `MailClient` whose transport answers a scripted `MailResponse` and records each request.
final class ScriptedMail: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [MailRequest] = []
    let response: MailResponse

    init(_ response: MailResponse) { self.response = response }

    var requests: [MailRequest] { lock.withLock { recorded } }

    var client: MailClient {
        MailClient { data in
            let request = try JSONDecoder().decode(MailRequest.self, from: data)
            self.lock.withLock { self.recorded.append(request) }
            return try JSONEncoder().encode(self.response)
        }
    }

    static func message(labelNames: [String] = ["Inbox", "Work"]) -> MailMessage {
        MailMessage(
            id: "m1", gmailId: "g1", threadId: "t1", account: "me@example.com", from: "a@example.com",
            to: ["me@example.com"], cc: [], labels: ["INBOX"], labelNames: labelNames, subject: "Hello",
            snippet: "snip", date: "2026-01-02T03:04:05.000Z", mailClass: .filed, bodyText: "body",
            bodyHtml: nil, attachments: [])
    }
}

/// Collects what a command line prints.
final class Output: @unchecked Sendable {
    private let lock = NSLock()
    private var out: [String] = []
    private var err: [String] = []

    var stdout: [String] { lock.withLock { out } }
    var stderr: [String] { lock.withLock { err } }
    func writeOut(_ text: String) { lock.withLock { out.append(text) } }
    func writeErr(_ text: String) { lock.withLock { err.append(text) } }
}

/// The expected `--json` / MCP text for a value: pretty-printed, keys sorted.
func expectedJSON<Value: Encodable>(_ value: Value) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try #require(String(bytes: try encoder.encode(value), encoding: .utf8))
}
