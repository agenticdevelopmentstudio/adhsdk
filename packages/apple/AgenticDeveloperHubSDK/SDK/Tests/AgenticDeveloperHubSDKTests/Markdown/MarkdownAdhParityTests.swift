import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

/// A line-for-line port of adh's own `test/markdown-lib.test.ts`, kept in adh's
/// order with adh's wording so the two suites can be diffed by eye.
///
/// adh's functions take `(content, frontmatter)` because the server has already
/// parsed the block; ours take the content alone and parse it themselves, so
/// every case that passed a frontmatter object here carries that object as a
/// real `---` block at the top of the content.
///
/// This suite is the executable statement of the parity contract: adh
/// recomputes `title` and `excerpt` on every write and returns them in every
/// response, so a rule we disagree on makes the synced `title` column flip back
/// and forth on each round trip. Where adh's rule is cruder than CommonMark's,
/// these cases pin us to the crude one on purpose.
@Suite("adh parity")
struct MarkdownAdhParityTests {

    // MARK: - contentHash / byteLength

    @Test("is the SHA-256 hex of the UTF-8 bytes")
    func hashIsSHA256Hex() {
        // `printf '# Hello\n' | shasum -a 256`
        #expect(MarkdownText.contentHash("# Hello\n")
                == "90f8ec5669cd34183b9b0fdf8b94f5efb4c3672876330f4aa76088c2b4ad17be")
        #expect(MarkdownText.contentHash("# Hello\n").count == 64)
    }

    @Test("counts UTF-8 bytes, not JS string length")
    func byteLengthCountsUTF8() {
        #expect(MarkdownText.byteLength("é") == 2)   // 2 bytes, 1 code unit
        #expect(MarkdownText.byteLength("😀") == 4)
    }

    // MARK: - parseFrontmatter

    @Test("parses a leading YAML block into an object")
    func parsesLeadingBlock() {
        let content = "---\nname: simplicity\ndescription: Prefer less code\n---\n\n# Body\n"
        #expect(Frontmatter.parse(Frontmatter.split(content).block ?? "")
                == ["name": "simplicity", "description": "Prefer less code"])
    }

    @Test("handles colons and quotes in values (the reason adh uses a real YAML parser)")
    func handlesColonsAndQuotes() {
        let content = "---\ntitle: \"Ratios: 1:2 and 3:4\"\nallowed: [a, b]\n---\nbody\n"
        let parsed = Frontmatter.parse(Frontmatter.split(content).block ?? "")
        #expect(parsed["title"] == "Ratios: 1:2 and 3:4")
        // DIVERGENCE, stated rather than hidden: adh's YAML parser returns the
        // list `['a', 'b']`; this reader has no parser and hands back the flow
        // sequence as written. `stringValue` is what keeps that out of a title.
        #expect(parsed["allowed"] == "[a, b]")
        #expect(Frontmatter.stringValue("allowed", in: content) == nil)
    }

    @Test("returns null when there is no frontmatter block")
    func noBlockIsNull() {
        #expect(Frontmatter.split("# Just a heading\n\ntext").block == nil)
        #expect(Frontmatter.split("").block == nil)
    }

    @Test("adh nulls a malformed or non-mapping block; this reader still reads its keys")
    func malformedBlockDiverges() {
        // adh: `parseFrontmatter('---\nname: *undef\n---\n')` is null, and so is
        // a top-level sequence — a real parser fails the whole block. This is
        // the residual divergence `Frontmatter.stringValue` documents; it is
        // recorded here so it cannot be discovered by surprise.
        #expect(Frontmatter.stringValue("name", in: "---\nname: *undef\n---\n") == "*undef")
        #expect(Frontmatter.parse(Frontmatter.split("---\n- a\n- b\n---\n").block ?? "").isEmpty)
    }

    // MARK: - the frontmatter column

    @Test("the frontmatter column is typed JSON, the shape adh's parser produces")
    func frontmatterColumnIsTyped() {
        // adh parses the block with a YAML parser and stores the result as
        // JSONB, so `pinned: true` is the JSON boolean `true`. This client
        // recomputes the same column on the same write; if it stringified,
        // every write would be followed by the server rewriting the column,
        // and the row would read dirty on every round trip forever.
        let content = "---\npinned: true\norder: 3\ntitle: Notes\nempty:\ngone: null\n---\nbody\n"
        #expect(Frontmatter.jsonText(for: content)
                == #"{"empty":null,"gone":null,"order":3,"pinned":true,"title":"Notes"}"#)
    }

    @Test("a flow sequence reaches the column as a JSON array, as adh's parser gives it")
    func frontmatterColumnTypesFlowSequences() {
        // The companion to `handlesColonsAndQuotes` below: `parse` still hands
        // the flow sequence back as written, because the local text readers
        // want the text — but the COLUMN is typed, and here it agrees with
        // adh's `['a', 'b']`.
        let content = "---\ntitle: \"Ratios: 1:2 and 3:4\"\nallowed: [a, b]\n---\nbody\n"
        #expect(Frontmatter.jsonText(for: content)
                == #"{"allowed":["a","b"],"title":"Ratios: 1:2 and 3:4"}"#)
    }

    @Test("DIVERGENCE: a block sequence is flattened away, where adh's parser keeps it")
    func frontmatterColumnFlattensBlockSequences() {
        // A list written in block form puts its items on indented lines, and
        // this reader does not descend into them — adh's parser gives
        // `{"allowed":["a","b"]}` and this gives the key a null. Closing it
        // means becoming a YAML parser, which a foundation-tier package that
        // builds for five platforms does not get to do. Written down here so
        // it cannot be discovered by surprise.
        let content = "---\nallowed:\n  - a\n  - b\n---\nbody\n"
        #expect(Frontmatter.jsonText(for: content) == #"{"allowed":null}"#)
    }

    @Test("DIVERGENCE: a flow mapping, a block scalar and an alias reach the column as text")
    func frontmatterColumnKeepsUntypeableScalarsAsText() {
        // Same root cause as the block sequence, same choice: hand back the
        // text rather than guess at a type. adh's parser would give an object,
        // the folded string, and a parse failure that nulls the WHOLE block.
        #expect(Frontmatter.jsonText(for: "---\nk: {a: 1}\n---\nb\n") == #"{"k":"{a: 1}"}"#)
        #expect(Frontmatter.jsonText(for: "---\nk: >-\n  folded\n---\nb\n") == #"{"k":">-"}"#)
        #expect(Frontmatter.jsonText(for: "---\nname: *undef\n---\n") == #"{"name":"*undef"}"#)
    }

    @Test("a document with no block has no column value at all")
    func frontmatterColumnIsNullWithoutABlock() {
        #expect(Frontmatter.jsonText(for: "# Just a heading\n") == nil)
    }

    // MARK: - deriveTitle

    @Test("prefers frontmatter title, then name")
    func prefersTitleThenName() {
        #expect(MarkdownText.deriveTitle("---\ntitle: T\nname: N\n---\nx") == "T")
        #expect(MarkdownText.deriveTitle("---\nname: N\n---\nx") == "N")
    }

    @Test("ignores a non-string frontmatter title/name (no crash) and falls through")
    func ignoresNonStringFrontmatterTitle() {
        // array title ignored -> body
        #expect(MarkdownText.deriveTitle("---\ntitle: [1, 2]\n---\n# H") == "H")
        // number ignored -> name
        #expect(MarkdownText.deriveTitle("---\ntitle: 42\nname: N\n---\nbody line") == "N")
        // -> Untitled, never slice a non-string
        #expect(MarkdownText.deriveTitle("---\ntitle: 42\n---\n") == MarkdownText.untitled)
        // a QUOTED 42 is a string, and is taken
        #expect(MarkdownText.deriveTitle("---\ntitle: \"42\"\n---\n# H") == "42")
        // a block-scalar indicator is not a title either
        #expect(MarkdownText.deriveTitle("---\ntitle: >-\n---\n# H") == "H")
        #expect(MarkdownText.deriveTitle("---\ntitle: |2-\n---\n# H") == "H")
        #expect(MarkdownText.deriveTitle("---\ntitle: true\nname: N\n---\nx") == "N")
        #expect(MarkdownText.deriveTitle("---\ntitle: ~\nname: N\n---\nx") == "N")
    }

    @Test("falls back to the first body line (ignoring the frontmatter block itself)")
    func fallsBackToFirstBodyLine() {
        #expect(MarkdownText.deriveTitle("---\nfoo: bar\n---\n\n# The Real Title\n\nbody")
                == "The Real Title")
    }

    @Test("takes a PLAIN first line — a document needs no heading to have a title")
    func takesAPlainFirstLine() {
        #expect(MarkdownText.deriveTitle("plain text, no heading\n\nmore body")
                == "plain text, no heading")
    }

    @Test("skips blank lines to reach the first line with text")
    func skipsBlankLines() {
        #expect(MarkdownText.deriveTitle("\n\n   \n\nthe first real line\nnext")
                == "the first real line")
    }

    @Test("strips the markdown syntax a line OPENS with")
    func stripsOpeningSyntax() {
        #expect(MarkdownText.deriveTitle("# Hello") == "Hello")
        #expect(MarkdownText.deriveTitle("###   Hello") == "Hello")
        #expect(MarkdownText.deriveTitle("- Hello") == "Hello")
        #expect(MarkdownText.deriveTitle("* Hello") == "Hello")
        #expect(MarkdownText.deriveTitle("1. Hello") == "Hello")
        #expect(MarkdownText.deriveTitle("1) Hello") == "Hello")
        #expect(MarkdownText.deriveTitle("> Hello") == "Hello")
        #expect(MarkdownText.deriveTitle("> # Hello") == "Hello")
    }

    @Test("keeps scanning past a line that is nothing BUT syntax")
    func keepsScanningPastBareSyntax() {
        #expect(MarkdownText.deriveTitle("#\n\nthe real first line") == "the real first line")
        #expect(MarkdownText.deriveTitle(">\n-\n\nthe real first line") == "the real first line")
    }

    @Test("keeps text that only LOOKS like syntax (no space = not a heading)")
    func keepsTextThatLooksLikeSyntax() {
        #expect(MarkdownText.deriveTitle("#hashtag opener") == "#hashtag opener")
        // Seven hashes cannot match `#{1,6}` followed by a space or EOL.
        #expect(MarkdownText.deriveTitle("####### Seven hashes") == "####### Seven hashes")
    }

    @Test("strips only what the line opens with — inline syntax is kept")
    func keepsInlineSyntax() {
        #expect(MarkdownText.deriveTitle("## **Bold** and `code` and [a link](http://x)\n")
                == "**Bold** and `code` and [a link](http://x)")
        #expect(MarkdownText.deriveTitle("[Label](https://x)\n") == "[Label](https://x)")
        // The list marker goes; GFM's task marker is not one of adh's three.
        #expect(MarkdownText.deriveTitle("- [ ] a task\n") == "[ ] a task")
    }

    @Test("applies the three patterns once each, not to a fixed point")
    func appliesEachPatternOnce() {
        // `>` is stripped; the heading pattern then fails because the line
        // opens with `-`; the list pattern strips `- `, leaving `# Title`.
        #expect(MarkdownText.deriveTitle("> - # Title\n") == "# Title")
    }

    @Test("falls back to Untitled only when there is no text at all")
    func untitledOnlyWhenEmpty() {
        #expect(MarkdownText.deriveTitle("") == MarkdownText.untitled)
        #expect(MarkdownText.deriveTitle("\n\n   \n") == MarkdownText.untitled)
    }

    @Test("ignores an empty frontmatter title and uses name")
    func ignoresEmptyFrontmatterTitle() {
        #expect(MarkdownText.deriveTitle("---\ntitle: \"\"\nname: N\n---\nx") == "N")
    }

    @Test("ignores a line inside a code fence")
    func ignoresFencedLines() {
        #expect(MarkdownText.deriveTitle("```\n# not the title\n```\n\n# Real Title\n")
                == "Real Title")
        #expect(MarkdownText.deriveTitle("~~~\n# Not the title\n~~~\n\nReal title\n")
                == "Real title")
        // The backtick pattern runs first and swallows the `~~~` with it.
        #expect(MarkdownText.deriveTitle("```\n~~~\n# Inside\n```\n\nReal title\n")
                == "Real title")
    }

    @Test("has no CommonMark minimum-length rule: a ragged fence pairs lazily")
    func raggedFencePairsLazily() {
        // /```[\s\S]*?```/ pairs the first three backticks of the ```` opener
        // with the three on the next line; the unterminated-fence pattern then
        // runs from the ```` on line four to EOF.
        #expect(MarkdownText.deriveTitle("````\n```\n# Inside\n````\n\nReal title\n") == "Inside")
    }

    @Test("ignores everything inside an UNTERMINATED code fence (falls back to Untitled)")
    func unterminatedFenceRunsToEOF() {
        #expect(MarkdownText.deriveTitle("```\n# not the title (fence never closes)\n\nmore text\n")
                == MarkdownText.untitled)
    }

    @Test("caps the derived title at the column width (500)")
    func capsTitleAt500() {
        #expect(MarkdownText.deriveTitle(String(repeating: "x", count: 600)).count == 500)
        let content = "---\ntitle: " + String(repeating: "y", count: 600) + "\n---\nbody"
        #expect(MarkdownText.deriveTitle(content).count == 500)
    }

    // MARK: - deriveExcerpt

    @Test("is the lines AFTER the one the title came from")
    func excerptStartsAfterTheTitleLine() {
        #expect(MarkdownText.deriveExcerpt("the title\nsecond\nthird") == "second\nthird")
    }

    @Test("spends no body line when frontmatter named the title")
    func excerptSpendsNoLineWhenFrontmatterNames() {
        #expect(MarkdownText.deriveExcerpt("---\ntitle: T\n---\nfirst line\nsecond")
                == "first line\nsecond")
    }

    @Test("stops at four lines")
    func excerptStopsAtFour() {
        #expect(MarkdownText.deriveExcerpt("t\na\nb\nc\nd\ne\nf") == "a\nb\nc\nd")
    }

    @Test("skips blanks rather than counting them as preview lines")
    func excerptSkipsBlanks() {
        #expect(MarkdownText.deriveExcerpt("t\n\n\na\n\nb") == "a\nb")
    }

    @Test("strips the markdown syntax each line opens with, exactly as the title does")
    func excerptStripsOpeningSyntax() {
        #expect(MarkdownText.deriveExcerpt("# Title\n- one\n* two\n1. three\n> four")
                == "one\ntwo\nthree\nfour")
        // ...and keeps inline syntax, exactly as the title does.
        #expect(MarkdownText.deriveExcerpt("Title\n**Bold line**\n[L](u)")
                == "**Bold line**\n[L](u)")
    }

    @Test("is empty when the body holds nothing past its title")
    func excerptCanBeEmpty() {
        #expect(MarkdownText.deriveExcerpt("just a title") == "")
        #expect(MarkdownText.deriveExcerpt("") == "")
        #expect(MarkdownText.deriveExcerpt("   \n\n") == "")
    }

    @Test("ignores the frontmatter block and code fences, like the title derivation")
    func excerptIgnoresFrontmatterAndFences() {
        #expect(MarkdownText.deriveExcerpt("---\nfoo: bar\n---\ntitle line\nbody line")
                == "body line")
        #expect(MarkdownText.deriveExcerpt("title line\n```\nfenced\n```\nafter") == "after")
    }

    @Test("caps each line so one long paragraph cannot make the excerpt unbounded")
    func excerptCapsEachLine() {
        let lines = MarkdownText.deriveExcerpt("t\n" + String(repeating: "x", count: 400))
            .components(separatedBy: "\n")
        #expect(lines.count == 1)
        #expect(lines[0].count == MarkdownText.excerptLineCharacters)
    }

    // MARK: - EXCERPT_SOURCE_CHARS

    @Test("the list projection cuts its excerpt from the first 2000 characters only")
    func excerptSourceWindow() {
        #expect(MarkdownText.excerptSourceCharacters == 2000)
        let filler = String(repeating: "-\n", count: 1200)   // > 2000 characters of bare syntax
        let document = MarkdownDocument.new(
            id: "0198c0de-0000-7000-8000-000000000002",
            content: "the title\n" + filler + "past the window\n",
            ownerKind: .customer,
            ownerID: "local")
        // The title sees the whole document; the excerpt sees only the window,
        // which here holds nothing but bare list markers.
        #expect(document.title == "the title")
        #expect(document.excerpt == "")
        // Unwindowed, the same content does reach the line — which is exactly
        // the asymmetry the two properties document.
        #expect(MarkdownText.deriveExcerpt(document.content) == "past the window")
    }

    @Test("windows the body but not the frontmatter, as adh's list handler does")
    func excerptWindowKeepsWholeDocumentFrontmatter() {
        // adh calls `deriveExcerpt(left(content, 2000), row.frontmatter)`, and
        // `row.frontmatter` was parsed from the WHOLE document on write. So a
        // `---` block that runs past the window still names the title, and the
        // excerpt therefore spends no body line skipping one.
        let padding = String(repeating: "p", count: 2500)
        let document = MarkdownDocument.new(
            id: "0198c0de-0000-7000-8000-000000000003",
            content: "---\ntitle: T\npad: " + padding + "\n---\nbody line\n",
            ownerKind: .customer,
            ownerID: "local")
        #expect(document.title == "T")
        // The window ends mid-`pad:`, so the truncated body has no closing
        // `---` and adh's frontmatter regex does not match it: every line of
        // the opened block becomes a preview line, starting at the first.
        let lines = document.excerpt.components(separatedBy: "\n")
        #expect(lines.count == 3)
        #expect(lines[0] == "---")
        #expect(lines[1] == "title: T")
        #expect(lines[2] == "pad: " + String(repeating: "p", count: 155))
    }

    // MARK: - the units adh cuts in

    @Test("caps the title at 500 UTF-16 code units, not 500 grapheme clusters")
    func titleCapCountsUTF16CodeUnits() {
        // JavaScript's `.slice(0, 500)` counts code units, so 600 astral emoji
        // (two units each) cap at 250 of them — not 500.
        let title = MarkdownText.deriveTitle(String(repeating: "\u{1F600}", count: 600))
        #expect(title.utf16.count == 500)
        #expect(title.count == 250)
    }

    @Test("drops a surrogate pair the 500th code unit would split")
    func titleCapSplittingASurrogatePairDropsIt() {
        // adh's cut lands between the two halves of the emoji and yields an
        // unpaired surrogate; a Swift `String` cannot hold one, so we stop at
        // the last whole scalar — 499 code units — rather than invent a
        // character. This is the single documented divergence in the port.
        let content = String(repeating: "a", count: 499) + "\u{1F600}" + " and more\n"
        let title = MarkdownText.deriveTitle(content)
        #expect(title.utf16.count == 499)
        #expect(title == String(repeating: "a", count: 499))
    }

    @Test("caps an excerpt line at 160 UTF-16 code units, splitting a cluster if adh does")
    func excerptLineCapCountsUTF16CodeUnits() {
        // "e" + U+0301 is one Character but two code units. adh keeps 80 of
        // them; `prefix(160)` would have kept 160 and produced a 320-unit line.
        let accented = String(repeating: "e\u{0301}", count: 200)
        let wide = MarkdownText.deriveExcerpt("t\n" + accented)
        #expect(wide.utf16.count == 160)
        #expect(wide.count == 80)

        // And the cut lands mid-cluster when adh's does: the 160th code unit is
        // the base "e", the combining mark is the 161st and is dropped.
        let split = MarkdownText.deriveExcerpt(
            "t\n" + String(repeating: "x", count: 159) + "e\u{0301}z")
        #expect(split.utf16.count == 160)
        #expect(split == String(repeating: "x", count: 159) + "e")
    }

    @Test("windows the excerpt source in scalars, the unit Postgres' left() counts")
    func excerptWindowCountsUnicodeScalars() {
        // The window is `left(content, 2000)` in SQL, not a `.slice`, and
        // Postgres counts characters — one Unicode scalar each in a UTF-8
        // database. "e" + U+0301 is two of them, so 2500 of those sequences
        // window down to 1000, where `prefix(2000)` would have kept 2000.
        let accented = String(repeating: "e\u{0301}", count: 2500)
        let source = MarkdownText.excerptSource(accented)
        #expect(source.unicodeScalars.count == 2000)
        #expect(source.count == 1000)

        // An astral emoji is one scalar and one Character, so the window keeps
        // 2000 of them — two thousand characters, four thousand code units.
        let emoji = MarkdownText.excerptSource(String(repeating: "\u{1F600}", count: 2500))
        #expect(emoji.unicodeScalars.count == 2000)
        #expect(emoji.utf16.count == 4000)
    }
}
