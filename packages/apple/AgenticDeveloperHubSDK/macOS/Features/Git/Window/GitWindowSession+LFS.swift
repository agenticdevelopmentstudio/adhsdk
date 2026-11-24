import AppKit
import AgenticDeveloperHubSDKCore

/// The Git window's LFS verbs (recipe `workspace/git/git-views`, "LFS"): offered in
/// the Fetch menu while the repository uses LFS. Neither confirms; both are long-running
/// writes, run through `perform(_:)` like every other verb.
extension GitWindowSession {

    /// Whether the repository uses Git LFS, as last loaded with the refs.
    var usesLFS: Bool { model.lfs?.isInUse == true }

    /// `git lfs fetch`: downloads the checkout's LFS objects without touching the working tree.
    func lfsFetch() { perform(.lfsFetch) }

    /// `git lfs pull`: fetches the LFS objects and replaces their pointer files in the working tree.
    func lfsPull() { perform(.lfsPull) }
}
