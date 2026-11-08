import Foundation

/// How an App's icon is drawn on the Desktop.
public enum DesktopAppIcon: Codable, Sendable, Equatable {
    /// An SF Symbol with a `#RRGGBB` tint.
    case symbol(name: String, tint: String)
    /// A named image resource.
    case resource(name: String)
}
