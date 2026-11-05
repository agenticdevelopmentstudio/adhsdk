import Testing
import UIKit
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// The UIKit twin of `ThemedControlsTests` (macOS): the small family of bases a
/// UIKit screen is assembled from, each checked against the palette it claims
/// to paint from. Without these, a view that quietly reaches for `UIColor.label`
/// still looks right in one theme and wrong in every other.
@MainActor
@Suite("Themed views (UIKit)")
struct ThemedViewsUIKitTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }
    private var lightPalette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedLight) }

    @Test("ThemedBackgroundView fills with its role, and an override replaces it")
    func backgroundView() {
        let view = ThemedBackgroundView(role: .surface)
        view.applyTheme(palette)
        #expect(view.backgroundColor == palette.uiColor(.surface))

        view.colorOverride = .red
        #expect(view.backgroundColor == .red)
        view.colorOverride = nil
        #expect(view.backgroundColor == view.resolvedThemeScope.palette.uiColor(.surface))
    }

    @Test("ThemedLabel applies its colour role and typography role")
    func label() {
        let label = ThemedLabel(string: "Hi", role: .secondaryText, textRole: .caption)
        label.applyTheme(palette)
        #expect(label.text == "Hi")
        #expect(label.textColor == palette.uiColor(.secondaryText))
        #expect(label.font.pointSize == palette.font(.caption).pointSize)
    }

    @Test("ThemedLabel repaints when its roles change")
    func labelRoleChange() {
        let label = ThemedLabel(string: "Hi")
        label.applyTheme(palette)
        label.role = .danger
        #expect(label.textColor == label.resolvedThemeScope.palette.uiColor(.danger))
        label.textRole = .title
        #expect(label.font.pointSize == label.resolvedThemeScope.palette.font(.title).pointSize)
    }

    @Test("ThemedTextField uses the control background, body font and themed cursor")
    func textField() {
        let field = ThemedTextField()
        field.applyTheme(palette)
        #expect(field.borderStyle == .roundedRect)
        #expect(field.backgroundColor == palette.controlBackgroundColor)
        #expect(field.textColor == palette.primaryTextColor)
        #expect(field.font?.pointSize == palette.font(.body).pointSize)
        #expect(field.tintColor == palette.cursorColor)
    }

    @Test("a placeholder set after construction is themed too, not left system grey")
    func textFieldPlaceholder() {
        let field = ThemedTextField()
        field.applyTheme(palette)
        #expect(field.attributedPlaceholder == nil)

        field.placeholder = "you@example.com"
        let attributed = field.attributedPlaceholder
        #expect(attributed?.string == "you@example.com")
        let color = attributed?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        #expect(color == field.resolvedThemeScope.palette.placeholderTextColor)
    }

    @Test("ThemedTextView paints its plane, its text role and its outline")
    func textView() {
        let view = ThemedTextView(textRole: .code)
        view.applyTheme(palette)
        #expect(view.backgroundColor == palette.controlBackgroundColor)
        #expect(view.textColor == palette.primaryTextColor)
        #expect(view.font?.pointSize == palette.font(.code).pointSize)
        #expect(view.layer.borderWidth == 1)
        #expect(view.layer.borderColor == palette.uiColor(.outline).cgColor)
    }

    @Test("ThemedTextView with no stroke role draws no border at all")
    func textViewWithoutStroke() {
        let view = ThemedTextView(stroke: nil)
        view.applyTheme(palette)
        #expect(view.layer.borderWidth == 0)
        #expect(view.layer.borderColor == nil)
    }

    @Test("a theme change re-resolves the text view's border, which CGColor cannot do itself")
    func textViewBorderFollowsTheTheme() {
        let view = ThemedTextView()
        view.applyTheme(palette)
        let dark = view.layer.borderColor
        view.applyTheme(lightPalette)
        #expect(view.layer.borderColor == lightPalette.uiColor(.outline).cgColor)
        #expect(view.layer.borderColor != dark)
    }

    @Test("ThemedButton fills with the accent and titles in onAccent")
    func filledButton() {
        let button = ThemedButton(title: "Go")
        button.applyTheme(palette)
        #expect(button.configuration?.baseBackgroundColor == palette.accentColor)
        #expect(button.configuration?.baseForegroundColor == palette.onAccentTextColor)
        // The title is checked as text only. Reading a font attribute off an
        // `AttributedString` resolves through SwiftUI's attribute scope, which
        // drags SwiftUI into a bundle that cannot link it.
        #expect(button.configuration?.attributedTitle.map { String($0.characters) } == "Go")
    }

    @Test("ThemedSecondaryButton is an outlined elevated surface with primary text")
    func secondaryButton() {
        let button = ThemedSecondaryButton(title: "Cancel")
        button.applyTheme(palette)
        #expect(button.configuration?.baseBackgroundColor == palette.elevatedSurfaceColor)
        #expect(button.configuration?.baseForegroundColor == palette.primaryTextColor)
        #expect(button.configuration?.background.strokeColor == palette.outlineColor)
    }

    @Test("ThemedBox fills and strokes from the palette")
    func box() {
        let box = ThemedBox(fill: .elevatedSurface, stroke: .border)
        box.applyTheme(palette)
        #expect(box.backgroundColor == palette.uiColor(.elevatedSurface))
        #expect(box.layer.borderWidth == 1)
        #expect(box.layer.borderColor == palette.uiColor(.border).cgColor)
    }

    @Test("ThemedBox with no stroke role has no border")
    func boxWithoutStroke() {
        let box = ThemedBox(stroke: nil)
        box.applyTheme(palette)
        #expect(box.layer.borderWidth == 0)
    }

    @Test("ThemedSeparatorView is an auto layout hairline on the axis it runs")
    func separator() {
        let horizontal = ThemedSeparatorView(role: .divider)
        horizontal.applyTheme(palette)
        #expect(!horizontal.translatesAutoresizingMaskIntoConstraints)
        #expect(horizontal.backgroundColor == palette.uiColor(.divider))
        #expect(horizontal.constraints.contains { $0.firstAttribute == .height && $0.constant == 1 })

        let vertical = ThemedSeparatorView(axis: .vertical)
        #expect(vertical.constraints.contains { $0.firstAttribute == .width && $0.constant == 1 })
    }

    @Test("ThemedTableView paints its plane, separators and section index")
    func tableView() {
        let table = ThemedTableView()
        table.applyTheme(palette)
        #expect(table.backgroundColor == palette.surfaceColor)
        #expect(table.separatorColor == palette.dividerColor)
        #expect(table.sectionIndexColor == palette.accentColor)
    }

    @Test("ThemedTableView takes the role it was given, so a list can vanish into its screen")
    func tableViewRole() {
        let table = ThemedTableView(role: .windowBackground)
        table.applyTheme(palette)
        #expect(table.backgroundColor == palette.windowBackgroundColor)
    }

    @Test("ThemedTableViewCell selects in the theme's colour, not a fixed system style")
    func tableViewCell() {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: "c")
        cell.applyTheme(palette)
        #expect(cell.backgroundColor == palette.surfaceColor)
        #expect(cell.selectedBackgroundView?.backgroundColor == palette.selectionColor)
        #expect(cell.tintColor == palette.accentColor)
    }

    @Test("a reused cell repaints on a theme change rather than keeping the palette it was dequeued under")
    func tableViewCellFollowsTheTheme() {
        let cell = ThemedTableViewCell(style: .default, reuseIdentifier: "c")
        cell.applyTheme(palette)
        cell.applyTheme(lightPalette)
        #expect(cell.backgroundColor == lightPalette.surfaceColor)
        #expect(cell.palette.theme.id == lightPalette.theme.id)
    }

    @Test("applyThemedTint paints a system button's tint, configuration colour and font")
    func systemButtonTint() {
        let button = UIButton(type: .system)
        button.configuration = .plain()
        button.applyThemedTint(.danger)
        let expected = button.resolvedThemeScope.palette
        #expect(button.tintColor == expected.uiColor(.danger))
        #expect(button.configuration?.baseForegroundColor == expected.uiColor(.danger))
    }
}
