import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

/// `MailRequest.isMailboxAccess` is what a host gates its non-UI clients on, so it must cover
/// every request the command line and MCP tools send, and nothing that administers the
/// integration.
struct MailRequestAccessTests {
    /// Records each request a client sends, answering with an empty but well-formed reply.
    private final class Sent: @unchecked Sendable {
        private let lock = NSLock()
        private var requests: [MailRequest] = []
        func add(_ request: MailRequest) { lock.withLock { requests.append(request) } }
        var all: [MailRequest] { lock.withLock { requests } }
    }

    private func recordingClient(_ sent: Sent) -> MailClient {
        MailClient { data in
            let request = try JSONDecoder().decode(MailRequest.self, from: data)
            sent.add(request)
            let response: MailResponse
            switch request {
            case .listAccounts: response = .accounts([])
            case .listLabels: response = .labels([])
            case .getMessage: response = .failure("none")
            default: response = .messages(MailMessagePage(messages: [], nextCursor: nil))
            }
            return try JSONEncoder().encode(response)
        }
    }

    @Test func everyCommandLineRequestIsMailboxAccess() async {
        let sent = Sent()
        let client = recordingClient(sent)
        for args in [["accounts"], ["labels", "a"], ["list", "a"], ["get", "a", "1"],
                     ["label", "add", "a", "L", "1"], ["label", "remove", "a", "L", "1"]] {
            _ = await MailCommandLine.run(args, client: client, stdout: { _ in }, stderr: { _ in })
        }
        #expect(sent.all.count == 6)
        #expect(sent.all.allSatisfy { $0.isMailboxAccess })
    }

    @Test func administrationIsNot() {
        let administration: [MailRequest] = [
            .providerStatus, .importOAuthClient(json: Data()), .removeProvider, .signIn, .cancelSignIn,
            .removeAccount(account: "a"), .updateSettings(account: "a", settings: .default),
            .syncNow(account: nil)
        ]
        #expect(administration.allSatisfy { !$0.isMailboxAccess })
    }
}
