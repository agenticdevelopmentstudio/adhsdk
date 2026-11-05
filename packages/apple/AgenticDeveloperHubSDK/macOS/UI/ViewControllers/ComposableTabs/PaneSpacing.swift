import AppKit

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS

/// How much room every window keeps around, between and inside its panes.
///
/// Ten numbers in three groups: the four insets between the pane area and the
/// tab bars framing it (*frame*), the two gutters — one for panes side by side,
/// one for panes stacked — and the four insets between a pane's edges and its
/// content (*pane content*). A gutter is the whole gap, not each pane's half,
/// which is why it is stored once rather than as a per-pane inset: ten means
/// ten points between two panes.
///
/// App-wide, deliberately, and set in one place — Settings > Appearance >
/// Spacing. A window whose panes are spaced differently from the window beside
/// it reads as a bug, so no window or pane carries spacing of its own: the
/// project windows, the Coding Partner window and the terminal all read these.
@MainActor
public enum PaneSpacing {

    public static var current: Spacing {
        var spacing = Spacing()
        for (edge, setting) in edgeSettings {
            spacing[edge] = setting.value
        }
        for (gutter, setting) in gutterSettings {
            spacing[gutter] = setting.value
        }
        return spacing
    }

    public static let edgeSettings: [SpacingEdge: UserSetting<Int>] = [
        .top: UserSettings.paneSpacingTop,
        .leading: UserSettings.paneSpacingLeading,
        .bottom: UserSettings.paneSpacingBottom,
        .trailing: UserSettings.paneSpacingTrailing
    ]

    public static let gutterSettings: [SpacingGutter: UserSetting<Int>] = [
        .betweenColumns: UserSettings.paneSpacingBetweenColumns,
        .betweenRows: UserSettings.paneSpacingBetweenRows
    ]

    /// How far every pane holds its content off its own edges. A terminal
    /// applies this itself, so a theme can still override it; every other
    /// pane has it applied by `PaneViewController`.
    public static let contentSettings: [SpacingEdge: UserSetting<Int>] = [
        .top: UserSettings.paneContentSpacingTop,
        .leading: UserSettings.paneContentSpacingLeading,
        .bottom: UserSettings.paneContentSpacingBottom,
        .trailing: UserSettings.paneContentSpacingTrailing
    ]

    /// The pane-content insets, as a `Spacing` with no gutters.
    public static var contentSpacing: Spacing {
        var spacing = Spacing()
        for (edge, setting) in contentSettings {
            spacing[edge] = setting.value
        }
        return spacing
    }

    /// Every spacing key, so one filter on `UserSettings.shared.changes` can
    /// tell a spacing change from any other.
    public static let settingKeys: Set<String> = Set(
        edgeSettings.values.map(\.name) + gutterSettings.values.map(\.name) + contentSettings.values.map(\.name))

    /// The pane-content keys alone: a pane re-insets on these and nothing else.
    public static let contentSettingKeys: Set<String> = Set(contentSettings.values.map(\.name))

    /// The terminal's own padding keys, from before pane-content spacing
    /// replaced them. Read only by ``migrateLegacyTerminalPadding(in:)``.
    static let legacyTerminalPadding: [SpacingEdge: UserSetting<Int>] = [
        .top: UserSetting<Int>("terminal_padding_top", default: UserSettings.defaultPaneSpacing),
        .leading: UserSetting<Int>("terminal_padding_leading", default: UserSettings.defaultPaneSpacing),
        .bottom: UserSetting<Int>("terminal_padding_bottom", default: UserSettings.defaultPaneSpacing),
        .trailing: UserSetting<Int>("terminal_padding_trailing", default: UserSettings.defaultPaneSpacing)
    ]

    /// Carries a terminal padding the owner saved before pane-content spacing
    /// replaced it over to that side's pane-content spacing, then deletes the
    /// old key, so a terminal set to 0 does not jump to the default 10.
    /// A side whose pane-content spacing is already stored keeps it: that is
    /// the newer choice. Safe to run on every launch; once the old keys are
    /// gone it does nothing. Pane-content spacing is app-wide, so the carried
    /// value now insets every pane, not just terminals — the one setting there is.
    public static func migrateLegacyTerminalPadding(in store: SettingsStore = UserSettings.shared) {
        for (edge, legacy) in legacyTerminalPadding where store.contains(legacy) {
            if let content = contentSettings[edge], !store.contains(content) {
                store.set(store.get(legacy), for: content)
            }
            store.remove(legacy)
        }
    }

