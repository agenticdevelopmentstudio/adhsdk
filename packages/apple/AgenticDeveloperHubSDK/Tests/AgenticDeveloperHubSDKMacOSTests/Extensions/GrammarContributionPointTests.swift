import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKMacOS

/// The `contributes.grammars` contribution point and the
/// `ExtensionGrammarSource` snapshot it hands the highlighter.
///
/// Every fixture is a real extension folder: a `package.json` decoded through
/// the real parser, and grammar files on disk, because resolving `path`
/// against the extension's folder is half of what is under test.
///
/// `.serialized` because the registry test swaps `UserSettings.shared`, which
/// the disabled-extension set lives in.
@MainActor
@Suite(.serialized)
struct GrammarContributionPointTests {

    // MARK: - Fixtures

    private static let widgetGrammar = #"{ "scopeName": "source.widget", "patterns": [] }"#
    private static let injectionGrammar =
        #"{ "scopeName": "text.widget.injection", "injectionSelector": "L:source", "patterns": [] }"#

    private static let widgetContributes = """
    {
        "grammars": [
            {
                "language": "widget",
                "scopeName": "source.widget",
                "path": "./syntaxes/widget.tmLanguage.json",
                "embeddedLanguages": { "meta.embedded.block.js": "javascript" }
            },
            {
                "scopeName": "text.widget.injection",
                "path": "./syntaxes/injection.json",
                "injectTo": ["source.widget"]
            }
        ],
        "languages": [
            {
                "id": "widget",
                "aliases": ["Widget"],
                "extensions": [".Widget", "wdg", "*.w?"],
                "filenames": ["Widgetfile"]
            }
        ]
    }
    """

    private func manifest(name: String, contributes: String) throws -> ExtensionManifest {
        let json = """
        {
            "name": "\(name)",
            "publisher": "test",
            "version": "1.0.0",
            "engines": { "vscode": "^1.74.0" },
            "contributes": \(contributes)
        }
        """
        return try JSONDecoder().decode(ExtensionManifest.self, from: Data(json.utf8))
    }

    /// Writes the manifest and the two widget grammars into a fresh extension
    /// folder under `root` and returns the folder.
    private func writeWidgetExtension(name: String = "widget", in root: URL) throws -> URL {
        let directory = root.appendingPathComponent("\(name)-1.0.0")
        let json = """
        {
            "name": "\(name)",
            "publisher": "test",
            "version": "1.0.0",
            "engines": { "vscode": "^1.74.0" },
            "contributes": \(Self.widgetContributes)
        }
        """
        try ExtensionFixtures.write(json, to: "package.json", in: directory)
        try ExtensionFixtures.write(Self.widgetGrammar, to: "syntaxes/widget.tmLanguage.json", in: directory)
        try ExtensionFixtures.write(Self.injectionGrammar, to: "syntaxes/injection.json", in: directory)
        return directory
    }

    private func makeRoot() throws -> URL {
        try ExtensionFixtures.makeTemporaryDirectory("GrammarContributionPointTests")
    }

    // MARK: - Identity

    @Test("the point consumes the grammars key")
    func contributionKey() {
        #expect(GrammarContributionPoint().contributionKey == "grammars")
    }

    // MARK: - Reading

    @Test("a grammar contribution is read by scope name from its path, joined with its language")
    func grammarContributionReadsScopeAndPath() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = try writeWidgetExtension(in: root)
        let manifest = try manifest(name: "widget", contributes: Self.widgetContributes)

