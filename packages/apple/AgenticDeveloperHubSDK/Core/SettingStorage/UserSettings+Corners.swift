import Foundation
import CoreGraphics

extension UserSettings {
    /// Whether the app's panes and tab cards draw rounded corners instead of
    /// square ones. Set from Appearance > General.
    static public var preferRoundedCorners = UserSetting<Bool>("prefer_rounded_corners", default: false)
}

/// The one place the corner radii live, so every surface rounds by the same
/// amount and the setting is read one way.
@MainActor
public enum CornerStyle {
    /// A pane's outer radius; its fill, held `borderInset` inside, rounds less.
    public static let paneRadius: CGFloat = 10
    /// A tab card's two outer corners.
    public static let tabRadius: CGFloat = 8

    public static var prefersRounded: Bool { UserSettings.preferRoundedCorners.currentValue }

    /// `radius` while rounded corners are preferred, else zero.
    public static func radius(_ radius: CGFloat) -> CGFloat { prefersRounded ? radius : 0 }
}
