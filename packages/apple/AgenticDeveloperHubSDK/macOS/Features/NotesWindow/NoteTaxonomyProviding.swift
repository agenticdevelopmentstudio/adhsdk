import Foundation
import AgenticDeveloperHubSDKMarkdown

/// Storage that can also answer taxonomy questions (categories and which notes
/// are in them).
///
/// `NoteStorage` deliberately does not know about categories — it is an
/// abstract note-persistence seam — so the folders pane asks for this
/// capability separately and does without when the host's storage cannot
/// supply it.
public protocol NoteTaxonomyProviding {
    var taxonomy: any NoteTaxonomy { get }
}

extension MarkdownNoteStorage: NoteTaxonomyProviding {
    public var taxonomy: any NoteTaxonomy { store }
}
