import Foundation

/// One of the four directions a pane can be minimized toward.
///
/// It lives in the chrome tier rather than beside `PaneHost` because the
/// minimize picker is a chrome view and its four buttons *are* these four
/// values. Everything here is Foundation-only, so putting it this low costs
/// nothing.
///
/// The case order is the cross the design draws — up, left, down, right — and
/// the raw values are the accessibility-identifier suffixes under
/// `pane.minimize.`, which makes them part of the contract a UI test addresses
/// rather than an implementation detail.
public enum PaneEdge: String, CaseIterable, Sendable {
    case top
    case leading
    case bottom
    case trailing

    /// True for the two edges of a horizontal split.
    ///
    /// A pane may only be minimized along its parent split's axis — freed space
    /// can only go to a sibling that shares that axis — so this is the
    /// predicate the offered set is filtered by.
    public var isHorizontal: Bool {
        self == .leading || self == .trailing
    }

    /// The edge directly across from this one, on the same axis.
    ///
    /// This is the flip: a pane asked to minimize toward the edge its sibling
    /// is already on resolves to the opposite edge, so that the neighbour has
    /// somewhere to expand into.
    public var opposite: PaneEdge {
        switch self {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
    }

    /// The SF Symbol the minimize picker draws for this direction.
    public var arrowSymbolName: String {
        switch self {
        case .top: "arrow.up"
        case .leading: "arrow.left"
        case .bottom: "arrow.down"
        case .trailing: "arrow.right"
        }
    }

    /// Tooltip and accessibility-description text.
    public var displayName: String {
        switch self {
        case .top: "Minimize to Top"
        case .leading: "Minimize to Left"
        case .bottom: "Minimize to Bottom"
        case .trailing: "Minimize to Right"
        }
    }
}
