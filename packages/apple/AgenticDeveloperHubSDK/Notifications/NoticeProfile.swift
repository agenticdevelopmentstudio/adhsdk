import Foundation

/// How one class of notice is presented.
public struct NoticeProfile: Codable, Sendable, Equatable {

    public enum Style: String, Codable, Sendable, CaseIterable {
        case toast, crawl, fullScreen, alert, system, none
    }

    public enum Position: String, Codable, Sendable, CaseIterable {
        case topLeft, topCenter, topRight, center, bottomLeft, bottomCenter, bottomRight
    }

    public enum ScreenSelection: String, Codable, Sendable, CaseIterable {
        case main, cursor, all
    }

    public enum Layer: String, Codable, Sendable, CaseIterable {
        /// Above other windows.
        case floating
        /// Other windows can cover it.
        case normal
    }

    public var style: Style
    public var position: Position
    public var screens: ScreenSelection
    public var layer: Layer
    /// Seconds before the presentation goes away; nil means never.
    public var autoDismiss: TimeInterval?
    /// Also post to the system's own notification center.
    public var forwardToSystem: Bool

    public init(
        style: Style,
        position: Position,
        screens: ScreenSelection,
        layer: Layer,
        autoDismiss: TimeInterval?,
        forwardToSystem: Bool
    ) {
        self.style = style
        self.position = position
        self.screens = screens
        self.layer = layer
        self.autoDismiss = autoDismiss
        self.forwardToSystem = forwardToSystem
    }
}
