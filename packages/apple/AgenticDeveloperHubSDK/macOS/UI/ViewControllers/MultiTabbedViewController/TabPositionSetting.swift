import Foundation
import AgenticDeveloperHubSDKCore

/// Which edges a `MultiTabbedViewController` shows its tab bars on: the
/// app-wide default (`UserSettings.tabsPositions`) and any view's override.
///
/// Never empty. A view with no enabled edge has no tab bar, so it has nowhere
/// to put the control that would bring one back; an empty input therefore
/// reads as the top edge alone, and a change that would leave no edge is
/// refused (`setting(_:enabled:)` answers `nil`).
public struct TabPositions: Codable, Hashable, Sendable {

    /// The order the primary edge is chosen in. Not `Edge.allCases`, which
    /// goes round the view (top, right, bottom, left): a single-edge host
    /// whose user ticked left and right wants its tabs on the left.
    public static let primaryOrder: [Edge] = [.top, .left, .right, .bottom]

    public let edges: Set<Edge>

    public init(_ edges: Set<Edge>) {
        self.edges = edges.isEmpty ? [.top] : edges
    }

    /// The edge a host that keeps its tabs on one edge puts them on: the
    /// first of top, left, right, bottom that is in `edges`.
    public var primaryEdge: Edge {
        Self.primaryOrder.first(where: edges.contains) ?? .top
    }

    /// `edges` in `primaryOrder`, for a host that walks them.
    public var orderedEdges: [Edge] {
        Self.primaryOrder.filter(edges.contains)
    }

    /// These positions with `edge` turned on or off, or `nil` when turning it
    /// off would leave no edge at all.
    public func setting(_ edge: Edge, enabled: Bool) -> TabPositions? {
        var next = edges
        if enabled { next.insert(edge) } else { next.remove(edge) }
        guard !next.isEmpty else { return nil }
        return TabPositions(next)
    }

    // MARK: - Codable

    /// Stored as the edges' raw names in `primaryOrder` — a `Set` has no
    /// stable order, and a stored value that reshuffles on every write is
    /// noise in a settings diff. Names this build does not know are dropped,
    /// and an empty result reads as the top edge (`edges-never-empty`).
    public init(from decoder: Decoder) throws {
        let names = try decoder.singleValueContainer().decode([String].self)
        self.init(Set(names.compactMap(Edge.init(rawValue:))))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(orderedEdges.map(\.rawValue))
    }
}

extension UserSettings {
    /// The app-wide tab positions every `MultiTabbedViewController` follows
    /// until a host or the user gives it edges of its own. Set from System >
    /// General and View > Tab Position.
    public static let tabsPositions = UserSetting<TabPositions>("tabs.positions", default: TabPositions([.top]))
}
