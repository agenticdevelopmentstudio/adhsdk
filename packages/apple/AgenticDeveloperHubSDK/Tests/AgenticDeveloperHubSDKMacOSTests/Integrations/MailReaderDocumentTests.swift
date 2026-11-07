import Foundation
import Testing
import AgenticDeveloperHubSDKIntegrations
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
struct MailReaderDocumentTests {
    private static func html(_ body: String) -> MailMessage {
        var message = MailMessage.fixture(id: "m1")
        message.bodyHtml = body
        return message
    }

    @Test func aBlockedDocumentOpensWithAPolicyThatAllowsNothingRemote() {
        let document = MailReaderViewController.document(
            for: Self.html("<html><body><img src=\"https://t.example.com/open.gif\"></body></html>"),
            blockingRemote: true)
        #expect(document.hasPrefix("<meta http-equiv=\"Content-Security-Policy\""))
        #expect(document.contains("default-src 'none'"))
        #expect(!document.contains("https:;") && !document.contains("img-src *"))
    }

    @Test func loadingRemoteImagesDropsThePolicy() {
        let body = "<html><body>hi</body></html>"
        #expect(MailReaderViewController.document(for: Self.html(body), blockingRemote: false) == body)
    }

    @Test func aTextBodyIsEscaped() {
        var message = MailMessage.fixture(id: "m1")
        message.bodyText = "<script>alert(1)</script> & co"
        let document = MailReaderViewController.document(for: message, blockingRemote: true)
        #expect(document.contains("&lt;script&gt;alert(1)&lt;/script&gt; &amp; co"))
        #expect(!document.contains("<script>"))
    }
}
