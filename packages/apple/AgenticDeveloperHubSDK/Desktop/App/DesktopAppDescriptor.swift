import CoreGraphics
import Foundation

/// The static description of a Desktop App: identity, icon, window sizes, settings.
public struct DesktopAppDescriptor: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let identifier: String
    public let displayName: String
    public let version: String
    public let summary: String
    public let icon: DesktopAppIcon
    public let attribution: DesktopAppAttribution
    public let integration: DesktopAppIntegrationBinding?
    public let defaultWindowSize: CGSize
    public let minimumWindowSize: CGSize
    public let settingsSchema: DesktopAppSettingsSchema

    public init(
        identifier: String,
        displayName: String,
        version: String,
        summary: String,
        icon: DesktopAppIcon,
        attribution: DesktopAppAttribution,
        integration: DesktopAppIntegrationBinding? = nil,
        defaultWindowSize: CGSize,
        minimumWindowSize: CGSize,
        settingsSchema: DesktopAppSettingsSchema = .empty
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.identifier = identifier
        self.displayName = displayName
        self.version = version
        self.summary = summary
        self.icon = icon
        self.attribution = attribution
        self.integration = integration
        self.defaultWindowSize = defaultWindowSize
        self.minimumWindowSize = minimumWindowSize
        self.settingsSchema = settingsSchema
    }
}
