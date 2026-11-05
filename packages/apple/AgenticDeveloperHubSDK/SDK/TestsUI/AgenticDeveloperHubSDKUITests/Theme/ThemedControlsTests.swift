import Testing
import AppKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// Relocated from AgenticDeveloperHubSDK's `Tests/AgenticDeveloperHubSDKMacOSTests/Theme/`.
/// It tests the `Themed*` view family (`ThemedLabel`, `ThemedButton`,
/// `ThemedTextField`, `ThemedBox`, `ThemedTableRowView`, `ThemedTableView`,
/// `ThemedScrollView`), which moved here in the same step — its old home
/// stopped compiling it once those types (and their `internal` `palette`
/// property, reached only through `@testable import AgenticDeveloperHubSDKUI`)
/// no longer lived in `AgenticDeveloperHubSDKMacOS` itself.
@MainActor
@Suite("Themed controls (color + typography + border)")
struct ThemedControlsTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }
    private var lightPalette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedLight) }

    @Test("ThemedLabel applies its color role and typography role")
    func label() {
        let label = ThemedLabel(string: "Hi", role: .secondaryText, textRole: .caption)
        label.applyTheme(palette)
        #expect(label.textColor == palette.nsColor(.secondaryText))
        #expect(label.font?.pointSize == palette.font(.caption).pointSize)
    }

    @Test("ThemedButton uses onAccent text and the button font")
    func button() {
        let button = ThemedButton(title: "Go")
        button.applyTheme(palette)
        let attrs = button.attributedTitle.attributes(at: 0, effectiveRange: nil)
        #expect((attrs[.foregroundColor] as? NSColor) == palette.onAccentTextColor)
        #expect((attrs[.font] as? NSFont)?.pointSize == palette.font(.button).pointSize)
    }

    @Test("ThemedTextField uses the control background and body font")
    func textField() {
        let field = ThemedTextField(string: "x")
        field.applyTheme(palette)
        #expect(field.backgroundColor == palette.controlBackgroundColor)
        #expect(field.font?.pointSize == palette.font(.body).pointSize)
    }

    @Test("ThemedBox strokes only when a stroke role is set, and tracks the palette")
    func box() {
        let bordered = ThemedBox(fill: .surface, stroke: .outline)
        bordered.applyTheme(palette)
        #expect(bordered.layer?.borderWidth == 1)
        let darkFill = bordered.layer?.backgroundColor
        bordered.applyTheme(lightPalette)
        #expect(bordered.layer?.backgroundColor != darkFill)   // wired to the palette

        let plain = ThemedBox(fill: .surface, stroke: nil)
        plain.applyTheme(palette)
        #expect(plain.layer?.borderWidth == 0)
    }

    @Test("ThemedTableRowView tracks the palette across a theme change")
    func tableRow() {
        let row = ThemedTableRowView(frame: .zero)
        // A reused, pooled row must adopt the new palette (its selection fill
        // would otherwise stay frozen at the palette captured when it was created).
        row.applyTheme(lightPalette)
        #expect(row.palette == lightPalette)
        row.applyTheme(palette)
        #expect(row.palette == palette)
    }

    @Test("ThemedTableView paints its role, not the system control background")
    func tableView() {
        let table = ThemedTableView(role: .surface)
        table.applyTheme(palette)
        #expect(table.backgroundColor == palette.nsColor(.surface))
        #expect(table.gridColor == palette.nsColor(.divider))
        // Banding comes from a system color pair the palette cannot reach.
        #expect(table.usesAlternatingRowBackgroundColors == false)
    }

    @Test("ThemedSeparatorView is an auto layout view, hairline height and all")
    func separator() {
        let separator = ThemedSeparatorView(role: .divider)
        separator.applyTheme(palette)
        #expect(separator.layer?.backgroundColor == palette.nsColor(.divider).cgColor)

        // It activates a height constraint on itself in `init`, so it only
        // works under auto layout — and a caller who left the autoresizing
        // translation on got a hairline nailed to (0, 0, 0, 0) by required
        // constraints, which dragged everything positioned off its edges to
        // zero with it. `InlineChatView`'s composer was crushed to nothing
        // that way, on screen, with no constraint conflict logged.
        #expect(separator.translatesAutoresizingMaskIntoConstraints == false)
        let heights = separator.constraints.filter { $0.firstAttribute == .height }
        #expect(heights.count == 1)
        #expect(heights.first?.constant == 1)
    }

    @Test("ThemedTableView leaves the role of the scroll view hosting it alone")
    func tableViewDoesNotRestyleItsHost() {
        // A table fills its clip view, so the host's backdrop is the host's
        // business. Reaching out to recolor it would override a deliberately
        // different role (a `.surface` list inside a `.windowBackground` scroll
        // view) — and only from the *second* theme change onward, since
        // `enclosingScrollView` is still nil when the observer first fires.
        let table = ThemedTableView(role: .surface)
        let scroll = ThemedScrollView(frame: .zero)
        scroll.documentView = table
        // Theme the host explicitly: its constructor seeds from the ambient
        // `ThemeManager.shared`, which another suite in this process may have
        // pointed at a different theme. The claim under test is that the table
        // does not *change* the host, so pin the host first and re-check it.
        scroll.applyTheme(palette)
        table.applyTheme(palette)
        #expect(scroll.backgroundColor == palette.nsColor(.windowBackground))
        #expect(table.backgroundColor == palette.nsColor(.surface))
    }
}
