import Foundation
import JavaScriptCore
import Testing
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage

/// The toolkit's committed `Resources/TextMate/` tree, found from this file.
enum TextMateFixture {
    static let directory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Syntax
        .deletingLastPathComponent()  // AgenticDeveloperHubSDKLanguageTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // AgenticDeveloperHubSDK
        .appendingPathComponent("Resources/TextMate", isDirectory: true)

    static func resources() throws -> TextMateResources {
        try TextMateResources(directory: directory)
    }

    static func bundledRegistry() throws -> GrammarRegistry {
        GrammarRegistry(sources: [try BundledGrammarSource(resources: resources())])
    }

    /// A new highlighter whose engine has not been created yet.
    static func highlighter() throws -> SyntaxHighlighter {
        try SyntaxHighlighter(resources: resources(), registry: bundledRegistry())
    }

    static func theme(_ name: String) throws -> CodeTheme {
        try CodeTheme(vscodeThemeData: Data(contentsOf: directory.appendingPathComponent("themes/\(name).json")))
    }
}

@Suite("SyntaxHighlighter")
struct SyntaxHighlighterTests {

    /// One engine for the suite: creating it interprets the whole WASM
    /// Oniguruma without the JIT, which is the slow part of every test.
    /// Kept as a `Result` so a failed init is reported by every test as the
    /// error it was, not as a nil.
    private static let shared = Result { try TextMateFixture.highlighter() }

    private func highlighter() throws -> SyntaxHighlighter {
        try Self.shared.get()
    }

    private func hex(_ color: RGBAColor) -> String {
        CodeTheme.hex(color)
    }

    // MARK: - Colouring

