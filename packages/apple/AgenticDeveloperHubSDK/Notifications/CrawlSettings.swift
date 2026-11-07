import Foundation

/// How the crawl looks and moves. Global, not per item: there is one crawl.
public struct CrawlSettings: Codable, Sendable, Equatable {

    public enum Edge: String, Codable, Sendable, CaseIterable {
        case top, bottom
    }

    public static let speedRange: ClosedRange<Double> = 20...400
    public static let textSizeRange: ClosedRange<Double> = 10...28
    public static let itemOpacityRange: ClosedRange<Double> = 0.2...1

    public var edge: Edge
    public var showsBackground: Bool
    public var background: NoticeColor
    /// 0...1.
    public var backgroundOpacity: Double
    /// Points per second, `speedRange`.
    public var speed: Double
    public var leftToRight: Bool
    /// Points, `textSizeRange`.
    public var textSize: Double
    /// `itemOpacityRange`.
    public var itemOpacity: Double

    public init(
        edge: Edge = .bottom,
        showsBackground: Bool = true,
        background: NoticeColor = .theme,
        backgroundOpacity: Double = 0.9,
        speed: Double = 80,
        leftToRight: Bool = false,
        textSize: Double = 13,
        itemOpacity: Double = 1.0
    ) {
        self.edge = edge
        self.showsBackground = showsBackground
        self.background = background
        self.backgroundOpacity = backgroundOpacity.clamped(to: 0...1)
        self.speed = speed.clamped(to: Self.speedRange)
        self.leftToRight = leftToRight
        self.textSize = textSize.clamped(to: Self.textSizeRange)
        self.itemOpacity = itemOpacity.clamped(to: Self.itemOpacityRange)
    }

    private enum CodingKeys: String, CodingKey {
        case edge, showsBackground, background, backgroundOpacity, speed, leftToRight, textSize, itemOpacity
    }

    /// Every key is optional, falling back to the default.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = CrawlSettings()
        self.init(
            edge: try container.decodeIfPresent(String.self, forKey: .edge).flatMap(Edge.init(rawValue:))
                ?? base.edge,
            showsBackground: try container.decodeIfPresent(Bool.self, forKey: .showsBackground)
                ?? base.showsBackground,
            background: try container.decodeNoticeColorIfPresent(forKey: .background, default: base.background),
            backgroundOpacity: try container.decodeIfPresent(Double.self, forKey: .backgroundOpacity)
                ?? base.backgroundOpacity,
            speed: try container.decodeIfPresent(Double.self, forKey: .speed) ?? base.speed,
            leftToRight: try container.decodeIfPresent(Bool.self, forKey: .leftToRight) ?? base.leftToRight,
            textSize: try container.decodeIfPresent(Double.self, forKey: .textSize) ?? base.textSize,
            itemOpacity: try container.decodeIfPresent(Double.self, forKey: .itemOpacity) ?? base.itemOpacity)
    }
}
