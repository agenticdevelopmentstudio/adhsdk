import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
@Suite("GitCommitDetailViewController signature")
struct GitCommitDetailSignatureTests {
    private static let date = Date(timeIntervalSince1970: 1_800_000_000)

    private static func commit(_ id: String) -> GitCommit {
        let person = GitPerson(name: "Ann Lee", email: "ann@example.com", date: date)
        return GitCommit(id: id, parents: [], author: person, committer: person, subject: "subject", body: "")
    }

    private static func detail() -> GitCommitDetailViewController {
        let detail = GitCommitDetailViewController(source: GitViewsFakeContentSource(),
                                                   pasteboard: NSPasteboard(name: .init("git.signature.\(UUID())")))
        detail.loadViewIfNeeded()
        return detail
    }

    @Test("the Signature line shows the status and signer, beside the author and committer")
    func signedLine() {
        let detail = Self.detail()
        detail.signatureLookup = { commit in
            commit.id == "c1" ? GitSignature(status: .good, signer: "Ann Lee", key: "SHA256:abc") : nil
        }
        detail.show(commit: Self.commit("c1"))
        let row = detail.signatureRow
        #expect(!row.isHidden)
        #expect(row.accessibilityIdentifier() == "git.commit.signature")
        #expect(row.caption.stringValue == "Signature")
        #expect(row.textLabel.stringValue == "Good signature by Ann Lee")
        #expect(row.symbolView.symbolName == "checkmark.seal")
        #expect(row.accessibilityLabel() == "Signature: Good signature by Ann Lee")

        let arranged = detail.headerStack.arrangedSubviews
        let committer = arranged.firstIndex { $0 === detail.committerRow }
        let signature = arranged.firstIndex { $0 === row }
        let sessions = arranged.firstIndex { $0 === detail.agentSessionsView }
        #expect(committer.map { $0 + 1 } == signature)
        #expect(signature.flatMap { index in sessions.map { index < $0 } } == true)
    }

    @Test("hidden without a lookup, for an unsigned commit, and for one not checked yet")
    func hidden() {
        let detail = Self.detail()
        detail.show(commit: Self.commit("c1"))
        #expect(detail.signatureRow.isHidden)
        detail.signatureLookup = { _ in GitSignature(status: .unsigned) }
        #expect(detail.signatureRow.isHidden)
        detail.signatureLookup = { _ in nil }
        #expect(detail.signatureRow.isHidden)
    }

    @Test("reloadSignature reads the lookup again, so a signature that lands shows")
    func reloadShowsLanded() {
        let detail = Self.detail()
        var landed: GitSignature?
        detail.signatureLookup = { _ in landed }
        detail.show(commit: Self.commit("c1"))
        #expect(detail.signatureRow.isHidden)
        landed = GitSignature(status: .bad, signer: "Bo")
        detail.reloadSignature()
        #expect(!detail.signatureRow.isHidden)
        #expect(detail.signatureRow.textLabel.stringValue == "Bad signature by Bo")
        #expect(detail.signatureRow.symbolView.symbolName == "exclamationmark.triangle")
    }
}
