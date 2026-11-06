import Combine
import Foundation

/// Whether a file browser applies the Excluded patterns, shared by every
/// browser that should agree on it.
///
/// The patterns themselves are app-wide (Settings > File Browser > Excluded);
/// this is the switch that sets them aside so the reader can see what they
/// hide, without editing the list to do it. A project hands out one of these
/// to all of its browser panes, so turning it off in one pane shows the hidden
/// files in every pane of that project, and it persists the answer per project.
///
/// A browser built without one gets its own, on: the default is that excluded
/// content stays hidden.
@MainActor
public final class FileBrowserExclusionState: ObservableObject {

    /// On (the default) applies the Excluded patterns; off shows everything.
    @Published public var hidesExcludedContent: Bool {
        didSet {
            guard hidesExcludedContent != oldValue else { return }
            onChange?(hidesExcludedContent)
        }
    }

    /// Called after each change, for the owner that persists it.
    public var onChange: ((Bool) -> Void)?

    public init(hidesExcludedContent: Bool = true) {
        self.hidesExcludedContent = hidesExcludedContent
    }
}
