import CoreText
import Foundation

/// Registers the font faces this toolkit ships with, so a theme that names one
/// resolves to the face the theme meant rather than silently falling back.
///
/// Web themes name their faces and then *fetch* them — `old-school-terminal`
/// imports VT323 from Google Fonts, and the whole look of the theme is that
/// face. A native app has no such fetch: `NSFont(name: "VT323", …)` returns nil
/// on a machine where nobody happens to have installed it, and the font bridge
/// falls through to the system monospaced face without complaint. The theme is
/// then "ported" in every respect except the one a person actually sees.
///
/// So the faces those themes depend on travel with the framework, exactly as
/// the web package vendors its own (`packages/web/packages/themes/src/fonts/`),
/// and are registered into the process on first use. `.process` scope, not
/// `.persistent`: this makes the face available to the app that linked the
/// toolkit, and installs nothing on the user's machine.
public enum ToolkitFonts {

    /// Anchors `Bundle(for:)` on the framework this file is compiled into.
    /// `Bundle.module` is a SwiftPM resource-accessor and this package is built
    /// by XcodeGen, so the class-based lookup is the portable one.
    private final class BundleToken {}

    /// The bundled faces, by file name. Every one of them is a face some ported
    /// theme names in its `--pc-font` / `--font-*` stack.
    private static let bundledFaces = ["VT323-Regular"]

    /// Registration runs once, on whichever thread asks first — `static let`
    /// initialisation is atomic, which is the whole reason the work lives in
    /// one.
    private static let registration: Void = {
        let bundle = Bundle(for: BundleToken.self)
        for name in bundledFaces {
            guard let url = bundle.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? bundle.url(forResource: name, withExtension: "ttf") else { continue }
            // Errors are deliberately dropped: a face that fails to register
            // (already registered by the host app, say) leaves the bridge's
            // existing system-font fallback in place, which is a worse-looking
            // theme and not a broken one. Nothing here is worth a crash.
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    /// Makes the bundled faces resolvable by name. Idempotent and cheap after
    /// the first call; the font bridges call it before every lookup.
    public static func registerBundledFonts() {
        _ = registration
    }
}
