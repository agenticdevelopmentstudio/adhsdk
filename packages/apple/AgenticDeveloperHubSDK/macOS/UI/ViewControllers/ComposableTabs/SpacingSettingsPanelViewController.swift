import AppKit

import AgenticDeveloperHubSDKCore

/// Settings > Appearance > Spacing: the one place the app's spacing is set.
///
/// Three groups, all bound to the app-wide keys `PaneSpacing` reads: the room
/// around the panes (frame), the gaps between them (dividers), and the room
/// between a pane's edges and its content. Every window reads these — the
/// project windows, the Coding Partner window and the terminal — and none of
/// them offers spacing controls of its own, so there is exactly one answer to
/// "why is this pane spaced like that" (`dry`).
@MainActor
public final class SpacingSettingsPanelViewController: ComposableSettings.SettingsPanelViewController {

    /// Held so the panel can join their Tab orders end to end — see
    /// `joinTabOrder()`.
    private var frameSpacing: SpacingControl?
    private var dividerSpacing: SpacingControl?
    private var contentSpacing: SpacingControl?

    public init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Spacing",
            icon: NSImage(systemSymbolName: "rectangle.split.3x1", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The sidebar's search only reads the controls of a panel that has already
    /// been opened, so this panel names what it is about for the search that
    /// happens before anyone opens it.
    public override var searchKeywords: [String] {
        ["spacing", "frame", "divider", "gutter", "pane", "padding", "margin", "terminal", "project", "partner"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Frame Spacing",
                body: "The room between the panes and the tab bars framing them, in points, "
                    + "set per side. Each number stands outside the diagram, in line with "
                    + "the edge it belongs to. Every arrow stands against that edge and "
                    + "points the way it travels, so the arrow pointing into the view is "
                    + "the one that adds space. Hold an arrow down to "
                    + "keep going, or type a number and press Return. The stepper beside "
                    + "each number adjusts it a point at a time."
            ),
            .init(
                title: "Pane Divider Spacing",
                body: "The gaps between panes: one number for panes side by side, one for "
                    + "panes stacked, each sitting on the divider it opens. The arrows "
                    + "pointing at the divider close the gap; the ones pointing away open "
                    + "it. Each number is the whole gap, not each pane's half — ten means "
                    + "ten points between two panes. A gap of zero still drags: the divider "
                    + "keeps a few points of grab area whatever it is drawn at."
            ),
            .init(
                title: "Pane Content Spacing",
                body: "The room between a pane's edges and what it shows, per side — a "
                    + "terminal's text, a chat, a list. A theme can carry its own terminal "
                    + "padding, and when it does that wins for terminals."
            ),
            .init(
                title: "Everywhere",
                body: "Spacing belongs to the app, not to a window: every Development Project window, the "
                    + "Coding Partner window and every terminal use these numbers, and "
                    + "changes apply to all of them as you make them."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(createFrameGroup())
        addGroup(createDividerGroup())
        addGroup(createContentGroup())
        joinTabOrder()
    }

    // MARK: - Groups

    /// Separate groups rather than one, because they answer separate questions:
    /// how much room around the panes, between them, and inside them. One
    /// diagram carrying all of them made the reader work out which numbers
    /// were which.
    private func createFrameGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Frame Spacing")
        let control = SpacingControl.boundToSettings(style: .frame, edges: PaneSpacing.edgeSettings)
        control.accessibilityID("settings.spacing.frame")
        frameSpacing = control
        group.addSettingSubview(control)
        return group
    }

    private func createDividerGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Pane Divider Spacing")
        let control = SpacingControl.boundToSettings(
            style: .paneDividers,
            gutters: PaneSpacing.gutterSettings
        )
        control.accessibilityID("settings.spacing.dividers")
        dividerSpacing = control
        group.addSettingSubview(control)
        return group
    }

    private func createContentGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Pane Content Spacing")
        let control = SpacingControl.boundToSettings(style: .frame, edges: PaneSpacing.contentSettings)
        control.accessibilityID("settings.spacing.content")
        contentSpacing = control
        group.addSettingSubview(control)
        return group
    }

    /// Tab out of the last number in one group and into the first number of the
    /// next.
    ///
    /// Each control answers Tab within itself and hands the key back at either
    /// end, which is where AppKit takes over — and AppKit works the key view
    /// loop out from where subviews *are*. These are placed by frame, so left
    /// to itself Tab out of the bottom number went somewhere that looked like
    /// nowhere. Which control follows which is the panel's knowledge, so the
    /// panel is what says it. `nextKeyView` sets the back link too, so
    /// Shift-Tab walks the same chain the other way.
    private func joinTabOrder() {
        frameSpacing?.lastNumberField?.nextKeyView = dividerSpacing?.firstNumberField
        dividerSpacing?.lastNumberField?.nextKeyView = contentSpacing?.firstNumberField
    }
}
