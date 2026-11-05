import Combine
import Foundation
import ObjectiveC
import AgenticDeveloperHubSDK

/// A view (or other object) that recolors itself from a `SemanticPalette`.
@MainActor
public protocol Themeable: AnyObject {
    func applyTheme(_ palette: SemanticPalette)
}

/// Something that can say which `ThemeScope` it belongs to. Views conform by
/// walking their superviews (see the `NSView`/`UIView` extension), so a host
/// only has to declare a scope at the top of a window's content and everything
/// inside finds it.
@MainActor
public protocol ThemeScopeResolving: AnyObject {
    var resolvedThemeScope: ThemeScope { get }
}

/// Watches the active theme and invokes a closure with the current
/// `SemanticPalette` — immediately on creation, then on every theme change.
/// Mirrors `UserSettingObserver`: own one per themeable control and the control
/// repaints live. Falls back to Solarized Dark when no `ThemeManager` exists
/// (e.g. previews / unit tests without an app host).
///
/// Pass the view being painted as `host` and the palette is resolved through
/// that view's `ThemeScope` — which is how one window can run its type larger
/// than the window beside it. Omit it and the observer reads the app-wide
/// scope, which is what every call site did before scopes existed.
@MainActor
public final class ThemePaletteObserver {

    private var cancellables: Set<AnyCancellable> = []

    /// Whose scope to paint in. Weak because the host owns the observer, not
    /// the other way round; a host on its way out simply falls back to the app
    /// scope for whatever final apply is in flight.
    private weak var host: (any ThemeScopeResolving)?

    /// The palette currently in effect app-wide (or a sensible default). This
    /// is the *unscoped* answer — a view that may live in a scope should ask
    /// its own `resolvedThemeScope.palette` instead.
    public static var currentPalette: SemanticPalette {
        ThemeManager.shared?.currentPalette ?? SemanticPalette(theme: BuiltInThemes.solarizedDark)
    }

    public init(host: (any ThemeScopeResolving)? = nil, _ apply: @escaping (SemanticPalette) -> Void) {
        self.host = host
        apply(self.palette)

        // No `receive(on:)` on either of these: the apply runs inside the post.
        //
        // It was `RunLoop.main`, and Combine's RunLoop scheduler enqueues only
        // in `RunLoop.Mode.default` while AppKit tracks a mouse drag in
        // `.eventTracking` — so with a continuous slider, which is exactly what
        // the Text Size control is, every change was held back and arrived in
        // one lump on mouse-up. `DispatchQueue.main` would fix that, but it
        // still defers, and a deferred repaint cannot be asserted on without
        // spinning a nested run loop — which re-enters the main actor and lets
        // whatever else is running swap `ThemeManager.shared` out mid-test.
        //
        // Both notifications are posted from `@MainActor` code — `ThemeManager`
        // and `ThemeScope` are both main-actor types — so the sink already runs
        // on the main thread. `assumeIsolated` says that, instead of scheduling
        // a hop back to where it already is. If either name is ever posted from
        // a background thread it traps here, which is the right place to find
        // out.
        //
        // A theme change reaches every scope, so it always re-applies.
        NotificationCenter.default
            .publisher(for: ThemeManager.didChangeNotification)
            .map { _ in () }                       // drop the (non-Sendable) Notification
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    apply(self.palette)
                }
            }
            .store(in: &cancellables)

        // A scope change reaches one scope, so it is filtered to ours. The
        // identity is extracted in the `compactMap` because `Notification`
        // itself cannot cross an isolation boundary; `ObjectIdentifier` can.
        NotificationCenter.default
            .publisher(for: ThemeScope.didChangeNotification)
            .compactMap { ($0.object as? ThemeScope).map(ObjectIdentifier.init) }
            .sink { [weak self] changed in
                MainActor.assumeIsolated {
                    guard let self, ObjectIdentifier(self.resolvedScope) == changed else { return }
                    apply(self.palette)
                }
            }
            .store(in: &cancellables)
    }

    /// The scope this observer paints in, re-resolved on every change rather
    /// than captured once: a view is routinely built before it is added to the
    /// window that declares the scope, and the walk only works once it is in
    /// place.
    private var resolvedScope: ThemeScope { host?.resolvedThemeScope ?? .app }

    private var palette: SemanticPalette { resolvedScope.palette }
}

/// The address of this byte is the associated-object key under which a view
/// keeps the observers attached by `observeTheme(_:)`. Never read or written —
/// only its address is used — so the unchecked annotation is sound.
private nonisolated(unsafe) var themeObserversKey: UInt8 = 0

/// Gives every view the `observeTheme` helper below.
///
/// It is a protocol extension rather than a plain `extension PlatformView`
/// because the closure takes `Self`: inside a class extension `Self` is only
/// the covariant return position, so `[weak self]` there is typed
/// `PlatformView?` and will not satisfy the parameter. In a protocol extension
/// `Self` is the concrete conforming class, and the capture types correctly.
@MainActor
public protocol ThemeObserving: NSObject {}

extension PlatformView: ThemeObserving {}

extension ThemeObserving where Self: PlatformView {

    /// Repaint this view on every theme change, for views that have no themed
    /// subclass — a wrapping label, a text view, a stock control whose one
    /// themed property is a tint.
    ///
    /// The view owns the observer (stored as an associated object), so it lives
    /// exactly as long as the view does. The closure is handed the view rather
    /// than capturing it, which is what keeps this from building the
    /// view → observer → closure → view cycle the obvious version would.
    ///
    /// The view is also the observer's host, so the palette it is handed is the
    /// one for the view's own `ThemeScope` rather than the app's — a view
    /// themed this way sizes with the window it is in, like every `Themed*`
    /// class does.
    ///
    /// Prefer a `Themed*` class where one fits; reach for this when none does.
    public func observeTheme(_ apply: @escaping @MainActor (Self, SemanticPalette) -> Void) {
        let observer = ThemePaletteObserver(host: self) { [weak self] palette in
            guard let self else { return }
            apply(self, palette)
        }
        var observers = objc_getAssociatedObject(self, &themeObserversKey) as? [ThemePaletteObserver] ?? []
        observers.append(observer)
        objc_setAssociatedObject(self, &themeObserversKey, observers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
