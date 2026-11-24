import Foundation

/// A file URL's language id. In order: the override, an exact file name, an
/// extension ignoring case (the longest multi-dot extension first, so
/// `x.h.in` tries `.h.in` before `.in`), otherwise nil. Where languages claim
/// the same name, the registry's earlier language wins.
public struct LanguageResolver: Sendable {

    private let override: @Sendable (URL) -> String?
    private let byFilename: [String: String]
    private let byExtension: [String: String]

    public init(registry: GrammarRegistry, override: @escaping @Sendable (URL) -> String? = { _ in nil }) {
        self.override = override
        var byFilename: [String: String] = [:]
        var byExtension: [String: String] = [:]
        for language in registry.languages {
            for name in language.filenames where byFilename[name] == nil {
                byFilename[name] = language.id
            }
            for ext in language.extensions where byExtension[ext.lowercased()] == nil {
                byExtension[ext.lowercased()] = language.id
            }
        }
        self.byFilename = byFilename
        self.byExtension = byExtension
    }

    public func languageID(for url: URL) -> String? {
        if let id = override(url) { return id }
        let name = url.lastPathComponent
        if let id = byFilename[name] { return id }
        let lowered = name.lowercased()
        var index = lowered.startIndex
        while let dot = lowered[index...].firstIndex(of: ".") {
            if let id = byExtension[String(lowered[dot...])] { return id }
            index = lowered.index(after: dot)
        }
        return nil
    }
}
