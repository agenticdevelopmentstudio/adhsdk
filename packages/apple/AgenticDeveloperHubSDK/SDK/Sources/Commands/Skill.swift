import Foundation

public protocol Skill: Command {
    var skillIdentifier: String { get }
}
