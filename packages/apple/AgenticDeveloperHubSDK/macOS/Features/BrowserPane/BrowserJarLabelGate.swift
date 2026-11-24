//
//  BrowserJarLabelGate.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Decides when a pane renames its jar: at most once per committed
/// navigation.
///
/// A page may change its title as often as it likes — an unread counter, a
/// clock, a typing indicator — and every change was a database write. The
/// name a jar is listed under only has to say what the pane was last for, so
/// one write per page is enough: the first real title after a commit, or,
/// for a page that never sets one, the pane's fallback title once the load
/// finishes. A title changed later by script on the same page waits for the
/// next navigation.
struct BrowserJarLabelGate {

    private(set) var isArmed = false

    /// A navigation committed: the next title is the new page's.
    mutating func navigationDidCommit() { isArmed = true }

    /// The label to write now, or `nil`.
    /// - Parameters:
    ///   - pageTitle: The page's own title, blank while it has none.
    ///   - fallback: What the pane calls itself without one (its host, or
    ///     "Browser"), taken only once the load has finished.
    ///   - finished: Whether the committed navigation has finished loading.
    ///   - current: The label the row already has.
    mutating func label(pageTitle: String?, fallback: String, finished: Bool, current: String?) -> String? {
        guard isArmed else { return nil }
        let candidate: String
        if let pageTitle, !pageTitle.isEmpty {
            candidate = pageTitle
        } else if finished {
            candidate = fallback
        } else {
            return nil
        }
        isArmed = false
        return candidate == current ? nil : candidate
    }
}
