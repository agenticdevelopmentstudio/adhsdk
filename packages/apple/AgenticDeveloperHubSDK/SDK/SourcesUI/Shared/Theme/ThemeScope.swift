import Foundation
import AgenticDeveloperHubSDK

/// A region of the interface with its own type size.
///
/// The theme is one thing and how big a particular window draws it is another.
/// `ThemeManager.textScale` answers the first question for the whole app — a
/// reader who wants everything larger. A scope answers the second: *this*
/// window's chat is set to 130%, and the window beside it is not. The two
/// compose, because they mean different things.
///
/// Scopes exist because a palette is pulled, not pushed:
/// `ThemePaletteObserver` is how every themed view gets one, and nothing hands
/// a palette down a view tree. A scope is the smallest thing that lets a view
/// pull a *different* palette than its neighbour without inverting that.
///
/// `ThemeScope.app` is the one every view resolves to when no closer scope
/// declares itself, so a host that never wanted per-window sizes gets exactly
/// the behaviour it had before scopes existed.
@MainActor
public final class ThemeScope {

    /// Posted when a scope's own scale changes, with the scope as the object.
    /// A theme change still arrives as `ThemeManager.didChangeNotification`;
    /// the two are separate because a theme change reaches every scope and
    /// this reaches one.
    public static let didChangeNotification = Notification.Name(
        "AgenticDeveloperHubSDKUI.ThemeScopeDidChange")

    /// The scope a view resolves to when nothing nearer declares one.
    public static let app = ThemeScope()

    /// This region's multiplier over the app's type size. `1` means "whatever
    /// the app is set to", which is why it is the default and why a scope left
    /// alone is indistinguishable from no scope at all.
    public var textScale: Double = 1 {
        didSet {
            guard textScale != oldValue else { return }
            NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
        }
    }

    public init() {}

    /// Re-announces the scope without changing it, so views built *since* the
    /// last change paint at the scale in force now.
    ///
    /// A themed view's first `applyTheme` happens inside its own initialiser,
    /// which is necessarily before it has a superview to walk — so it resolves
    /// to `.app`, and nothing corrects it until the next notification. For a
    /// view that lives as long as its window that is invisible; for a transcript
    /// that is rebuilt on every message it is the whole feature failing, because
    /// each new bubble arrives at 100% while the composer beside it is at 150%.
    /// Whoever inserted the views is the one who knows the tree is complete, so
    /// this is theirs to call.
    public func refresh() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    /// The palette a view in this scope should paint with: the app's current
    /// palette, scaled by this region's own factor.
    public var palette: SemanticPalette {
        let base = ThemeManager.shared?.currentPalette
            ?? SemanticPalette(theme: BuiltInThemes.solarizedDark)
        return textScale == 1 ? base : base.scaled(by: textScale)
    }
}

/// A view that declares a `ThemeScope` for itself and everything inside it.
///
/// Conform the view that owns a window's content — a chat, an editor, a
/// sidebar — and every themed descendant picks the scope up by walking its
/// superviews. Descendants do not conform; that is the point.
@MainActor
public protocol ThemeScopeProviding: AnyObject {
    var themeScope: ThemeScope { get }
}
