import Foundation
import Testing
@testable import AgenticDeveloperHubSDKLanguage

@Suite("LanguageResolver")
struct LanguageResolverTests {

    private func resolver(
        override: @escaping @Sendable (URL) -> String? = { _ in nil }
    ) throws -> LanguageResolver {
        LanguageResolver(registry: try TextMateFixture.bundledRegistry(), override: override)
    }

    private func file(_ name: String) -> URL {
        URL(fileURLWithPath: "/tmp/project/\(name)")
    }

    @Test("extensions resolve ignoring case")
    func extensions() throws {
        let resolver = try resolver()
        #expect(resolver.languageID(for: file("Package.swift")) == "swift")
        #expect(resolver.languageID(for: file("x.PY")) == "python")
        #expect(resolver.languageID(for: file("data.json")) == "json")
    }

    @Test("an exact file name resolves before any extension")
    func filenames() throws {
        let resolver = try resolver()
        #expect(resolver.languageID(for: file("Makefile")) == "make")
        #expect(resolver.languageID(for: file("BUILD.bazel")) == "python")
    }

    @Test("the longest multi-dot extension is tried first")
    func multiDotExtension() throws {
        #expect(try resolver().languageID(for: file("config.h.in")) == "c")
    }

    @Test("the override wins over file name and extension")
    func overrideWins() throws {
        let resolver = try resolver { $0.lastPathComponent == "Package.swift" ? "json" : nil }
        #expect(resolver.languageID(for: file("Package.swift")) == "json")
        #expect(resolver.languageID(for: file("main.swift")) == "swift")
    }

    @Test("an unknown file resolves to nil")
    func unknown() throws {
        let resolver = try resolver()
        #expect(resolver.languageID(for: file("notes.unknownext")) == nil)
        #expect(resolver.languageID(for: file("noextension")) == nil)
    }
}
