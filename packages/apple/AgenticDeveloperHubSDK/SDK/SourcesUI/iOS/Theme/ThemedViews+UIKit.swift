import UIKit
import AgenticDeveloperHubSDK

/// The UIKit twin of `ThemedViews.swift` (macOS).
///
/// It exists for the same reason that file does: a view that reaches for
/// `UIColor.label` or `.preferredFont(forTextStyle:)` is painting from the
/// system's vocabulary, not the user's theme, and no amount of theming
/// elsewhere reaches it. These classes are the small set of bases a UIKit
/// screen can be assembled from and come out themed — the counterpart of the
/// AppKit ones, mirrored class-for-class where UIKit has an analogue.
///
/// Two macOS classes are deliberately absent. `ThemedSplitView`/
/// `ThemedSplitViewController` recolor an `NSSplitView` divider, which
/// `UISplitViewController` does not expose; `ThemedHighlightLabel` has no
/// caller on this platform. Add either when something needs it, not before
/// (`yagni`).

/// A view filled with a single semantic role color. Use it for screen and panel
/// backgrounds. Repaints live on theme change.
@MainActor
public final class ThemedBackgroundView: UIView, Themeable {
    public let role: ThemeRole

    /// A specific color to paint instead of the role — how a themeable
    /// *setting* (a color a theme names outright) reaches a view that otherwise
    /// just follows the palette. `nil` puts it back on the role.
    public var colorOverride: UIColor? {
        didSet { applyTheme(resolvedThemeScope.palette) }
    }
    private var observer: ThemePaletteObserver?

    public init(role: ThemeRole = .windowBackground) {
        self.role = role
        super.init(frame: .zero)
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = colorOverride ?? palette.uiColor(role)
    }
}

/// A label whose text color tracks a `ThemeRole` and whose font tracks a
/// `TextRole`, so both color *and* size/weight follow the theme.
@MainActor
public final class ThemedLabel: UILabel, Themeable {
    public var role: ThemeRole { didSet { applyTheme(resolvedThemeScope.palette) } }
    public var textRole: TextRole { didSet { applyTheme(resolvedThemeScope.palette) } }
    private var observer: ThemePaletteObserver?

    public init(string: String = "", role: ThemeRole = .primaryText, textRole: TextRole = .body) {
        self.role = role
        self.textRole = textRole
        super.init(frame: .zero)
        self.text = string
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        textColor = palette.uiColor(role)
        font = palette.font(textRole)
    }
}

/// An editable text field themed from the palette: control-background fill,
/// primary text, body font, and a placeholder in the placeholder-text role.
@MainActor
public final class ThemedTextField: UITextField, Themeable {
    private var observer: ThemePaletteObserver?

    public init(string: String = "") {
        super.init(frame: .zero)
        self.text = string
        self.borderStyle = .roundedRect
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    /// Re-themes so a placeholder set after construction is colored too — the
    /// attributed form is built from `placeholder`, so assigning it alone would
    /// leave the system's grey behind.
    public override var placeholder: String? {
        didSet { applyTheme(resolvedThemeScope.palette) }
    }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.controlBackgroundColor
        textColor = palette.primaryTextColor
        font = palette.font(.body)
        tintColor = palette.cursorColor
        if let placeholder {
            attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: palette.placeholderTextColor,
                .font: palette.font(.body)
            ])
        }
    }
}

/// A text view themed from the palette — the multi-line counterpart of
/// `ThemedTextField`, for the form fields that take a paragraph.
@MainActor
public final class ThemedTextView: UITextView, Themeable {
    /// The role the body text is painted in. `code` fields want the monospaced
    /// style the theme names, not a hard-coded `monospacedSystemFont`.
    public var textRole: TextRole { didSet { applyTheme(resolvedThemeScope.palette) } }

    /// The role of the one-point outline UIKit does not draw for a text view.
    public var strokeRole: ThemeRole? { didSet { applyTheme(resolvedThemeScope.palette) } }
    private var observer: ThemePaletteObserver?

    public init(textRole: TextRole = .body, stroke: ThemeRole? = .outline) {
        self.textRole = textRole
        self.strokeRole = stroke
        super.init(frame: .zero, textContainer: nil)
        self.layer.cornerRadius = 6
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.controlBackgroundColor
        textColor = palette.primaryTextColor
        font = palette.font(textRole)
        tintColor = palette.cursorColor
        // Re-resolved on every apply because `CGColor` is not dynamic: a border
        // converted once keeps the palette it was converted under, which is the
        // exact bug `FormViewController+UIKit` documented against `.separator`.
        layer.borderWidth = strokeRole == nil ? 0 : 1
        layer.borderColor = strokeRole.map { palette.uiColor($0).cgColor }
    }
}

/// A flat button filled with the accent color and an automatically contrasting
/// title — the primary action.
///
/// Built on `UIButton.Configuration` rather than the `setTitleColor` /
/// `contentEdgeInsets` pair the AppKit twin's shape suggests: those are
/// deprecated, and a configuration is the one place UIKit lets a button's fill,
/// title color and insets all be stated at once.
@MainActor
public final class ThemedButton: UIButton, Themeable {
    private var observer: ThemePaletteObserver?

