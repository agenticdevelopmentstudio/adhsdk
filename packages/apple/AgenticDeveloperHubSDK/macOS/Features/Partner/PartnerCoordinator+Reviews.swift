import AppKit
import AgenticDeveloperHubSDKCore

extension PartnerCoordinator {
    /// Shows the Coding Partner window on the session that ran the review with `id`, for
    /// the Git window's "Open in Coding Partner" (recipe `workspace/git/git-views`,
    /// "Reviews"). A review with no session, or one whose session is no longer open, shows
    /// the partner. The review is read off the main thread; the store is never written.
    public func showReview(id: String) {
        let store = controller.store
        Task { [weak self] in
            let sessionID = await Task.detached(priority: .userInitiated) { () -> UUID? in
                do {
                    return try store.review(id: id)?.sessionID.flatMap(UUID.init(uuidString:))
                } catch {
                    Self.logger.error("Reading review \(id, privacy: .public) failed: \(error.localizedDescription)")
                    return nil
                }
            }.value
            guard let self else { return }
            PartnerWindowController.present(controller: self.controller)
                .splitViewController.select(sessionID: sessionID)
        }
    }
}
