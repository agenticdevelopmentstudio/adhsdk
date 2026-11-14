import AppKit
import AgenticDeveloperHubSDKCore

/// The Git window's three panes on the project window's composable-tabs layout
/// (recipe `workspace/git/git-window`, "Layout"): the overview on the left, the
/// history beside it, and the commit (description, file list and diff) on the
/// right. Fixed, one of each, no tabs: the window is one arrangement, not a
/// document of them.
public enum GitWindowPanes {

    /// The overview: the refs sidebar. A storage format — never rename.
    public static let overview = ComposableTabsViewID("git.overview")
    /// The history, or the working copy while it is selected.
    public static let history = ComposableTabsViewID("git.history")
    /// The commit detail over its diff, blame or file history.
    public static let commit = ComposableTabsViewID("git.commit")

    static let symbolName = "point.3.connected.trianglepath.dotted"

    /// The overview | (history | commit) split, each pane fixed and allowing only itself.
    public static let spec: ComposableTabLayoutSpec = .split(
        axis: .horizontal,
        children: [
            .pane(overview, allows: [.init(overview)], isFixed: true),
            .split(
                axis: .horizontal,
                children: [
                    .pane(history, allows: [.init(history)], isFixed: true),
                    .pane(commit, allows: [.init(commit)], isFixed: true)
                ],
                isFixed: true)
        ],
        isFixed: true)

    /// Registers the three panes, each vending its pane of the session `session`
    /// returns for the window the context names.
    @MainActor
    static func register(
        in registry: ComposableTabsViewRegistry,
        session: @escaping @MainActor (ComposableTabsViewContext) -> GitWindowSession
    ) {
        registry.register(overview, descriptor: ComposableTabsViewDescriptor(
            displayName: "Overview", symbolName: symbolName, minimumThickness: 180,
            preferredThicknessFraction: 0.2)) { session($0).overviewPane }
        registry.register(history, descriptor: ComposableTabsViewDescriptor(
            displayName: "History", symbolName: symbolName, minimumThickness: 260,
            preferredThicknessFraction: 0.5)) { session($0).centre }
        registry.register(commit, descriptor: ComposableTabsViewDescriptor(
            displayName: "Commit", symbolName: symbolName, minimumThickness: 320)) { session($0).commitPane }
    }

    /// The Git window's layout over a registry of its three panes.
    @MainActor
    static func layout(
        session: @escaping @MainActor (ComposableTabsViewContext) -> GitWindowSession
    ) throws -> ComposableTabsLayout {
        let registry = ComposableTabsViewRegistry()
        register(in: registry, session: session)
        return try ComposableTabsLayout(registry: registry, spec: spec)
    }
}
