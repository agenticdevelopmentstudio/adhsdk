import Foundation

/// One node of an agent's page: built by `AgentPageBuilder` from a node the
/// walker emitted and the builder re-validated, every string already
/// concealed.
///
/// `text` is the node's own direct text: a text node's content, a control's
/// label, a button's or link's caption. Descendants carry their own text.
/// `attributes` holds only what the allowlist permits for `kind` (plus a
/// landmark's `role` and a node's `states`, from fixed vocabularies).
/// `selector` locates the node's element in the live page, for mapping a
/// pick in the Agent preview back to it; no rendering emits it.
public struct AgentNode: Sendable, Hashable {
    public let ref: String
    public let kind: AgentNodeKind
    public let text: String
    public let attributes: [String: String]
    public let value: String?
    public let selector: String
    public let children: [AgentNode]
    /// The subtree's text the way `textContent` reads it — the page's own
    /// pieces concatenated with their boundary spaces, images contributing
    /// none — collapsed line by line, keeping the walker's line breaks
    /// (`<br>`, block edges, `<pre>` newlines), then concealed once as a
    /// whole, so `Buy <b>now</b>` reads "Buy now" and a privacy word split
    /// across inline elements (`Ac<b>me</b>`) is concealed as the word it
    /// reads as. Every rendering but the page's text collapses the breaks.
    let contentText: String

    init(ref: String, kind: AgentNodeKind, text: String, attributes: [String: String], value: String?,
         selector: String, children: [AgentNode], contentText: String) {
        self.ref = ref
        self.kind = kind
        self.text = text
        self.attributes = attributes
        self.value = value
        self.selector = selector
        self.children = children
        self.contentText = contentText
    }

    /// The node's states, in vocabulary order.
    var states: [String] {
        guard let raw = attributes[AgentPageAllowlist.statesAttribute] else { return [] }
        return raw.split(separator: " ").map(String.init)
    }
}

/// Everything an agent receives from one page, as one immutable value, and
/// its three renderings (`one-value-three-renderings`): the snapshot tree in
/// `browser_snapshot`'s format, the plain text, and an HTML document for the
/// Agent preview and Agent source views.
///
/// An unavailable page has no root and a reason beginning
/// `Agent view unavailable: `, which every rendering returns in place of
/// content (`unavailable-page-renders-reason`).
public struct AgentPage: Sendable, Equatable {
    /// The page's address as the agent sees it: concealed under Agent
    /// Privacy. Shown, never stored: nothing saved (a hidden-items entry's
    /// site above all) may be derived from it; take the engine's URL.
    public let url: URL?
    public let title: String
    public let root: AgentNode?
    public let unavailableReason: String?

    /// What every unavailable page's reason begins with.
    public static let unavailablePrefix = "Agent view unavailable: "

    init(url: URL?, title: String, root: AgentNode?, unavailableReason: String? = nil) {
        self.url = url
        self.title = title
        self.root = root
        self.unavailableReason = unavailableReason
    }

    /// The page with nothing on it and no reason, shown by an agent view
    /// while its first rebuild runs.
    static let blank = AgentPage(url: nil, title: "", root: nil)

    /// The empty page carrying `reason`, prefixed with
    /// `Agent view unavailable: ` unless it already is.
    public static func unavailable(_ reason: String, url: URL?) -> AgentPage {
        let full = reason.hasPrefix(unavailablePrefix) ? reason : unavailablePrefix + reason
        return AgentPage(url: url, title: "", root: nil, unavailableReason: full)
    }

    /// The node holding `ref`, anywhere in the page.
    public func node(ref: String) -> AgentNode? {
        guard let root else { return nil }
        var stack = [root]
        while let node = stack.popLast() {
            if node.ref == ref { return node }
            stack.append(contentsOf: node.children.reversed())
        }
        return nil
    }

    // MARK: Snapshot tree

