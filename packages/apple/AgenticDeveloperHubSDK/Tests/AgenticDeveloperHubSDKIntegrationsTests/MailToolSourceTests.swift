import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

struct MailToolSourceTests {
    private func call(
        _ source: MailToolSource, _ name: String, _ json: String
    ) async -> (content: String, isError: Bool) {
        await source.callTool(name: name, argumentsJSON: Data(json.utf8))
    }

    @Test func listsFiveTools() async {
        let source = MailToolSource(client: ScriptedMail(.ok).client)
        let names = await source.toolDefinitions().map(\.name)
        #expect(names == [
            "mail_list_accounts", "mail_list_labels", "mail_list_messages", "mail_get_message",
            "mail_modify_labels"
        ])
    }

    @Test func listMessagesMapsArguments() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil)))
        let source = MailToolSource(client: mail.client)
        let result = await call(source, "mail_list_messages", """
            {"account":"me@example.com","since":"2026-01-01","until":"2026-01-31T10:00:00Z",
             "labels":["Work","INBOX"],"limit":25,"cursor":"50","include_bodies":true}
            """)
        #expect(!result.isError)
        #expect(mail.requests == [.listMessages(MailMessageFilter(
            account: "me@example.com", since: "2026-01-01T00:00:00.000Z", until: "2026-01-31T10:00:00.000Z",
            labels: ["Work", "INBOX"], limit: 25, cursor: "50", includeBodies: true))])
    }

    @Test func resultsArePrettySortedJSON() async throws {
        let message = ScriptedMail.message()
        let mail = ScriptedMail(.message(message))
        let result = await call(MailToolSource(client: mail.client), "mail_get_message",
                                #"{"account":"a","id":"m1"}"#)
        #expect(!result.isError)
        #expect(result.content == (try expectedJSON(message)))
        // `account` is declared after `id`, so only sorting puts it first.
        let account = try #require(result.content.range(of: "\"account\""))
        let id = try #require(result.content.range(of: "\"id\""))
        #expect(account.lowerBound < id.lowerBound)
    }

    @Test func badArgumentTypesAreErrors() async {
        let cases = [
            #"{"account":"a","limit":0}"#, #"{"account":"a","limit":true}"#,
            #"{"account":"a","limit":2.5}"#, #"{"account":"a","limit":"5"}"#,
            #"{"account":"a","since":"yesterday"}"#, #"{"account":"a","until":"2026-02-30"}"#,
            #"{"account":"a","since":20260101}"#, #"{"account":"a","until":true}"#,
            #"{"account":"a","cursor":5}"#, #"{"account":"a","include_bodies":"yes"}"#
        ]
        for json in cases {
            let mail = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil)))
            let result = await call(MailToolSource(client: mail.client), "mail_list_messages", json)
            #expect(result.isError, "\(json)")
            #expect(mail.requests.isEmpty, "\(json)")
        }
    }

    @Test func badLimitMessage() async {
        let result = await call(MailToolSource(client: ScriptedMail(.ok).client), "mail_list_messages",
                                #"{"account":"a","limit":true}"#)
        #expect(result.content == "limit must be a positive integer")
    }

    @Test func timestampsAreConvertedToUTC() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil)))
        _ = await call(MailToolSource(client: mail.client), "mail_list_messages",
                       #"{"account":"a","since":"2026-01-02T03:00:00+02:00"}"#)
        guard case .listMessages(let filter)? = mail.requests.first else {
            Issue.record("no request")
            return
        }
        #expect(filter.since == "2026-01-02T01:00:00.000Z")
    }

    @Test func missingArgumentIsError() async {
        let mail = ScriptedMail(.ok)
        let result = await call(MailToolSource(client: mail.client), "mail_list_labels", "{}")
        #expect(result.isError)
        #expect(result.content == "missing required argument: account")
        #expect(mail.requests.isEmpty)
    }

    @Test func modifyRequiresAddOrRemove() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [], nextCursor: nil)))
        let result = await call(MailToolSource(client: mail.client), "mail_modify_labels",
                                #"{"account":"a","message_ids":["m1"]}"#)
        #expect(result.isError)
        #expect(mail.requests.isEmpty)
    }

    @Test func modifyMapsArguments() async {
        let mail = ScriptedMail(.messages(MailMessagePage(messages: [ScriptedMail.message()], nextCursor: nil)))
        let result = await call(MailToolSource(client: mail.client), "mail_modify_labels",
                                #"{"account":"a","message_ids":["m1","m2"],"add":["Work"]}"#)
        #expect(!result.isError)
        #expect(mail.requests == [.modifyLabels(account: "a", messageIds: ["m1", "m2"], add: ["Work"], remove: [])])
    }

    @Test func toolErrorSurfacesRemoteFailure() async {
        let mail = ScriptedMail(.failure("unknown label: Nope"))
        let result = await call(MailToolSource(client: mail.client), "mail_list_accounts", "{}")
        #expect(result.isError)
        #expect(result.content == "unknown label: Nope")
    }
}
