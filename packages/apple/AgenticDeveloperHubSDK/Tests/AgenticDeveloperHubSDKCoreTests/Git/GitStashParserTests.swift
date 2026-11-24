import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitStash.parse")
struct GitStashParserTests {
    @Test("the format string is the documented one")
    func format() {
        #expect(GitStash.listFormat == "%gd%x1f%H%x1f%ct%x1f%gs")
    }

    @Test("parses -z records into index, sha, date and message")
    func parsesList() {
        let output = ["stash@{0}", "aaa", "1700000000", "WIP on main: abc subject"].joined(separator: "\u{1F}")
            + "\0"
            + ["stash@{12}", "bbb", "1700000100", "On dev: keep"].joined(separator: "\u{1F}")
            + "\0"
        let stashes = GitStash.parse(list: output)
        #expect(stashes == [
            GitStash(index: 0, id: "aaa", message: "WIP on main: abc subject",
                     date: Date(timeIntervalSince1970: 1_700_000_000)),
            GitStash(index: 12, id: "bbb", message: "On dev: keep",
                     date: Date(timeIntervalSince1970: 1_700_000_100))
        ])
    }

    @Test("malformed records are dropped")
    func dropsMalformed() {
        let output = "nonsense\0" + ["stash@{x}", "a", "1", "m"].joined(separator: "\u{1F}") + "\0"
        #expect(GitStash.parse(list: output).isEmpty)
        #expect(GitStash.parse(list: "").isEmpty)
    }
}
