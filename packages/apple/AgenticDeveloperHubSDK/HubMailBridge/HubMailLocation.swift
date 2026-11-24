import Foundation

/// Where an app keeps its hub mail mirror, and the stable device id its sync
/// cursor is filed under. Every app that reads hub mail needs both, on every
/// platform, so the rules live here once rather than in each app.
public struct HubMailLocation: Sendable, Equatable {
    /// The UserDefaults key the device id is stored under.
    public static let defaultDeviceIdKey = "hub_mail_device_id"

    /// The mirror's database file.
    public let databaseURL: URL
    /// Made on first use and kept, so the hub resumes this device's cursor.
    public let deviceId: String

    public init(databaseURL: URL, deviceId: String) {
        self.databaseURL = databaseURL
        self.deviceId = deviceId
    }

    /// `Application Support/<appFolder>/hub-mail.db`, with the device id kept
    /// in `defaults`. The mirror is its own file, so signing out purges hub
    /// mail without touching any other database the app keeps.
    public static func app(
        _ appFolder: String,
        defaults: UserDefaults = .standard,
        deviceIdKey: String = defaultDeviceIdKey,
        fileManager: FileManager = .default
    ) -> HubMailLocation {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return HubMailLocation(
            databaseURL: support
                .appendingPathComponent(appFolder, isDirectory: true)
                .appendingPathComponent("hub-mail.db"),
            deviceId: deviceId(defaults: defaults, key: deviceIdKey)
        )
    }

    /// The id stored under `key`, made and stored on first use.
    public static func deviceId(defaults: UserDefaults, key: String = defaultDeviceIdKey) -> String {
        if let existing = defaults.string(forKey: key), !existing.isEmpty { return existing }
        let made = UUID().uuidString
        defaults.set(made, forKey: key)
        return made
    }
}
