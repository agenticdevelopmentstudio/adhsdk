import Foundation

/// Which mail classes a connection mirrors, how far back, and how often it polls.
/// Decoding is lenient per key: a missing key takes its default.
public struct MailSyncSettings: Codable, Sendable, Equatable {
    public var includeArchived: Bool
    public var includeSpam: Bool
    public var includeTrash: Bool
    public var windowDays: Int
    public var pollIntervalMinutes: Int

    public static let windowDaysRange = 1...3650
    public static let pollIntervalRange = 1...1440

    public static let `default` = MailSyncSettings(
        includeArchived: false, includeSpam: false, includeTrash: false,
        windowDays: 30, pollIntervalMinutes: 15
    )

    public init(
        includeArchived: Bool = false, includeSpam: Bool = false, includeTrash: Bool = false,
        windowDays: Int = 30, pollIntervalMinutes: Int = 15
    ) {
        self.includeArchived = includeArchived
        self.includeSpam = includeSpam
        self.includeTrash = includeTrash
        self.windowDays = windowDays
        self.pollIntervalMinutes = pollIntervalMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case includeArchived, includeSpam, includeTrash, windowDays, pollIntervalMinutes
    }

    public init(from decoder: Decoder) throws {
        let fallback = MailSyncSettings.default
        let container = try decoder.container(keyedBy: CodingKeys.self)
        includeArchived = try container.decodeIfPresent(Bool.self, forKey: .includeArchived) ?? fallback.includeArchived
        includeSpam = try container.decodeIfPresent(Bool.self, forKey: .includeSpam) ?? fallback.includeSpam
        includeTrash = try container.decodeIfPresent(Bool.self, forKey: .includeTrash) ?? fallback.includeTrash
        windowDays = try container.decodeIfPresent(Int.self, forKey: .windowDays) ?? fallback.windowDays
        pollIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .pollIntervalMinutes)
            ?? fallback.pollIntervalMinutes
    }

    /// Filed mail is always mirrored; the other classes follow their flag.
    public func allows(_ cls: MailClass) -> Bool {
        switch cls {
        case .filed: return true
        case .archived: return includeArchived
        case .spam: return includeSpam
        case .trash: return includeTrash
        }
    }

    public func validated() throws -> MailSyncSettings {
        guard Self.windowDaysRange.contains(windowDays) else {
            throw IntegrationError.invalidSettings("windowDays must be 1–3650, got \(windowDays)")
        }
        guard Self.pollIntervalRange.contains(pollIntervalMinutes) else {
            throw IntegrationError.invalidSettings("pollIntervalMinutes must be 1–1440, got \(pollIntervalMinutes)")
        }
        return self
    }
}
