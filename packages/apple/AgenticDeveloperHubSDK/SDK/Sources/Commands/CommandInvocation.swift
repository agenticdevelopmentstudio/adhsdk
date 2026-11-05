import Foundation

public protocol CommandInvocation: Sendable {
    var id: String { get }
    var commandName: String { get }
    var invokerID: String { get }
    var invokerKind: CommandInvoker { get }
    var argumentsJSON: String { get }
    var requestedAt: Date { get }
}
