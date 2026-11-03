#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// `ConversationExtractor` results, remembered by event-store message (the
/// merged feed) or by transcript line and filters (one session's read).
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
        /// The two sources number their rows independently, so each keeps its
        /// own case: a transcript line and an event-store message with the same
        /// id are different things.
        enum Source: Hashable, Sendable {
            /// A `transcript_lines` row read with the given filters.
            case transcriptLine(lineId: Int, rawLength: Int, includeSidechains: Bool, includeScripted: Bool)
            /// An event-store `messages` row.
            case message(messageId: Int64, textLength: Int, attrsLength: Int)
        }

        let source: Source
    }

    private let cache: LRUCache<Key, [ConversationExtractor.Line]>

    public init(capacity: Int = 12_000) {
        cache = LRUCache(capacity: capacity)
    }

    public var capacity: Int { cache.capacity }

    /// The lines of one transcript line — see
    /// ``ConversationExtractor/extract(rawJSON:includeSidechains:includeScripted:)``.
    public func lines(
        lineId: Int, rawJSON: String, includeSidechains: Bool = false, includeScripted: Bool = false
    ) -> [ConversationExtractor.Line] {
        let key = Key(source: .transcriptLine(
            lineId: lineId, rawLength: rawJSON.utf8.count,
            includeSidechains: includeSidechains, includeScripted: includeScripted))
        return cached(key) {
            ConversationExtractor.extract(
                rawJSON: rawJSON, includeSidechains: includeSidechains, includeScripted: includeScripted)
        }
    }

    /// The lines of one message — see ``ConversationExtractor/extract(role:text:attrsJSON:)``.
    public func lines(messageId: Int64, role: String, text: String, attrsJSON: String) -> [ConversationExtractor.Line] {
        let key = Key(source: .message(
            messageId: messageId, textLength: text.utf8.count, attrsLength: attrsJSON.utf8.count))
        return cached(key) {
            ConversationExtractor.extract(role: role, text: text, attrsJSON: attrsJSON)
        }
    }

    private func cached(
        _ key: Key, parse: () -> [ConversationExtractor.Line]
    ) -> [ConversationExtractor.Line] {
        if let hit = cache.value(for: key) { return hit }
        // Parsed outside any lock: concurrent feed reads must not queue behind
        // one another's JSON.
        let parsed = parse()
        cache.set(parsed, for: key)
        return parsed
    }

    /// Entries held — for tests.
    public var count: Int { cache.count }
}
#endif
