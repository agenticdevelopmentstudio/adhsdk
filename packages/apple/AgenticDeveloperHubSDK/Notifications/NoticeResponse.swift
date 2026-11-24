import Foundation

/// How the user answered a notice: which action, and the text if it was a
/// reply. Daemon-owned — set when the user acts, never by the poster.
public struct NoticeResponse: Codable, Sendable, Equatable {

    public var actionID: String
    public var text: String?
    // `at` is the wire key and the name the plan fixes.
    // swiftlint:disable:next identifier_name
    public var at: Date

    public init(
        actionID: String, text: String? = nil,
        // swiftlint:disable:next identifier_name
        at: Date = Date()
    ) {
        self.actionID = actionID
        self.text = text
        self.at = at
    }

    private enum CodingKeys: String, CodingKey {
        case actionID = "action"
        // swiftlint:disable:next identifier_name
        case text, at
    }
}
