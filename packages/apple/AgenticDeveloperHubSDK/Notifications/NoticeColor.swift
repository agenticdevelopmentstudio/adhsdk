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
        self.red = red.clamped(to: 0...1)
        self.green = green.clamped(to: 0...1)
        self.blue = blue.clamped(to: 0...1)
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
    /// A missing or unknown source reads as `.system`; a field with its own
    /// default reads through `decodeNoticeColorIfPresent(forKey:default:)`.
    public init(from decoder: Decoder) throws {
        self = try Self.decode(from: decoder, fallback: .system)
    }

    /// `fallback` stands in for a missing or unknown source, so a source a
    /// later build adds costs only this color, never the value holding it.
    static func decode(from decoder: Decoder, fallback: Source) throws -> NoticeColor {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        return NoticeColor(
            source: try container.decodeIfPresent(String.self, forKey: .source)
                .flatMap(Source.init(rawValue:)) ?? fallback,
            red: try container.decodeIfPresent(Double.self, forKey: .red) ?? 0,
            green: try container.decodeIfPresent(Double.self, forKey: .green) ?? 0,
            blue: try container.decodeIfPresent(Double.self, forKey: .blue) ?? 0)
    }
}

extension KeyedDecodingContainer {
    /// The color at `key`, or `fallback` when the key is absent or null. An
    /// unknown stored source reads as `fallback`'s source: the field's default.
    func decodeNoticeColorIfPresent(forKey key: Key, default fallback: NoticeColor) throws -> NoticeColor {
        guard contains(key), try !decodeNil(forKey: key) else { return fallback }
        return try NoticeColor.decode(from: superDecoder(forKey: key), fallback: fallback.source)
    }
}
