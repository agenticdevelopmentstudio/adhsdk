import Foundation

/// The Apps the Desktop knows about, in registration order.
@MainActor
public final class DesktopAppRegistry {
    public private(set) var apps: [DesktopApp] = []

    public init() {}

    /// Registers an App. A duplicate identifier or duplicate settings keys is a programmer error.
    public func register(_ app: DesktopApp) {
        if let message = Self.validationFailure(for: app, in: apps) {
            preconditionFailure(message)
        }
        apps.append(app)
    }

    public func app(withIdentifier identifier: String) -> DesktopApp? {
        apps.first { $0.descriptor.identifier == identifier }
    }

    /// A human-readable reason the App cannot be registered, or nil when it is valid.
    static func validationFailure(for app: DesktopApp, in existing: [DesktopApp]) -> String? {
        let identifier = app.descriptor.identifier
        if existing.contains(where: { $0.descriptor.identifier == identifier }) {
            return "Desktop App '\(identifier)' is already registered."
        }
        let duplicates = app.descriptor.settingsSchema.duplicateKeys
        if !duplicates.isEmpty {
            return "Desktop App '\(identifier)' declares duplicate settings keys: "
                + duplicates.sorted().joined(separator: ", ")
        }
        return nil
    }
}
