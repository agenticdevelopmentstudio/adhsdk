import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
private final class LFSWorkingCopySource: GitWorkingCopyDataSource {
    var staged: [GitFileChange] = []
    var unstaged: [GitFileChange] = []
    var conflicts: [String: GitConflictKind] = [:]
    var lfs: GitLFSState?
}

/// Git LFS in the Git window's views (recipe `workspace/git/git-views`, "LFS"): a pointer
/// diff's summary row, the working copy's badge and the Fetch menu's LFS items.
@Suite("Git LFS views")
@MainActor
struct GitLFSViewsTests {

    private static let oldOID = "4d7a214614ab2935c943f9e0ff69d22eadbb8f32b1258daaa5e2ca24d17e2393"
    private static let newOID = String(repeating: "b", count: 64)

    private static func pointerDiff(path: String = "a.bin") -> GitDiff {
        let hunk = GitDiffHunk(oldStart: 1, oldCount: 3, newStart: 1, newCount: 3, section: "", lines: [
            GitDiffFixtures.context("version https://git-lfs.github.com/spec/v1", 1, 1),
            GitDiffFixtures.removed("oid sha256:\(oldOID)", 2),
            GitDiffFixtures.removed("size 2048", 3),
            GitDiffFixtures.added("oid sha256:\(newOID)", 2),
            GitDiffFixtures.added("size 4096", 3)
        ])
        return GitDiff(files: [GitFileDiff(oldPath: path, newPath: path, change: .modified, isBinary: false,
                                           hunks: [hunk])])
    }

    @Test("a pointer diff shows one summary row instead of the pointer text")
    func pointerDiffRow() async {
        let source = GitViewsFakeContentSource()
        source.diffs["unstaged"] = Self.pointerDiff()
        let controller = GitDiffViewController(source: source, coloring: nil,
                                               settings: UserSettings(with: InMemorySettingsStorageProvider()))
        controller.loadViewIfNeeded()

        controller.show(target: .unstaged(paths: ["a.bin"]), file: "a.bin")
        await controller.loadTask?.value

        let oldSize = ByteCountFormatter.string(fromByteCount: 2048, countStyle: .file)
        let newSize = ByteCountFormatter.string(fromByteCount: 4096, countStyle: .file)
        #expect(controller.lfsLabel.accessibilityIdentifier() == "git.diff.lfs")
        #expect(!controller.lfsLabel.isHidden)
        #expect(controller.lfsLabel.stringValue == "LFS object 4d7a214 · \(oldSize) → bbbbbbb · \(newSize)")
        #expect(controller.inlineViewer.dataSource == nil || controller.inlineViewer.dataSource?.rowCount == 0)
    }

    @Test("an ordinary diff hides the LFS row")
    func ordinaryDiffHidesRow() async {
        let source = GitViewsFakeContentSource()
        source.diffs["unstaged"] = GitDiff(files: [GitDiffFixtures.twoHunks()])
        let controller = GitDiffViewController(source: source, coloring: nil,
                                               settings: UserSettings(with: InMemorySettingsStorageProvider()))
        controller.loadViewIfNeeded()

        controller.show(target: .unstaged(paths: ["a.swift"]), file: "a.swift")
        await controller.loadTask?.value

        #expect(controller.lfsLabel.isHidden)
        #expect((controller.inlineViewer.dataSource?.rowCount ?? 0) > 0)
    }

