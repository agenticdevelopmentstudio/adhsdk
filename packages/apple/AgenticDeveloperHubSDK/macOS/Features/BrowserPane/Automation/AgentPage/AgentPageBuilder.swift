import Foundation

/// What `AgentPageWalker.js` returns: the page's address and title and the
/// tree of nodes it emitted, every one still to be re-validated.
struct AgentWalkerPayload: Decodable {
    let url: String
    let title: String
    let root: RawNode
}

/// One node as the walker emitted it. `attrs` may carry a landmark's `role`
/// and a node's space-separated `states` beside the allowlisted attributes.
struct RawNode: Decodable {
    let ref: String
    let kind: String
    let text: String?
    let attrs: [String: String]?
    let value: String?
    let selector: String?
    let children: [RawNode]?
}

/// The walker's failure answer, `{"error": "timeout"}` and the like.
private struct AgentWalkerFailure: Decodable {
    let error: String
}

/// The one gatekeeper between a page and an agent, host side (the Agent
/// Page Builder recipe): builds an `AgentPage` up from the walker's payload,
/// keeping only allowlisted kinds and attributes and concealing every string
/// before the node holding it exists. It fails closed — any doubt about the
/// payload or the privacy words gives the empty page with a reason.
///
/// A value with no mutable state; builds from any thread are independent.
public struct AgentPageBuilder: Sendable {
    public let allowlist: AgentPageAllowlist
    public let privacy: BrowserAgentPrivacy
    public let hideImages: Bool

    /// The kinds whose value is kept, as the legacy walk kept them: a text
    /// field's (a slider's or spinbutton's `aria-valuenow` arrives as one),
    /// a text area's, a select's; never a password's, never a button's.
    static let valueKinds: Set<AgentNodeKind> = [.textField, .textArea, .select, .checkbox, .radio]

    public init(allowlist: AgentPageAllowlist = .standard, privacy: BrowserAgentPrivacy, hideImages: Bool) {
        self.allowlist = allowlist
        self.privacy = privacy
        self.hideImages = hideImages
    }

    /// The string path: `string` as an agent may see it — unchanged with
    /// Agent Privacy off, concealed with the privacy words when on, and empty
    /// when the words cannot be read or conflict.
    public func conceal(_ string: String) -> String {
        switch privacy {
        case .off: string
        case .enabled: privacy.concealing(string)
        case .unavailable, .conflicting: ""
        }
    }

    /// The agent's page from the walker's `payload`, or the unavailable page
    /// when the privacy words are closed (checked before the payload is
    /// read), the walker failed, or the payload does not decode.
    public func build(payload: Data?, error: Error?) -> AgentPage {
        switch privacy {
        case .unavailable:
            return .unavailable("the privacy words could not be read.", url: nil)
        case .conflicting:
            return .unavailable("one privacy word's stand-in contains another's real word.", url: nil)
        case .off, .enabled:
            break
        }
        if let error {
            if let automation = error as? BrowserAutomationError, case .timeout = automation {
                return .unavailable(Self.timeoutReason, url: nil)
            }
            return .unavailable("the page could not be read.", url: nil)
        }
        guard let payload else { return .unavailable(Self.malformedReason, url: nil) }
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(AgentWalkerPayload.self, from: payload) else {
            if let failure = try? decoder.decode(AgentWalkerFailure.self, from: payload) {
                if failure.error == "timeout" { return .unavailable(Self.timeoutReason, url: nil) }
                if failure.error == "agent-list" { return .unavailable(Self.agentListReason, url: nil) }
            }
            return .unavailable(Self.malformedReason, url: nil)
        }
        let base = URL(string: decoded.url)
        let pageURL = URL(string: conceal(decoded.url))
        guard let root = node(from: decoded.root, base: base) else {
            return .unavailable("the page holds nothing an agent may be shown.", url: pageURL)
        }
        return AgentPage(url: pageURL, title: conceal(decoded.title), root: root)
    }

    static let timeoutReason = "the page took too long to read."
    static let malformedReason = "the page's reading could not be understood."
    /// An agent-list selector the page could not evaluate: it would hide
    /// nothing, so nothing is shown.
    static let agentListReason = "the agent's hidden-items list could not be applied to this page."

    // MARK: Nodes

