import XCTest
@testable import AgenticToolkitDatabase

final class ConversationExtractCacheTests: XCTestCase {

    private func lines(_ cache: ConversationExtractCache, _ id: Int64, _ text: String) -> [ConversationExtractor.Line] {
        cache.lines(messageId: id, role: "user", text: text, attrsJSON: "{}")
    }

    func testExtractCacheReturnsWhatTheExtractorReturns() {
        let cache = ConversationExtractCache()

        XCTAssertEqual(lines(cache, 1, "hello there"),
                       ConversationExtractor.extract(role: "user", text: "hello there", attrsJSON: "{}"))
        XCTAssertEqual(lines(cache, 1, "hello there").first?.text, "hello there")
        XCTAssertEqual(cache.lines(messageId: 2, role: "assistant", text: "", attrsJSON: "{not json"), [])
    }

    func testExtractCacheNeverServesAReusedIdAnotherMessagesText() {
        let cache = ConversationExtractCache()
        _ = lines(cache, 7, "first")

        let reused = lines(cache, 7, "a different line")

        XCTAssertEqual(reused.first?.text, "a different line")
    }

    func testExtractCacheStaysBoundedAndKeepsWhatIsStillRead() {
        let cache = ConversationExtractCache(capacity: 4)
        _ = lines(cache, 0, "hot")
        for id in 1...20 {
            _ = lines(cache, Int64(id), "line \(id)")
            _ = lines(cache, 0, "hot")   // a poll keeps reading it
        }

        XCTAssertLessThanOrEqual(cache.count, 4, "never more than `capacity`")
        XCTAssertEqual(lines(cache, 0, "hot").first?.text, "hot")
    }
}
