import Foundation

/// What a signed-in native app holds: the bearer credential the client sends
/// on every request plus, for password/MFA/passkey/OAuth sign-ins, the
/// single-use refresh token `POST /auth/refresh` rotates. API-token sessions
/// have no refresh token (`refreshToken == nil`) and are never refreshed.
public struct HubSession: Sendable, Equatable, Codable {
    public var credentials: Credentials
    public var refreshToken: String?

    public init(credentials: Credentials, refreshToken: String? = nil) {
        self.credentials = credentials
        self.refreshToken = refreshToken
    }
}

/// Redacted by default, for the same reason as ``Credentials``: neither the
/// access token nor the (single-use, long-lived) refresh token may ever reach
/// a log. Whether a refresh token is present is the part that matters when
/// diagnosing a session, so that much is reported.
extension HubSession: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        "Session(kind: \(credentials.kind.rawValue), token: <redacted>, refreshToken: \(refreshToken == nil ? "none" : "<redacted>"))"
    }

    public var debugDescription: String { description }
}
