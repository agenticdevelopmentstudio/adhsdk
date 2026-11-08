import Foundation

/// The integration service an App is bound to (for example `messages` via `gmail`).
public struct DesktopAppIntegrationBinding: Codable, Sendable, Equatable {
    public let serviceType: String
    public let provider: String?

    public init(serviceType: String, provider: String? = nil) {
        self.serviceType = serviceType
        self.provider = provider
    }
}
