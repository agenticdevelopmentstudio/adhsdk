import AgenticDeveloperHubSDKCore

extension GitRepositoryModel {

    /// The signature of `sha`, cached; nil when it has not been checked (yet). Never runs git.
    public func signature(for sha: String) -> GitSignature? {
        signatureLoader.value(for: sha)
    }

    /// Checks the signatures of `shas` — the rows the history draws — in one coalesced,
    /// debounced batch off the main thread; a newer call replaces a batch still waiting.
    /// `.annotations` is posted when results land.
    public func requestSignatures(for shas: [String]) {
        signatureLoader.request(shas)
    }

    /// Checks one commit's signature, for a commit the detail shows outside the history
    /// rows, without displacing the history's queued batch.
    public func requestSignature(for sha: String) {
        signatureLoader.request([sha], replacingQueued: false)
    }
}
