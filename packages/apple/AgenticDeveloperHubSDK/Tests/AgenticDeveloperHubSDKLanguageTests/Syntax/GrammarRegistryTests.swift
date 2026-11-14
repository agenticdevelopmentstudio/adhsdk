import Foundation
import Testing
@testable import AgenticDeveloperHubSDKLanguage

@Suite("GrammarRegistry")
struct GrammarRegistryTests {

    /// A temporary directory, removed when `body` returns.
    private func withTemporaryDirectory<T>(_ body: (URL) throws -> T) throws -> T {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GrammarRegistryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        return try body(directory)
    }

    private func write(_ text: String, _ name: String, in directory: URL) throws {
        try Data(text.utf8).write(to: directory.appendingPathComponent(name))
    }

    @Test("a user grammar directory ahead of the bundled source wins")
    func userDirectoryWinsOverBundled() throws {
        try withTemporaryDirectory { directory in
            let userSwift = #"{"name":"User Swift","scopeName":"source.swift","#
                + #""fileTypes":["swift","SWIFTX"],"patterns":[]}"#
            try write(userSwift, "swift.tmLanguage.json", in: directory)
            let registry = GrammarRegistry(sources: [
                DirectoryGrammarSource(directory: directory),
                try BundledGrammarSource(resources: TextMateFixture.resources())
            ])

            #expect(registry.grammarText(scopeName: "source.swift") == userSwift)
            #expect(registry.scopeName(languageID: "swift") == "source.swift")
            let swift = registry.languages.filter { $0.id == "swift" }
            #expect(swift == [LanguageEntry(
                id: "swift", scopeName: "source.swift", aliases: [], extensions: [".swift", ".swiftx"],
                filenames: ["swift", "SWIFTX"])])
            #expect(registry.grammarText(scopeName: "source.python") != nil)
            #expect(registry.scopeName(languageID: "python") == "source.python")
        }
    }

    @Test("the bundled source reads the language table and every manifest scope, embed-only ones included")
    func bundledSource() throws {
        let source = try BundledGrammarSource(resources: TextMateFixture.resources())

        #expect(source.languages.count == 200)
        #expect(source.languages.first { $0.id == "make" }?.aliases == ["makefile"])
        #expect(source.grammarText(scopeName: "source.cpp.embedded.macro") != nil)
        #expect(source.grammarText(scopeName: "source.nonexistent") == nil)
    }

    @Test("a directory source skips files that are not grammars and answers nothing for a missing directory")
    func directorySourceSkipsNonGrammars() throws {
        try withTemporaryDirectory { directory in
            try write("not json", "broken.tmLanguage.json", in: directory)
            try write(#"{"name":"No scope"}"#, "noscope.tmLanguage.json", in: directory)
            try write(#"{"scopeName":"source.other"}"#, "other.json", in: directory)
            try write(#"{"scopeName":"source.toy"}"#, "toy.tmLanguage.json", in: directory)

            let source = DirectoryGrammarSource(directory: directory)

            #expect(source.languages == [LanguageEntry(
                id: "toy", scopeName: "source.toy", aliases: [], extensions: [], filenames: [])])
            #expect(source.grammarText(scopeName: "source.toy") == #"{"scopeName":"source.toy"}"#)
            #expect(source.grammarText(scopeName: "source.other") == nil)
        }
        let missing = DirectoryGrammarSource(directory: URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)"))
        #expect(missing.languages.isEmpty)
    }

    @Test("a fileType is a file name as written and an extension, as TextMate matches it")
    func directoryFileTypes() throws {
        try withTemporaryDirectory { directory in
            try write(#"{"scopeName":"source.toymake","fileTypes":["Makefile","MK",".gnu"]}"#,
                      "toymake.tmLanguage.json", in: directory)
            let registry = GrammarRegistry(sources: [DirectoryGrammarSource(directory: directory)])
            let resolver = LanguageResolver(registry: registry)

            #expect(registry.languages == [LanguageEntry(
                id: "toymake", scopeName: "source.toymake", aliases: [],
                extensions: [".makefile", ".mk", ".gnu"], filenames: ["Makefile", "MK"])])
            #expect(resolver.languageID(for: URL(fileURLWithPath: "/p/Makefile")) == "toymake")
            #expect(resolver.languageID(for: URL(fileURLWithPath: "/p/rules.mk")) == "toymake")
        }
    }

    @Test("a second grammar with a scope already taken is skipped")
    func directoryDuplicateScope() throws {
        try withTemporaryDirectory { directory in
            try write(#"{"scopeName":"source.toy"}"#, "a.tmLanguage.json", in: directory)
            try write(#"{"scopeName":"source.toy","fileTypes":["b"]}"#, "b.tmLanguage.json", in: directory)

            let source = DirectoryGrammarSource(directory: directory)

            #expect(source.languages.map(\.id) == ["a"])
            #expect(source.grammarText(scopeName: "source.toy") == #"{"scopeName":"source.toy"}"#)
        }
    }

    @Test("hasGrammar answers without reading the grammar")
    func hasGrammar() throws {
        let bundled = try BundledGrammarSource(resources: TextMateFixture.resources())
        #expect(bundled.hasGrammar(scopeName: "source.swift"))
        #expect(bundled.hasGrammar(scopeName: "source.cpp.embedded.macro"))
        #expect(!bundled.hasGrammar(scopeName: "source.nonexistent"))

        try withTemporaryDirectory { directory in
            try write(#"{"scopeName":"source.toy"}"#, "toy.tmLanguage.json", in: directory)
            let source = DirectoryGrammarSource(directory: directory)
            let registry = GrammarRegistry(sources: [source, bundled])

            #expect(source.hasGrammar(scopeName: "source.toy"))
            #expect(!source.hasGrammar(scopeName: "source.swift"))
            #expect(registry.hasGrammar(scopeName: "source.toy"))
            #expect(registry.hasGrammar(scopeName: "source.swift"))
            #expect(!registry.hasGrammar(scopeName: "source.nonexistent"))

            try FileManager.default.removeItem(at: directory.appendingPathComponent("toy.tmLanguage.json"))
            #expect(!source.hasGrammar(scopeName: "source.toy"))
        }
    }

    @Test("resources missing a required file are refused")
    func resourcesRequireTheirFiles() throws {
        try withTemporaryDirectory { directory in
            #expect(throws: TextMateResourcesError.missingFile("highlighter.js")) {
                try TextMateResources(directory: directory)
            }
            for name in ["highlighter.js", "onig.wasm", "languages.json"] {
                try write("", name, in: directory)
            }
            #expect(throws: TextMateResourcesError.missingFile("manifest.json")) {
                try TextMateResources(directory: directory)
            }
        }
        #expect(throws: Never.self) { try TextMateFixture.resources() }
    }
}
