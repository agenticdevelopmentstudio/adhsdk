import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("MarkdownText")
struct MarkdownTextTests {

    @Test("the title is the first heading, without its hashes")
    func titleFromHeading() {
        #expect(MarkdownText.deriveTitle("# Release notes\n\nbody\n") == "Release notes")
    }

    @Test("a document with no heading uses its first line of prose")
    func titleFromProse() {
        #expect(MarkdownText.deriveTitle("just some prose\nand more\n") == "just some prose")
    }

    @Test("a frontmatter title wins over the body's first heading")
    func titleComesFromFrontmatter() {
        // adh's server derives the title the same way and rewrites the column
        // on every write: a local rule that read the heading instead would
        // make the title flip on each sync round trip.
        #expect(MarkdownText.deriveTitle("---\ntitle: Meta\n---\n# Real\n") == "Meta")
    }

    @Test("frontmatter without a title or name leaves the body to supply one")
    func titleFallsThroughUnrelatedFrontmatter() {
        #expect(MarkdownText.deriveTitle("---\npinned: true\n---\n# Real\n") == "Real")
    }

    @Test("frontmatter name is the fallback, and loses to title when both are set")
    func titleFallsBackToFrontmatterName() {
        #expect(MarkdownText.deriveTitle("---\nname: Named\n---\n# Real\n") == "Named")
        #expect(MarkdownText.deriveTitle("---\ntitle: Titled\nname: Named\n---\n# Real\n") == "Titled")
    }

    @Test("an empty or whitespace-only frontmatter title is not a title")
    func blankFrontmatterTitleIsSkipped() {
        #expect(MarkdownText.deriveTitle("---\ntitle: \"   \"\nname: Named\n---\n# Real\n") == "Named")
        #expect(MarkdownText.deriveTitle("---\ntitle: \"\"\n---\n# Real\n") == "Real")
    }

    @Test("a frontmatter title is capped like any other")
    func frontmatterTitleIsCapped() {
        let content = "---\ntitle: " + String(repeating: "a", count: 900) + "\n---\nbody\n"
        #expect(MarkdownText.deriveTitle(content).count == MarkdownText.titleCharacterLimit)
    }

    @Test("the excerpt keeps the first body line when frontmatter named the title")
    func excerptSkipsNoLineWhenFrontmatterTitles() {
        // Exactly one line is skipped when the body supplied the title and
        // none when frontmatter did — otherwise the preview loses a line.
        #expect(MarkdownText.deriveExcerpt("---\ntitle: Meta\n---\nfirst\nsecond\n") == "first\nsecond")
        #expect(MarkdownText.deriveExcerpt("# Title\n\nfirst\nsecond\n") == "first\nsecond")
    }

    @Test("a fenced code block is not a title")
    func titleSkipsCodeFences() {
        #expect(MarkdownText.deriveTitle("```\nlet x = 1\n```\n\nReal title\n") == "Real title")
    }

