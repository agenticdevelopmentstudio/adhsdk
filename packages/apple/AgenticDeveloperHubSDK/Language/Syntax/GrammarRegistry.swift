import Foundation

/// Grammars from an ordered list of sources, the first source winning: a
/// scope's text comes from the first source that has it, and each language id
/// is listed once, as the first source states it. Put a user directory ahead
/// of the bundled source to let it override.
public final class GrammarRegistry: Sendable {

    private let sources: [any GrammarSource]
    public let languages: [LanguageEntry]
    private let scopeByLanguageID: [String: String]

    public init(sources: [any GrammarSource]) {
        self.sources = sources
        var seen = Set<String>()
        var languages: [LanguageEntry] = []
        for source in sources {
            for language in source.languages where seen.insert(language.id).inserted {
                languages.append(language)
            }
        }
        self.languages = languages
        scopeByLanguageID = Dictionary(languages.map { ($0.id, $0.scopeName) }, uniquingKeysWith: { first, _ in first })
    }

    public func grammarText(scopeName: String) -> String? {
        for source in sources {
            if let text = source.grammarText(scopeName: scopeName) { return text }
        }
        return nil
    }

    public func hasGrammar(scopeName: String) -> Bool {
        sources.contains { $0.hasGrammar(scopeName: scopeName) }
    }

    public func scopeName(languageID: String) -> String? {
        scopeByLanguageID[languageID]
    }

    /// The id of the language a person's `name` for it means: a language id or alias
    /// in any case (`Objective-C`, `C++`, `C#`), else the first whose id or alias is
    /// the same once spaces and punctuation other than `+` and `#` are dropped
    /// (`Shell Script` is `shellscript`). Nil when no language goes by it.
    public func languageID(named name: String) -> String? {
        let lowered = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lowered.isEmpty else { return nil }
        if let exact = languages.first(where: { $0.id == lowered || $0.aliases.contains(lowered) }) {
            return exact.id
        }
        let compact = Self.compact(lowered)
        guard !compact.isEmpty else { return nil }
        return languages.first { language in
            Self.compact(language.id) == compact || language.aliases.contains { Self.compact($0) == compact }
        }?.id
    }

    private static func compact(_ name: String) -> String {
        String(String.UnicodeScalarView(name.lowercased().unicodeScalars.filter {
            CharacterSet.alphanumerics.contains($0) || $0 == "+" || $0 == "#"
        }))
    }
}
