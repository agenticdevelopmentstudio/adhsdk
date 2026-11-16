import XCTest
@testable import AgenticDeveloperHubSDKMacOS
@testable import AgenticDeveloperHubSDKCore

/// `AgentPageBuilder` and the three renderings of `AgentPage` (the Agent
/// Page Builder recipe, vectors 001–015, 032, 033).
final class AgentPageBuilderTests: XCTestCase {

    // MARK: Fixtures

    private let acme = BrowserAgentPrivacy.enabled(
        TextSubstitutionFilter(pairs: [.init(alias: "Zed", real: "Acme")]))

    private func node(_ ref: String, _ kind: String, text: String? = nil, attrs: [String: String]? = nil,
                      value: String? = nil, children: [[String: Any]] = []) -> [String: Any] {
        var out: [String: Any] = ["ref": ref, "kind": kind, "selector": "#\(ref)"]
        if let text { out["text"] = text }
        if let attrs { out["attrs"] = attrs }
        if let value { out["value"] = value }
        if !children.isEmpty { out["children"] = children }
        return out
    }

    private func document(_ children: [[String: Any]]) -> [String: Any] {
        node("e0", "document", children: children)
    }

    private func payload(_ root: [String: Any], url: String = "https://site.example/",
                         title: String = "Page") -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: ["url": url, "title": title, "root": root])
        } catch {
            XCTFail("payload did not serialize: \(error)")
            return Data()
        }
    }

    private func build(_ root: [String: Any], privacy: BrowserAgentPrivacy = .off, hideImages: Bool = false,
                       title: String = "Page") -> AgentPage {
        AgentPageBuilder(privacy: privacy, hideImages: hideImages)
            .build(payload: payload(root, title: title), error: nil)
    }

    private func allRenderings(_ page: AgentPage) -> [String] {
        var full = BrowserSnapshotOptions()
        full.includeURLs = true
        return [page.snapshotTree(BrowserSnapshotOptions()), page.snapshotTree(full), page.text(), page.html()]
    }

    private func assertUnavailable(_ page: AgentPage, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNil(page.root, file: file, line: line)
        XCTAssertTrue(page.unavailableReason?.hasPrefix("Agent view unavailable: ") ?? false,
                      "reason: \(page.unavailableReason ?? "nil")", file: file, line: line)
        XCTAssertEqual(page.text(), page.unavailableReason, file: file, line: line)
        XCTAssertEqual(page.snapshotTree(BrowserSnapshotOptions()), page.unavailableReason, file: file, line: line)
    }

    private struct WalkerFailed: Error {}

    // MARK: Allowlist

    func test_unknownKindDroppedWithSubtree() {
        let page = build(document([
            node("e1", "paragraph", children: [node("e2", "text", text: "outer")]),
            node("e3", "iframe", children: [node("e4", "text", text: "inner secret")])
        ]))
        XCTAssertTrue(page.text().contains("outer"))
        for rendering in allRenderings(page) { XCTAssertFalse(rendering.contains("inner secret"), rendering) }
        XCTAssertNil(page.node(ref: "e3"))
        XCTAssertNil(page.node(ref: "e4"))
    }

    func test_attributeNotOnAllowlistDropped() {
        let page = build(document([
            node("e1", "link", text: "Go", attrs: ["onclick": "steal()", "href": "https://a.example/"])
        ]))
        let link = page.node(ref: "e1")
        XCTAssertEqual(link?.attributes, ["href": "https://a.example/"])
        for rendering in allRenderings(page) { XCTAssertFalse(rendering.contains("steal"), rendering) }
    }

    func test_hrefSanitizedAndConcealed() {
        let page = build(document([
            node("e1", "link", text: "one", attrs: ["href": "javascript:alert(1)"]),
            node("e2", "link", text: "two", attrs: ["href": "data:text/html,x"]),
            node("e3", "link", text: "three", attrs: ["href": "/p?u=Acme"])
        ]), privacy: acme)
        XCTAssertNil(page.node(ref: "e1")?.attributes["href"])
        XCTAssertNil(page.node(ref: "e2")?.attributes["href"])
        XCTAssertEqual(page.node(ref: "e3")?.attributes["href"], "https://site.example/p?u=Zed")
        for rendering in allRenderings(page) {
            XCTAssertFalse(rendering.contains("Acme"), rendering)
            XCTAssertFalse(rendering.contains("javascript:"), rendering)
            XCTAssertFalse(rendering.contains("data:text"), rendering)
        }
    }

    func test_concealedBeforeInsertion() {
        let page = build(document([
            node("e1", "heading", text: "Acme news", attrs: ["level": "1"]),
            node("e2", "textField", text: "Company", attrs: ["type": "text"], value: "Acme Ltd"),
            node("e3", "button", text: "Go", attrs: ["aria-label": "Visit Acme", "title": "Acme tip"]),
            node("e4", "paragraph", text: "About Acme")
        ]), privacy: acme, title: "Acme Home")
        XCTAssertEqual(page.title, "Zed Home")
        let renderings = allRenderings(page)
        for rendering in renderings {
            XCTAssertFalse(rendering.contains("Acme"), rendering)
            XCTAssertTrue(rendering.contains("Zed"), rendering)
        }
        XCTAssertEqual(page.node(ref: "e2")?.value, "Zed Ltd")
        XCTAssertEqual(page.node(ref: "e3")?.attributes["aria-label"], "Visit Zed")
        XCTAssertEqual(page.node(ref: "e3")?.attributes["title"], "Zed tip")
        XCTAssertTrue(page.html().contains("<title>Zed Home</title>"))
    }

    func test_passwordValueNeverKept() {
        let page = build(document([
            node("e1", "textField", text: "User", attrs: ["type": "text"], value: "hello"),
            node("e2", "textField", text: "Password", attrs: ["type": "password"], value: "hunter2"),
            node("e3", "button", text: "Sign in", value: "go"),
            node("e4", "textArea", text: "Notes", value: "private notes")
        ]))
        XCTAssertEqual(page.node(ref: "e1")?.value, "hello")
        XCTAssertNil(page.node(ref: "e2")?.value)
        XCTAssertNil(page.node(ref: "e3")?.value)
        XCTAssertEqual(page.node(ref: "e4")?.value, "private notes")
        XCTAssertTrue(page.snapshotTree(BrowserSnapshotOptions()).contains("[value=\"hello\"]"))
        for rendering in allRenderings(page) {
            XCTAssertFalse(rendering.contains("hunter2"), rendering)
            XCTAssertFalse(rendering.contains("value=\"go\""), rendering)
        }
    }

    func test_textAreaValueShownAsLegacy() {
        let page = build(document([
            node("e1", "textArea", text: "Notes", value: "Line one\n   line two"),
            node("e2", "textArea", text: "Empty", value: ""),
            node("e3", "textArea", text: "Blank", value: "\n   ")
        ]), title: "T")
        XCTAssertEqual(page.node(ref: "e1")?.value, "Line one\n   line two")
        XCTAssertEqual(page.snapshotTree(BrowserSnapshotOptions()), """
        - document "T":
          - textbox "Notes" [ref=e1] [value="Line one line two"]
          - textbox "Empty" [ref=e2]
          - textbox "Blank" [ref=e3] [value=""]

        """)
        XCTAssertTrue(page.html().contains(">Line one\n   line two</textarea>"), page.html())
    }

    func test_inlineTextConcatenatedAsTextContent() {
        // `<p>a<b>b</b></p>` and `<button>Sign<b>in</b></button>`: textContent has no separator.
        let page = build(document([
            node("e1", "paragraph", children: [node("e2", "text", text: "a"), node("e3", "text", text: "b")]),
            node("e4", "button", text: "Sign", children: [node("e5", "text", text: "in")])
        ]), title: "T")
        XCTAssertEqual(page.snapshotTree(BrowserSnapshotOptions()), """
        - document "T":
          - text: ab
          - button "Signin" [ref=e4]

        """)
    }

    func test_privacyWordSplitAcrossTagsConcealed() {
        // `<p>Ac<b>me</b></p>`, `<button>Ac<b>me</b></button>`, an option and a
        // heading the same way: each piece alone holds no privacy word, the
        // joined text does, and is concealed once it is joined.
        let page = build(document([
            node("e1", "paragraph", children: [node("e2", "text", text: "Ac"), node("e3", "text", text: "me")]),
            node("e4", "button", text: "Ac", children: [node("e5", "text", text: "me")]),
            node("e6", "heading", attrs: ["level": "2"], children: [
                node("e7", "text", text: "Ac"), node("e8", "text", text: "me Co")
            ]),
            node("e9", "select", text: "Pick", children: [
                node("e10", "option", children: [node("e11", "text", text: "Ac"), node("e12", "text", text: "me")])
            ])
        ]), privacy: acme, title: "T")
        for rendering in allRenderings(page) {
            XCTAssertFalse(rendering.contains("Acme"), rendering)
            XCTAssertTrue(rendering.contains("Zed"), rendering)
        }
        let tree = page.snapshotTree(BrowserSnapshotOptions())
        XCTAssertTrue(tree.contains("- text: Zed\n"), tree)
        XCTAssertTrue(tree.contains("- button \"Zed\" [ref=e4]"), tree)
        XCTAssertTrue(tree.contains("- heading \"Zed Co\" [ref=e6] [level=2]"), tree)
        XCTAssertTrue(tree.contains("- option \"Zed\" [ref=e10]"), tree)
        XCTAssertTrue(page.html().contains(">Zed</option>"), page.html())
        XCTAssertTrue(page.text().contains("Zed"), page.text())
    }

    func test_tagBoundarySpaceKept() {
        // `<li>Buy <b>now</b></li>` and `<button>Buy <b>now</b></button>`: the walker
        // keeps "Buy "'s trailing space, so every rendering reads "Buy now" as
        // `innerText` does, and the tree keeps the legacy per-piece text lines.
        let page = build(document([
            node("e1", "list", children: [
                node("e2", "listItem", children: [node("t1", "text", text: "Buy "), node("t2", "text", text: "now")])
            ]),
            node("e3", "button", text: "Buy ", children: [node("t3", "text", text: "now ")]),
            node("e4", "paragraph", children: [node("t4", "text", text: " Sign "), node("t5", "text", text: "up")])
        ]), title: "T")
        XCTAssertEqual(page.text(), "Buy now\nBuy now\nSign up")
        XCTAssertTrue(page.html().contains(">Buy now</li>"), page.html())
        XCTAssertTrue(page.html().contains(">Buy now</button>"), page.html())
        XCTAssertEqual(page.snapshotTree(BrowserSnapshotOptions()), """
        - document "T":
          - list [ref=e1]:
            - listitem [ref=e2]:
              - text: Buy
              - text: now
          - button "Buy now" [ref=e3]
          - text: Sign up

        """)
        for rendering in allRenderings(page) { XCTAssertFalse(rendering.contains("Buynow"), rendering) }
    }

    func test_textKeepsTheWalkersLineBreaks() {
        // The walker's breaks: `<p>123 Main Street<br>Springfield</p>`, two
        // flattened `<div>`s, a `<pre>`. The page's text keeps each as a new
        // line as `innerText` does; the tree reads them as spaces.
        let page = build(document([
            node("g1", "paragraph", text: "123 Main Street\nSpringfield"),
            node("t1", "text", text: "\n\nPrice\n$10\n\n"),
            node("e2", "heading", text: "Code", attrs: ["level": "2"]),
            node("t2", "text", text: "\nlet a = 1\nlet b = 2\n"),
            node("e3", "listItem", children: [
                node("t3", "text", text: "Line "), node("t4", "text", text: "one"),
                node("t5", "text", text: "\n"), node("t6", "text", text: "line two")
            ])
        ]), title: "T")
        XCTAssertEqual(page.text(),
                       "123 Main Street\nSpringfield\nPrice\n$10\nCode\nlet a = 1\nlet b = 2\nLine one\nline two")
        let tree = page.snapshotTree(BrowserSnapshotOptions())
        XCTAssertTrue(tree.contains("- text: 123 Main Street Springfield\n"), tree)
        XCTAssertTrue(tree.contains("- text: Price $10\n"), tree)
        XCTAssertFalse(tree.contains("- text: \n"), tree)
        let html = page.html()
        XCTAssertTrue(html.contains("<p data-adk-ref=\"g1\">123 Main Street<br data-adk-ref=\"g1\">Springfield</p>"),
                      html)
        XCTAssertTrue(html.contains("<li data-adk-ref=\"e3\">Line one<br data-adk-ref=\"e3\">line two</li>"), html)
    }

    func test_privacyWordAcrossALineBreakStillConcealed() {
        // A break never carries a privacy word past the filter: text whose
        // one-line reading holds the word is concealed as that one line.
        let privacy = BrowserAgentPrivacy.enabled(
            TextSubstitutionFilter(pairs: [.init(alias: "Zed", real: "Acme Corp")]))
        let page = build(document([
            node("g1", "paragraph", text: "Acme\nCorp rocks"),
            node("g2", "paragraph", children: [node("t1", "text", text: "Acme"), node("t2", "text", text: "\nCorp")])
        ]), privacy: privacy)
        for rendering in allRenderings(page) {
            XCTAssertFalse(rendering.contains("Acme"), rendering)
            XCTAssertTrue(rendering.contains("Zed"), rendering)
        }
        XCTAssertEqual(page.text(), "Zed rocks\nZed")
    }

    func test_sliderAndSpinbuttonValueKept() {
        // A `role=slider` or `role=spinbutton` element arrives from the walker
        // as a text field of type range or number, its value `aria-valuenow`.
        let page = build(document([
            node("e1", "textField", attrs: ["type": "range", "aria-label": "Volume"], value: "40"),
            node("e2", "textField", text: "Count", attrs: ["type": "number"], value: "3")
        ]), title: "T")
        XCTAssertEqual(page.node(ref: "e1")?.value, "40")
        XCTAssertEqual(page.snapshotTree(BrowserSnapshotOptions()), """
        - document "T":
          - slider "Volume" [ref=e1] [value="40"]
          - spinbutton "Count" [ref=e2] [value="3"]

        """)
    }

    func test_hideImagesDropsImages() {
        let root = document([node("e1", "image", attrs: ["alt": "Logo", "src": "https://cdn.example/l.png"])])
        let hidden = build(root, hideImages: true)
        XCTAssertNil(hidden.node(ref: "e1"))
        for rendering in allRenderings(hidden) { XCTAssertFalse(rendering.contains("Logo"), rendering) }

        let shown = build(root, hideImages: false)
        XCTAssertTrue(shown.html().contains("<span data-adk-ref=\"e1\" class=\"adk-image\">[image: Logo]</span>"),
                      shown.html())
        for rendering in allRenderings(shown) {
            XCTAssertFalse(rendering.contains("cdn.example"), rendering)
            XCTAssertFalse(rendering.contains("src="), rendering)
        }
    }

    // MARK: Fail closed

    func test_malformedPayloadIsUnavailable() {
        let builder = AgentPageBuilder(privacy: .off, hideImages: false)
        assertUnavailable(builder.build(payload: Data("{".utf8), error: nil))
        assertUnavailable(builder.build(payload: nil, error: nil))
        assertUnavailable(builder.build(payload: Data("{\"error\":\"timeout\"}".utf8), error: nil))
    }

    func test_walkerErrorIsUnavailable() {
        let builder = AgentPageBuilder(privacy: .off, hideImages: false)
        let valid = payload(document([node("e1", "text", text: "content")]))
        let page = builder.build(payload: valid, error: WalkerFailed())
        assertUnavailable(page)
        XCTAssertFalse(page.html().contains("content"))
        assertUnavailable(builder.build(payload: nil, error: BrowserAutomationError.timeout("the agent walk")))
    }

    func test_vaultUnavailableIsUnavailable() {
        let page = AgentPageBuilder(privacy: .unavailable, hideImages: false)
            .build(payload: payload(document([node("e1", "text", text: "content")])), error: nil)
        assertUnavailable(page)
        XCTAssertFalse(page.html().contains("content"))
    }

    func test_conflictingIsUnavailable() {
        let page = AgentPageBuilder(privacy: .conflicting, hideImages: false)
            .build(payload: payload(document([node("e1", "text", text: "content")])), error: nil)
        assertUnavailable(page)
    }

    func test_unavailablePageRendersReasonAsOneParagraph() {
        let page = AgentPage.unavailable("the page could not be read.", url: nil)
        XCTAssertEqual(page.unavailableReason, "Agent view unavailable: the page could not be read.")
        XCTAssertTrue(page.html().contains("<body><p>Agent view unavailable: the page could not be read.</p></body>"))
    }

    // MARK: HTML

    func test_contentEditableFieldShowsItsContentInHTML() {
        // A webmail compose box: `<div contenteditable role=textbox>` holding
        // the draft. The agent's text and snapshot carry the draft, so the
        // preview shows it inside the field rather than an empty input.
        let page = build(document([
            node("e1", "textField", attrs: ["aria-label": "Message body"], children: [
                node("e2", "paragraph", children: [
                    node("t1", "text", text: "Dear "), node("t2", "text", text: "Acme")
                ]),
                node("e3", "link", text: "the offer", attrs: ["href": "https://site.example/offer"])
            ])
        ]), privacy: acme)
        let html = page.html()
        XCTAssertTrue(html.contains("<div data-adk-ref=\"e1\" aria-label=\"Message body\" class=\"adk-textfield\""
            + " role=\"textbox\" aria-disabled=\"true\">"), html)
        XCTAssertTrue(html.contains("<p data-adk-ref=\"e2\">Dear Zed</p>"), html)
        XCTAssertTrue(html.contains(">the offer</a></div>"), html)
        XCTAssertFalse(html.contains("<input"), html)
        XCTAssertFalse(html.contains("Acme"), html)
        XCTAssertTrue(page.text().contains("Dear Zed"), page.text())

        // A plain text field with no content is still a disabled input.
        let plain = build(document([node("e1", "textField", text: "Name", attrs: ["type": "text"], value: "Bo")]))
        XCTAssertTrue(plain.html().contains("<input data-adk-ref=\"e1\" type=\"text\" value=\"Bo\" disabled=\"\">"),
                      plain.html())
    }

    func test_htmlHasNoScriptOrStyle() {
        let page = build(document([
            node("e1", "paragraph", children: [node("e2", "text", text: "<script>x</script>")]),
            node("e3", "button", text: "Press", attrs: ["style": "color: red"]),
            node("e4", "textField", text: "Name", attrs: ["type": "text"], value: "\"><script>")
        ]))
        let html = page.html()
        XCTAssertTrue(html.contains("&lt;script&gt;x&lt;/script&gt;"), html)
        XCTAssertFalse(html.lowercased().contains("<script"), html)
        XCTAssertFalse(html.contains("style="), html)
        XCTAssertFalse(html.lowercased().contains("<style"), html)
        // Every element in the body carries its node's ref.
        let body = html.components(separatedBy: "<body").last ?? ""
        guard let regex = try? NSRegularExpression(pattern: "<([a-z][a-z0-9]*)(\\s[^>]*)?>") else {
            return XCTFail("tag pattern did not compile")
        }
        let range = NSRange(body.startIndex..., in: body)
        let matches = regex.matches(in: body, range: range)
        XCTAssertFalse(matches.isEmpty)
        for match in matches {
            let tag = String(body[Range(match.range, in: body)!])
                        XCTAssertTrue(tag.contains("data-adk-ref=\""), tag)
        }
    }

    // MARK: Snapshot format

    func test_snapshotTreeMatchesLegacyFormat() throws {
        let page = build(document([
            node("e1", "landmark", attrs: ["role": "navigation", "aria-label": "Primary"], children: [
                node("e2", "list", children: [
                    node("e3", "listItem", children: [
                        node("e4", "link", text: "Home", attrs: ["href": "/home"])
                    ])
                ])
            ]),
            node("e5", "landmark", attrs: ["role": "main"], children: [
                node("e6", "heading", text: "Welcome", attrs: ["level": "1"]),
                node("e7", "paragraph", children: [node("e8", "text", text: "Hello there.")]),
                node("e9", "textField", text: "Email",
                     attrs: ["type": "email", "placeholder": "you@example.com"], value: "a@b.c"),
                node("e10", "checkbox", text: "Remember me", attrs: ["states": "checked"], value: "on"),
                node("e11", "button", text: "Sign in", attrs: ["states": "disabled bogus"]),
                node("e12", "textArea", text: "Notes", value: "Line one\n  two"),
                node("e18", "textArea", text: "Blank", value: "  "),
                node("e13", "paragraph", children: [node("e14", "text", text: "a"), node("e15", "text", text: "b")]),
                node("e16", "textField", attrs: ["type": "range", "aria-label": "Volume"], value: "40"),
                node("e17", "textField", text: "Count", attrs: ["type": "number"], value: "3")
            ])
        ]), title: "Fixture")

        let legacyJSON = """
        {"role": "document", "name": "Fixture", "states": [], "children": [
          {"role": "navigation", "name": "Primary", "ref": "e1", "states": [], "children": [
            {"role": "list", "ref": "e2", "states": [], "children": [
              {"role": "listitem", "ref": "e3", "states": [], "children": [
                {"role": "link", "name": "Home", "ref": "e4", "states": [],
                 "url": "https://site.example/home", "children": []}]}]}]},
          {"role": "main", "ref": "e5", "states": [], "children": [
            {"role": "heading", "name": "Welcome", "ref": "e6", "level": 1, "states": [], "children": []},
            {"role": "text", "text": "Hello there."},
            {"role": "textbox", "name": "Email", "ref": "e9", "states": [], "value": "a@b.c", "children": []},
            {"role": "checkbox", "name": "Remember me", "ref": "e10", "states": ["checked"], "children": []},
            {"role": "button", "name": "Sign in", "ref": "e11", "states": ["disabled"], "children": []},
            {"role": "textbox", "name": "Notes", "ref": "e12", "states": [], "value": "Line one two", "children": []},
            {"role": "textbox", "name": "Blank", "ref": "e18", "states": [], "value": "", "children": []},
            {"role": "text", "text": "ab"},
            {"role": "slider", "name": "Volume", "ref": "e16", "states": [], "value": "40", "children": []},
            {"role": "spinbutton", "name": "Count", "ref": "e17", "states": [], "value": "3", "children": []}]}]}
        """
        let legacy = try JSONDecoder().decode(BrowserSnapshotNode.self, from: Data(legacyJSON.utf8))

        // depth 0 and below are unlimited in the legacy walk, the same as none.
        for includeURLs in [false, true] {
            for depth in [nil, 0, -1] as [Int?] {
                var options = BrowserSnapshotOptions()
                options.includeURLs = includeURLs
                options.depth = depth
                XCTAssertEqual(page.snapshotTree(options).split(separator: "\n"),
                               BrowserSnapshotRenderer.render(legacy, includeURLs: includeURLs)
                                   .split(separator: "\n"))
            }
        }
        // Spelled out once, so a change to the shared renderer shows here too.
        var withURLs = BrowserSnapshotOptions()
        withURLs.includeURLs = true
        XCTAssertEqual(page.snapshotTree(withURLs), """
        - document "Fixture":
          - navigation "Primary" [ref=e1]:
            - list [ref=e2]:
              - listitem [ref=e3]:
                - link "Home" [ref=e4] [url=https://site.example/home]
          - main [ref=e5]:
            - heading "Welcome" [ref=e6] [level=1]
            - text: Hello there.
            - textbox "Email" [ref=e9] [value="a@b.c"]
            - checkbox "Remember me" [ref=e10] [checked]
            - button "Sign in" [ref=e11] [disabled]
            - textbox "Notes" [ref=e12] [value="Line one two"]
            - textbox "Blank" [ref=e18] [value=""]
            - text: ab
            - slider "Volume" [ref=e16] [value="40"]
            - spinbutton "Count" [ref=e17] [value="3"]

        """)
    }

    func test_snapshotTreeHonorsInteractiveOnlyAndDepth() {
        let page = build(document([
            node("e1", "landmark", attrs: ["role": "main"], children: [
                node("e2", "paragraph", children: [node("e3", "text", text: "Words")]),
                node("e4", "button", text: "Go")
            ])
        ]), title: "T")
        var interactive = BrowserSnapshotOptions()
        interactive.interactiveOnly = true
        XCTAssertEqual(page.snapshotTree(interactive), """
        - document "T":
          - main [ref=e1]:
            - button "Go" [ref=e4]

        """)
        var shallow = BrowserSnapshotOptions()
        shallow.depth = 1
        XCTAssertEqual(page.snapshotTree(shallow), "- document \"T\":\n  - main [ref=e1]\n")
        // As in the legacy walk, a depth of 0 or less is no limit at all.
        for unlimited in [0, -3] {
            var options = BrowserSnapshotOptions()
            options.depth = unlimited
            XCTAssertEqual(page.snapshotTree(options), page.snapshotTree(BrowserSnapshotOptions()))
            XCTAssertTrue(page.snapshotTree(options).contains("- button \"Go\" [ref=e4]"))
        }
    }

    // MARK: Always runs

    func test_offPrivacyStillFiltersAllowlist() {
        let page = build(document([
            node("e1", "script", text: "var secret = 1"),
            node("e2", "button", text: "OK", attrs: ["onclick": "x()"])
        ]), privacy: .off)
        XCTAssertNil(page.node(ref: "e1"))
        XCTAssertEqual(page.node(ref: "e2")?.attributes, [:])
        for rendering in allRenderings(page) { XCTAssertFalse(rendering.contains("secret"), rendering) }
    }

    // MARK: String path, text, refs

    func test_stringPath() {
        XCTAssertEqual(AgentPageBuilder(privacy: .off, hideImages: false).conceal("Acme"), "Acme")
        XCTAssertEqual(AgentPageBuilder(privacy: acme, hideImages: false).conceal("Acme"), "Zed")
        XCTAssertEqual(AgentPageBuilder(privacy: .unavailable, hideImages: false).conceal("Acme"), "")
        XCTAssertEqual(AgentPageBuilder(privacy: .conflicting, hideImages: false).conceal("Acme"), "")
        XCTAssertEqual(AgentPageBuilder(privacy: acme, hideImages: false).conceal(""), "")
    }

    func test_textUsesMainLandmark() {
        let page = build(document([
            node("e1", "landmark", attrs: ["role": "navigation"], children: [node("e2", "link", text: "Menu")]),
            node("e3", "landmark", attrs: ["role": "main"], children: [
                node("e4", "heading", text: "Title", attrs: ["level": "2"]),
                node("e5", "paragraph", children: [node("e6", "text", text: "Body text")])
            ])
        ]))
        XCTAssertEqual(page.text(), "Title\nBody text")
    }

    func test_nodeByRefCarriesSelector() {
        let page = build(document([node("e1", "list", children: [node("e2", "listItem", text: "x")])]))
        XCTAssertEqual(page.node(ref: "e2")?.selector, "#e2")
        XCTAssertEqual(page.node(ref: "e0")?.kind, .document)
        XCTAssertNil(page.node(ref: "nope"))
    }

    func test_invalidRefOrLandmarkRoleDropped() {
        let page = build(document([
            node("e1\"><x", "button", text: "bad ref"),
            node("e2", "landmark", attrs: ["role": "Acme-role"], children: [node("e3", "text", text: "y")])
        ]))
        XCTAssertFalse(page.html().contains("bad ref"))
        XCTAssertNil(page.node(ref: "e2")?.attributes["role"])
    }

    func test_allowlistEncodesForTheWalker() throws {
        let json = try AgentPageAllowlist.standard.jsonString()
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let kinds = try XCTUnwrap(object["kinds"] as? [String])
        XCTAssertEqual(Set(kinds), Set(AgentNodeKind.allCases.map(\.rawValue)))
        let attributes = try XCTUnwrap(object["attributes"] as? [String: [String]])
        XCTAssertEqual(attributes["link"], ["aria-label", "href", "title"])
        XCTAssertEqual(attributes["textField"], ["aria-label", "name", "placeholder", "title", "type"])
        XCTAssertEqual(attributes["heading"], ["aria-label", "level", "title"])
        XCTAssertEqual(object["states"] as? [String], AgentPageAllowlist.stateVocabulary)
    }
}
