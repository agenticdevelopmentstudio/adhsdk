import Foundation

// `dx` and `dy` are the stored keys and the vocabulary of the spec.
// swiftlint:disable identifier_name

/// How far the user dragged a toast stack from where its position puts it:
/// points right and up (AppKit's coordinates). Stored per position by
/// `NoticeSettings.toastStackOffsets`, and applied on every screen.
public struct NoticeStackOffset: Codable, Equatable, Sendable {
    public var dx: Double
    public var dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }

    public static let zero = NoticeStackOffset(dx: 0, dy: 0)

    public var isZero: Bool { dx == 0 && dy == 0 }
}

// swiftlint:enable identifier_name
