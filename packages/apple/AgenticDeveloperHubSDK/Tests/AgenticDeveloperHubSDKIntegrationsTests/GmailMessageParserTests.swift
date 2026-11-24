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

    @Test func parsesANonEmptyCcList() {
        let dto = GmailMessageDTO(id: "m", threadId: "t", internalDate: "0", payload: GmailPart(headers: [
            GmailHeader(name: "cc", value: "\"Roe, Ann\" <a@x.com>, b@y.com")
        ]))
        let msg = GmailMessageParser.parse(dto, connectionId: "c", existingId: nil)
        #expect(msg.ccAddresses == ["\"Roe, Ann\" <a@x.com>", "b@y.com"])
    }

    @Test func aNamedTextPartWithoutAnAttachmentIdIsNotTheBody() {
        let named = GmailPart(mimeType: "text/plain", filename: "notes.txt",
                              body: GmailBody(data: "bm90ZXM"))
        let body = GmailPart(mimeType: "text/plain", body: GmailBody(data: "Ym9keQ"))
        let dto = GmailMessageDTO(id: "m", threadId: "t", internalDate: "0",
                                  payload: GmailPart(mimeType: "multipart/mixed", parts: [named, body]))
        let msg = GmailMessageParser.parse(dto, connectionId: "c", existingId: nil)
        #expect(msg.bodyText == "body")
        #expect(msg.attachments.isEmpty)
    }

    @Test func aMessageWhoseOnlyContentIsAnUnnamedEmbeddedMessageShowsItsBody() {
        let inner = GmailPart(mimeType: "multipart/alternative", parts: [
            GmailPart(mimeType: "text/plain", body: GmailBody(data: "aW5uZXI")),
            GmailPart(mimeType: "text/html", body: GmailBody(data: "PGI-aW5uZXI8L2I-"))
        ])
        let dto = GmailMessageDTO(id: "m", threadId: "t", internalDate: "0", payload: GmailPart(
            mimeType: "multipart/mixed", parts: [GmailPart(mimeType: "message/rfc822", parts: [inner])]))
        let msg = GmailMessageParser.parse(dto, connectionId: "c", existingId: nil)
        #expect(msg.bodyText == "inner")
        #expect(msg.bodyHtml == "<b>inner</b>")
    }

    @Test func anEmbeddedMessageIsNotMergedIntoAnOuterBody() {
        let embedded = GmailPart(mimeType: "message/rfc822", parts: [
            GmailPart(mimeType: "text/plain", body: GmailBody(data: "aW5uZXI")),
            GmailPart(mimeType: "text/html", body: GmailBody(data: "PGI-aW5uZXI8L2I-"))
        ])
        let outer = GmailPart(mimeType: "text/plain", body: GmailBody(data: "Ym9keQ"))
        let dto = GmailMessageDTO(id: "m", threadId: "t", internalDate: "0",
                                  payload: GmailPart(mimeType: "multipart/mixed", parts: [outer, embedded]))
        let msg = GmailMessageParser.parse(dto, connectionId: "c", existingId: nil)
        #expect(msg.bodyText == "body")
        #expect(msg.bodyHtml == nil)
    }

    @Test func aNamedPartInsideAnEmbeddedMessageNeverBecomesTheBody() {
        let named = GmailPart(mimeType: "text/plain", filename: "n.txt", body: GmailBody(data: "bm90ZXM"))
        let dto = GmailMessageDTO(id: "m", threadId: "t", internalDate: "0", payload: GmailPart(
            mimeType: "multipart/mixed", parts: [GmailPart(mimeType: "message/rfc822", parts: [named])]))
        let msg = GmailMessageParser.parse(dto, connectionId: "c", existingId: nil)
        #expect(msg.bodyText == nil)
    }

    @Test func missingInternalDateFallsBackToTheDateHeader() {
        let dto = GmailMessageDTO(id: "m", threadId: "t", payload: GmailPart(headers: [
            GmailHeader(name: "Date", value: "Tue, 05 Nov 2024 09:46:40 +0000")
        ]))
        let msg = GmailMessageParser.parse(dto, connectionId: "c", existingId: nil,
                                           now: Date(timeIntervalSince1970: 1_793_000_000))
        #expect(msg.internalDate == "2024-11-05T09:46:40.000Z")
    }

    @Test func missingInternalDateAndDateHeaderFallsBackToNowNotTheEpoch() {
        let now = Date(timeIntervalSince1970: 1_793_000_000)
        let dto = GmailMessageDTO(id: "m", threadId: "t", internalDate: "not-a-number",
                                  payload: GmailPart(headers: [GmailHeader(name: "Date", value: "garbage")]))
        let msg = GmailMessageParser.parse(dto, connectionId: "c", existingId: nil, now: now)
        #expect(msg.internalDate == IntegrationClock.string(from: now))
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