    @Test("inline syntax is kept in the title, because adh keeps it")
    func titleKeepsInlineSyntax() {
        // adh's `stripLineSyntax` removes only what a line OPENS with — quote
        // arrows, heading hashes, list markers. Emphasis, code spans and links
        // survive into its title, so they survive into ours: a local rule that
        // stripped them would fight the column adh rewrites on every write.
        #expect(MarkdownText.deriveTitle("## **Bold** and `code` and [a link](http://x)\n")
                == "**Bold** and `code` and [a link](http://x)")
    }

    @Test("an empty document has no title to derive")
    func titleFallsBack() {
        #expect(MarkdownText.deriveTitle("   \n\n") == MarkdownText.untitled)
        #expect(MarkdownText.deriveTitle("") == MarkdownText.untitled)
    }

    @Test("a very long first line is capped rather than stored whole")
    func titleIsCapped() {
        let title = MarkdownText.deriveTitle(String(repeating: "a", count: 900))
        #expect(title.count == MarkdownText.titleCharacterLimit)
    }

    @Test("the excerpt takes the lines after the title, capped in count and width")
    func excerptTakesFollowingLines() {
        let content = "# Title\n\nfirst\nsecond\nthird\nfourth\nfifth\n"
        #expect(MarkdownText.deriveExcerpt(content) == "first\nsecond\nthird\nfourth")
    }

    @Test("each excerpt line is truncated on its own")
    func excerptTruncatesEachLine() {
        let content = "# Title\n\n" + String(repeating: "b", count: 400) + "\n"
        let excerpt = MarkdownText.deriveExcerpt(content)
        #expect(excerpt.count == MarkdownText.excerptLineCharacters)
    }

    @Test("a title-only document has an empty excerpt")
    func excerptCanBeEmpty() {
        #expect(MarkdownText.deriveExcerpt("# Title\n") == "")
    }

    @Test("the content hash is a stable lowercase SHA-256 of the UTF-8 bytes")
    func contentHashIsStable() {
        // `printf 'abc' | shasum -a 256`
        #expect(MarkdownText.contentHash("abc")
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        // `printf '' | shasum -a 256`
        #expect(MarkdownText.contentHash("")
                == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        // `printf '# Hello\n' | shasum -a 256` — a real document's bytes,
        // newline included, so the vector pins the encoding too.
        #expect(MarkdownText.contentHash("# Hello\n")
                == "90f8ec5669cd34183b9b0fdf8b94f5efb4c3672876330f4aa76088c2b4ad17be")
    }

    @Test("byteLength counts UTF-8 bytes, not characters")
    func byteLengthCountsBytes() {
        #expect(MarkdownText.byteLength("é") == 2)
        #expect(MarkdownText.byteLength("abc") == 3)
    }

    @Test("CRLF content does not leak a carriage return into the title or excerpt")
    func crlfLineEndings() {
        let content = "# Shopping list\r\n\r\nMilk\r\nBread\r\n"
        #expect(MarkdownText.deriveTitle(content) == "Shopping list")
        #expect(!MarkdownText.deriveExcerpt(content).contains("\r"))
    }

    @Test("a document that is only frontmatter still takes its title from it")
    func frontmatterOnly() {
        let content = "---\ntitle: Named\n---\n"
        #expect(MarkdownText.deriveTitle(content) == "Named")
        #expect(MarkdownText.deriveExcerpt(content).isEmpty)
    }

    @Test("a document that is only frontmatter with no title or name has neither")
    func frontmatterOnlyWithoutATitleKey() {
        let content = "---\npinned: true\n---\n"
        #expect(MarkdownText.deriveTitle(content) == MarkdownText.untitled)
        #expect(MarkdownText.deriveExcerpt(content).isEmpty)
    }

    @Test("a tilde-fenced code block is not a title")
    func titleSkipsTildeFences() {
        #expect(MarkdownText.deriveTitle("~~~\n# Not the title\n~~~\n\nReal title\n") == "Real title")
    }

    @Test("a fence only closes on its own marker — but adh has no minimum-length rule")
    func fenceMarkersDoNotCrossOver() {
        // The `~~~` inside the backtick block is content, not a closing fence,
        // so the heading after the real close is still the title. That much
        // adh and CommonMark agree on: the backtick pattern runs first and
        // pairs the two ``` lines, taking the ~~~ with it.
        #expect(MarkdownText.deriveTitle("```\n~~~\n# Inside\n```\n\nReal title\n") == "Real title")
        // CommonMark says a three-backtick run cannot close a four-backtick
        // opener; adh's lazy /```[\s\S]*?```/ has no such rule, so it pairs the
        // first three backticks of the opener with the three on the next line,
        // and the unterminated-fence pattern then eats from the ```` on the
        // fourth line to EOF. `Inside` is left as the only body line — which
        // is the title the server stores, so it is the title we store.
        #expect(MarkdownText.deriveTitle("````\n```\n# Inside\n````\n\nReal title\n") == "Inside")
    }

    @Test("an unterminated fence swallows the rest of the document")
    func unterminatedFenceRunsToEndOfFile() {
        // Without this rule a single stray fence would let a `#` line inside
        // the resulting code block become the title.
        #expect(MarkdownText.deriveTitle("Real title\n\n```\n# Not the title\nstill code\n")
                == "Real title")
        #expect(MarkdownText.deriveTitle("```\n# Not the title\n") == MarkdownText.untitled)
        #expect(MarkdownText.deriveExcerpt("Real title\n\n```\n# Not the title\n").isEmpty)
    }
}
