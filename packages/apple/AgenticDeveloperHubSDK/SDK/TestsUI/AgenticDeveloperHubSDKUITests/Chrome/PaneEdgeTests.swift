import Testing
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The four directions a pane can be minimized toward. A value type with no
/// dependencies, so that the chrome view that draws the arrows and the pane
/// controller that acts on them can both name it.
@Suite("Pane edge")
struct PaneEdgeTests {

    @Test("leading and trailing are the horizontal pair, top and bottom are not")
    func horizontalPair() {
        #expect(PaneEdge.leading.isHorizontal)
        #expect(PaneEdge.trailing.isHorizontal)
        #expect(!PaneEdge.top.isHorizontal)
        #expect(!PaneEdge.bottom.isHorizontal)
    }

    /// The flip rule in the design — "minimizing left with nothing to the left
    /// behaves as minimizing right" — is `opposite`, so it has to be an
    /// involution that stays on its own axis or the flip lands off-axis.
    @Test("opposite is an involution that stays on the same axis")
    func opposites() {
        #expect(PaneEdge.top.opposite == .bottom)
        #expect(PaneEdge.leading.opposite == .trailing)
        for edge in PaneEdge.allCases {
            #expect(edge.opposite.opposite == edge)
            #expect(edge.opposite.isHorizontal == edge.isHorizontal)
            #expect(edge.opposite != edge)
        }
    }

    @Test("each edge names a distinct arrow symbol")
    func arrowSymbolsAreDistinct() {
        #expect(Set(PaneEdge.allCases.map(\.arrowSymbolName)).count == 4)
        #expect(PaneEdge.top.arrowSymbolName == "arrow.up")
        #expect(PaneEdge.leading.arrowSymbolName == "arrow.left")
    }

    /// The raw value is the accessibility-identifier suffix under
    /// `pane.minimize.`, so it is part of the contract a UI test addresses.
    @Test("raw values are the accessibility suffixes the design names")
    func rawValuesAreStable() {
        #expect(PaneEdge.allCases.map(\.rawValue) == ["top", "leading", "bottom", "trailing"])
    }
}
