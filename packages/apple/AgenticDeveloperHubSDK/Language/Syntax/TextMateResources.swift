import Foundation

/// The TextMate resource directory (`Resources/TextMate/` in the toolkit,
/// `Contents/Resources/TextMate/` in an app): the highlighter bundle, its WASM
/// Oniguruma, the bundled grammars and themes, the language table and the
/// manifest. Code is handed the directory; nothing looks it up in a bundle.
public struct TextMateResources: Sendable {

    /// The files a usable directory must hold.
    public static let requiredFiles = ["highlighter.js", "onig.wasm", "languages.json", "manifest.json"]

    public let directory: URL

    /// - Throws: `TextMateResourcesError.missingFile` naming the first
    ///   required file the directory lacks.
    public init(directory: URL) throws {
        for name in Self.requiredFiles
        where !FileManager.default.fileExists(atPath: directory.appendingPathComponent(name).path) {
            throw TextMateResourcesError.missingFile(name)
        }
        self.directory = directory
    }

    var highlighterScript: URL { directory.appendingPathComponent("highlighter.js") }
    var onigWASM: URL { directory.appendingPathComponent("onig.wasm") }
    var languageTable: URL { directory.appendingPathComponent("languages.json") }
    var manifest: URL { directory.appendingPathComponent("manifest.json") }
    var grammarsDirectory: URL { directory.appendingPathComponent("grammars", isDirectory: true) }
}

public enum TextMateResourcesError: Error, Equatable {
    case missingFile(String)
    /// `manifest.json` has no `grammars` array of `{name, scopeName}`.
    case malformedManifest
}
