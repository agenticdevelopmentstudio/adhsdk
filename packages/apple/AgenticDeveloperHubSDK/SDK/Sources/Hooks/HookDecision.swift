import Foundation

public enum HookDecision: Sendable {
    case proceed
    case block(reason: String)
}
