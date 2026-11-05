import Foundation

public protocol Tool: Command {
    var builtInIdentifier: String { get }
}