    @Test("a Swift keyword takes the theme's keyword colour")
    func highlightsSwiftKeywordWithThemeColour() async throws {
        let lines = try #require(try await highlighter().highlight(
            "let x = 1", scopeName: "source.swift", theme: TextMateFixture.theme("dark-plus")))

        #expect(lines.count == 1)
        let first = try #require(lines[0].runs.first)
        #expect(first.range == NSRange(location: 0, length: 3))
        #expect(hex(first.foreground) == "#569CD6")
        #expect(first.fontStyle == [])
    }

    @Test("an open block comment colours the next line as comment")
    func stateCarriesAcrossLines() async throws {
        let lines = try #require(try await highlighter().highlight(
            "/* a\nb */", scopeName: "source.swift", theme: TextMateFixture.theme("dark-plus")))

        #expect(lines.count == 2)
        let second = try #require(lines[1].runs.first)
        #expect(second.range.location == 0)
        #expect(hex(second.foreground) == "#6A9955")
    }

    @Test("a fenced swift block in Markdown is coloured as Swift")
    func markdownEmbedsSwift() async throws {
        let text = "# T\n\n```swift\nlet y = 1\n```"
        let lines = try #require(try await highlighter().highlight(
            text, scopeName: "text.html.markdown", theme: TextMateFixture.theme("dark-plus")))

        #expect(lines.count == 5)
        let letRun = try #require(lines[3].runs.first { $0.range == NSRange(location: 0, length: 3) })
        #expect(hex(letRun.foreground) == "#569CD6")
    }

    @Test("a different theme repaints the same text")
    func changedThemeIsApplied() async throws {
        let engine = try highlighter()
        let dark = try #require(try await engine.highlight(
            "let x = 1", scopeName: "source.swift", theme: TextMateFixture.theme("dark-plus")))
        let light = try #require(try await engine.highlight(
            "let x = 1", scopeName: "source.swift", theme: TextMateFixture.theme("light-plus")))

        #expect(hex(try #require(dark[0].runs.first).foreground) == "#569CD6")
        #expect(hex(try #require(light[0].runs.first).foreground) == "#0000FF")
    }

    @Test("lines split on \\r\\n, \\r and \\n, each one break, as the bundle splits")
    func linesSplitLikeTheBundle() async throws {
        let lines = try #require(try await highlighter().highlight(
            "let a\rlet b\r\nlet c\n", scopeName: "source.swift", theme: TextMateFixture.theme("dark-plus")))

        #expect(lines.count == 4)
        for index in 0..<3 {
            #expect(lines[index].runs.first?.range == NSRange(location: 0, length: 3))
        }
        #expect(lines[3].runs.isEmpty)
    }

    @Test("concurrent first calls build one engine and both are coloured by the theme")
    func concurrentFirstCalls() async throws {
        let engine = try TextMateFixture.highlighter()
        let theme = try TextMateFixture.theme("dark-plus")

        async let first = engine.highlight("let x = 1", scopeName: "source.swift", theme: theme)
        async let second = engine.highlight("let y = 2", scopeName: "source.swift", theme: theme)
        let more = try await withThrowingTaskGroup(of: [StyledLine]?.self) { group in
            for index in 0..<6 {
                group.addTask {
                    try await engine.highlight("let z\(index) = 3", scopeName: "source.swift", theme: theme)
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
        let results = try await [first, second] + more

        #expect(results.count == 8)
        for lines in results {
            let styled = try #require(lines)
            let run = try #require(styled.first?.runs.first)
            #expect(hex(run.foreground) == "#569CD6")
        }
        #expect(await engine.engineCount == 1)
        #expect(await engine.setThemeCount == 1)
    }

    @Test("the theme is handed to the bundle only when it changes")
    func themeSetOnlyWhenChanged() async throws {
        let engine = try TextMateFixture.highlighter()
        let dark = try TextMateFixture.theme("dark-plus")
        let light = try TextMateFixture.theme("light-plus")

        for (theme, expected) in [(dark, 1), (dark, 1), (light, 2), (light, 2), (dark, 3)] {
            _ = try await engine.highlight("let x = 1", scopeName: "source.swift", theme: theme)
            #expect(await engine.setThemeCount == expected)
        }
    }

    // MARK: - Promises and WebAssembly

    @Test("a promise still pending when the call returns throws rather than waits")
    func settleWithoutRunLoop() throws {
        let context = try #require(JSContext())

        #expect(try SyntaxHighlighter.settle(
            try #require(context.evaluateScript("Promise.resolve('done')")), in: context, "resolved") == "done")
        #expect(throws: SyntaxHighlighterError.javaScript("Error: no")) {
            try SyntaxHighlighter.settle(
                try #require(context.evaluateScript("Promise.reject(new Error('no'))")), in: context, "rejected")
        }
        #expect(throws: SyntaxHighlighterError.promiseDidNotSettle("pending")) {
            try SyntaxHighlighter.settle(
                try #require(context.evaluateScript("new Promise(() => {})")), in: context, "pending")
        }
    }

    @Test("the synchronous instantiate takes bytes or a module, and rejects bad bytes")
    func synchronousInstantiate() throws {
        let context = try #require(JSContext())
        context.evaluateScript(SyntaxHighlighter.synchronousWebAssembly)
        context.evaluateScript("var bytes = new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0]);")
        func settle(_ script: String) throws -> String {
            try SyntaxHighlighter.settle(try #require(context.evaluateScript(script)), in: context, script)
        }

        #expect(try settle("""
            WebAssembly.instantiate(bytes, {}).then(r =>
              `${r.module instanceof WebAssembly.Module},${r.instance instanceof WebAssembly.Instance}`)
            """) == "true,true")
        #expect(try settle("""
            WebAssembly.instantiate(new WebAssembly.Module(bytes), {}).then(r =>
              `${r instanceof WebAssembly.Instance}`)
            """) == "true")
        #expect(throws: SyntaxHighlighterError.self) {
            try settle("WebAssembly.instantiate(new Uint8Array([1, 2, 3]), {})")
        }
    }

    // MARK: - Declining

    @Test("text over the byte limit or with an over-long line is not highlighted")
    func overLimitsReturnsNil() async throws {
        let engine = try highlighter()
        let theme = try TextMateFixture.theme("dark-plus")
        let tooLarge = String(repeating: "a\n", count: SyntaxHighlighter.maximumBytes / 2) + "a"
        let tooLong = "let x = 1\n" + String(repeating: "a", count: SyntaxHighlighter.maximumLineLength + 1)

        #expect(try await engine.highlight(tooLarge, scopeName: "source.swift", theme: theme) == nil)
        #expect(try await engine.highlight(tooLong, scopeName: "source.swift", theme: theme) == nil)
    }

    @Test("the limits are inclusive: exactly at a limit is highlighted")
    func limitBoundaries() {
        let atBytes = String(repeating: "a\n", count: SyntaxHighlighter.maximumBytes / 2)
        let atLine = String(repeating: "é", count: SyntaxHighlighter.maximumLineLength)
        let overLineByUTF16 = String(repeating: "😀", count: SyntaxHighlighter.maximumLineLength / 2 + 1)

        #expect(atBytes.utf8.count == SyntaxHighlighter.maximumBytes)
        #expect(!SyntaxHighlighter.exceedsLimits(atBytes))
        #expect(!SyntaxHighlighter.exceedsLimits(atBytes.dropLast() + "a"))
        #expect(SyntaxHighlighter.exceedsLimits(atBytes + "a"))
        #expect(!SyntaxHighlighter.exceedsLimits(atLine + "\r\n" + atLine))
        #expect(SyntaxHighlighter.exceedsLimits(overLineByUTF16))
    }

    @Test("a scope with no grammar is not highlighted")
    func unknownScopeReturnsNil() async throws {
        let result = try await highlighter().highlight(
            "anything", scopeName: "source.nonexistent", theme: TextMateFixture.theme("dark-plus"))
        #expect(result == nil)
    }

    // MARK: - Line split and colours

    @Test("the Swift line split matches the bundle's /\\r\\n|\\r|\\n/")
    func lineLengths() {
        #expect(SyntaxHighlighter.lineLengths("") == [0])
        #expect(SyntaxHighlighter.lineLengths("a\rb") == [1, 1])
        #expect(SyntaxHighlighter.lineLengths("a\r\nb") == [1, 1])
        #expect(SyntaxHighlighter.lineLengths("a\n\rb") == [1, 0, 1])
        #expect(SyntaxHighlighter.lineLengths("😀\n") == [2, 0])
    }

    @Test("bundle output that disagrees with the Swift line split, or runs outside their line, throws")
    func malformedOutputThrows() throws {
        let good = ##"{"lines":[[[0,3,"#569CD6",2]],[]]}"##
        let lines = try SyntaxHighlighter.styledLines(json: good, lineLengths: [3, 0])
        #expect(lines[0].runs == [SyntaxRun(
            range: NSRange(location: 0, length: 3), foreground: try SyntaxRun.color(highlighterHex: "#569CD6"),
            fontStyle: .bold)])
        #expect(lines[1].runs.isEmpty)

        #expect(throws: SyntaxHighlighterError.malformedOutput("1 lines, expected 2")) {
            try SyntaxHighlighter.styledLines(json: #"{"lines":[[]]}"#, lineLengths: [0, 0])
        }
        #expect(throws: SyntaxHighlighterError.self) {
            try SyntaxHighlighter.styledLines(json: ##"{"lines":[[[2,3,"#569CD6",0]]]}"##, lineLengths: [4])
        }
        #expect(throws: SyntaxHighlighterError.unexpectedColor("#569cd6")) {
            try SyntaxHighlighter.styledLines(json: ##"{"lines":[[[0,1,"#569cd6",0]]]}"##, lineLengths: [1])
        }
        #expect(throws: SyntaxHighlighterError.self) {
            try SyntaxHighlighter.styledLines(json: "[]", lineLengths: [0])
        }
    }

    @Test("run colours parse only as uppercase #RRGGBB or #RRGGBBAA")
    func strictColours() throws {
        let opaque = try SyntaxRun.color(highlighterHex: "#569CD6")
        #expect(opaque.hexString == "#569CD6FF")
        let translucent = try SyntaxRun.color(highlighterHex: "#569CD680")
        #expect(translucent.hexString == "#569CD680")

        for bad in ["#569cd6", "#FFF", "#FFFF", "569CD6", "#569CD6F", "#GGGGGG", "", "#569CD6FF00"] {
            #expect(throws: SyntaxHighlighterError.unexpectedColor(bad)) {
                try SyntaxRun.color(highlighterHex: bad)
            }
        }
    }
}
