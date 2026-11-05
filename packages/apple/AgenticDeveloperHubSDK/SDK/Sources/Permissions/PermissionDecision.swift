import Foundation

public enum PermissionDecision: Sendable, Hashable {
    case allowOnce
    case allowAlways
    case denyOnce
    case denyAlways
}
