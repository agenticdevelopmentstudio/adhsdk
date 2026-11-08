import Foundation

/// Who made an App.
public struct DesktopAppAttribution: Codable, Sendable, Equatable {
    public let author: String
    public let copyright: String
    public let url: URL?

    public init(author: String, copyright: String, url: URL? = nil) {
        self.author = author
        self.copyright = copyright
        self.url = url
    }
}
