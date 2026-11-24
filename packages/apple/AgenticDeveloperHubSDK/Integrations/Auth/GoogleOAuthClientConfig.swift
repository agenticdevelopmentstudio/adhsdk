import Foundation

/// The Google "Desktop app" OAuth client the user imports (the downloaded client JSON).
public struct GoogleOAuthClientConfig: Sendable, Equatable {
    public let clientId: String
    public let clientSecret: String

    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    /// Accepts `{"installed": {"client_id": …, "client_secret": …}}`. Web clients and files with
    /// missing keys throw `IntegrationError.invalidSettings`.
    public static func parse(json: Data) throws -> GoogleOAuthClientConfig {
        guard let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            throw IntegrationError.invalidSettings("the OAuth client file is not valid JSON")
        }
        if root["installed"] == nil, root["web"] != nil {
            throw IntegrationError.invalidSettings(
                "this is a Web application client; create a Desktop app OAuth client instead")
        }
        guard let installed = root["installed"] as? [String: Any],
              let clientId = installed["client_id"] as? String, !clientId.isEmpty,
              let clientSecret = installed["client_secret"] as? String, !clientSecret.isEmpty
        else {
            throw IntegrationError.invalidSettings(
                "the OAuth client file has no installed.client_id and installed.client_secret")
        }
        return GoogleOAuthClientConfig(clientId: clientId, clientSecret: clientSecret)
    }

    /// This client in the downloaded file's shape, so values typed into a form go through the
    /// same import (and the same `parse` checks) as an uploaded file.
    public func installedJSON() throws -> Data {
        try JSONSerialization.data(
            withJSONObject: ["installed": ["client_id": clientId, "client_secret": clientSecret]],
            options: [.sortedKeys])
    }
}
