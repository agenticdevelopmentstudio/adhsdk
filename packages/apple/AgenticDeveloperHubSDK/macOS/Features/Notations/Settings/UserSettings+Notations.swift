import Foundation
import AgenticDeveloperHubSDKCore

@MainActor
extension UserSettings {

    /// How many days an archived notation is kept before a reconcile may
    /// delete it — and then only once no ref with its branch name and fork
    /// point exists, locally or on origin.
    public static let notationsArchivedRetentionDays = UserSetting<Int>(
        "notations.archived_retention_days", default: 30)

    /// Whether a Notations pane opens with one of its panes at a time or
    /// with Markdown and Preview side by side. The last choice made in any
    /// pane; each open pane keeps its own until it is changed there.
    public static let notationsPaneLayout = UserSetting<NotationsPaneLayout>(
        "notations.pane.layout", default: .singlePane)

    /// Which pane a single-pane Notations pane opens on. Same scope as
    /// `notationsPaneLayout`.
    public static let notationsPaneContent = UserSetting<NotationsPaneContent>(
        "notations.pane.content", default: .markdown)
}

/// How the Notations pane arranges its Markdown and Preview panes.
public enum NotationsPaneLayout: String, Codable, Sendable, CaseIterable {
    /// One pane at a time, both as tabs of one frame.
    case singlePane
    /// Both panes, each in its own frame, next to each other.
    case sideBySide
}

/// The Notations pane's two panes: the markdown source and its rendering.
public enum NotationsPaneContent: String, Codable, Sendable, CaseIterable {
    case markdown
    case preview

    /// The tab title, tooltip and accessibility label.
    public var title: String {
        switch self {
        case .markdown: return "Markdown"
        case .preview: return "Preview"
        }
    }
}

/// The range Settings accepts for `UserSettings.notationsArchivedRetentionDays`.
public enum NotationsRetention {
    public static let range = 1...3_650
}