    /// The page in `browser_snapshot`'s tree format, line for line what
    /// `BrowserSnapshotRenderer` printed for the equivalent legacy tree,
    /// honoring `interactiveOnly`, `depth` (0 or less is unlimited, as in the legacy walk) and
    /// `includeURLs`. Scope is the walk's (the root is the scoped element);
    /// delta and generation stamps are the tool's, on this text.
    public func snapshotTree(_ options: BrowserSnapshotOptions) -> String {
        if let unavailableReason { return unavailableReason }
        guard let root else { return "" }
        let depth = options.depth.flatMap { $0 > 0 ? $0 : nil }
        let mapper = AgentSnapshotMapper(interactiveOnly: options.interactiveOnly, title: title)
        return BrowserSnapshotRenderer.render(mapper.root(root, depth: depth), includeURLs: options.includeURLs)
    }

    // MARK: Text

    /// The page's text: its main landmark when it has one, else the whole
    /// page (the whole scoped element, for a scoped walk), one line per
    /// block. Image alternative text and form values are not page text.
    public func text() -> String {
        if let unavailableReason { return unavailableReason }
        guard let root else { return "" }
        let scope = root.kind == .document ? (Self.firstMain(in: root) ?? root) : root
        var renderer = AgentTextRenderer()
        renderer.visit(scope)
        return renderer.finish()
    }

    private static func firstMain(in node: AgentNode) -> AgentNode? {
        if node.kind == .landmark, node.attributes[AgentPageAllowlist.roleAttribute] == "main" { return node }
        for child in node.children {
            if let found = firstMain(in: child) { return found }
        }
        return nil
    }

    // MARK: HTML

    /// The page as an HTML document the builder writes itself
    /// (`html-rendering-safe`): every string escaped, only elements mapped
    /// from node kinds, each carrying its node's `data-adk-ref`, no `script`
    /// element, no `style` attribute, controls disabled, and an image as
    /// `<span class="adk-image">[image: alt]</span>`.
    public func html() -> String {
        var out = "<!DOCTYPE html>\n<html><head><meta charset=\"utf-8\"><title>"
            + AgentHTMLRenderer.escape(title) + "</title></head>"
        if let unavailableReason {
            out += "<body><p>" + AgentHTMLRenderer.escape(unavailableReason) + "</p></body></html>\n"
            return out
        }
        var renderer = AgentHTMLRenderer()
        if let root {
            if root.kind == .document {
                out += "<body data-adk-ref=\"" + AgentHTMLRenderer.escape(root.ref) + "\">"
                renderer.content(of: root)
            } else {
                out += "<body>"
                renderer.element(root)
            }
        } else {
            out += "<body>"
        }
        return out + renderer.output + "</body></html>\n"
    }
}

// MARK: - Shared string helpers

