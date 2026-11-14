//
//  GrammarContributionPoint.swift
//  AgenticDeveloperHubSDK
//

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage
import Foundation
import OSLog

/// The grammars the enabled extensions contribute, as the highlighter's
/// `GrammarSource`: a snapshot taken when it was built, which never changes
/// afterwards. Its owner builds a new one when extensions change
/// (`GrammarContributionPoint.source`).
///
/// A grammar's text is read when asked for, like the other sources; whether
/// a scope has a grammar is a dictionary lookup.
public struct ExtensionGrammarSource: GrammarSource {

    /// No extension grammars at all.
    public static let empty = ExtensionGrammarSource(grammarFiles: [:], languages: [])

    public let languages: [LanguageEntry]
    private let grammarFiles: [String: URL]

    init(grammarFiles: [String: URL], languages: [LanguageEntry]) {
        self.grammarFiles = grammarFiles
        self.languages = languages
    }

    public func grammarText(scopeName: String) -> String? {
        grammarFiles[scopeName].flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    }

    public func hasGrammar(scopeName: String) -> Bool {
        grammarFiles[scopeName] != nil
    }
}

/// The `contributes.grammars` contribution point: each applied extension's
/// TextMate grammars, joined with every applied extension's
/// `contributes.languages` for the file extensions and names a language goes
/// by, published as `source`.
///
/// The registry applies only enabled extensions and withdraws one when it is
/// disabled, so `source` is always the enabled extensions' grammars.
///
/// A grammar is read only if its `path` resolves inside its extension and
/// names a JSON file (`.tmLanguage.json` or `.json`). A plist `.tmLanguage`,
/// a path that escapes the extension and a missing file are skipped with a
/// log line, never failing the extension. Two claims on one scope are settled
/// as `LanguageContributionPoint` settles a contested file extension: lowest
/// extension identifier first, then manifest order — a stable winner across
/// launches, whatever order the extensions were applied in.
///
/// In the macOS framework beside the other points, where the extensions
/// coordinator registers them; nothing here needs AppKit, and the
/// highlighter in the Language framework sees only the `GrammarSource`.
@MainActor
public final class GrammarContributionPoint: ContributionPoint {

    /// One extension's usable grammars and its language entries.
    private struct Registration {
        let grammars: [ResolvedGrammar]
        let languages: [ExtensionManifest.Language]
    }

    private struct ResolvedGrammar {
        let language: String?
        let scopeName: String
        let file: URL
    }

    /// A scope claimed by an extension after a lower identifier took it.
    private struct Conflict: Hashable {
        let scopeName: String
        let extensionIdentifier: String
    }

    private var registrations: [String: Registration] = [:]

    /// The contested scopes as of the last rebuild, so each is logged once
    /// rather than on every rebuild while it stands.
    private var conflicts = Set<Conflict>()

    /// How many contested-scope log lines have been written; tests read it.
    private(set) var conflictReportCount = 0

    /// The enabled extensions' grammars as of the last apply or withdraw.
    public private(set) var source = ExtensionGrammarSource.empty

    public init() {}

    // MARK: - ContributionPoint

    public var contributionKey: String { "grammars" }

    /// Records this extension's grammars, replacing any it already had.
    ///
    /// Never throws: a grammar that cannot be read is skipped with a log line
    /// and costs the extension nothing else.
    public func apply(
        _ contributions: ExtensionManifest.Contributions,
        from manifest: ExtensionManifest,
        at directory: URL
    ) throws {
        let identifier = manifest.identifier
        let grammars = contributions.grammars.compactMap { grammar in
            Self.resolve(grammar, extensionIdentifier: identifier, directory: directory)
        }
        registrations[identifier] = Registration(grammars: grammars, languages: contributions.languages)
        rebuild()
    }

    public func withdraw(extensionIdentifier: String) {
        guard registrations.removeValue(forKey: extensionIdentifier) != nil else { return }
        rebuild()
    }

    // MARK: - Derivation

