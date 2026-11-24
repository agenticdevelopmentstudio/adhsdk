import Foundation

/// The node kinds an agent's page can hold — the only shapes page content
/// reaches an agent in (the Agent Page Builder recipe).
public enum AgentNodeKind: String, Codable, CaseIterable, Sendable {
    case document, landmark, heading, paragraph, text, list, listItem, link, button, textField, textArea,
         checkbox, radio, select, option, table, rowGroup, row, cell, columnHeader, rowHeader, image, label,
         // ARIA grid roles, kept apart from table and cell so the snapshot
         // prints `grid`, `treegrid` and `gridcell` as the legacy walk did.
         grid, treeGrid, gridCell
}

/// What the agent walker may emit and the builder may keep: node kinds, and
/// per kind the attributes allowed on it.
///
/// Defined here, once, and handed to the walker as a JSON argument of every
/// walk (`allowlist-defined-once`); the builder re-validates every node
/// against the same value, so a walker that emits more than it was allowed
/// loses it again on the host side.
///
/// Two structural attributes come from fixed vocabularies rather than page
/// text, so the snapshot keeps today's roles and states
/// (`snapshot-tool-contract-unchanged`): `role` on a landmark, one of
/// `landmarkRoles`, and `states` on any node, a space-separated list drawn
/// from `states`. A value outside its vocabulary is dropped.
public struct AgentPageAllowlist: Sendable, Encodable {
    public let kinds: Set<AgentNodeKind>
    public let attributes: [AgentNodeKind: Set<String>]
    /// The roles a landmark's `role` attribute may name.
    public let landmarkRoles: [String]
    /// The states a node's `states` attribute may list, in the order the
    /// snapshot prints them.
    public let states: [String]

    /// The attribute key carrying a landmark's role.
    public static let roleAttribute = "role"
    /// The attribute key carrying a node's states, space-separated.
    public static let statesAttribute = "states"

    /// The landmark roles today's snapshot prints.
    public static let landmarkRoleVocabulary = [
        "main", "navigation", "banner", "contentinfo", "complementary", "search", "form", "region", "article"
    ]

    /// The states today's snapshot prints, in its order.
    public static let stateVocabulary = ["checked", "disabled", "expanded", "selected", "pressed", "required"]

    public init(
        kinds: Set<AgentNodeKind>,
        attributes: [AgentNodeKind: Set<String>],
        landmarkRoles: [String] = AgentPageAllowlist.landmarkRoleVocabulary,
        states: [String] = AgentPageAllowlist.stateVocabulary
    ) {
        self.kinds = kinds
        self.attributes = attributes
        self.landmarkRoles = landmarkRoles
        self.states = states
    }

    /// Every kind; `aria-label` and `title` on each, `href` on links, `alt`
    /// on images, `placeholder`, `name` and `type` on text fields and text
    /// areas, `name` on selects, checkboxes and radios, `level` on headings.
    public static let standard: AgentPageAllowlist = {
        let everywhere: Set<String> = ["aria-label", "title"]
        let extra: [AgentNodeKind: Set<String>] = [
            .link: ["href"],
            .image: ["alt"],
            .textField: ["placeholder", "name", "type"],
            .textArea: ["placeholder", "name", "type"],
            .select: ["name"],
            .checkbox: ["name"],
            .radio: ["name"],
            .heading: ["level"]
        ]
        var attributes: [AgentNodeKind: Set<String>] = [:]
        for kind in AgentNodeKind.allCases {
            attributes[kind] = everywhere.union(extra[kind] ?? [])
        }
        return AgentPageAllowlist(kinds: Set(AgentNodeKind.allCases), attributes: attributes)
    }()

    /// Whether `attribute` may stay on a node of `kind`.
    func permits(_ attribute: String, on kind: AgentNodeKind) -> Bool {
        kinds.contains(kind) && (attributes[kind]?.contains(attribute) ?? false)
    }

    private enum CodingKeys: String, CodingKey { case kinds, attributes, landmarkRoles, states }

    /// `{"kinds": [...], "attributes": {"link": ["aria-label", "href", "title"], ...},
    /// "landmarkRoles": [...], "states": [...]}`, sorted so the argument is
    /// the same on every walk. A dictionary keyed by an enum would encode as
    /// a flat array of alternating keys and values, which is why this is
    /// written out.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kinds.map(\.rawValue).sorted(), forKey: .kinds)
        var byName: [String: [String]] = [:]
        for (kind, names) in attributes where kinds.contains(kind) { byName[kind.rawValue] = names.sorted() }
        try container.encode(byName, forKey: .attributes)
        try container.encode(landmarkRoles, forKey: .landmarkRoles)
        try container.encode(states, forKey: .states)
    }

    /// The allowlist as the JSON string the walker receives.
    public func jsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let json = String(bytes: try encoder.encode(self), encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return json
    }
}