    /// The insets, as AppKit wants them.
    public static var contentInsets: NSEdgeInsets {
        let spacing = current
        return NSEdgeInsets(
            top: CGFloat(spacing.top),
            left: CGFloat(spacing.leading),
            bottom: CGFloat(spacing.bottom),
            right: CGFloat(spacing.trailing)
        )
    }

    /// How wide a divider stays draggable, however narrow the gutter is drawn.
    /// A zero-point gutter is a legitimate look, and it would otherwise be a
    /// layout the user cannot undo with the mouse.
    public static let minimumDividerGrab: CGFloat = 6
}

/// The split view behind a project window's panes.
///
/// Two overrides, both for the same reason: a divider here is a *gap*, not a
/// seam. Its thickness is the gutter the user asked for, and once it is wider
/// than a hairline it is painted as window background — a ten-point bar in the
/// divider colour would be a stripe between the panes rather than space.
@MainActor
public final class PaneSplitView: ThemedSplitView {

    /// A vertical split view stands its panes side by side, so its divider is
    /// the gap between two columns; a horizontal one stacks them.
    public override var dividerThickness: CGFloat {
        CGFloat(isVertical ? PaneSpacing.current.betweenColumns : PaneSpacing.current.betweenRows)
    }

    public override func drawDivider(in rect: NSRect) {
        guard dividerThickness > 1 else {
            super.drawDivider(in: rect)
            return
        }
        // The backdrop, not the window background: a gutter is a window-shaped
        // hole between two panes, so it has to show the same plane the frame
        // spacing around them does or the panes float on two different grounds.
        NSColor(currentPalette.projectPaneBackdrop).setFill()
        rect.fill()
    }

    /// Re-reads the gutter after the setting changes. `dividerThickness` is
    /// computed, so nothing tells AppKit on its own that the answer moved.
    ///
    /// `adjustSubviews()` is the resize-based layout path, and an
    /// `NSSplitViewController` lays its panes out with constraints instead —
    /// constraints whose constants were built from `dividerThickness` when the
    /// items were installed. Assigning the divider style is what makes AppKit
    /// throw those away and ask again, so the style is toggled off its current
    /// value and back rather than left alone.
    public func spacingDidChange() {
        let style = dividerStyle
        dividerStyle = style == .thin ? .paneSplitter : .thin
        dividerStyle = style
        needsDisplay = true
    }
}

extension UserSettings {

    /// The house spacing: ten points for every gap, outside the panes and in.
    public static let defaultPaneSpacing = 10

    /// Space between the pane area and the tab bars framing it, per side, in
    /// points.
    static public var paneSpacingTop = UserSetting<Int>("pane_spacing_top", default: defaultPaneSpacing)
    static public var paneSpacingLeading = UserSetting<Int>("pane_spacing_leading", default: defaultPaneSpacing)
    static public var paneSpacingBottom = UserSetting<Int>("pane_spacing_bottom", default: defaultPaneSpacing)
    static public var paneSpacingTrailing = UserSetting<Int>("pane_spacing_trailing", default: defaultPaneSpacing)

    /// The gap between two panes, in points — the whole gap, shared by both.
    static public var paneSpacingBetweenColumns = UserSetting<Int>(
        "pane_spacing_between_columns", default: defaultPaneSpacing)
    static public var paneSpacingBetweenRows = UserSetting<Int>(
        "pane_spacing_between_rows", default: defaultPaneSpacing)

    /// Space between a pane's edges and its content, per side, in points. The
    /// terminal's padding is this: there is one inner margin, not one for
    /// terminals and another for everything else.
    static public var paneContentSpacingTop = UserSetting<Int>(
        "pane_content_spacing_top", default: defaultPaneSpacing)
    static public var paneContentSpacingLeading = UserSetting<Int>(
        "pane_content_spacing_leading", default: defaultPaneSpacing)
    static public var paneContentSpacingBottom = UserSetting<Int>(
        "pane_content_spacing_bottom", default: defaultPaneSpacing)
    static public var paneContentSpacingTrailing = UserSetting<Int>(
        "pane_content_spacing_trailing", default: defaultPaneSpacing)
}
