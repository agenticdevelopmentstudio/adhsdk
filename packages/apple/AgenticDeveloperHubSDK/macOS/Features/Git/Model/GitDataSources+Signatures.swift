import AgenticDeveloperHubSDKCore

public extension GitHistoryDataSource {
    /// No signatures, for a source that does not check them.
    func signature(for sha: String) -> GitSignature? { nil }

    /// Nothing to check, for a source that does not check signatures.
    func requestSignatures(for shas: [String]) {}
}
