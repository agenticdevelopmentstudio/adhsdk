import Foundation

/// One presentation of a notice: one item of a `NoticeStyleSet`.
public struct NoticeProfile: Codable, Sendable, Equatable {

    /// An empty set, not a style, means "don't show".
    public enum Style: String, Codable, Sendable, CaseIterable {
        case toast, crawl, fullScreen, alert, system
    }

    /// There is no top-right: it is where macOS puts its own banners. A
    /// stored `topRight` reads as `bottomRight`.
    public enum Position: String, Codable, Sendable, CaseIterable {
        case topLeft, topCenter, center, bottomLeft, bottomCenter, bottomRight
    }

    /// Which screens notices present on. A global setting,
    /// `NoticeRoutingRules.screens`, not a per-item one.
    public enum ScreenSelection: String, Codable, Sendable, CaseIterable {
        case main, all
    }

    public enum Layer: String, Codable, Sendable, CaseIterable {
        /// Above other windows.
        case floating
        /// Other windows can cover it.
        case normal
    }

    /// How a full-screen item draws its backdrop: a blur, then a tint over it.
    public struct FullScreenAppearance: Codable, Sendable, Equatable {
        /// 0...1: how much of the blurred view shows. macOS has no blur radius.
        public var blur: Double
        public var color: NoticeColor
        /// 0...1: the tint's opacity. 0.55 black is the classic dim.
        public var opacity: Double

        public init(blur: Double = 0.6, color: NoticeColor = .system, opacity: Double = 0.55) {
            self.blur = blur.clamped(to: 0...1)
            self.color = color
            self.opacity = opacity.clamped(to: 0...1)
        }

        private enum CodingKeys: String, CodingKey {
            case blur, color, opacity
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let base = FullScreenAppearance()
            self.init(
                blur: try container.decodeIfPresent(Double.self, forKey: .blur) ?? base.blur,
                color: try container.decodeNoticeColorIfPresent(forKey: .color, default: base.color),
                opacity: try container.decodeIfPresent(Double.self, forKey: .opacity) ?? base.opacity)
        }
    }

    public var style: Style
    public var position: Position
    public var layer: Layer
    /// Always stored; only full-screen items read it.
    public var fullScreen: FullScreenAppearance
    /// Seconds before the presentation goes away; nil means never.
    ///
    /// A *runtime* field, never encoded: dismiss timing belongs to the
    /// owning `NoticeStyleSet`, and the presentation center stamps the set's
    /// value into every item it presents, so presenters read it here.
    public var autoDismiss: TimeInterval?

    public init(
        style: Style,
        position: Position? = nil,
        layer: Layer = .floating,
        fullScreen: FullScreenAppearance = .init(),
        autoDismiss: TimeInterval? = nil
    ) {
        self.style = style
        self.position = position ?? Self.defaultPosition(for: style)
        self.layer = layer
        self.fullScreen = fullScreen
        self.autoDismiss = autoDismiss
    }

    /// Where an item of `style` goes when nothing says otherwise.
    public static func defaultPosition(for style: Style) -> Position {
        switch style {
        case .toast, .system: .bottomRight
        case .crawl: .bottomCenter
        case .alert, .fullScreen: .center
        }
    }

    /// A stored position, read tolerantly: the retired `topRight` becomes
    /// `bottomRight`, and anything unknown (or missing) the style's default.
    static func position(decoding raw: String?, for style: Style) -> Position {
        if raw == "topRight" { return .bottomRight }
        return raw.flatMap(Position.init(rawValue:)) ?? defaultPosition(for: style)
    }

    // MARK: Coding

    private enum CodingKeys: String, CodingKey {
        case style, position, layer, fullScreen
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let style = try container.decode(Style.self, forKey: .style)
        self.init(
            style: style,
            position: Self.position(
                decoding: try container.decodeIfPresent(String.self, forKey: .position), for: style),
            layer: try container.decodeIfPresent(String.self, forKey: .layer).flatMap(Layer.init(rawValue:))
                ?? .floating,
            fullScreen: try container.decodeIfPresent(FullScreenAppearance.self, forKey: .fullScreen) ?? .init())
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(style, forKey: .style)
        try container.encode(position, forKey: .position)
        try container.encode(layer, forKey: .layer)
        try container.encode(fullScreen, forKey: .fullScreen)
    }
}
