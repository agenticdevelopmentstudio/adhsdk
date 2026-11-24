import Foundation

/// What an avatar shows: whose face, a stable identity for its colour (an
/// email, say), and the picture to try, if any. Foundation only, so a view
/// model can build one without a UI framework; the macOS `AvatarView` draws it.
public struct AvatarContent: Sendable, Equatable {
    public let name: String
    public let seed: String
    public let imageURL: URL?

    public init(name: String, seed: String, imageURL: URL?) {
        self.name = name
        self.seed = seed
        self.imageURL = imageURL
    }

    /// `PersonInitials` of the name, with the seed as the fallback.
    public var initials: String { PersonInitials.of(name: name, fallback: seed) }
}

extension AvatarContent {
    /// An account user's avatar: the email seeds the colour and stands in for
    /// a blank name's initials.
    public init(user: AccountUser) {
        self.init(name: user.name, seed: user.email, imageURL: user.avatarURL)
    }
}
