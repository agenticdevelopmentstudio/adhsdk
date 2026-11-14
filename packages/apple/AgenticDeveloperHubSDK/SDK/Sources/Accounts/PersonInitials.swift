import Foundation

/// The one initials rule every avatar shares (recipe
/// `ui/components/display/avatar`): `AccountUser`, the hub's `HubUser` and
/// `AvatarContent` all ask here, so a face reads the same everywhere.
public enum PersonInitials {
    /// Up to two initials from the name's first two words, else `fallback`'s
    /// first letter (an email, say), else "?" — never empty, so an avatar
    /// always has a face.
    public static func of(name: String, fallback: String) -> String {
        let words = name.split(whereSeparator: { $0.isWhitespace }).prefix(2)
        let letters = words.compactMap { $0.first.map { String($0).uppercased() } }
        if !letters.isEmpty { return letters.joined() }
        return fallback.first.map { String($0).uppercased() } ?? "?"
    }
}
