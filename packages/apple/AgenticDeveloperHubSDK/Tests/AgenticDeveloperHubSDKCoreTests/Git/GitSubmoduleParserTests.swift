import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitSubmodule.parse")
struct GitSubmoduleParserTests {
    @Test("the state prefix maps to current, modified, uninitialized and conflicted")
    func parsesStates() {
        let output = " 1234 path (v1)\n+5678 other\n-9abc new\nUdef0 c\n"
        #expect(GitSubmodule.parse(status: output) == [
            GitSubmodule(path: "path", id: "1234", state: .current),
            GitSubmodule(path: "other", id: "5678", state: .modified),
            GitSubmodule(path: "new", id: "9abc", state: .uninitialized),
            GitSubmodule(path: "c", id: "def0", state: .conflicted)
        ])
    }

    @Test("a path with a space survives, with or without a describe suffix")
    func pathWithSpace() {
        let output = " 1234 my lib (heads/main)\n-5678 new dir\n"
        #expect(GitSubmodule.parse(status: output).map(\.path) == ["my lib", "new dir"])
    }

    @Test("blank and malformed lines are ignored")
    func ignoresJunk() {
        #expect(GitSubmodule.parse(status: "\n\n?zzz path\n+nopath\n").isEmpty)
    }
}
