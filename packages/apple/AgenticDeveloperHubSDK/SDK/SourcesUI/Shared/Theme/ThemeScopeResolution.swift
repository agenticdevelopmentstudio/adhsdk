#if os(macOS)
import AppKit
public typealias PlatformView = NSView
#else
import UIKit
public typealias PlatformView = UIView
#endif

/// Every view can name a theme scope: the nearest one declared above it, or the
/// app's.
///
/// The walk goes *up* rather than the scope being handed *down* because that is
/// the direction that survives the view lifecycle. A themed view is built
/// before it is added to anything — its `ThemePaletteObserver` exists a beat
/// before the superview chain does — so a scope pushed down at construction
/// would reach half the tree. Walking up on each apply always reads the tree as
/// it is now.
extension PlatformView: ThemeScopeResolving {
    public var resolvedThemeScope: ThemeScope {
        var view: PlatformView? = self
        while let current = view {
            if let provider = current as? any ThemeScopeProviding { return provider.themeScope }
            view = current.superview
        }
        return .app
    }
}
