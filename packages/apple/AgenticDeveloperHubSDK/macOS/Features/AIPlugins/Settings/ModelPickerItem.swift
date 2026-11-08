import Foundation
import AIPluginKit
import AgenticDeveloperHubSDKCore

/// One model row's data for the chooser: its id plus everything known about it —
/// the shared catalog's facts merged with this provider's terms and any curated
/// `modelDetails` copy (see `AIModelCatalog.resolve`).
///
/// The resolved facts are stored whole rather than copied field-by-field so the
/// row and the catalog can never disagree, and so a field added to the catalog
/// reaches the UI without touching this type.
public struct ModelPickerItem: Equatable, Sendable {
    public let id: String
    /// What the row shows: the provider's name for the model (`Opus 5.5`), or
    /// the id when it has none.
    public let title: String
    public let info: AIModelCatalog.ResolvedModel

    public init(id: String, title: String? = nil, info: AIModelCatalog.ResolvedModel) {
        self.id = id
        self.title = title ?? id
        self.info = info
    }

    /// Curated-only convenience — a model the shared catalog has nothing on.
    public init(id: String, description: String? = nil, tools: Bool? = nil, goodFor: String? = nil) {
        self.init(id: id, info: AIModelCatalog.ResolvedModel(
            id: id, description: description, goodFor: goodFor, tools: tools))
    }

    public var description: String? { info.description }
    public var tools: Bool? { info.tools }
    public var goodFor: String? { info.goodFor }

    /// "Tools: Yes · Good for: …" — nil when neither is known.
    var capabilities: String? {
        var parts: [String] = []
        if let tools { parts.append("Tools: \(tools ? "Yes" : "No")") }
        if let goodFor, !goodFor.isEmpty { parts.append("Good for: \(goodFor)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// The chooser's "any" filter: `needle`'s characters appear in the title or
    /// the id, in order and case-sensitively (`SubsequenceMatch`). Only those two
    /// are searched — a scattered-letter match against a paragraph of description
    /// matches nearly every model.
    func matches(_ needle: String) -> Bool {
        SubsequenceMatch.indices(of: needle, in: title) != nil
            || SubsequenceMatch.indices(of: needle, in: id) != nil
    }

    /// The text the row shows for `needle`: the title, or the id when only the
    /// id matched, so the underlined letters always explain the match.
    func rowText(for needle: String) -> String {
        needle.isEmpty || SubsequenceMatch.indices(of: needle, in: title) != nil ? title : id
    }
}