enum AgentPageText {
    /// Whitespace runs collapsed to one space, trimmed: the legacy runtime's `collapse`.
    static func collapse(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Each line of `text` collapsed, empty lines dropped, the rest joined
    /// by newlines: `text`'s line structure, and nothing else of its
    /// whitespace. With its newlines read as spaces it is `collapse(text)`.
    static func lines(_ text: String) -> String {
        text.split(whereSeparator: \.isNewline).map { collapse(String($0)) }.filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// The legacy runtime's `cut`: at most `limit` characters, then an ellipsis.
    static func cut(_ text: String, _ limit: Int) -> String {
        text.count > limit ? String(text.prefix(limit)) + "…" : text
    }

    /// Every text in `node`'s subtree, its own first, concatenated as an
    /// element's `textContent` is — `a<b>b</b>` gives "ab", `a <b>b</b>`
    /// "a b" — collapsed, and concealed after joining, never piece by piece;
    /// images contribute none, as `textContent` holds no alt.
    static func allText(_ node: AgentNode) -> String {
        node.kind == .image ? "" : node.contentText
    }

    /// Whether `node`'s children are all text: a run the page reads as one
    /// string, which the renderings print joined and concealed as a whole.
    static func isTextRun(_ node: AgentNode) -> Bool {
        node.kind != .image && !node.children.isEmpty && node.children.allSatisfy { $0.kind == .text }
    }
}

// MARK: - Snapshot mapping

extension BrowserSnapshotNode {
    /// A legacy node built in Swift, for rendering an `AgentPage` through
    /// the same `BrowserSnapshotRenderer` the legacy snapshot used.
    init(role: String, name: String? = nil, ref: String? = nil, states: [String] = [], level: Int? = nil,
         url: String? = nil, value: String? = nil, text: String? = nil, children: [BrowserSnapshotNode] = []) {
        self.role = role
        self.name = name
        self.ref = ref
        self.states = states
        self.level = level
        self.url = url
        self.value = value
        self.text = text
        self.children = children
    }
}

/// Maps an `AgentNode` tree onto the legacy `BrowserSnapshotNode` tree the
/// old `BrowserSnapshot.js` walk would have produced for the same page,
/// mirroring its rules: paragraphs and labels are generic (collapsed into
/// one text line, or flattened into their parent); a caption names a
/// button, link, heading, cell or option and then hides its contents;
/// `depth` counts levels below the root; interactive-only drops text and
/// every non-interactive node left with no children.
struct AgentSnapshotMapper {
    let interactiveOnly: Bool
    let title: String

    static let nameLimit = 100, valueLimit = 50
    static let genericKinds: Set<AgentNodeKind> = [.text, .paragraph, .label]
    static let nameFromContent: Set<AgentNodeKind> = [
        .button, .link, .heading, .cell, .gridCell, .columnHeader, .rowHeader, .option
    ]
    static let controls: Set<AgentNodeKind> = [.textField, .textArea, .select, .checkbox, .radio]
    static let valueShown: Set<AgentNodeKind> = [.textField, .textArea, .select]
    static let interactiveKinds: Set<AgentNodeKind> = [
        .link, .button, .textField, .textArea, .checkbox, .radio, .select, .option
    ]

    func root(_ node: AgentNode, depth: Int?) -> BrowserSnapshotNode {
        if node.kind == .document {
            let name = AgentPageText.cut(AgentPageText.collapse(title), Self.nameLimit)
            return BrowserSnapshotNode(role: "document", name: name.isEmpty ? nil : name,
                                       children: children(of: node, depthLeft: depth, ownText: node.text))
        }
        let built = build(node, depthLeft: depth)
        if built.count == 1, built[0].role != "text" { return built[0] }
        return BrowserSnapshotNode(role: "document", name: title.isEmpty ? nil : title, children: built)
    }

    private func textNode(_ text: String) -> BrowserSnapshotNode? {
        guard !interactiveOnly else { return nil }
        let collapsed = AgentPageText.collapse(text)
        guard !collapsed.isEmpty else { return nil }
        return BrowserSnapshotNode(role: "text", text: AgentPageText.cut(collapsed, Self.nameLimit))
    }

    private func children(of node: AgentNode, depthLeft: Int?, ownText: String?) -> [BrowserSnapshotNode] {
        let next = depthLeft.map { $0 - 1 }
        if next == -1 { return [] }
        var out: [BrowserSnapshotNode] = []
        if let ownText, let own = textNode(ownText) { out.append(own) }
        for child in node.children {
            if child.kind == .text {
                if let text = textNode(child.text) { out.append(text) }
            } else {
                out.append(contentsOf: build(child, depthLeft: next))
            }
        }
        return out
    }

    private func hasNonGenericDescendant(_ node: AgentNode) -> Bool {
        node.children.contains { !Self.genericKinds.contains($0.kind) || hasNonGenericDescendant($0) }
    }

    private func build(_ node: AgentNode, depthLeft: Int?) -> [BrowserSnapshotNode] {
        switch node.kind {
        case .text:
            return textNode(node.text).map { [$0] } ?? []
        case .paragraph, .label:
            if !hasNonGenericDescendant(node) {
                return textNode(AgentPageText.allText(node)).map { [$0] } ?? []
            }
            return children(of: node, depthLeft: depthLeft, ownText: node.text)
        default:
            break
        }
        let (name, fromContent) = legacyName(node)
        // Text the name did not use is shown as content, as the legacy walk
        // showed an element's text beneath a name taken from its attributes.
        let ownText: String? = (Self.controls.contains(node.kind) || node.kind == .image) ? nil : node.text
        var kids: [BrowserSnapshotNode] = []
        if !fromContent && depthLeft != 0 { kids = children(of: node, depthLeft: depthLeft, ownText: ownText) }
        if interactiveOnly && !Self.interactiveKinds.contains(node.kind) && kids.isEmpty { return [] }
        return [BrowserSnapshotNode(
            role: legacyRole(node),
            name: name.isEmpty ? nil : name,
            ref: node.ref,
            states: node.states,
            level: node.kind == .heading ? legacyLevel(node) : nil,
            url: node.kind == .link ? node.attributes["href"] : nil,
            value: legacyValue(node),
            children: kids)]
    }

    private func legacyRole(_ node: AgentNode) -> String {
        switch node.kind {
        case .document: return "document"
        case .landmark: return node.attributes[AgentPageAllowlist.roleAttribute] ?? "region"
        case .heading: return "heading"
        case .list: return "list"
        case .listItem: return "listitem"
        case .link: return "link"
        case .button: return "button"
        case .textField:
            switch node.attributes["type"]?.lowercased() {
            case "search": return "searchbox"
            case "number": return "spinbutton"
            case "range": return "slider"
            default: return "textbox"
            }
        case .textArea: return "textbox"
        case .checkbox: return "checkbox"
        case .radio: return "radio"
        case .select: return "combobox"
        case .option: return "option"
        case .table: return "table"
        case .rowGroup: return "rowgroup"
        case .row: return "row"
        case .cell: return "cell"
        case .grid: return "grid"
        case .treeGrid: return "treegrid"
        case .gridCell: return "gridcell"
        case .columnHeader: return "columnheader"
        case .rowHeader: return "rowheader"
        case .image: return "img"
        case .paragraph, .label, .text: return "generic"
        }
    }

    /// The legacy accessible name: `aria-label`, a control's label, `alt`,
    /// `title`, `placeholder`, then — for the kinds named by content — the
    /// text of the whole subtree.
    private func legacyName(_ node: AgentNode) -> (String, Bool) {
        let attrs = node.attributes
        let controlLabel = Self.controls.contains(node.kind) ? node.text : nil
        for candidate in [attrs["aria-label"], controlLabel, attrs["alt"], attrs["title"], attrs["placeholder"]] {
            let collapsed = AgentPageText.collapse(candidate ?? "")
            if !collapsed.isEmpty { return (AgentPageText.cut(collapsed, Self.nameLimit), false) }
        }
        if Self.nameFromContent.contains(node.kind) {
            let collapsed = AgentPageText.collapse(AgentPageText.allText(node))
            if !collapsed.isEmpty { return (AgentPageText.cut(collapsed, Self.nameLimit), true) }
        }
        return ("", false)
    }

    private func legacyLevel(_ node: AgentNode) -> Int {
        if let level = node.attributes["level"].flatMap({ Int($0.trimmingCharacters(in: .whitespaces)) }),
           level >= 1 { return level }
        return 2
    }

    /// A value as the legacy walk showed one: text fields (a slider's or
    /// spinbutton's `aria-valuenow` among them), text areas and selects —
    /// a checkbox's or radio's is its state. As the legacy walk does, an
    /// empty value is none, tested before collapsing, so a value of only
    /// whitespace is kept and prints as `[value=""]`; then collapsed and cut.
    private func legacyValue(_ node: AgentNode) -> String? {
        guard Self.valueShown.contains(node.kind), let value = node.value, !value.isEmpty else { return nil }
        return AgentPageText.cut(AgentPageText.collapse(value), Self.valueLimit)
    }
}

// MARK: - Text rendering

/// One line per block, as `innerText` reads: a run of text pieces as its
/// joined, concealed text (the page's own boundary spaces kept), other
/// inline text joined by spaces, and a new line at every break the walker
/// kept (`<br>`, a flattened block's edges, a `<pre>`'s newlines).
struct AgentTextRenderer {
    private var lines: [String] = []
    private var pieces: [String] = []

    private static let blocks: Set<AgentNodeKind> = [
        .document, .landmark, .heading, .paragraph, .list, .listItem, .table, .grid, .treeGrid, .rowGroup, .row,
        .select, .option, .textArea
    ]

    mutating func visit(_ node: AgentNode) {
        if node.kind == .image { return }
        let block = Self.blocks.contains(node.kind)
        if block { flush() }
        if AgentPageText.isTextRun(node) {
            pieces.append(AgentPageText.allText(node))
        } else {
            if !node.text.isEmpty { pieces.append(node.text) }
            for child in node.children { visit(child) }
        }
        if block { flush() }
    }

    private mutating func flush() {
        let text = AgentPageText.lines(pieces.joined(separator: " "))
        if !text.isEmpty { lines.append(text) }
        pieces = []
    }

    mutating func finish() -> String {
        flush()
        return lines.joined(separator: "\n")
    }
}

// MARK: - HTML rendering

/// Writes the agent page as HTML, element by element, from node kinds only.
struct AgentHTMLRenderer {
    private(set) var output = ""

    /// Input types the preview may show; anything else is shown as text.
    private static let inputTypes: Set<String> = [
        "text", "search", "email", "url", "tel", "number", "range", "password", "date", "time", "datetime-local",
        "month", "week"
    ]

    static func escape(_ text: String) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        for character in text {
            switch character {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            default: out.append(character)
            }
        }
        return out
    }

    /// `node`'s text and children, without an element for `node` itself.
    /// A run of text alone is written as the node's joined, concealed
    /// text, so adjacent pieces cannot read as a privacy word together.
    mutating func content(of node: AgentNode) {
        if AgentPageText.isTextRun(node) {
            output += Self.escapeLines(AgentPageText.allText(node), ref: node.ref)
            return
        }
        if !node.text.isEmpty { output += Self.escapeLines(node.text, ref: node.ref) }
        for child in node.children { element(child) }
    }

    /// `text` escaped, each line break the page's text keeps written as a
    /// `<br>` carrying `ref`, so the preview breaks lines where the agent's
    /// text does. A run of breaks is one `<br>`, as the text keeps no empty line.
    static func escapeLines(_ text: String, ref: String) -> String {
        guard text.contains(where: \.isNewline) else { return escape(text) }
        let lineBreak = "<br data-adk-ref=\"" + escape(ref) + "\">"
        var out = "", breakPending = false
        for character in text {
            if character.isNewline {
                breakPending = true
                continue
            }
            if breakPending { out += lineBreak }
            breakPending = false
            out += escape(String(character))
        }
        if breakPending { out += lineBreak }
        return out
    }

    mutating func element(_ node: AgentNode) {
        switch node.kind {
        case .text:
            output += Self.escapeLines(node.text, ref: node.ref)
        case .document:
            wrap("div", node)
        case .landmark:
            let tag: String
            switch node.attributes[AgentPageAllowlist.roleAttribute] {
            case "navigation": tag = "nav"
            case "main": tag = "main"
            case "banner": tag = "header"
            case "contentinfo": tag = "footer"
            default: tag = "section"
            }
            wrap(tag, node)
        case .heading:
            let level = min(6, max(1, node.attributes["level"].flatMap { Int($0) } ?? 2))
            wrap("h\(level)", node)
        case .paragraph: wrap("p", node)
        case .list: wrap("ul", node)
        case .listItem: wrap("li", node)
        case .link:
            var extra: [(String, String)] = []
            if let href = node.attributes["href"] { extra.append(("href", href)) }
            wrap("a", node, extra: extra)
        case .button: wrap("button", node, extra: [("type", "button")])
        case .table, .grid, .treeGrid: wrap("table", node)
        case .rowGroup: wrap("tbody", node)
        case .row: wrap("tr", node)
        case .cell, .gridCell: wrap("td", node)
        case .columnHeader: wrap("th", node, extra: [("scope", "col")])
        case .rowHeader: wrap("th", node, extra: [("scope", "row")])
        case .label: wrap("label", node)
        case .option:
            var extra: [(String, String)] = []
            if node.states.contains("selected") { extra.append(("selected", "")) }
            open("option", node, extra: extra)
            output += Self.escape(AgentPageText.collapse(AgentPageText.allText(node))) + "</option>"
        case .image:
            let alt = AgentPageText.collapse(node.attributes["alt"] ?? "")
            open("span", node, extra: [("class", "adk-image")])
            output += Self.escape(alt.isEmpty ? "[image]" : "[image: \(alt)]") + "</span>"
        case .textField where !node.children.isEmpty:
            // A `contenteditable` or `role=textbox` field holds content, not
            // a value, and the agent reads that content (its text and its
            // snapshot children), so the preview shows it inside the field.
            var extra: [(String, String)] = [("class", "adk-textfield"), ("role", "textbox"),
                                             ("aria-disabled", "true")]
            if let found = node.attributes["placeholder"] { extra.append(("aria-placeholder", found)) }
            wrap("div", node, extra: extra)
        case .textField:
            labelled(node) {
                let raw = node.attributes["type"]?.lowercased() ?? "text"
                var extra: [(String, String)] = [("type", Self.inputTypes.contains(raw) ? raw : "text")]
                for name in ["name", "placeholder"] {
                    if let found = node.attributes[name] { extra.append((name, found)) }
                }
                if let value = node.value { extra.append(("value", value)) }
                extra.append(("disabled", ""))
                $0.open("input", node, extra: extra)
            }
        case .textArea:
            labelled(node) {
                var extra: [(String, String)] = []
                for name in ["name", "placeholder"] {
                    if let found = node.attributes[name] { extra.append((name, found)) }
                }
                extra.append(("disabled", ""))
                $0.open("textarea", node, extra: extra)
                $0.output += Self.escape(node.value ?? "") + "</textarea>"
            }
        case .checkbox, .radio:
            labelled(node) {
                var extra: [(String, String)] = [("type", node.kind == .checkbox ? "checkbox" : "radio")]
                if let found = node.attributes["name"] { extra.append(("name", found)) }
                if node.states.contains("checked") { extra.append(("checked", "")) }
                extra.append(("disabled", ""))
                $0.open("input", node, extra: extra)
            }
        case .select:
            labelled(node) {
                var extra: [(String, String)] = []
                if let found = node.attributes["name"] { extra.append(("name", found)) }
                extra.append(("disabled", ""))
                $0.open("select", node, extra: extra)
                for child in node.children where child.kind == .option { $0.element(child) }
                $0.output += "</select>"
            }
        }
    }

    /// A control inside a `label` holding its text, when it has one.
    private mutating func labelled(_ node: AgentNode, _ body: (inout AgentHTMLRenderer) -> Void) {
        let label = AgentPageText.collapse(node.text)
        if label.isEmpty {
            body(&self)
            return
        }
        output += "<label data-adk-ref=\"" + Self.escape(node.ref) + "\">" + Self.escape(label) + " "
        body(&self)
        output += "</label>"
    }

    private mutating func wrap(_ tag: String, _ node: AgentNode, extra: [(String, String)] = []) {
        open(tag, node, extra: extra)
        content(of: node)
        output += "</\(tag)>"
    }

    /// `<tag data-adk-ref="…" aria-label="…" title="…" …>`, every value escaped.
    private mutating func open(_ tag: String, _ node: AgentNode, extra: [(String, String)]) {
        var attrs: [(String, String)] = [("data-adk-ref", node.ref)]
        for name in ["aria-label", "title"] { if let found = node.attributes[name] { attrs.append((name, found)) } }
        attrs.append(contentsOf: extra)
        output += "<" + tag
        for (name, value) in attrs { output += " \(name)=\"" + Self.escape(value) + "\"" }
        output += ">"
    }
}