    @Test("a path stored in LFS gets the badge in the working copy; others do not")
    func workingCopyBadge() throws {
        let source = LFSWorkingCopySource()
        source.unstaged = [GitFileChange(path: "art/cover.psd", status: .modified),
                           GitFileChange(path: "README.md", status: .modified)]
        source.lfs = GitLFSState(isInstalled: true, trackedPatterns: ["*.psd"], files: [:])
        let workingCopy = GitWorkingCopyViewController(source: source)
        workingCopy.loadViewIfNeeded()
        workingCopy.reload()

        let list = workingCopy.unstagedList
        let tracked = try #require(list.tableView(list.tableView, viewFor: nil, row: 0) as? GitFileListCellView)
        let plain = try #require(list.tableView(list.tableView, viewFor: nil, row: 1) as? GitFileListCellView)
        #expect(tracked.lfsBadge.accessibilityIdentifier() == "git.workingCopy.lfsBadge")
        #expect(tracked.lfsBadge.toolTip == "Stored in Git LFS")
        #expect(tracked.lfsBadge.isAccessibilityElement())
        #expect(tracked.lfsBadge.accessibilityLabel() == "Stored in Git LFS")
        #expect(tracked.lfsBadge.symbolName == "externaldrive")
        #expect(!tracked.lfsBadge.isHidden)
        #expect(plain.lfsBadge.isHidden)
    }

    @Test("a repository not using LFS badges nothing")
    func noBadgeWithoutLFS() throws {
        let source = LFSWorkingCopySource()
        source.unstaged = [GitFileChange(path: "art/cover.psd", status: .modified)]
        source.lfs = GitLFSState(isInstalled: false, trackedPatterns: ["*.psd"], files: [:])
        let workingCopy = GitWorkingCopyViewController(source: source)
        workingCopy.loadViewIfNeeded()
        workingCopy.reload()

        let list = workingCopy.unstagedList
        let cell = try #require(list.tableView(list.tableView, viewFor: nil, row: 0) as? GitFileListCellView)
        #expect(cell.lfsBadge.isHidden)
    }

    @Test("the Fetch menu has the LFS items only while LFS is in use")
    func fetchMenuItems() {
        let toolbar = GitWindowToolbar()
        let lfsIDs = ["git.toolbar.lfsFetch", "git.toolbar.lfsPull"]

        let plain = toolbar.fetchMenu(lfsInUse: false).items.compactMap { $0.identifier?.rawValue }
        #expect(lfsIDs.allSatisfy { !plain.contains($0) })

        let menu = toolbar.fetchMenu(lfsInUse: true)
        let inUse = menu.items.compactMap { $0.identifier?.rawValue }
        #expect(lfsIDs.allSatisfy { inUse.contains($0) })
        #expect(menu.items.map(\.title) == ["Fetch", "Fetch LFS Objects", "Pull LFS Objects"])
        #expect(menu.items.allSatisfy { $0.target === toolbar })
    }

    @Test("the toolbar's items are the same whether or not LFS is in use")
    func toolbarItemsUnchanged() {
        let identifiers = GitWindowToolbar().items.compactMap { item -> String? in
            guard case let .targetedButton(identifier, _, _, _, _) = item else { return nil }
            return identifier.rawValue
        }
        #expect(!identifiers.contains("git.toolbar.lfsFetch"))
        #expect(!identifiers.contains("git.toolbar.lfsPull"))
        #expect(identifiers.contains("git.toolbar.fetch"))
    }

    @Test("a .gitattributes change reloads the refs, which re-reads the LFS state")
    func gitattributesReloadsRefs() {
        #expect(GitRepositoryWatcher.classify(relativePath: ".gitattributes") == [.workingCopy, .refs])
        #expect(GitRepositoryWatcher.classify(relativePath: "assets/.gitattributes") == [.workingCopy, .refs])
        #expect(GitRepositoryWatcher.classify(relativePath: "README.md") == [.workingCopy])
    }

    @Test("the repository's info/attributes reloads the refs too; the rest of info does not")
    func infoAttributesReloadsRefs() {
        #expect(GitRepositoryWatcher.classify(relativePath: ".git/info/attributes") == [.refs])
        #expect(GitRepositoryWatcher.classify(relativePath: ".git/info/exclude") == [])
        #expect(GitRepositoryWatcher.classify(relativePath: ".git/info/attributes.lock") == [])
    }
}