        let point = GrammarContributionPoint()
        try point.apply(try #require(manifest.contributes), from: manifest, at: directory)
        let source = point.source

        #expect(source.grammarText(scopeName: "source.widget") == Self.widgetGrammar)
        #expect(source.hasGrammar(scopeName: "source.widget"))
        // An injection grammar names no language: its text is there by scope
        // name, and it adds nothing to the language table.
        #expect(source.grammarText(scopeName: "text.widget.injection") == Self.injectionGrammar)
        #expect(source.hasGrammar(scopeName: "text.widget.injection"))
        #expect(source.languages == [
            LanguageEntry(
                id: "widget",
                scopeName: "source.widget",
                aliases: ["Widget"],
                extensions: [".widget", ".wdg"],
                filenames: ["Widgetfile"]
            )
        ])
        #expect(!source.hasGrammar(scopeName: "source.unknown"))
        #expect(source.grammarText(scopeName: "source.unknown") == nil)
    }

    @Test("the source feeds a grammar registry and a language resolver")
    func sourceFeedsTheRegistryAndResolver() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = try writeWidgetExtension(in: root)
        let manifest = try manifest(name: "widget", contributes: Self.widgetContributes)
        let point = GrammarContributionPoint()
        try point.apply(try #require(manifest.contributes), from: manifest, at: directory)

        let registry = GrammarRegistry(sources: [point.source])
        let resolver = LanguageResolver(registry: registry)

        #expect(registry.scopeName(languageID: "widget") == "source.widget")
        #expect(registry.grammarText(scopeName: "source.widget") == Self.widgetGrammar)
        #expect(resolver.languageID(for: URL(fileURLWithPath: "/tmp/a.WDG")) == "widget")
        #expect(resolver.languageID(for: URL(fileURLWithPath: "/tmp/Widgetfile")) == "widget")
    }

    @Test("a plist grammar, an escaping path and a missing file are skipped")
    func unusableGrammarPathsAreSkipped() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("odd-1.0.0")
        try ExtensionFixtures.write("<plist/>", to: "syntaxes/old.tmLanguage", in: directory)
        try ExtensionFixtures.write(Self.widgetGrammar, to: "outside.json", in: root)
        let contributes = """
        {
            "grammars": [
                { "language": "old", "scopeName": "source.old", "path": "./syntaxes/old.tmLanguage" },
                { "language": "out", "scopeName": "source.out", "path": "../outside.json" },
                { "language": "gone", "scopeName": "source.gone", "path": "./syntaxes/gone.json" }
            ]
        }
        """
        let manifest = try manifest(name: "odd", contributes: contributes)
        let point = GrammarContributionPoint()
        try point.apply(try #require(manifest.contributes), from: manifest, at: directory)

        #expect(!point.source.hasGrammar(scopeName: "source.old"))
        #expect(!point.source.hasGrammar(scopeName: "source.out"))
        #expect(!point.source.hasGrammar(scopeName: "source.gone"))
        #expect(point.source.languages.isEmpty)
    }

    @Test("two extensions claiming one scope: the lower identifier wins, whatever the apply order")
    func lowerIdentifierWinsAContestedScope() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let alphaDirectory = try writeWidgetExtension(name: "alpha", in: root)
        let betaDirectory = root.appendingPathComponent("beta-1.0.0")
        let betaGrammar = #"{ "scopeName": "source.widget", "name": "beta" }"#
        try ExtensionFixtures.write(betaGrammar, to: "w.json", in: betaDirectory)
        let beta = try manifest(
            name: "beta",
            contributes: """
            { "grammars": [{ "language": "widget2", "scopeName": "source.widget", "path": "./w.json" }] }
            """
        )
        let alpha = try manifest(name: "alpha", contributes: Self.widgetContributes)

        let point = GrammarContributionPoint()
        try point.apply(try #require(beta.contributes), from: beta, at: betaDirectory)
        try point.apply(try #require(alpha.contributes), from: alpha, at: alphaDirectory)

        #expect(point.source.grammarText(scopeName: "source.widget") == Self.widgetGrammar)
        #expect(point.source.languages.map(\.id) == ["widget"])
    }

    // MARK: - Enablement

    @Test("a disabled extension contributes nothing, and re-enabling restores it")
    func disabledExtensionContributesNothing() throws {
        try withInMemorySettings {
            let root = try makeRoot()
            defer { try? FileManager.default.removeItem(at: root) }
            _ = try writeWidgetExtension(in: root)

            let point = GrammarContributionPoint()
            let registry = ExtensionRegistry(
                searchPaths: [root], hostVersion: ExtensionRegistry.declaredVSCodeVersion)
            registry.register(point)
            registry.loadAll()
            try #require(registry.extensions.count == 1)
            try #require(point.source.hasGrammar(scopeName: "source.widget"))

            // A snapshot taken while enabled stays as it was: the owner
            // rebuilds it when extensions change.
            let enabledSnapshot = point.source

            registry.setEnabled(false, for: "test.widget")
            #expect(point.source.languages.isEmpty)
            #expect(!point.source.hasGrammar(scopeName: "source.widget"))
            #expect(point.source.grammarText(scopeName: "source.widget") == nil)
            #expect(point.source.grammarText(scopeName: "text.widget.injection") == nil)
            #expect(enabledSnapshot.hasGrammar(scopeName: "source.widget"))

            registry.setEnabled(true, for: "test.widget")
            #expect(point.source.grammarText(scopeName: "source.widget") == Self.widgetGrammar)
            #expect(point.source.languages.map(\.id) == ["widget"])
        }
    }

    @Test("withdrawing an extension removes its grammars and nobody else's")
    func withdrawRemovesOnlyThatExtension() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let alphaDirectory = try writeWidgetExtension(name: "alpha", in: root)
        let betaDirectory = root.appendingPathComponent("beta-1.0.0")
        try ExtensionFixtures.write(#"{ "scopeName": "source.beta" }"#, to: "b.json", in: betaDirectory)
        let alpha = try manifest(name: "alpha", contributes: Self.widgetContributes)
        let beta = try manifest(
            name: "beta",
            contributes: #"{ "grammars": [{ "language": "beta", "scopeName": "source.beta", "path": "./b.json" }] }"#
        )
        let point = GrammarContributionPoint()
        try point.apply(try #require(alpha.contributes), from: alpha, at: alphaDirectory)
        try point.apply(try #require(beta.contributes), from: beta, at: betaDirectory)

        point.withdraw(extensionIdentifier: "test.alpha")

        #expect(!point.source.hasGrammar(scopeName: "source.widget"))
        #expect(point.source.hasGrammar(scopeName: "source.beta"))
        #expect(point.source.languages.map(\.id) == ["beta"])
    }
}
