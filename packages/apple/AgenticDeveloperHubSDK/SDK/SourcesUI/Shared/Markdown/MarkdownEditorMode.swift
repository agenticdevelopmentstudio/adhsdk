import Foundation

/// What the editor is showing. `.split` is only offered when there is room for
/// it; below the threshold the editor swaps between the other two.
public enum MarkdownEditorMode: String, CaseIterable, Sendable {
    case edit
    case preview
    case split

    public var label: String {
        switch self {
        case .edit: return "Edit"
        case .preview: return "Preview"
        case .split: return "Split"
        }
    }
}
