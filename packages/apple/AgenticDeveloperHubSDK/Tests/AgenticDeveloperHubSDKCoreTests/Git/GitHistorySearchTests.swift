import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// git-views-012.
@Suite("GitHistorySearch")
struct GitHistorySearchTests {

    private static func query(author: String? = nil, grep: String? = nil, pickaxe: String? = nil) -> GitLogQuery {
        var query = GitLogQuery()
        query.author = author
        query.messageGrep = grep
        query.pickaxe = pickaxe
        return query
    }

    @Test("empty or blank text is the unfiltered default query")
    func empty() {
        #expect(GitHistorySearch.parse("") == GitLogQuery())
        #expect(GitHistorySearch.parse("  \n\t") == GitLogQuery())
        #expect(GitHistorySearch.shaPrefix("") == nil)
    }

    @Test("plain text greps messages, trimmed, whole")
    func plainText() {
        #expect(GitHistorySearch.parse("fix bug") == Self.query(grep: "fix bug"))
        #expect(GitHistorySearch.parse("  fix: the bug  ") == Self.query(grep: "fix: the bug"))
        #expect(GitHistorySearch.shaPrefix("fix bug") == nil)
    }

    @Test("author: filters by author, prefix in any case, value trimmed")
    func author() {
        #expect(GitHistorySearch.parse("author:Ann") == Self.query(author: "Ann"))
        #expect(GitHistorySearch.parse("AUTHOR: Ann Lee ") == Self.query(author: "Ann Lee"))
        #expect(GitHistorySearch.shaPrefix("author:Ann") == nil)
    }

    @Test("sha: leaves the log unfiltered and yields the lowercased prefix")
    func sha() {
        #expect(GitHistorySearch.parse("sha:AbC12") == GitLogQuery())
        #expect(GitHistorySearch.parse("SHA: abc12") == GitLogQuery())
        #expect(GitHistorySearch.shaPrefix("sha:AbC12") == "abc12")
        #expect(GitHistorySearch.shaPrefix(" Sha: abc12 ") == "abc12")
    }

    @Test("-S with or without a space is a pickaxe search")
    func pickaxe() {
        #expect(GitHistorySearch.parse("-S needle") == Self.query(pickaxe: "needle"))
        #expect(GitHistorySearch.parse("-Sneedle") == Self.query(pickaxe: "needle"))
        #expect(GitHistorySearch.parse("-S two words") == Self.query(pickaxe: "two words"))
        #expect(GitHistorySearch.shaPrefix("-S needle") == nil)
    }

    @Test("a prefix with nothing after it is no filter")
    func emptyValues() {
        #expect(GitHistorySearch.parse("author:") == GitLogQuery())
        #expect(GitHistorySearch.parse("author:   ") == GitLogQuery())
        #expect(GitHistorySearch.parse("sha:") == GitLogQuery())
        #expect(GitHistorySearch.shaPrefix("sha:") == nil)
        #expect(GitHistorySearch.parse("-S") == GitLogQuery())
        #expect(GitHistorySearch.parse("-S  ") == GitLogQuery())
    }

    @Test("a lowercase -s is plain text, not a pickaxe")
    func lowercaseDashS() {
        #expect(GitHistorySearch.parse("-s x") == Self.query(grep: "-s x"))
    }
}
