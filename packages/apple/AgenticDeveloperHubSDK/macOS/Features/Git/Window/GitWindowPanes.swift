import AppKit
import AgenticDeveloperHubSDKCore

/// The Git window's panes on the project window's composable-tabs layout
/// (recipe `workspace/git/git-window`, "Layout"): the overview on the left, the
/// history beside it, and on the right the commit (description, file list and
/// diff) over a terminal opened in the repository.
///
/// The three Git panes are fixed, one of each: they are the window, not a
/// document of panes. The terminal region is not. It starts on one terminal
/// and offers the host's whole terminal family in its Split menu (terminals,
/// Terminal Chats and the rest) the way a project window does, so a second
/// shell or a chat sits beside the first. It keeps at least one terminal: the
/// commit pane above it is fixed, so a closed last terminal could never come
/// back. Minimizing it is how it gets out of the way.
///
/// The terminal region also offers the Command Log, one at most, which the
/// toolbar's Command Log toggle opens beside the terminal and closes again.
public enum GitWindowPanes {

    /// The overview: the refs sidebar. A storage format — never rename.
    public static let overview = ComposableTabsViewID("git.overview")
    /// The history, or the working copy while it is selected.
    public static let history = ComposableTabsViewID("git.history")
    /// The commit detail over its diff, blame or file history.
    public static let commit = ComposableTabsViewID("git.commit")
    /// The command log, in the terminal region. A storage format — never rename.
    public static let commandLog = ComposableTabsViewID("git.commandLog")

    /// The three fixed panes; everything else is the terminal region.
    static let fixedPanes: Set<ComposableTabsViewID> = [overview, history, commit]

    static let symbolName = "point.3.connected.trianglepath.dotted"

    /// The overview | (history | (commit / terminals)) split. Without
    /// `terminals` the right column is the commit pane alone.
    @MainActor
    public static func spec(terminals: TerminalPaneFamily?) -> ComposableTabLayoutSpec {
        let commitPane = ComposableTabLayoutSpec.pane(commit, allows: [.init(commit)], isFixed: true)
        let right: ComposableTabLayoutSpec
        if let terminals {
            right = .split(axis: .vertical, children: [
                commitPane,
                .pane(.terminal, allows: terminalAllowances(terminals))
            ])
        } else {
            right = commitPane
        }
        return .split(axis: .horizontal, children: [
            .pane(overview, allows: [.init(overview)], isFixed: true),
            .split(axis: .horizontal, children: [
                .pane(history, allows: [.init(history)], isFixed: true),
                right
            ])
        ])
    }

    /// The family's allowances with the terminal required once, and the Command Log
    /// at most once — see the type comment.
    @MainActor
    static func terminalAllowances(_ terminals: TerminalPaneFamily) -> [ComposableTabsViewAllowance] {
        terminals.allowances.map { allowance in
            guard allowance.viewID == .terminal else { return allowance }
            var required = allowance
            required.min = 1
            return required
        } + [ComposableTabsViewAllowance(commandLog)]
    }

    /// Registers the three Git panes, each vending its pane of the session
    /// `session` returns for the window the context names, and the terminal
    /// family when there is one.
    @MainActor
    static func register(
        in registry: ComposableTabsViewRegistry,
        terminals: TerminalPaneFamily?,
        session: @escaping @MainActor (ComposableTabsViewContext) -> GitWindowSession
    ) {
        registry.register(overview, descriptor: ComposableTabsViewDescriptor(
            displayName: "Overview", symbolName: symbolName, minimumThickness: 230,
            preferredThicknessFraction: 0.2)) { session($0).overviewPane }
        registry.register(history, descriptor: ComposableTabsViewDescriptor(
            displayName: "History", symbolName: symbolName, minimumThickness: 260,
            preferredThicknessFraction: 0.5)) { session($0).centre }
        // With a terminal the fraction is the commit's share of the right
        // column; the minimum holds both across the window and down the column.
        registry.register(commit, descriptor: ComposableTabsViewDescriptor(
            displayName: "Commit", symbolName: symbolName, minimumThickness: 240,
            preferredThicknessFraction: terminals == nil ? nil : 0.65)) { session($0).commitPane }
        registry.register(commandLog, descriptor: ComposableTabsViewDescriptor(
            displayName: "Command Log", symbolName: "list.bullet.rectangle", minimumThickness: 200,
            preferredThicknessFraction: nil)) { session($0).commandLog }
        terminals?.register(in: registry)
    }

    /// The Git window's layout over a registry of its panes.
    @MainActor
    static func layout(
        terminals: TerminalPaneFamily?,
        session: @escaping @MainActor (ComposableTabsViewContext) -> GitWindowSession
    ) throws -> ComposableTabsLayout {
        let registry = ComposableTabsViewRegistry()
        register(in: registry, terminals: terminals, session: session)
        return try ComposableTabsLayout(registry: registry, spec: spec(terminals: terminals))
    }
}