    /// `raw` re-validated, or `nil` to drop it and its whole subtree.
    private func node(from raw: RawNode, base: URL?) -> AgentNode? {
        built(from: raw, base: base)?.node
    }

    /// `raw` re-validated, with its subtree's unconcealed text joined the
    /// `textContent` way — the walker's text pieces keep their boundary
    /// spaces, so `Buy <b>now</b>` joins as "Buy now" and `Ac<b>me</b>` as
    /// "Acme". That text never leaves the builder unconcealed: it is
    /// collapsed line by line (the walker's breaks kept) and trimmed once,
    /// then concealed once, into `contentText`.
    private func built(from raw: RawNode, base: URL?) -> (node: AgentNode, content: String)? {
        guard let kind = AgentNodeKind(rawValue: raw.kind), allowlist.kinds.contains(kind) else { return nil }
        if hideImages && kind == .image { return nil }
        guard Self.isValidRef(raw.ref) else { return nil }

        let rawAttributes = raw.attrs ?? [:]
        var attributes: [String: String] = [:]
        for (name, value) in rawAttributes where allowlist.permits(name, on: kind) {
            let kept: String?
            if name == "href" {
                kept = Self.sanitizedHref(value, base: base).map(conceal)
            } else {
                kept = conceal(value)
            }
            if let kept, !kept.isEmpty { attributes[name] = kept }
        }
        // The fixed vocabularies: our own words, never page text, so they
        // are matched rather than concealed.
        attributes[AgentPageAllowlist.roleAttribute] = nil
        if kind == .landmark,
           let role = rawAttributes[AgentPageAllowlist.roleAttribute]?
               .trimmingCharacters(in: .whitespaces).lowercased(),
           allowlist.landmarkRoles.contains(role) {
            attributes[AgentPageAllowlist.roleAttribute] = role
        }
        attributes[AgentPageAllowlist.statesAttribute] = nil
        if let listed = rawAttributes[AgentPageAllowlist.statesAttribute] {
            let given = Set(listed.lowercased().split(whereSeparator: \.isWhitespace).map(String.init))
            let kept = allowlist.states.filter(given.contains)
            if !kept.isEmpty { attributes[AgentPageAllowlist.statesAttribute] = kept.joined(separator: " ") }
        }

        // The page's own `type`, read before concealment could change it.
        let isPassword = rawAttributes["type"]?.trimmingCharacters(in: .whitespaces).lowercased() == "password"
        let value = (Self.valueKinds.contains(kind) && !isPassword) ? raw.value.map(conceal) : nil

        let built = (raw.children ?? []).compactMap { self.built(from: $0, base: base) }
        let ownText = raw.text ?? ""
        let content = kind == .image ? "" : ownText + built.map(\.content).joined()
        let node = AgentNode(ref: raw.ref, kind: kind, text: concealKeepingLines(ownText), attributes: attributes,
                             value: value, selector: raw.selector ?? "", children: built.map(\.node),
                             contentText: concealKeepingLines(AgentPageText.lines(content)))
        return (node, content)
    }

    /// `text` concealed with its line breaks kept — unless a privacy word
    /// runs across one of them, which the text read as one line would
    /// conceal: then the text is concealed and returned as that one line, so
    /// a break can never carry a privacy word past the filter.
    func concealKeepingLines(_ text: String) -> String {
        guard text.contains(where: \.isNewline) else { return conceal(text) }
        let asOneLine = { (string: String) in String(string.map { $0.isNewline ? " " : $0 }) }
        let lined = conceal(text)
        let flat = conceal(asOneLine(text))
        return asOneLine(lined) == flat ? lined : flat
    }

    /// A ref the walker assigned: short, letters, digits, `-` and `_` only.
    /// Anything else did not come from the walker and is dropped.
    static func isValidRef(_ ref: String) -> Bool {
        !ref.isEmpty && ref.count <= 32 && ref.unicodeScalars.allSatisfy {
            ($0.isASCII && CharacterSet.alphanumerics.contains($0)) || $0 == "-" || $0 == "_"
        }
    }

    /// `href` resolved against the page's address, kept only when the result
    /// is an absolute `http` or `https` address with a host.
    static func sanitizedHref(_ href: String, base: URL?) -> String? {
        let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let resolved = URL(string: trimmed, relativeTo: base)?.absoluteURL,
              let components = URLComponents(url: resolved, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty else { return nil }
        return resolved.absoluteString
    }
}
