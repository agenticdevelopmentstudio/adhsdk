import Foundation
import os

import AgenticDeveloperHubSDKCore

/// One language a grammar source offers: an id, the grammar's scope name, and
/// the names a file of that language goes by. Extensions carry their leading
/// dot (`.swift`, `.h.in`); filenames are exact (`Makefile`).
public struct LanguageEntry: Sendable, Hashable, Codable {
    public let id: String
    public let scopeName: String
    public let aliases: [String]
    public let extensions: [String]
    public let filenames: [String]

    public init(id: String, scopeName: String, aliases: [String], extensions: [String], filenames: [String]) {
        self.id = id
        self.scopeName = scopeName
        self.aliases = aliases
        self.extensions = extensions
        self.filenames = filenames
    }
}

/// A place grammars come from.
public protocol GrammarSource: Sendable {
    /// The `.tmLanguage.json` text of the grammar for `scopeName`, or nil.
    func grammarText(scopeName: String) -> String?
    /// Whether there is a grammar for `scopeName`, answered without reading it.
    func hasGrammar(scopeName: String) -> Bool
    var languages: [LanguageEntry] { get }
}

extension GrammarSource {
    /// Reads the grammar; a source that can answer more cheaply overrides it.
    public func hasGrammar(scopeName: String) -> Bool {
        grammarText(scopeName: scopeName) != nil
    }
}

/// The grammars in the bundled TextMate resources: languages from
/// `languages.json`, and every scope in `manifest.json` — embed-only grammars
/// such as `source.cpp.embedded.macro` included — mapped to
/// `grammars/<name>.json`. A grammar's text is read when asked for.
public struct BundledGrammarSource: GrammarSource {

    public let languages: [LanguageEntry]
    private let grammarFiles: [String: URL]

    /// - Throws: the decoding error when `languages.json` is malformed, or
    ///   `TextMateResourcesError.malformedManifest`.
    public init(resources: TextMateResources) throws {
        languages = try JSONDecoder().decode([LanguageEntry].self, from: Data(contentsOf: resources.languageTable))
        let manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: resources.manifest))
        guard let grammars = (manifest as? [String: Any])?["grammars"] as? [[String: Any]] else {
            throw TextMateResourcesError.malformedManifest
        }
        var files: [String: URL] = [:]
        for grammar in grammars {
            guard let name = grammar["name"] as? String, let scope = grammar["scopeName"] as? String else {
                throw TextMateResourcesError.malformedManifest
            }
            files[scope] = resources.grammarsDirectory.appendingPathComponent(name + ".json")
        }
        grammarFiles = files
    }

    public func grammarText(scopeName: String) -> String? {
        grammarFiles[scopeName].flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    }

    public func hasGrammar(scopeName: String) -> Bool {
        grammarFiles[scopeName] != nil
    }
}

/// A directory of user grammars: every `*.tmLanguage.json` whose JSON has a
/// string `scopeName`. The language id is the file name without
/// `.tmLanguage.json`. Each of the file's `fileTypes` is matched as TextMate
/// matches it, against the whole file name or the part after a dot: it is an
/// extension, lowercased and given a leading dot, and, unless it starts with a
/// dot, also an exact file name as written (`Makefile`). Files that are not
/// such JSON, and a second file for a scope already taken, are skipped with a
/// log line; a missing directory offers nothing. Read once, at init.
public struct DirectoryGrammarSource: GrammarSource {

    static let suffix = ".tmLanguage.json"

    public let languages: [LanguageEntry]
    private let grammarFiles: [String: URL]

    public init(directory: URL) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        var languages: [LanguageEntry] = []
        var files: [String: URL] = [:]
        for name in names.sorted() where name.hasSuffix(Self.suffix) && name.count > Self.suffix.count {
            let url = directory.appendingPathComponent(name)
            guard let data = try? Data(contentsOf: url),
                  let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let scope = object["scopeName"] as? String else {
                Self.logger.info("Skipping \(name, privacy: .public): not a grammar with a scopeName")
                continue
            }
            guard files[scope] == nil else {
                Self.logger.info("Skipping \(name, privacy: .public): scope \(scope, privacy: .public) is taken")
                continue
            }
            files[scope] = url
            let fileTypes = object["fileTypes"] as? [String] ?? []
            languages.append(LanguageEntry(
                id: String(name.dropLast(Self.suffix.count)),
                scopeName: scope,
                aliases: [],
                extensions: fileTypes.map { type in
                    let lowered = type.lowercased()
                    return lowered.hasPrefix(".") ? lowered : "." + lowered
                },
                filenames: fileTypes.filter { !$0.hasPrefix(".") }
            ))
        }
        self.languages = languages
        grammarFiles = files
    }

    public func grammarText(scopeName: String) -> String? {
        grammarFiles[scopeName].flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    }

    public func hasGrammar(scopeName: String) -> Bool {
        grammarFiles[scopeName].map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }
}

extension DirectoryGrammarSource: Loggable {
    public static nonisolated let logger = makeLogger()
}
