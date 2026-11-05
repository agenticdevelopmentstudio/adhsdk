import AppKit

import AgenticDeveloperHubSDKCore

/// Settings panel for the terminal's font and caret.
///
/// No spacing: how far the text sits from the pane's edges is the app-wide pane
/// content spacing, set under Appearance > Spacing with every other pane's.
///
/// There is deliberately no color section: terminal colors are the app theme's,
/// edited in Theme settings, so there is one palette rather than two that drift
/// (`dry`).
@MainActor
public final class TerminalSettingsPanelViewController: ComposableSettings.SettingsPanelViewController {

    public init() {
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Terminal",
            icon: NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Font",
                body: "The terminal's own font, independent of the theme's code font — a "
                    + "terminal is usually read at a different size from a code editor. "
                    + "Pick a monospaced face: a proportional one renders, but columns "
                    + "will not line up."
            ),
            .init(
                title: "Cursor",
                body: "Block, hollow block, underline or bar, blinking or steady. The caret "
                    + "keeps its shape whether or not the terminal has focus — the active "
                    + "pane is shown by the pane outline instead."
            ),
            .init(
                title: "Themes Override These",
                body: "A theme can carry its own terminal padding, font and cursor, and when "
                    + "it does they win over the values here and under Appearance > Spacing. "
                    + "Those live in Theme settings, under the theme's Terminal topic. A theme "
                    + "has no terminal options until you set them, so by default these panels "
                    + "are what decide."
            ),
            .init(
                title: "Colors",
                body: "Terminal colors — foreground, background, cursor, selection and the 16 "
                    + "ANSI colors — are the active theme's, edited in Theme settings. One "
                    + "palette, not two that drift apart."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.settingsView.addGroup(createFontGroup())
        self.settingsView.addGroup(createCursorGroup())
    }

    private func createFontGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Font")

        let fontViewModel = ComposableSettings.FontViewModel(
            title: "Terminal font",
            nameSetting: UserSettings.terminalFontName,
            sizeSetting: UserSettings.terminalFontSize
        )
        group.addSettingSubview(ComposableSettings.FontPickerView(viewModel: fontViewModel))

        return group
    }

    private func createCursorGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Cursor")

        let shape = ComposableSettings.ChoiceViewModel<TerminalCursorShape>(
            title: "Shape",
            setting: UserSettings.terminalCursorShape,
            choices: TerminalCursorShape.allCases.map { .init(label: $0.label, value: $0) }
        )
        group.addSettingSubview(ComposableSettings.PopupMenuChoiceView(viewModel: shape))

        let blinks = ComposableSettings.ViewModel<Bool>(
            title: "Blink",
            setting: UserSettings.terminalCursorBlinks
        )
        group.addSettingSubview(ComposableSettings.CheckboxView(with: blinks))

        return group
    }
}
