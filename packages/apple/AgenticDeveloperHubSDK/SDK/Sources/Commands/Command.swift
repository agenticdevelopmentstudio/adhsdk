import Foundation

public protocol Command: Sendable {
    var name: String { get }
    var description: String { get }
    var allowedInvokers: Set<CommandInvoker> { get }
    var permission: (any Permission)? { get }
    var argumentSchema: String { get }
}
