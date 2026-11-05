import Testing
import Foundation
@testable import AgenticDeveloperHubSDK

@Suite("MarkdownDocument")
struct MarkdownDocumentTests {

    private func document(_ content: String) -> MarkdownDocument {
        MarkdownDocument.new(
            id: "0198c0de-0000-7000-8000-000000000001",
            content: content,
            ownerKind: .customer,
            ownerID: "local"
        )
    }

    @Test("a new document derives its title and excerpt from its content")
    func derivesTitleAndExcerpt() {
        let doc = document("# Hello\n\nworld\n")
        #expect(doc.title == "Hello")
        #expect(doc.excerpt == "world")
    }

    @Test("editing the content re-derives the title")
    func titleFollowsContent() {
        var doc = document("# Hello\n")
        doc.content = "# Goodbye\n"
        #expect(doc.title == "Goodbye")
    }

    @Test("a new document is a private draft owned by its creator")
    func defaultsMatchAdh() {
        let doc = document("body")
        #expect(doc.visibility == .private)
        #expect(doc.stage == .draft)
        #expect(doc.publicRoute == nil)
        #expect(doc.deletedAt == nil)
        #expect(doc.isDeleted == false)
        #expect(doc.currentVersion == 1)   // adh's column default
        #expect(doc.latestVersionID == nil)
    }

    @Test("size and hash track the content")
    func sizeAndHashTrackContent() {
        let doc = document("abc")
        #expect(doc.sizeBytes == 3)
        #expect(doc.contentHash == MarkdownText.contentHash("abc"))
    }

    @Test("frontmatter is exposed as a parsed map and as canonical JSON")
    func exposesFrontmatter() {
        let doc = document("---\nb: 2\na: 1\n---\nbody\n")
        // Two projections of one block, on purpose: `frontmatter` is the local
        // text map every reader here wants, and `frontmatterJSON` is the
        // column, which adh computes with a real YAML parser and types.
        #expect(doc.frontmatter == ["a": "1", "b": "2"])
        #expect(doc.frontmatterJSON == #"{"a":1,"b":2}"#)
    }

    @Test("the frontmatter column carries YAML's types, so it survives a sync round trip")
    func frontmatterJSONIsTyped() {
        let doc = document("---\npinned: true\norder: 3\ntitle: Hi\n---\nbody\n")
        #expect(doc.frontmatterJSON == #"{"order":3,"pinned":true,"title":"Hi"}"#)
    }

    @Test("a document with no frontmatter has no frontmatter JSON")
    func frontmatterCanBeAbsent() {
        let doc = document("body\n")
        #expect(doc.frontmatter.isEmpty)
        #expect(doc.frontmatterJSON == nil)
    }

    @Test("pinning writes frontmatter and unpinning removes it")
    func pinRoundTrips() {
        var doc = document("# Hi\n")
        #expect(doc.isPinned == false)
        doc.setPinned(true)
        #expect(doc.isPinned)
        // A YAML boolean, bare. Every other reader of the document — the web
        // editor above all — expects `pinned: true`, not the string "true".
        #expect(doc.content == "---\npinned: true\n---\n# Hi\n")
        // What adh's own reader would make of it: `stringValue` returns a
        // value only for a scalar YAML types as a string, so a `nil` here is
        // the assertion that the boolean went out as a boolean.
        #expect(Frontmatter.stringValue("pinned", in: doc.content) == nil)
        doc.setPinned(false)
        #expect(doc.isPinned == false)
        #expect(doc.content == "# Hi\n")
    }

    @Test("pinning does not disturb the derived title")
    func pinningLeavesTitleAlone() {
        var doc = document("# Hi\n")
        doc.setPinned(true)
        #expect(doc.title == "Hi")
    }
}
