import AppKit
import AgenticDeveloperHubSDKCore

extension GitWorkingCopyViewController {
    /// Re-reads the source's LFS state into the three lists, which badge each path stored
    /// in Git LFS (recipe `workspace/git/git-views`, "LFS"); a repository not using LFS
    /// badges none. `reload()` calls it, and so does a refs change, which is when the
    /// model reloads LFS.
    public func reloadLFS() {
        let tracked: ((String) -> Bool)? = source.lfs.flatMap { lfs in lfs.isInUse ? lfs.isTracked : nil }
        for list in [conflictsList, stagedList, unstagedList] { list.isLFSTracked = tracked }
    }
}
