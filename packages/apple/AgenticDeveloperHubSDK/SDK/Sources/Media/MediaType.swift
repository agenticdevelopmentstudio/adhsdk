import Foundation

public protocol MediaType: Sendable, Hashable {
    var identifier: String { get }
}
