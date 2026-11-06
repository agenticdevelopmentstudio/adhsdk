import XCTest
@testable import AgenticDeveloperHubSDKCore

final class GitIgnoreMatcherTests: XCTestCase {

    private func excluded(_ patterns: [String], _ path: String, directory: Bool = false) -> Bool {
        GitIgnoreMatcher(patterns: patterns).isExcluded(relativePath: path, isDirectory: directory)
    }

    func testEmptyMatcherExcludesNothing() {
        XCTAssertTrue(GitIgnoreMatcher.empty.isEmpty)
        XCTAssertFalse(excluded([], "anything"))
    }

    func testBlankLinesAndCommentsAreIgnored() {
        let matcher = GitIgnoreMatcher(patterns: ["", "   ", "# *.log"])
        XCTAssertTrue(matcher.isEmpty)
        XCTAssertFalse(matcher.isExcluded(relativePath: "a.log", isDirectory: false))
    }

    func testUnanchoredNameMatchesAtAnyDepth() {
        XCTAssertTrue(excluded(["*.log"], "a.log"))
        XCTAssertTrue(excluded(["*.log"], "deep/er/a.log"))
        XCTAssertFalse(excluded(["*.log"], "a.log.txt"))
        XCTAssertTrue(excluded(["node_modules"], "web/node_modules", directory: true))
        XCTAssertTrue(excluded([".DS_Store"], "x/.DS_Store"))
    }

    func testTrailingSlashMatchesDirectoriesOnly() {
        XCTAssertTrue(excluded(["build/"], "build", directory: true))
        XCTAssertTrue(excluded(["build/"], "app/build", directory: true))
        XCTAssertFalse(excluded(["build/"], "build", directory: false))
    }

    func testSlashAnchorsToTheRoot() {
        XCTAssertTrue(excluded(["/dist"], "dist", directory: true))
        XCTAssertFalse(excluded(["/dist"], "app/dist", directory: true))
        XCTAssertTrue(excluded(["docs/*.pdf"], "docs/a.pdf"))
        XCTAssertFalse(excluded(["docs/*.pdf"], "x/docs/a.pdf"))
        XCTAssertFalse(excluded(["docs/*.pdf"], "docs/sub/a.pdf"))
    }

    func testDoubleStar() {
        XCTAssertTrue(excluded(["**/logs"], "logs", directory: true))
        XCTAssertTrue(excluded(["**/logs"], "a/b/logs", directory: true))
        XCTAssertTrue(excluded(["out/**"], "out/a/b.txt"))
        XCTAssertFalse(excluded(["out/**"], "out", directory: true))
        XCTAssertTrue(excluded(["a/**/b"], "a/b"))
        XCTAssertTrue(excluded(["a/**/b"], "a/x/y/b"))
    }

    func testQuestionMarkAndCharacterClasses() {
        XCTAssertTrue(excluded(["file?.txt"], "file1.txt"))
        XCTAssertFalse(excluded(["file?.txt"], "file10.txt"))
        XCTAssertTrue(excluded(["*.[oa]"], "lib.a"))
        XCTAssertFalse(excluded(["*.[oa]"], "lib.c"))
        XCTAssertTrue(excluded(["*.[!oa]"], "lib.c"))
        XCTAssertFalse(excluded(["*.[!oa]"], "lib.o"))
    }

    func testNegationAndLastMatchWins() {
        let patterns = ["*.log", "!keep.log"]
        XCTAssertTrue(excluded(patterns, "a.log"))
        XCTAssertFalse(excluded(patterns, "keep.log"))
        XCTAssertTrue(excluded(["!keep.log", "*.log"], "keep.log"))
    }

    func testRegexCharactersAreLiteral() {
        XCTAssertTrue(excluded(["a+b(1).txt"], "a+b(1).txt"))
        XCTAssertFalse(excluded(["a.txt"], "abtxt"))
        XCTAssertTrue(excluded(["\\#hash"], "#hash"))
        XCTAssertTrue(excluded(["\\!bang"], "!bang"))
    }

    func testMatchingIsCaseSensitive() {
        XCTAssertFalse(excluded(["*.LOG"], "a.log"))
    }
}
