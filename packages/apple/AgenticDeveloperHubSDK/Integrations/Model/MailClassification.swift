import Foundation

/// Where a Gmail message sits, for the purposes of deciding whether to mirror it.
public enum MailClass: String, Codable, Sendable, CaseIterable {
    case filed, archived, spam, trash
}

/// Derives a `MailClass` from Gmail label ids.
///
/// Precedence: trash > spam > filed > archived. A message is filed when it has
/// `INBOX`, `SENT`, `DRAFT`, `STARRED` or any user label; attribute labels
/// (`UNREAD`, `IMPORTANT`, `CATEGORY_*`, `CHAT`) never make one filed.
public enum MailClassifier {

    /// Gmail's own label ids. `CATEGORY_*` is matched by prefix, see `isSystem`.
    public static let systemLabelIds: Set<String> = [
        "INBOX", "SENT", "DRAFT", "STARRED", "SPAM", "TRASH", "UNREAD", "IMPORTANT", "CHAT"
    ]

    private static let filingLabelIds: Set<String> = ["INBOX", "SENT", "DRAFT", "STARRED"]

    private static func isSystem(_ labelId: String) -> Bool {
        systemLabelIds.contains(labelId) || labelId.hasPrefix("CATEGORY_")
    }

    public static func classify(labelIds: [String]) -> MailClass {
        if labelIds.contains("TRASH") { return .trash }
        if labelIds.contains("SPAM") { return .spam }
        let filed = labelIds.contains { filingLabelIds.contains($0) || !isSystem($0) }
        return filed ? .filed : .archived
    }
}
