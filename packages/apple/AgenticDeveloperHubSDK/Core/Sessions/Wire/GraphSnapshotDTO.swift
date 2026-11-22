import Foundation

extension Sessions {

    /// Wire types for the stenographer `/visualization/graph` endpoint.
    /// Snake-case JSON on the wire; camelCase Swift on this side.

    /// Full graph snapshot rendered by the Visualization window.
    /// Nodes of three kinds — `session`, `tool`, `project` — connected via
    /// weighted links (session → tool, session → project).
    public struct GraphSnapshotDTO: Codable, Sendable {
        public let nodes: [GraphNodeDTO]
        public let links: [GraphLinkDTO]

        public init(nodes: [GraphNodeDTO], links: [GraphLinkDTO]) {
            self.nodes = nodes
            self.links = links
        }
    }

    /// One node in the force-directed graph.
    public struct GraphNodeDTO: Codable, Sendable {
        /// Opaque identifier used by the JS renderer. Namespaced by kind
        /// (`session:<id>`, `tool:<name>`, `project:<name>`) so a session and
        /// a tool cannot collide.
        public let id: String
        /// `"session"` | `"tool"` | `"project"`.
        public let kind: String
        /// Short human-facing label drawn on the node.
        public let label: String
        /// For session nodes: `"active"` | `"idle"` | `"ended"`. Nil otherwise.
        public let status: String?
        /// Size hint — event count for sessions, usage count for tools,
        /// session count for projects.
        public let weight: Int

        public init(id: String, kind: String, label: String, status: String?, weight: Int) {
            self.id = id
            self.kind = kind
            self.label = label
            self.status = status
            self.weight = weight
        }
    }

    /// One edge between two nodes.
    public struct GraphLinkDTO: Codable, Sendable {
        public let source: String
        public let target: String
        /// Link strength — number of uses for session→tool, 1 for session→project.
        public let value: Int

        public init(source: String, target: String, value: Int) {
            self.source = source
            self.target = target
            self.value = value
        }
    }
}
