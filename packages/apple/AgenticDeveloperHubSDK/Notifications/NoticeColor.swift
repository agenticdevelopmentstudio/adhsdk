import Foundation

/// A color a notice setting picked: the system's, the theme's, or a custom
/// RGB value. This module sees neither AppKit nor the theme model, so it
/// records only which color the user chose; the UI resolves it per use
/// (system is a per-use fallback, theme a palette role, custom the RGB).
///
/// Opacity is never part of the color. It is always its own setting.
public struct NoticeColor: Codable, Sendable, Equatable {

    public enum Source: String, Codable, Sendable, CaseIterable {
        case system, theme, custom
    }

    public var source: Source
    /// 0...1, read when `source == .custom`.
    public var red: Double
    /// 0...1, read when `source == .custom`.
    public var green: Double
    /// 0...1, read when `source == .custom`.
    public var blue: Double

    public init(source: Source, red: Double = 0, green: Double = 0, blue: Double = 0) {
        self.source = source
        self.red = Self.unit(red)
        self.green = Self.unit(green)
        self.blue = Self.unit(blue)
    }

    public static let system = NoticeColor(source: .system)
    public static let theme = NoticeColor(source: .theme)

    public static func custom(red: Double, green: Double, blue: Double) -> NoticeColor {
        NoticeColor(source: .custom, red: red, green: green, blue: blue)
    }

    private enum CodingKeys: String, CodingKey {
        case source, red, green, blue
    }

    /// Missing components read as 0, so a stored `{"source":"theme"}` loads.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            source: try container.decode(Source.self, forKey: .source),
            red: try container.decodeIfPresent(Double.self, forKey: .red) ?? 0,
            green: try container.decodeIfPresent(Double.self, forKey: .green) ?? 0,
            blue: try container.decodeIfPresent(Double.self, forKey: .blue) ?? 0)
    }

    private static func unit(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
