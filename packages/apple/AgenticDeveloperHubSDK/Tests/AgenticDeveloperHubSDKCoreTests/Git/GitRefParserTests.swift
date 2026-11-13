import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitRef.parse")
struct GitRefParserTests {
    private static func line(
        _ fullName: String, short: String = "", object: String = "obj", peeled: String = "",
        upstream: String = "", track: String = "", head: String = " "
    ) -> String {
        [fullName, short, object, peeled, upstream, track, head].joined(separator: "\u{1F}")
    }

    @Test("the format string is the documented one")
    func format() {
        let expected = "%(refname)%1f%(refname:short)%1f%(objectname)%1f%(*objectname)%1f"
            + "%(upstream:short)%1f%(upstream:track,nobracket)%1f%(HEAD)"
        #expect(GitRef.forEachRefFormat == expected)
    }

    @Test("a checked-out local branch with tracking")
    func localBranchWithTracking() throws {
        let output = Self.line("refs/heads/main", short: "main", object: "abc",
                               upstream: "origin/main", track: "ahead 2, behind 1", head: "*") + "\n"
        let ref = try #require(GitRef.parse(forEachRef: output).first)
        #expect(ref.kind == .localBranch)
        #expect(ref.fullName == "refs/heads/main")
        #expect(ref.id == "refs/heads/main")
        #expect(ref.name == "main")
        #expect(ref.target == "abc")
        #expect(ref.upstream == "origin/main")
        #expect(ref.isHead)
        #expect(ref.ahead == 2)
        #expect(ref.behind == 1)
        #expect(ref.remote == nil)
    }

    @Test("a gone upstream is 0/0 and the upstream is kept")
    func goneUpstream() throws {
        let output = Self.line("refs/heads/old", upstream: "origin/old", track: "gone")
        let ref = try #require(GitRef.parse(forEachRef: output).first)
        #expect(ref.upstream == "origin/old")
        #expect(ref.ahead == 0)
        #expect(ref.behind == 0)
        #expect(!ref.isHead)
    }

    @Test("an annotated tag targets the peeled commit, a lightweight tag its own object")
    func tagsPeel() {
        let output = Self.line("refs/tags/v1", object: "tagobj", peeled: "commit1") + "\n"
            + Self.line("refs/tags/v2", object: "commit2") + "\n"
        let refs = GitRef.parse(forEachRef: output)
        #expect(refs.map(\.kind) == [.tag, .tag])
        #expect(refs.map(\.name) == ["v1", "v2"])
        #expect(refs.map(\.target) == ["commit1", "commit2"])
    }

    @Test("a remote branch names its remote; remote HEAD and refs/stash are dropped")
    func remotesAndDrops() throws {
        let output = Self.line("refs/remotes/origin/HEAD", short: "origin") + "\n"
            + Self.line("refs/stash", short: "stash") + "\n"
            + Self.line("refs/remotes/origin/feature/x", short: "origin/feature/x") + "\n"
        let refs = GitRef.parse(forEachRef: output)
        #expect(refs.count == 1)
        let ref = try #require(refs.first)
        #expect(ref.kind == .remoteBranch)
        #expect(ref.name == "origin/feature/x")
        #expect(ref.remote == "origin")
    }

    @Test("a non-ASCII branch name with a space survives")
    func unusualName() throws {
        let output = Self.line("refs/heads/feature/ü x", short: "feature/ü x")
        let ref = try #require(GitRef.parse(forEachRef: output).first)
        #expect(ref.name == "feature/ü x")
    }

    @Test("blank lines and short lines are ignored")
    func ignoresJunk() {
        #expect(GitRef.parse(forEachRef: "\n\nrefs/heads/x\n").isEmpty)
    }
}
