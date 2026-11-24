import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("Partner review conformance") struct PartnerReviewConformanceTests {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeReview(state: PartnerReviewState = .queued, supersededBy: [String] = []) -> PartnerReview {
        PartnerReview(id: "r", repoID: "repo", repoPath: "/r", repoName: "demo", sha: "abc", parent: "p",
                      branch: "main", subject: "s", author: "a", committedAt: date, state: state,
                      supersededBy: supersededBy)
    }
    private func fullReview() -> PartnerReview {
        PartnerReview(id: "r1", repoID: "repo", repoPath: "/r", repoName: "demo", sha: "abc", parent: "p",
                      branch: "main", subject: "s", author: "a", committedAt: date, state: .done,
                      sessionID: "s", startedAt: date, finishedAt: date.addingTimeInterval(5), summary: "x",
                      skipReason: "y", supersededBy: ["s2"])
    }
    private func jsonObject(_ review: PartnerReview) throws -> [String: Any] {
        let data = try JSONEncoder().encode(review)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("V1: initializer defaults") func v1InitializerDefaults() {
        let review = makeReview()
        #expect(review.state == .queued)
        #expect(review.sessionID == nil && review.startedAt == nil && review.finishedAt == nil)
        #expect(review.summary == nil && review.skipReason == nil)
        #expect(review.supersededBy.isEmpty)
    }
    @Test("V2: states encode to their names") func v2StateStrings() throws {
        let states: [PartnerReviewState] = [.queued, .running, .done, .failed, .skipped]
        let encoded = try states.map { String(bytes: try JSONEncoder().encode($0), encoding: .utf8) }
        #expect(encoded == ["\"queued\"", "\"running\"", "\"done\"", "\"failed\"", "\"skipped\""])
    }
    @Test("V3: unknown state string fails to decode") func v3UnknownStateThrows() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PartnerReviewState.self, from: Data("\"cancelled\"".utf8))
        }
    }
    @Test("V4: nil optionals are omitted and round-trip") func v4OptionalsOmitted() throws {
        let review = makeReview()
        let object = try jsonObject(review)
        for key in ["sessionID", "startedAt", "finishedAt", "summary", "skipReason"] {
            #expect(object[key] == nil)
        }
        let decoded = try JSONDecoder().decode(PartnerReview.self, from: JSONEncoder().encode(review))
        #expect(decoded == review)
    }
    @Test("V5: missing supersededBy fails to decode") func v5MissingSupersededByThrows() throws {
        var object = try jsonObject(makeReview())
        object.removeValue(forKey: "supersededBy")
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PartnerReview.self, from: data) }
    }
    @Test("V6: reviews differing only in summary are not equal") func v6SummaryBreaksEquality() {
        var other = makeReview()
        other.summary = "x"
        #expect(makeReview() != other)
    }
    @Test("V7: Identifiable identity is id") func v7Identity() {
        var review = makeReview()
        review.id = "r1"
        func identity<T: Identifiable>(_ value: T) -> T.ID { value.id }
        #expect(identity(review) == "r1")
    }
    @Test("V8: no lifecycle rules are enforced") func v8NoLifecycleRules() {
        var review = makeReview(state: .done)
        review.skipReason = "x"
        #expect(review.state == .done && review.startedAt == nil && review.skipReason == "x")
    }
    @Test("V9: PartnerReviewStart round-trips") func v9StartRoundTrip() throws {
        let step = PartnerJobStep(name: "open", environment: .terminal, command: "echo", condition: "")
        let start = PartnerReviewStart(review: makeReview(), worktreePath: "/w", fixBranch: "fix/x", tipDiff: "d",
                                       steps: [step])
        let decoded = try JSONDecoder().decode(PartnerReviewStart.self, from: JSONEncoder().encode(start))
        #expect(decoded == start)
    }
    @Test("V10: supersededBy keeps its order") func v10SupersededByOrder() throws {
        let review = makeReview(supersededBy: ["s2", "s3"])
        let decoded = try JSONDecoder().decode(PartnerReview.self, from: JSONEncoder().encode(review))
        #expect(decoded.supersededBy == ["s2", "s3"])
    }
    @Test("V11: every field reads back") func v11FieldsReadBack() {
        let review = PartnerReview(id: "i", repoID: "rid", repoPath: "/p", repoName: "n", sha: "sh", parent: "pa",
                                   branch: "b", subject: "su", author: "au", committedAt: date, state: .running,
                                   supersededBy: ["z"])
        #expect(review.id == "i" && review.repoID == "rid" && review.repoPath == "/p" && review.repoName == "n")
        #expect(review.sha == "sh" && review.parent == "pa" && review.branch == "b" && review.subject == "su")
        #expect(review.author == "au" && review.committedAt == date && review.state == .running)
        #expect(review.supersededBy == ["z"])
    }
    @Test("V12: optional fields round-trip") func v12OptionalFieldsRoundTrip() throws {
        let finished = date.addingTimeInterval(5)
        let decoded = try JSONDecoder().decode(PartnerReview.self, from: JSONEncoder().encode(fullReview()))
        #expect(decoded.sessionID == "s" && decoded.startedAt == date && decoded.finishedAt == finished)
        #expect(decoded.summary == "x" && decoded.skipReason == "y")
    }
    @Test("V13: coding keys equal property names") func v13CodingKeys() throws {
        let keys = Set(try jsonObject(fullReview()).keys)
        #expect(keys == ["id", "repoID", "repoPath", "repoName", "sha", "parent", "branch", "subject", "author",
                         "committedAt", "state", "sessionID", "startedAt", "finishedAt", "summary", "skipReason",
                         "supersededBy"])
    }
    @Test("V14: whole review with unknown state fails to decode") func v14UnknownStateInReviewThrows() throws {
        var object = try jsonObject(fullReview())
        object["state"] = "cancelled"
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(PartnerReview.self, from: data) }
    }
    @Test("V15: identical field values are equal") func v15Equality() {
        #expect(makeReview() == makeReview())
        #expect(fullReview() == fullReview())
    }
}
