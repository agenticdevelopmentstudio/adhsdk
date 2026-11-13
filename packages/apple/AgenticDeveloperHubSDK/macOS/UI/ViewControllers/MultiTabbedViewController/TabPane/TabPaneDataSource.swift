import Foundation

/// Supplies everything a tab pane displays. The pane never computes any of
/// it; whoever vends the pane (a branch controller) answers these.
@MainActor
public protocol TabPaneDataSource: AnyObject {
    func tabPaneAgentName(_ pane: TabPaneViewController) -> String
    func tabPaneModelName(_ pane: TabPaneViewController) -> String?
    func tabPaneStatusSymbols(_ pane: TabPaneViewController) -> [TabPaneStatusSymbol]
    func tabPaneSessionName(_ pane: TabPaneViewController) -> String
    func tabPaneWorkingDirectory(_ pane: TabPaneViewController) -> URL
    func tabPaneBranch(_ pane: TabPaneViewController) -> String?
    func tabPaneSummary(_ pane: TabPaneViewController) -> String?
    /// What the tab's session is doing, drawn at the far end of the top line;
    /// `nil` for a tab with no session.
    func tabPaneActivitySymbol(_ pane: TabPaneViewController) -> TabPaneStatusSymbol?
    /// False for a card that is only its top line and summary: no session
    /// line, working directory or branch line under it.
    func tabPaneShowsDetails(_ pane: TabPaneViewController) -> Bool
}

public extension TabPaneDataSource {
    func tabPaneActivitySymbol(_ pane: TabPaneViewController) -> TabPaneStatusSymbol? { nil }
    func tabPaneShowsDetails(_ pane: TabPaneViewController) -> Bool { true }
}
