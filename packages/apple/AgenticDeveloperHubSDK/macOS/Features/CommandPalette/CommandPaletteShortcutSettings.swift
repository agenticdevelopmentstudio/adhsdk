import AppKit
import KeyboardShortcuts

/// Where the user rebinds the palette's global shortcut: a group, its help
/// topic and its search words, for an app that builds the command palette to
/// fold into its shortcuts panel (`KeyCommandsSettingsPanelViewController`'s
/// `leadingGroups`).
///
/// Not a panel of its own: one recorder alone in a panel beside the list of
/// every other shortcut split one subject in two. Not part of the shared Key
/// Commands panel either, because Stenographer shows that panel and must not
/// be made to advertise a command palette it does not build (`srp`).
@MainActor
public enum CommandPaletteShortcutSettings {

    /// The recorder is a third-party control with no text of its own to
    /// match, so everything a user might type to find it is named here.
    public static let searchKeywords = ["palette", "command palette"]

    public static var helpTopic: ComposableSettings.PanelHelp.Topic {
        .init(
            // Titled for the row it explains — "Command Palette:" — not for
            // the command that opens the palette, which the user does not
            // see from here. Same reasoning as the row label below.
            title: "Command Palette",
            body: "Opens the command palette: a search field listing every command in "
                + "the app, including the ones extensions add. This shortcut is "
                + "registered system-wide, so it works while another app is frontmost "
                + "— which also means it is taken away from that app. If a combination "
                + "does nothing, another app or a macOS shortcut already claimed it; "
                + "record a different one here."
        )
    }

    public static func makeGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Command Palette")

        let recorder = KeyboardShortcuts.RecorderCocoa(for: .showCommandPalette)
        recorder.accessibilityID("settings.keyboard.show-command-palette")

        // The library's recorder is the whole control — it draws the current
        // binding, records a new one and persists it — but it brings no label,
        // so the row is assembled the way every other labelled row here is.
        let row = ComposableSettings.HorizontalStackView()
        // "Command Palette:", not the command's own title "Show All Commands":
        // this row binds the shortcut that *opens* the palette, and the surface
        // the user is looking for it from is the View menu's "Command Palette…".
        row.addArrangedSubview(ComposableSettings.makeRowLabel("Command Palette:"))
        row.addArrangedSubview(recorder)
        group.addSettingSubview(row)

        return group
    }
}
