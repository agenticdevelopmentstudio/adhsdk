import XCTest
@testable import AgenticDeveloperHubSDKCore

final class ConversationEntryDTOConformanceTests: XCTestCase {

    private func entry(kind: String, termProgram: String = "") -> ConversationEntryDTO {
        ConversationEntryDTO(
            id: 7000, sessionId: "s1", kind: kind, text: "hello", timestamp: "2026-09-01T10:00:00Z",
            projectName: "proj", gitBranch: "main", sessionName: "name", termProgram: termProgram)
    }

    private func json(termProgram: String?, includeBranch: Bool = true) -> Data {
        var parts = [
            #""id":7000"#, #""sessionId":"s1""#, #""kind":"reply""#, #""text":"hi""#,
            #""timestamp":"2026-09-01T10:00:00Z""#, #""projectName":"proj""#,
            #""sessionName":"name""#
        ]
        if includeBranch { parts.append(#""gitBranch":"main""#) }
        if let termProgram { parts.append("\"termProgram\":\(termProgram)") }
        return Data("{\(parts.joined(separator: ","))}".utf8)
    }

    func testV001_promptIsFromUser() {
        XCTAssertTrue(entry(kind: "prompt").isFromUser)
    }

    func testV002_replyIsNotFromUser() {
        XCTAssertFalse(entry(kind: "reply").isFromUser)
    }

    func testV003_progressAndThinkingAreWorkOutput() {
        XCTAssertTrue(entry(kind: "progress").isWorkOutput)
        XCTAssertTrue(entry(kind: "thinking").isWorkOutput)
        XCTAssertEqual(ConversationEntryDTO.workOutputKinds, ["progress", "thinking"])
    }

    func testV004_otherKindsAreNotWorkOutput() {
        for kind in ["prompt", "reply", "notice"] {
            XCTAssertFalse(entry(kind: kind).isWorkOutput, kind)
        }
    }

    func testV005_missingTermProgramDecodesAsEmpty() throws {
        let decoded = try JSONDecoder().decode(ConversationEntryDTO.self, from: json(termProgram: nil))
        XCTAssertEqual(decoded.termProgram, "")
        XCTAssertEqual(decoded.gitBranch, "main")
    }

    func testV006_missingGitBranchThrowsKeyNotFound() {
        let data = json(termProgram: nil, includeBranch: false)
        XCTAssertThrowsError(try JSONDecoder().decode(ConversationEntryDTO.self, from: data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "gitBranch")
        }
    }

    func testV007_roundTripKeepsTermProgram() throws {
        let original = entry(kind: "reply", termProgram: "iTerm.app")
        let decoded = try JSONDecoder().decode(
            ConversationEntryDTO.self, from: try JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.termProgram, "iTerm.app")
    }

    func testV008_initializerDefaultsTermProgramToEmpty() {
        XCTAssertEqual(entry(kind: "reply").termProgram, "")
    }

    func testV009_rowIdentityIsComputedByTheDaemon() throws {
        throw XCTSkip("Daemon behavior (ConversationStore id = row id * 1000 + offset); see ConversationFeedTests")
    }

    func testV010_daemonExtractorKindsReadSharedList() throws {
        throw XCTSkip("ConversationExtractor lives in the daemon target, not Core")
    }

    func testV011_nullTermProgramDecodesAsEmpty() throws {
        let decoded = try JSONDecoder().decode(ConversationEntryDTO.self, from: json(termProgram: "null"))
        XCTAssertEqual(decoded.termProgram, "")
    }
}
