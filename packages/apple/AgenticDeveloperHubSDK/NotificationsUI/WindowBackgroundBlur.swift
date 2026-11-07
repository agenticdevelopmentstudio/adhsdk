import AppKit

/// Blurs what is behind a window by a real radius.
///
/// AppKit's only public behind-window blur is `NSVisualEffectView`, and it is
/// all or nothing: the window server drops the blur entirely as soon as the
/// view's or the window's `alphaValue` falls below 1. So an amount needs the
/// window server's own per-window radius, `CGSSetWindowBackgroundBlurRadius`,
/// the call iTerm2's blur slider is built on. It is private, so it is looked
/// up at run time; where it is missing, `apply` answers false and the caller
/// falls back to the all-or-nothing view.
@MainActor
struct WindowBackgroundBlur {

    /// The radius, in points, that a blur of 1 maps to.
    static let maximumRadius = 40

    /// Sets `radius` on `window`; false when the radius cannot be set.
    let apply: @MainActor (_ window: NSWindow, _ radius: Int) -> Bool

    /// The radius for a 0...1 amount.
    static func radius(for amount: Double) -> Int {
        Int((min(max(amount, 0), 1) * Double(maximumRadius)).rounded())
    }

    static let live = WindowBackgroundBlur { window, radius in
        guard let functions = WindowServerBlurFunctions.shared else { return false }
        let status = functions.setRadius(functions.mainConnection(), Int32(window.windowNumber), Int32(radius))
        return status == 0
    }

    /// For tests and hosts where the private call must not be used.
    static let unavailable = WindowBackgroundBlur { _, _ in false }
}

/// The two window-server functions, resolved once.
private struct WindowServerBlurFunctions: Sendable {
    typealias MainConnection = @convention(c) () -> Int32
    typealias SetBlurRadius = @convention(c) (Int32, Int32, Int32) -> Int32

    let mainConnection: MainConnection
    let setRadius: SetBlurRadius

    static let shared: WindowServerBlurFunctions? = {
        let handle = dlopen(nil, RTLD_NOW)
        guard let connection = dlsym(handle, "CGSMainConnectionID"),
              let setRadius = dlsym(handle, "CGSSetWindowBackgroundBlurRadius")
        else { return nil }
        return WindowServerBlurFunctions(
            mainConnection: unsafeBitCast(connection, to: MainConnection.self),
            setRadius: unsafeBitCast(setRadius, to: SetBlurRadius.self))
    }()
}
