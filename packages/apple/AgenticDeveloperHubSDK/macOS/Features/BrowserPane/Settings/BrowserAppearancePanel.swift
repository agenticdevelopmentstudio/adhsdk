//
//  BrowserAppearancePanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit

import AgenticDeveloperHubSDKCore

/// The Browser panel's Appearance topic: how a page and a pane look — the
/// page's zoom and smallest text, and, in a pane's sheet, which edges of the
/// pane show its tab bar.
///
/// Zoom and Minimum font size moved here from General, and the tab position
/// row from General's pane-scope Tabs group; each keeps its setting key and
/// accessibility identifier (`keys-never-change`). The tab position row is a
/// pane's override of the app-wide value, so it is shown only in a pane's
/// sheet: in the app's Settings window there is no pane to override for, and
/// the app-wide value is System ▸ General's.
@MainActor
final class BrowserAppearancePanel: BrowserTopicPanel {

    init(binding: BrowserSettingsBinding) {
        super.init(title: "Appearance", symbol: "textformat.size", binding: binding)
    }

    /// The tab position row is a pane's alone, so in the Settings window the
    /// Tab Position help says where the app-wide value is instead.
    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Page",
                body: "Zoom scales every page, from half size to three times, and applies "
                    + "to open panes at once. Minimum font size stops a page using text "
                    + "smaller than this many points; zero lets the page decide."
            ),
            .init(
                title: "Tab Position",
                body: binding.isPaneScope
                    ? "Which edges of this pane show its tab bar. Without an override the "
                        + "pane follows the app's own tab position, set in System ▸ General "
                        + "or View ▸ Tab Position; changing a switch here gives the pane its "
                        + "own, and Use Global Setting in the row's menu goes back. At least "
                        + "one edge stays on."
                    : "Which edges a browser pane shows its tabs on follows the app's own "
                        + "tab position, set in System ▸ General or View ▸ Tab Position. A "
                        + "single pane can override it in its own settings, under Appearance."
            )
        ])
    }

    /// Every control's title, then the other words someone might search by.
    static let keywords: [String] = [
        "Zoom", "Minimum font size", "Tab position",
        "font size", "text size", "tabs", "tab bar", "appearance"
    ]

    override var searchKeywords: [String] { Self.keywords }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makePageGroup())
        if binding.isPaneScope {
            settingsView.addGroup(makeTabsGroup())
        }
    }

    private func makePageGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Page")

        let zoom = binding.range("Zoom", UserSettings.browserPageZoom, bounds: BrowserSettings.pageZoomRange)
        let zoomView = ComposableSettings.CaptionedSliderView(viewModel: zoom) { "\(Int(($0 * 100).rounded()))%" }
        _ = zoomView.slider.accessibilityID("settings.browser.general.zoom")
        binding.add(zoomView, model: zoom, key: UserSettings.browserPageZoom, to: group)

        // What it does is in the topic's help (`no-inline-help-labels`).
        let fontSize = binding.range(
            "Minimum font size", UserSettings.browserMinimumFontSize,
            bounds: BrowserSettings.minimumFontSizeRange
        )
        let fontView = ComposableSettings.IntegerFieldView(viewModel: fontSize)
        _ = fontView.textField.accessibilityID("settings.browser.general.minimum-font-size")
        binding.add(fontView, model: fontSize, key: UserSettings.browserMinimumFontSize, to: group)

        return group
    }

    private func makeTabsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Tabs")
        let key = UserSettings.browserTabsPositions
        let store = binding.store
        let row = TabPositionsSettingView(
            get: { BrowserSettings.tabPositions(in: store) },
            set: { store.set($0, for: key) },
            identifierPrefix: "settings.browser.general.tab-position"
        )
        let layered = binding.layered
        binding.add(row, name: key.name, model: nil, to: group, refresh: { [weak row] in
            row?.refresh()
        }, hasOverride: {
            layered?.hasOverride(key) ?? false
        }, revert: { [weak row] in
            layered?.removeOverride(key)
            row?.refresh()
        })
        return group
    }
}
