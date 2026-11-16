import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `GitSignature.parse(log:)` over hand-written `%H<US>%G?<US>%GS<US>%GK<RS>` output
/// (recipe `foundation/git/git-client`, "Signatures").
@Suite("GitSignature")
struct GitSignatureTests {
    private static func sha(_ prefix: String) -> String {
        prefix + String(repeating: "0", count: 40 - prefix.count)
    }

    private static func record(_ sha: String, _ status: String, _ signer: String = "", _ key: String = "") -> String {
        "\(sha)\u{1F}\(status)\u{1F}\(signer)\u{1F}\(key)\u{1E}\n"
    }

    @Test("all eight statuses parse from git's letters")
    func allStatuses() {
        let letters: [(String, GitSignatureStatus)] = [
            ("G", .good), ("B", .bad), ("U", .unknownValidity), ("X", .expired),
            ("Y", .expiredKey), ("R", .revokedKey), ("E", .cannotCheck), ("N", .unsigned)
        ]
        let output = letters.enumerated().map { index, pair in
            Self.record(Self.sha("a\(index)"), pair.0, "Signer \(index)", "KEY\(index)")
        }.joined()
        let parsed = GitSignature.parse(log: output)
        #expect(parsed.count == 8)
        for (index, pair) in letters.enumerated() {
            let signature = parsed[Self.sha("a\(index)")]
            #expect(signature?.status == pair.1)
            #expect(signature?.signer == "Signer \(index)")
            #expect(signature?.key == "KEY\(index)")
        }
        #expect(GitSignatureStatus.allRawValues == ["G", "B", "U", "X", "Y", "R", "E", "N"])
    }

    @Test("an unsigned commit has no signer or key; an unknown letter reads as cannot check")
    func emptyFieldsAndUnknownLetter() {
        let output = Self.record(Self.sha("aa"), "N") + Self.record(Self.sha("bb"), "Q", "Ann")
        let parsed = GitSignature.parse(log: output)
        #expect(parsed[Self.sha("aa")] == GitSignature(status: .unsigned, signer: nil, key: nil))
        #expect(parsed[Self.sha("bb")] == GitSignature(status: .cannotCheck, signer: "Ann", key: nil))
    }

    @Test("empty output and a truncated record parse to nothing")
    func emptyAndTruncated() {
        #expect(GitSignature.parse(log: "").isEmpty)
        #expect(GitSignature.parse(log: "\n").isEmpty)
        #expect(GitSignature.parse(log: "\(Self.sha("aa"))\u{1E}\n").isEmpty)
    }

    @Test("the summary names the status and the signer")
    func summary() {
        #expect(GitSignature(status: .good, signer: "Ann").summary == "Good signature by Ann")
        #expect(GitSignature(status: .cannotCheck).summary == "Signature cannot be checked")
    }
}

private extension GitSignatureStatus {
    static var allRawValues: [String] {
        [GitSignatureStatus.good, .bad, .unknownValidity, .expired, .expiredKey, .revokedKey, .cannotCheck, .unsigned]
            .map(\.rawValue)
    }
}
