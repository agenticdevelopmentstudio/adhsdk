import Foundation

public protocol CommandResult: Sendable {
    var invocationID: String { get }
    var ok: Bool { get }
    var resultJSON: String? { get }
    var errorMessage: String? { get }
    var completedAt: Date { get }
}
