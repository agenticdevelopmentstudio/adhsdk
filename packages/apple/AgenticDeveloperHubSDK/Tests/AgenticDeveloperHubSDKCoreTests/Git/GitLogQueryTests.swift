import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitLogQuery.arguments")
struct GitLogQueryTests {
    @Test("defaults: date order, the log format, paging and every ref, with no path separator")
    func defaults() {
        let arguments = GitLogQuery().arguments()
        #expect(arguments.contains("--date-order"))
        #expect(arguments.contains("--format=" + GitCommit.logFormat))
        #expect(arguments.contains("--max-count=500"))
        #expect(arguments.contains("--skip=0"))
        #expect(arguments.contains("--no-color"))
        #expect(arguments.contains("--no-show-signature"))
        #expect(Array(arguments.suffix(4)) == ["--branches", "--tags", "--remotes", "HEAD"])
        #expect(!arguments.contains("--"))
        #expect(!arguments.contains("-z"))
    }

    @Test("a path without follow keeps the revisions before the separator")
    func pathWithoutFollow() {
        var query = GitLogQuery()
        query.path = "a b.txt"
        #expect(Array(query.arguments().suffix(6)) == ["--branches", "--tags", "--remotes", "HEAD", "--", "a b.txt"])
    }

    @Test("following renames ends with --follow -- <path> and drops the revisions")
    func followRenames() {
        var query = GitLogQuery()
        query.path = "a b.txt"
        query.followRenames = true
        query.limit = 50
        query.skip = 100
        let arguments = query.arguments()
        #expect(Array(arguments.suffix(3)) == ["--follow", "--", "a b.txt"])
        #expect(!arguments.contains("--branches"))
        #expect(!arguments.contains("HEAD"))
        #expect(arguments.contains("--max-count=50"))
        #expect(arguments.contains("--skip=100"))
    }

    @Test("author, message search and pickaxe map to flags")
    func filters() {
        var query = GitLogQuery()
        query.author = "Ada"
        query.messageGrep = "fix bug"
        query.pickaxe = "needle text"
        let arguments = query.arguments()
        #expect(arguments.contains("--author=Ada"))
        #expect(arguments.contains("--grep=fix bug"))
        #expect(arguments.contains("--regexp-ignore-case"))
        #expect(arguments.contains("-Sneedle text"))
    }

    @Test("unset filters add no flags")
    func noFilters() {
        let arguments = GitLogQuery().arguments()
        #expect(!arguments.contains { $0.hasPrefix("--author") || $0.hasPrefix("--grep") || $0.hasPrefix("-S") })
        #expect(!arguments.contains("--regexp-ignore-case"))
    }
}
