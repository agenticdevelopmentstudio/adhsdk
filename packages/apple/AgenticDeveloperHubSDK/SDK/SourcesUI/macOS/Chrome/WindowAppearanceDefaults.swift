import Foundation

/// The switches behind a window's gear, and their persistence.
///
/// A plain `UserDefaults` shim rather than anything grander because that is
/// the whole of the requirement: four values, one window, no sync, no
/// migration. It is a `struct` of computed properties so there is no cached
/// copy to fall out of step with the defaults — every read is the current
/// value, which is what makes the gear correct after a relaunch without a load
/// step to remember.
///
/// The `namespace` is the host app's, so two apps built on this toolkit (or
/// two windows in one app) never write over each other, and neither collides
/// with a key the toolkit itself might add to the same suite.
public struct WindowAppearanceDefaults: Sendable {

    /// Deliberately the ranges Stenographer uses: a reader who has both apps
    /// open should find the same slider means the same thing in each.
    public static let textScaleRange: ClosedRange<Double> = 0.85...1.75

    /// Transparency as a percentage, read the way the word does: `0` is
    /// nothing taken away, `100` is everything. It used to be an *alpha* in
    /// `0.3...1.0`, where the slider ran backwards — dragging right made the
    /// window more solid under a label reading "70% transparent".
    public static let transparencyRange: ClosedRange<Double> = 0...100

    private let namespace: String

    /// `UserDefaults` is thread-safe but not yet marked `Sendable`, and this
    /// struct crosses isolation boundaries as a plain value describing *which*
    /// keys a window owns. Unchecked here rather than dropping `Sendable`,
    /// which would push the problem onto every host.
    private nonisolated(unsafe) let defaults: UserDefaults

    public init(namespace: String, defaults: UserDefaults = .standard) {
        self.namespace = namespace
        self.defaults = defaults
    }

    private func key(_ name: String) -> String { "\(namespace).\(name)" }

    /// Multiplier over the theme's own type size. `1` is the theme as its
    /// designer scaled it.
    public var textScale: Double {
        get { value(for: key("textScale"), default: 1, in: Self.textScaleRange) }
        nonmutating set { defaults.set(newValue, forKey: key("textScale")) }
    }

    /// How much of the window's surface to take away, `0`–`100`. `0` is the
    /// theme's own alpha and nothing further — `old-school-terminal` is
    /// already `rgba(5, 8, 5, 0.8)`, so this thins what the theme chose rather
    /// than introducing translucency.
    ///
    /// Written under a new key because the old one held the opposite quantity
    /// on a different scale, and a reader who had already set a window to 70%
    /// transparent should not find it at 0.3% after an update. The old key is
    /// read once, converted, and never written again.
    public var transparency: Double {
        get {
            if defaults.object(forKey: key("transparencyPercent")) != nil {
                return value(for: key("transparencyPercent"), default: 0, in: Self.transparencyRange)
            }
            guard defaults.object(forKey: key("transparency")) != nil else { return 0 }
            let legacyAlpha = Swift.max(0, Swift.min(1, defaults.double(forKey: key("transparency"))))
            return (1 - legacyAlpha) * 100
        }
        nonmutating set { defaults.set(newValue, forKey: key("transparencyPercent")) }
    }

    /// Whether the window draws its animated backdrop. On by default: a host
    /// that hands a window a backdrop meant it to be seen, and this is the
    /// switch for the reader who finds it distracting.
    public var showsBackdrop: Bool {
        get { !defaults.bool(forKey: key("backdrop.off")) }
        nonmutating set { defaults.set(!newValue, forKey: key("backdrop.off")) }
    }

    /// Whether the window floats above other apps' windows.
    public var isFloating: Bool {
        get { defaults.bool(forKey: key("floating")) }
        nonmutating set { defaults.set(newValue, forKey: key("floating")) }
    }

    /// Whether the composer's block caret blinks. Defaults to on, which is
    /// what web does unconditionally — hence the inverted key:
    /// `bool(forKey:)` answers `false` for a key nobody has written, and the
    /// default has to be the other one.
    public var blinksCaret: Bool {
        get { !defaults.bool(forKey: key("blinkCaret.off")) }
        nonmutating set { defaults.set(!newValue, forKey: key("blinkCaret.off")) }
    }

    /// Forgets the three window settings — text size, transparency, and
    /// whether the window floats — so each one reads as its own default again.
    ///
    /// Removing the keys rather than writing the default values back: every
    /// default is stated once, in the getter above it, and a reset that
    /// assigned `1` and `0` here would be a second copy of both that nothing
    /// keeps in step. The legacy alpha key goes with the new one, or the
    /// conversion above would resurrect the value the reset just cleared.
    ///
    /// `blinksCaret` and `showsBackdrop` are deliberately left alone: they are
    /// reading preferences rather than the window's shape, and a reset that
    /// quietly turned a backdrop back on would be doing something nobody asked
    /// of it.
    public func resetWindowAppearance() {
        defaults.removeObject(forKey: key("textScale"))
        defaults.removeObject(forKey: key("transparencyPercent"))
        defaults.removeObject(forKey: key("transparency"))
        defaults.removeObject(forKey: key("floating"))
    }

    /// A stored double, or `fallback` when the key is absent — `UserDefaults`
    /// answers `0` for both, which as a text scale would lay the window out at
    /// no height. Clamped as well, so a hand-edited plist cannot do the same.
    private func value(for key: String, default fallback: Double, in range: ClosedRange<Double>) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, defaults.double(forKey: key)))
    }
}
