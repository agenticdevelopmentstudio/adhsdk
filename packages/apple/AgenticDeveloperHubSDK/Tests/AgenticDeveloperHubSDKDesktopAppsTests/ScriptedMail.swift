import Foundation
import AgenticDeveloperHubSDKIntegrations

/// A `MailClient` that answers every request with one scripted response and records each request.
///
/// Local to this bundle: sharing an existing fake by path put one file reference in two Xcode
/// groups, which Xcode refuses to open. Built on the public `MailClient` transport only.
final class ScriptedMail: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [MailRequest] = []
    private let response: MailResponse

    init(_ response: MailResponse) { self.response = response }

    var requests: [MailRequest] { lock.withLock { recorded } }

    var client: MailClient {
        MailClient { data in
            let request = try JSONDecoder().decode(MailRequest.self, from: data)
            self.lock.withLock { self.recorded.append(request) }
            return try JSONEncoder().encode(self.response)
        }
    }
}
