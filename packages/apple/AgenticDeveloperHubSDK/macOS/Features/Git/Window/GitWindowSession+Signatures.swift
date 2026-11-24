import Foundation
import AgenticDeveloperHubSDKCore

/// Wires commit signatures (recipe `workspace/git/git-window`, "Signing badges") into the
/// commit detail. The history asks for its own rows; the detail asks for a commit that was
/// never drawn there (a stash, a reflog entry) without displacing the history's batch, and
/// reads it again when `.history` reports that signatures landed.
extension GitWindowSession {
    func configureSignatures() {
        detail.signatureLookup = { [weak model] commit in
            guard let model else { return nil }
            if let signature = model.signature(for: commit.id) { return signature }
            model.requestSignature(for: commit.id)
            return nil
        }
    }
}