    /// The grammar's file, or nil (logged) when it cannot be used.
    private static func resolve(
        _ grammar: ExtensionManifest.Grammar,
        extensionIdentifier: String,
        directory: URL
    ) -> ResolvedGrammar? {
        let lowered = grammar.path.lowercased()
        if lowered.hasSuffix(".tmlanguage") {
            logSkip(extensionIdentifier, grammar.scopeName, "plist grammars are not read")
            return nil
        }
        guard lowered.hasSuffix(".json") else {
            logSkip(extensionIdentifier, grammar.scopeName, "not a JSON grammar")
            return nil
        }
        let file: URL
        do {
            file = try ExtensionResourcePath.resolve(grammar.path, inside: directory)
        } catch {
            logSkip(extensionIdentifier, grammar.scopeName, error.localizedDescription)
            return nil
        }
        guard FileManager.default.fileExists(atPath: file.path) else {
            logSkip(extensionIdentifier, grammar.scopeName, "no file at \(file.path)")
            return nil
        }
        return ResolvedGrammar(language: grammar.language, scopeName: grammar.scopeName, file: file)
    }

    private static func logSkip(_ identifier: String, _ scopeName: String, _ reason: String) {
        let scope = "\(identifier) grammar \(scopeName)"
        logger.info("Skipping \(scope, privacy: .public): \(reason, privacy: .public)")
    }

    /// Rebuilds `source` from every registration, in identifier order.
    ///
    /// A grammar is served by its scope name whatever else is true. It adds a
    /// `LanguageEntry` only when the applied extensions declare at least one
    /// file extension or name for its language: an entry with neither would
    /// resolve no file, yet would still hide the bundled entry of the same id,
    /// because `GrammarRegistry` keeps each language id's first entry and this
    /// source comes first.
    private func rebuild() {
        let identifiers = registrations.keys.sorted()
        let ordered = identifiers.compactMap { registrations[$0] }

        var files: [String: URL] = [:]
        var languages: [LanguageEntry] = []
        var languageIDs = Set<String>()
        var conflicts = Set<Conflict>()
        for (identifier, registration) in zip(identifiers, ordered) {
            for grammar in registration.grammars {
                guard files[grammar.scopeName] == nil else {
                    conflicts.insert(Conflict(scopeName: grammar.scopeName, extensionIdentifier: identifier))
                    continue
                }
                files[grammar.scopeName] = grammar.file
                guard let id = grammar.language, languageIDs.insert(id).inserted else { continue }
                let declared = ordered.flatMap { $0.languages.filter { $0.id == id } }
                let extensions = Self.unique(
                    declared.flatMap { $0.extensions ?? [] }.compactMap(Self.normalizedExtension))
                let filenames = Self.unique(declared.flatMap { $0.filenames ?? [] })
                guard !extensions.isEmpty || !filenames.isEmpty else { continue }
                languages.append(LanguageEntry(
                    id: id,
                    scopeName: grammar.scopeName,
                    aliases: Self.unique(declared.flatMap { $0.aliases ?? [] }),
                    extensions: extensions,
                    filenames: filenames
                ))
            }
        }
        report(conflicts)
        source = ExtensionGrammarSource(grammarFiles: files, languages: languages)
    }

    /// Logs the conflicts that were not standing at the last rebuild.
    private func report(_ current: Set<Conflict>) {
        let fresh = current.subtracting(conflicts).sorted {
            ($0.scopeName, $0.extensionIdentifier) < ($1.scopeName, $1.extensionIdentifier)
        }
        for conflict in fresh {
            conflictReportCount += 1
            Self.logSkip(conflict.extensionIdentifier, conflict.scopeName, "the scope is taken")
        }
        conflicts = current
    }

    /// A declared `extensions` value as a `LanguageEntry` extension: lowercased
    /// with one leading dot, as `DirectoryGrammarSource` stores them. Multi-dot
    /// values (`.h.in`) are kept, since `LanguageResolver` tries them; empty
    /// values and globs, which no file name could match, are dropped.
    private static func normalizedExtension(_ declared: String) -> String? {
        var value = declared.lowercased()
        if value.hasPrefix(".") { value.removeFirst() }
        guard !value.isEmpty, !value.contains("*"), !value.contains("?") else { return nil }
        return "." + value
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}

extension GrammarContributionPoint: Loggable {
    public static nonisolated let logger = makeLogger()
}
