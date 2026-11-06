import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

struct MailCommandLineTests {
    private func run(_ args: [String], _ mail: ScriptedMail) async -> (code: Int32, out: Output) {
        let output = Output()
        let code = await MailCommandLine.run(
            args, client: mail.client, stdout: { output.writeOut($0) }, stderr: { output.writeErr($0) })
        return (code, output)
    }

    private func account() -> MailAccount {
        MailAccount(id: "c1", email: "me@example.com", status: .active, lastSyncAt: "2026-01-02T00:00:00.000Z",
                    lastError: nil, settings: .default)
    }

    @Test func accountsTextOutput() async {
        let (code, out) = await run(["accounts"], ScriptedMail(.accounts([account()])))
        #expect(code == 0)
        #expect(out.stdout == ["me@example.com  active  2026-01-02T00:00:00.000Z"])
    }

    @Test func listParsesDateOnlyBounds() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil)))
        let (code, _) = await run(
            ["list", "me@example.com", "--since", "2026-01-01", "--until", "2026-01-31", "--label", "Work",
             "--label", "INBOX", "--limit", "10", "--cursor", "20", "--bodies"], mail)
        #expect(code == 0)
        #expect(mail.requests == [.listMessages(MailMessageFilter(
            account: "me@example.com", since: "2026-01-01T00:00:00.000Z", until: "2026-01-31T23:59:59.999Z",
            labels: ["Work", "INBOX"], limit: 10, cursor: "20", includeBodies: true))])
    }

    @Test func listPrintsMessagesAndNextCursor() async {
        let page = MailMessagePage(messages: [ScriptedMail.message()], nextCursor: "50")
        let (code, out) = await run(["list", "a"], ScriptedMail(.messages(page)))
        #expect(code == 0)
        #expect(out.stdout == [
            "2026-01-02T03:04:05.000Z  m1  a@example.com  Hello  [Inbox, Work]\nnext cursor: 50"
        ])
    }

    @Test func labelAddBuildsModifyRequest() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [ScriptedMail.message()], nextCursor: nil)))
        let (code, _) = await run(["label", "add", "a", "Work", "m1", "m2"], mail)
        #expect(code == 0)
        #expect(mail.requests == [.modifyLabels(account: "a", messageIds: ["m1", "m2"], add: ["Work"], remove: [])])
    }

    @Test func labelRemoveBuildsModifyRequest() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil)))
        let (code, _) = await run(["label", "remove", "a", "Work", "m1"], mail)
        #expect(code == 0)
        #expect(mail.requests == [.modifyLabels(account: "a", messageIds: ["m1"], add: [], remove: ["Work"])])
    }

    @Test func labelWithoutIdsIsUsageError() async {
        let mail = ScriptedMail(.ok)
        let (code, out) = await run(["label", "add", "a", "Work"], mail)
        #expect(code == 64)
        #expect(out.stderr == [MailCommandLine.usage])
        #expect(mail.requests.isEmpty)
    }

    @Test func badLimitIsUsageError() async {
        for limit in ["0", "-3", "abc"] {
            let (code, _) = await run(["list", "a", "--limit", limit], ScriptedMail(.ok))
            #expect(code == 64)
        }
    }

    @Test func badDateIsUsageError() async {
        let (since, _) = await run(["list", "a", "--since", "yesterday"], ScriptedMail(.ok))
        let (until, _) = await run(["list", "a", "--until", "2026-13-45"], ScriptedMail(.ok))
        #expect(since == 64)
        #expect(until == 64)
    }

    @Test func unknownSubcommandReturns64() async {
        let (code, out) = await run(["frobnicate"], ScriptedMail(.ok))
        #expect(code == 64)
        #expect(out.stderr == [MailCommandLine.usage])
        let (none, _) = await run([], ScriptedMail(.ok))
        #expect(none == 64)
    }

    @Test func remoteFailureReturns1() async {
        let (code, out) = await run(["accounts"], ScriptedMail(.failure("boom")))
        #expect(code == 1)
        #expect(out.stderr == ["Error: boom"])
    }

    @Test func jsonFlagEmitsJSON() async throws {
        let (code, out) = await run(["accounts", "--json"], ScriptedMail(.accounts([account()])))
        #expect(code == 0)
        let decoded = try JSONDecoder().decode([MailAccount].self, from: Data(out.stdout[0].utf8))
        #expect(decoded == [account()])
        #expect(out.stdout[0].contains("\n"))
    }
}
