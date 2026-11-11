import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

/// The sentences a host's Integrations panel and its command-line tool both
/// show when the daemon does not answer, and the per-request deadlines.
struct MailDaemonTransportTests {
    private struct Boom: Error {}

    @Test func aTimeoutSaysTheDaemonDidNotAnswerInTime() {
        #expect(MailDaemonTransport.remoteError(for: .timedOut, daemonName: "d")
                == .remote("d did not answer within 360 s"))
        #expect(MailDaemonTransport.callTimeout == 360)
    }

    /// A sync answers when it ends, however long that takes, so it has no
    /// deadline; everything else keeps the sign-in-sized one.
    @Test func onlySyncNowWaitsWithoutADeadline() throws {
        func encoded(_ request: MailRequest) throws -> Data { try JSONEncoder().encode(request) }
        #expect(MailDaemonTransport.timeout(for: try encoded(.syncNow(account: nil))) == nil)
        #expect(MailDaemonTransport.timeout(for: try encoded(.syncNow(account: "a@example.com"))) == nil)
        #expect(MailDaemonTransport.timeout(for: try encoded(.signIn)) == 360)
        #expect(MailDaemonTransport.timeout(for: try encoded(.listAccounts)) == 360)
        #expect(MailDaemonTransport.timeout(for: Data("not a request".utf8)) == 360)
    }

    @Test func aRefusedConnectionSaysTheDaemonCannotBeReached() {
        #expect(MailDaemonTransport.remoteError(for: .connectionDropped, daemonName: "d")
                == .remote("cannot reach d: the connection was refused or dropped "
                           + "(is d running, and signed by the same team as this tool?)"))
    }

    @Test func everyOtherFailureSaysTheDaemonCannotBeReached() {
        #expect(MailDaemonTransport.remoteError(for: .unreachable("nope"), daemonName: "d")
                == .remote("cannot reach d: nope"))
    }

    @Test func aFailedCallIsClassifiedReportedAndNotRetried() async {
        final class Count: @unchecked Sendable { var calls = 0, seen = 0 }
        let count = Count()
        await #expect(throws: MailClientError.remote("d did not answer within 360 s")) {
            _ = try await MailDaemonTransport.send(
                Data("x".utf8), daemonName: "d",
                call: { _, _ in count.calls += 1; throw Boom() },
                classify: { _ in .timedOut },
                onFailure: { _ in count.seen += 1 })
        }
        #expect(count.calls == 1)
        #expect(count.seen == 1)
    }

    @Test func anEmptyReplyIsAnError() async {
        await #expect(throws: MailClientError.remote("d dropped the reply")) {
            _ = try await MailDaemonTransport.send(
                Data("x".utf8), daemonName: "d", call: { _, _ in Data() }, classify: { _ in .timedOut })
        }
    }
}
