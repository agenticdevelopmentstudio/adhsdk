import Foundation

/// Why an integration operation failed. Every case reads as a sentence a person can act on.
public enum IntegrationError: Error, Equatable, Sendable, LocalizedError {
    case invalidSettings(String)
    case notConfigured
    case unknownAccount(String)
    case unknownMessage(String)
    case unknownLabel(String)
    case revoked
    case gmail(status: Int, message: String)
    case signInCancelled
    case signInFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSettings(let reason): return "Invalid sync settings: \(reason)"
        case .notConfigured: return "Gmail is not configured — import an OAuth client JSON first"
        case .unknownAccount(let account): return "No connected account matches “\(account)”"
        case .unknownMessage(let id): return "No message matches “\(id)”"
        case .unknownLabel(let id): return "No label matches “\(id)”"
        case .revoked: return "Google access was revoked — sign in again"
        case .gmail(let status, let message): return "Gmail returned \(status): \(message)"
        case .signInCancelled: return "Sign-in was cancelled"
        case .signInFailed(let reason): return "Sign-in failed: \(reason)"
        }
    }
}
