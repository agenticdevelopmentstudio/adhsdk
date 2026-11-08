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
        // `a.b` and `a.b.c` would share a settings key prefix, so one would see the other's keys.
        if let other = existing.map(\.descriptor.identifier).first(where: {
            $0.hasPrefix(identifier + ".") || identifier.hasPrefix($0 + ".")
        }) {
            return "Desktop App '\(identifier)' conflicts with '\(other)': one identifier is a dot-prefix of the other."
        }
        let duplicates = app.descriptor.settingsSchema.duplicateKeys
        if !duplicates.isEmpty {
            return "Desktop App '\(identifier)' declares duplicate settings keys: "
                + duplicates.sorted().joined(separator: ", ")
        }
        for field in app.descriptor.settingsSchema.fields {
            if let problem = defaultsProblem(in: field) {
                return "Desktop App '\(identifier)' field '\(field.key)' \(problem)"
            }
        }
        return nil
    }

    private static func defaultsProblem(in field: DesktopAppSettingsSchema.Field) -> String? {
        switch field.kind {
        case .toggle, .text:
            return nil
        case let .integer(fallback, range):
            return range.contains(fallback) ? nil : "has default \(fallback) outside its range \(range)."
        case let .choice(fallback, options):
            if options.isEmpty { return "is a choice with no options." }
            return options.contains { $0.id == fallback }
                ? nil : "has default '\(fallback)' that is not among its options."
        }
    }
}
