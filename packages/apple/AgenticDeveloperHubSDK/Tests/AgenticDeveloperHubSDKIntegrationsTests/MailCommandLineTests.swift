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

    @Test func listParsesAnyLabelAsItsOwnRepeatableOption() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil, appliedAnyLabels: true)))
        let (code, _) = await run(
            ["list", "a", "--any-label", "INBOX", "--label", "STARRED", "--any-label", "Job Search/00. Inbox"],
            mail)
        #expect(code == 0)
        #expect(mail.requests == [.listMessages(MailMessageFilter(
            account: "a", labels: ["STARRED"], anyLabels: ["INBOX", "Job Search/00. Inbox"]))])
    }

    @Test func anyLabelFromAServiceThatIgnoresItFailsInsteadOfListingEverything() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [ScriptedMail.message()], nextCursor: nil)))
        let (code, out) = await run(["list", "a", "--any-label", "INBOX"], mail)
        #expect(code == 1)
        #expect(out.stdout.isEmpty)
        #expect(out.stderr.joined().contains("too old to filter by any of several labels"))
    }

    @Test func usageDocumentsHowLabelFiltersCombine() {
        let usage = MailCommandLine.usage()
        #expect(usage.contains("[--label L]... [--any-label L]..."))
        #expect(usage.contains("every --label (AND)"))
        #expect(usage.contains("at least one\n  --any-label (OR)"))
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

    @Test func moveBuildsMoveRequest() async {
        let moved = MailMoveResult(message: ScriptedMail.message(), added: ["Work"], removed: ["INBOX"])
        let mail = ScriptedMail(.moved([moved]))
        let (code, _) = await run(["move", "a", "m1", "m2", "--to", "Work"], mail)
        #expect(code == 0)
        let (withFrom, _) = await run(
            ["move", "a", "--from", "INBOX", "m1", "--to", "Job Search/01. Applied", "--from", "Job Search/00. Inbox"],
            mail)
        #expect(withFrom == 0)
        #expect(mail.requests == [
            .moveMessages(account: "a", messageIds: ["m1", "m2"], destination: "Work", from: nil),
            .moveMessages(account: "a", messageIds: ["m1"], destination: "Job Search/01. Applied",
                          from: ["INBOX", "Job Search/00. Inbox"])
        ])
    }

    @Test func moveNeedsExactlyOneDestinationAndAnId() async {
        let mail = ScriptedMail(.moved([]))
        for args in [["move", "a", "m1"], ["move", "a", "m1", "--to", "X", "--to", "Y"], ["move", "a", "--to", "X"],
                     ["move", "a", "m1", "--to"], ["move", "a", "m1", "--to", "X", "--from"],
                     ["move", "a", "m1", "--to", "X", "--bogus"]] {
            let (code, out) = await run(args, mail)
            #expect(code == 64, "\(args)")
            #expect(out.stderr == [MailCommandLine.usage()], "\(args)")
        }
        #expect(mail.requests.isEmpty)
    }

    @Test func movePrintsWhatEachMessageGainedAndLost() async {
        var second = ScriptedMail.message(labelNames: ["Work"])
        second.id = "m2"
        let mail = ScriptedMail(.moved([
            MailMoveResult(message: ScriptedMail.message(labelNames: ["Work"]), added: ["Work"],
                           removed: ["INBOX", "Later"]),
            MailMoveResult(message: second, added: [], removed: [])
        ]))
        let (code, out) = await run(["move", "a", "m1", "m2", "--to", "Work"], mail)
        #expect(code == 0)
        #expect(out.stdout == [
            "2026-01-02T03:04:05.000Z  m1  a@example.com  Hello  [Work]  +Work -INBOX -Later\n"
                + "2026-01-02T03:04:05.000Z  m2  a@example.com  Hello  [Work]  (no change)"
        ])
    }

    @Test func moveJSONIsTheResults() async throws {
        let results = [MailMoveResult(message: ScriptedMail.message(), added: ["Work"], removed: ["INBOX"])]
        let (code, out) = await run(["move", "a", "m1", "--to", "Work", "--json"], ScriptedMail(.moved(results)))
        #expect(code == 0)
        #expect(out.stdout == [try expectedJSON(results)])
    }

    @Test func moveOfAnUnknownMessageExits3() async {
        let mail = ScriptedMail(.notFound("No message matches “zz”"))
        let (code, out) = await run(["move", "a", "zz", "--to", "Work"], mail)
        #expect(code == 3)
        #expect(out.stderr == ["Error: No message matches “zz”"])
    }

    @Test func labelWithoutIdsIsUsageError() async {
        let mail = ScriptedMail(.ok)
        let (code, out) = await run(["label", "add", "a", "Work"], mail)
        #expect(code == 64)
        #expect(out.stderr == [MailCommandLine.usage()])
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
        #expect(out.stderr == [MailCommandLine.usage()])
        let (none, _) = await run([], ScriptedMail(.ok))
        #expect(none == 64)
    }

    @Test func helpPrintsUsageToStdoutAndSucceeds() async {
        for args in [["--help"], ["-h"], ["help"], ["list", "--help"], ["label", "add", "-h"]] {
            let (code, out) = await run(args, ScriptedMail(.ok))
            #expect(code == 0, "\(args)")
            #expect(out.stdout == [MailCommandLine.usage()], "\(args)")
            #expect(out.stderr.isEmpty, "\(args)")
        }
    }

    @Test func usageNamesTheCommandAsTheHostSpellsIt() async {
        let output = Output()
        let code = await MailCommandLine.run(
            ["--help"], program: "temporal mail", client: ScriptedMail(.ok).client,
            stdout: { output.writeOut($0) }, stderr: { output.writeErr($0) })
        #expect(code == 0)
        let text = output.stdout.joined()
        #expect(text.hasPrefix("usage: temporal mail <command>"))
        #expect(text.contains("  temporal mail list <account>"))
        #expect(!text.contains("\n  mail "))
    }

    @Test func remoteFailureReturns1() async {
        let (code, out) = await run(["accounts"], ScriptedMail(.failure("boom")))
        #expect(code == 1)
        #expect(out.stderr == ["Error: boom"])
    }

    @Test func notFoundMessageReturnsItsOwnStatus() async {
        for args in [["get", "a", "zz"], ["label", "add", "a", "Work", "zz"], ["get", "a", "zz", "--json"]] {
            let (code, out) = await run(args, ScriptedMail(.notFound("No message matches “zz”")))
            #expect(code == MailCommandLine.notFoundStatus, "\(args)")
            #expect(code == 3, "\(args)")
            #expect(out.stderr == ["Error: No message matches “zz”"], "\(args)")
            #expect(out.stdout.isEmpty, "\(args)")
        }
    }

    @Test func usageDocumentsExitStatuses() {
        #expect(MailCommandLine.usage().contains("3 a message id matches nothing"))
    }

    @Test func jsonFlagEmitsJSON() async throws {
        let (code, out) = await run(["accounts", "--json"], ScriptedMail(.accounts([account()])))
        #expect(code == 0)
        #expect(out.stdout == [try expectedJSON([account()])])
        // `email` is declared after `id`, so only sorting puts it first.
        let text = out.stdout[0]
        let email = try #require(text.range(of: "\"email\""))
        let id = try #require(text.range(of: "\"id\""))
        #expect(email.lowerBound < id.lowerBound)
    }

    @Test func listJSONIncludesNextCursor() async throws {
        let page = MailMessagePage(messages: [ScriptedMail.message()], nextCursor: "50")
        let (code, out) = await run(["list", "a", "--json"], ScriptedMail(.messages(page)))
        #expect(code == 0)
        #expect(out.stdout == [try expectedJSON(page)])
        #expect(out.stdout[0].contains("\"nextCursor\" : \"50\""))
    }

    @Test func emptyResultsPrintNothing() async {
        let (accounts, accountsOut) = await run(["accounts"], ScriptedMail(.accounts([])))
        let (labels, labelsOut) = await run(["labels", "a"], ScriptedMail(.labels([])))
        let empty = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil)))
        let (list, listOut) = await run(["list", "a"], empty)
        #expect([accounts, labels, list] == [0, 0, 0])
        #expect(accountsOut.stdout.isEmpty && labelsOut.stdout.isEmpty && listOut.stdout.isEmpty)
    }

    @Test func emptyPageWithCursorPrintsOnlyCursor() async {
        let page = MailMessagePage(messages: [], nextCursor: "50")
        let (_, out) = await run(["list", "a"], ScriptedMail(.messages(page)))
        #expect(out.stdout == ["next cursor: 50"])
    }

    @Test func timestampsAreConvertedToUTC() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil)))
        _ = await run(["list", "a", "--since", "2026-01-02T03:00:00+02:00", "--until", "2026-01-02T03:00:00.250Z"],
                      mail)
        #expect(mail.requests == [.listMessages(MailMessageFilter(
            account: "a", since: "2026-01-02T01:00:00.000Z", until: "2026-01-02T03:00:00.250Z"))])
    }

    @Test func impossibleDateIsUsageError() async {
        let (code, _) = await run(["list", "a", "--since", "2026-02-30"], ScriptedMail(.ok))
        #expect(code == 64)
    }

    @Test func labelsTextOutput() async {
        let labels = [
            MailLabel(id: "Label_1", name: "Work", type: "user", parentName: nil, messagesTotal: 3,
                      messagesUnread: 1),
            MailLabel(id: "INBOX", name: "INBOX", type: "system", parentName: nil, messagesTotal: nil,
                      messagesUnread: nil)
        ]
        let (code, out) = await run(["labels", "a"], ScriptedMail(.labels(labels)))
        #expect(code == 0)
        #expect(out.stdout == ["Work  Label_1  user\nINBOX  INBOX  system"])
    }

    @Test func getTextOutput() async {
        let (code, out) = await run(["get", "a", "m1"], ScriptedMail(.message(ScriptedMail.message())))
        #expect(code == 0)
        #expect(out.stdout == [
            "From: a@example.com\nTo: me@example.com\nDate: 2026-01-02T03:04:05.000Z\nSubject: Hello\n"
                + "Labels: Inbox, Work\n\nbody"
        ])
    }

    @Test func getTextFallsBackToSnippet() async {
        var message = ScriptedMail.message()
        message.bodyText = nil
        let (_, out) = await run(["get", "a", "m1"], ScriptedMail(.message(message)))
        #expect(out.stdout[0].hasSuffix("\n\nsnip"))
    }

    @Test func getTextReadsHTMLWhenThereIsNoBodyText() async {
        var message = ScriptedMail.message()
        message.bodyText = nil
        message.bodyHtml = "<style>x{}</style><p>Dear Mike,</p><p>It&#39;s a match.</p>"
        let (_, out) = await run(["get", "a", "m1"], ScriptedMail(.message(message)))
        #expect(out.stdout[0].hasSuffix("\n\nDear Mike,\n\nIt's a match."))
    }

    @Test func unknownOptionIsUsageError() async {
        let mail = ScriptedMail(.ok)
        let (code, out) = await run(["list", "a", "--bogus"], mail)
        #expect(code == 64)
        #expect(out.stderr == [MailCommandLine.usage()])
        let (accounts, _) = await run(["accounts", "--limit", "5"], mail)
        #expect(accounts == 64)
        #expect(mail.requests.isEmpty)
    }

    @Test func optionMissingValueIsUsageError() async {
        for option in ["--since", "--until", "--label", "--any-label", "--limit", "--cursor"] {
            let (code, _) = await run(["list", "a", option], ScriptedMail(.ok))
            #expect(code == 64, "\(option)")
        }
    }
}
