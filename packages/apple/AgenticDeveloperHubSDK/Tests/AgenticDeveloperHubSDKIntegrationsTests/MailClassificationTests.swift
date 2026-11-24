import Testing
import Foundation
@testable import AgenticDeveloperHubSDKIntegrations

@Suite("MailClassification")
struct MailClassificationTests {

    @Test("labels map to the expected class", arguments: [
        (["INBOX", "UNREAD"], MailClass.filed),
        (["SENT"], .filed),
        (["DRAFT"], .filed),
        (["STARRED", "CATEGORY_PROMOTIONS"], .filed),
        (["Label_123"], .filed),
        (["CATEGORY_PROMOTIONS", "UNREAD", "IMPORTANT"], .archived),
        ([], .archived),
        (["SPAM", "INBOX"], .spam),
        (["TRASH", "SPAM"], .trash),
        (["TRASH", "Label_9"], .trash)
    ] as [([String], MailClass)])
    func classifies(labels: [String], expected: MailClass) {
        #expect(MailClassifier.classify(labelIds: labels) == expected)
    }
}
