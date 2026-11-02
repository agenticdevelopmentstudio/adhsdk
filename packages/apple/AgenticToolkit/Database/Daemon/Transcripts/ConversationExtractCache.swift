#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Foundation

/// `ConversationExtractor` results, remembered by event-store message.
///
/// The Conversations window re-reads its whole feed on every poll, and each read
/// parses up to `limit × 12` messages' `attrs` JSON — tens of KB apiece — to
/// find the few hundred that are conversation. Almost all of them are the same
/// messages the previous poll parsed: ~1 of every 20 sampled daemon seconds went
/// to re-parsing them while the window was open. `messages` rows are
/// insert-only (`ON CONFLICT DO NOTHING`), so a message's parse never goes
/// stale; the text and attrs lengths ride along in the key only so a rowid
/// reused after retention can't be served another message's lines.
///
/// The bounded, lock-guarded store is the toolkit's `LRUCache`; what stays
/// here is the key and the extractor. Its eviction is O(n) — about 15 µs per
/// miss at 12,000 entries, well under the JSON parse every miss already pays.
public final class ConversationExtractCache: Sendable {
    private struct Key: Hashable, Sendable {
        let messageId: Int64
        let textLength: Int
        let attrsLength: Int
    }

    private let cache: LRUCache<Key, [ConversationExtractor.Line]>

    public init(capacity: Int = 12_000) {
        cache = LRUCache(capacity: capacity)
    }

    public var capacity: Int { cache.capacity }

    /// The lines of one message — see ``ConversationExtractor/extract(role:text:attrsJSON:)``.
    public func lines(messageId: Int64, role: String, text: String, attrsJSON: String) -> [ConversationExtractor.Line] {
        let key = Key(messageId: messageId, textLength: text.utf8.count, attrsLength: attrsJSON.utf8.count)
        if let hit = cache.value(for: key) { return hit }
        // Parsed outside any lock: concurrent feed reads must not queue behind
        // one another's JSON.
        let parsed = ConversationExtractor.extract(role: role, text: text, attrsJSON: attrsJSON)
        cache.set(parsed, for: key)
        return parsed
    }

    /// Entries held — for tests.
    public var count: Int { cache.count }
}
#endif