    public init(title: String, target: Any? = nil, action: Selector? = nil) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        self.configuration = config
        if let action {
            addTarget(target, action: action, for: .touchUpInside)
        }
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    /// The `UIAction` form, which is how modern UIKit wires a button up. The
    /// target/action initialiser above stays for the call sites that already
    /// have a selector.
    public convenience init(title: String, primaryAction: UIAction) {
        self.init(title: title)
        addAction(primaryAction, for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        configuration?.baseBackgroundColor = palette.accentColor
        configuration?.baseForegroundColor = palette.onAccentTextColor
        configuration?.attributedTitle = configuration?.title.map {
            AttributedString($0, attributes: AttributeContainer([.font: palette.font(.button)]))
        }
    }
}

/// The secondary action beside a `ThemedButton`: an elevated surface one step
/// above the backdrop, outlined, with primary-emphasis text.
@MainActor
public final class ThemedSecondaryButton: UIButton, Themeable {
    private var observer: ThemePaletteObserver?

    public init(title: String, target: Any? = nil, action: Selector? = nil) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.bordered()
        config.title = title
        config.cornerStyle = .medium
        config.background.strokeWidth = 1
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        self.configuration = config
        if let action {
            addTarget(target, action: action, for: .touchUpInside)
        }
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        configuration?.baseBackgroundColor = palette.elevatedSurfaceColor
        configuration?.baseForegroundColor = palette.primaryTextColor
        configuration?.background.strokeColor = palette.outlineColor
        configuration?.attributedTitle = configuration?.title.map {
            AttributedString($0, attributes: AttributeContainer([.font: palette.font(.button)]))
        }
    }
}

/// A panel: a surface fill with an optional outline stroke and rounded corners.
@MainActor
public final class ThemedBox: UIView, Themeable {
    public let fillRole: ThemeRole
    public let strokeRole: ThemeRole?
    private var observer: ThemePaletteObserver?

    public init(fill: ThemeRole = .surface, stroke: ThemeRole? = .outline, cornerRadius: CGFloat = 8) {
        self.fillRole = fill
        self.strokeRole = stroke
        super.init(frame: .zero)
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = stroke == nil ? 0 : 1
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.uiColor(fillRole)
        if let strokeRole {
            layer.borderColor = palette.uiColor(strokeRole).cgColor
        }
    }
}

/// A one-point hairline. Defaults to the `border` role; pass `.divider` for a
/// fainter line.
@MainActor
public final class ThemedSeparatorView: UIView, Themeable {
    public let role: ThemeRole
    private var observer: ThemePaletteObserver?

    /// - Parameter axis: the direction the hairline *runs*. A horizontal rule is
    ///   one point tall and unconstrained in width; a vertical one is the
    ///   transpose.
    public init(role: ThemeRole = .border, axis: NSLayoutConstraint.Axis = .horizontal) {
        self.role = role
        super.init(frame: .zero)
        // This class constrains itself, so it only makes sense under auto
        // layout — and the autoresizing constraints a caller forgets to turn
        // off would pin it, and everything positioned off its edges, to zero.
        self.translatesAutoresizingMaskIntoConstraints = false
        switch axis {
        case .vertical:
            self.widthAnchor.constraint(equalToConstant: 1).isActive = true
        default:
            self.heightAnchor.constraint(equalToConstant: 1).isActive = true
        }
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.uiColor(role)
    }
}

/// A table whose backdrop, separators and section index track the palette. A
/// plain `UITableView` fills itself with the system background, painting over
/// whatever themed screen hosts it. Defaults to `surface` so a list reads as its
/// own plane; pass `.windowBackground` to make it disappear into the screen.
@MainActor
public final class ThemedTableView: UITableView, Themeable {
    public let role: ThemeRole
    private var observer: ThemePaletteObserver?

    public init(role: ThemeRole = .surface, style: UITableView.Style = .plain) {
        self.role = role
        super.init(frame: .zero, style: style)
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.uiColor(role)
        separatorColor = palette.dividerColor
        sectionIndexColor = palette.accentColor
    }
}

/// A table cell whose fill and selection come from the palette. Subclass it
/// rather than `UITableViewCell` and a reused cell repaints live — without
/// this, a UIKit-pooled cell keeps whatever palette was in force when it was
/// first dequeued.
@MainActor
open class ThemedTableViewCell: UITableViewCell, Themeable {
    public private(set) var palette: SemanticPalette = ThemePaletteObserver.currentPalette
    private var observer: ThemePaletteObserver?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    open func applyTheme(_ palette: SemanticPalette) {
        self.palette = palette
        backgroundColor = palette.surfaceColor
        // `selectedBackgroundView` rather than `selectionStyle`, because the
        // styles are a fixed system set — none of them is the theme's
        // selection color.
        let selected = UIView()
        selected.backgroundColor = palette.selectionColor
        selectedBackgroundView = selected
        tintColor = palette.accentColor
    }
}

@MainActor
public extension UIButton {

    /// Paint a *system* button from the palette — the UIKit counterpart of the
    /// AppKit `apply…ActionTheme(_:)` extensions.
    ///
    /// `ThemedButton`/`ThemedSecondaryButton` are the classes to reach for when
    /// a call site builds its own button. This is for the ones that must stay
    /// `UIButton(type: .system)` because UIKit draws something for them that a
    /// subclass would have to reimplement — a pull-down menu's chevron and
    /// selection behaviour, a plain text action in a form footer
    /// (`native-controls`). On those, the tint *is* the look, so tint and the
    /// theme's button font are the whole paint job.
    ///
    /// - Parameter role: the colour the button reads as. `.accent` for an
    ///   ordinary action, `.danger` for a destructive one.
    func applyThemedTint(_ role: ThemeRole = .accent) {
        observeTheme { button, palette in
            let color = palette.uiColor(role)
            button.tintColor = color
            // A button UIKit gave a configuration (a pull-down, say) takes its
            // colours from that rather than from `tintColor`, so both are set:
            // whichever one the button is actually drawing from is right.
            button.configuration?.baseForegroundColor = color
            button.titleLabel?.font = palette.font(.button)
        }
    }
}
