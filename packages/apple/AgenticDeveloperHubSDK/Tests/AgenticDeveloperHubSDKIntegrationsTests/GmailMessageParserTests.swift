import Foundation
import Testing
@testable import AgenticDeveloperHubSDKIntegrations

enum GmailFixture {
    static func data(_ name: String) throws -> Data {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        return try Data(contentsOf: dir.appendingPathComponent("gmail-\(name).json"))
    }

    static func message(_ name: String) throws -> GmailMessageDTO {
        try JSONDecoder().decode(GmailMessageDTO.self, from: data(name))
    }
}

@Suite struct GmailMessageParserTests {
    private func parsed(_ fixture: String) throws -> EmailMessage {
        GmailMessageParser.parse(try GmailFixture.message(fixture), connectionId: "c1", existingId: nil)
    }

    @Test func parsesPlainAndHtmlFromNestedAlternative() throws {
        let msg = try parsed("message-multipart")
        #expect(msg.bodyText == "Hello plain")
        #expect(msg.bodyHtml == "<b>Hi</b>")
        #expect(msg.attachments == [EmailAttachmentRef(attachmentId: "att1", filename: "a.pdf",
                                                       mimeType: "application/pdf", size: 1234)])
        #expect(msg.fromAddress == "Jane <j@x.com>")
        #expect(msg.subject == "Hi")
        #expect(msg.mailClass == .filed)
        #expect(msg.externalId == "m1")
    }

    @Test func parsesHtmlOnly() throws {
        let msg = try parsed("message-html-only")
        #expect(msg.bodyText == nil)
        #expect(msg.bodyHtml == "<p>x</p>")
        #expect(msg.mailClass == .trash)
    }

    @Test func decodesLatin1Charset() throws {
        let msg = try parsed("message-latin1")
        // C3 A9 is valid UTF-8 ("e-acute"); only the declared charset makes it "A-tilde, copyright".
        #expect(msg.bodyText == "\u{C3}\u{A9}")
    }

    @Test func decodesWindows1252Charset() throws {
        let msg = try parsed("message-windows1252")
        #expect(msg.bodyText == "\u{20AC}")
    }

    @Test func decodesQuotedMixedCaseCharsetParameter() throws {
        let msg = try parsed("message-quoted-charset")
        #expect(msg.bodyText == "\u{C3}\u{A9}")
    }

    @Test func splitsAddressListsRespectingQuotes() throws {
        let msg = try parsed("message-multipart")
        #expect(msg.toAddresses == ["\"Doe, Jane\" <j@x.com>", "b@y.com"])
        #expect(msg.ccAddresses.isEmpty)
    }

    @Test func internalDateConvertsToISO() throws {
        let msg = try parsed("message-multipart")
        #expect(msg.internalDate == "2024-11-05T09:46:40.000Z")
    }

    @Test func keepsExistingIdElseGeneratesOne() throws {
        let dto = try GmailFixture.message("message-multipart")
        #expect(GmailMessageParser.parse(dto, connectionId: "c", existingId: "keep").id == "keep")
        #expect(!GmailMessageParser.parse(dto, connectionId: "c", existingId: nil).id.isEmpty)
    }

    // MARK: - GmailQuery

    private let now = Date(timeIntervalSince1970: 1_730_800_000)

    @Test func fullSyncQueryDefault() {
        let result = GmailQuery.fullSync(settings: .default, now: now)
        let after = 1_730_800_000 - 30 * 86_400
        #expect(result.query == "after:\(after) {in:inbox in:sent in:drafts is:starred has:userlabels}")
        #expect(result.includeSpamTrash == false)
    }

    @Test func fullSyncQueryWithSpamAndTrash() {
        let settings = MailSyncSettings(includeSpam: true, includeTrash: true, windowDays: 1)
        let result = GmailQuery.fullSync(settings: settings, now: now)
        #expect(result.query == "after:\(1_730_800_000 - 86_400) "
            + "{in:inbox in:sent in:drafts is:starred has:userlabels in:spam in:trash}")
        #expect(result.includeSpamTrash)
    }

    @Test func fullSyncQueryArchivedDropsClassFilter() {
        let settings = MailSyncSettings(includeArchived: true, includeSpam: true, windowDays: 2)
        let result = GmailQuery.fullSync(settings: settings, now: now)
        #expect(result.query == "after:\(1_730_800_000 - 2 * 86_400)")
        #expect(result.includeSpamTrash)
    }
}
