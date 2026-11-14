import AgenticDeveloperHubAuth
import AgenticDeveloperHubSDK
import Foundation

/// The app-facing user. Deliberately narrower than the generated schema:
/// the shell needs an identity, a label and an avatar — nothing else.
public struct HubUser: Sendable, Equatable, Codable {
    public let id: String
    public let email: String
    public let name: String
    public let slug: String?
    public let avatarURL: URL?

    public init(id: String, email: String, name: String, slug: String?, avatarURL: URL?) {
        self.id = id
        self.email = email
        self.name = name
        self.slug = slug
        self.avatarURL = avatarURL
    }

    public init(_ user: Components.Schemas.User) {
        let trimmed = user.avatarUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(
            id: user.id,
            email: user.email,
            name: user.name,
            slug: user.slug,
            avatarURL: trimmed.isEmpty ? nil : URL(string: trimmed)
        )
    }

    /// Spec §5.5: the name, or the email when the name is blank.
    public var displayLabel: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? email : trimmed
    }

    /// Spec §5.5 avatar fallback: `PersonInitials` of the name, with the
    /// email as the fallback.
    public var initials: String { PersonInitials.of(name: name, fallback: email) }
}
