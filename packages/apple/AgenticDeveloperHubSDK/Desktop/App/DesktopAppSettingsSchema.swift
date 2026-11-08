import Foundation

/// The settings fields an App declares; the Desktop renders them in Settings.
public struct DesktopAppSettingsSchema: Codable, Sendable, Equatable {
    public static let empty = DesktopAppSettingsSchema(fields: [])

    public let fields: [Field]

    public init(fields: [Field]) {
        self.fields = fields
    }

    /// Keys that appear on more than one field.
    public var duplicateKeys: Set<String> {
        var seen = Set<String>()
        var duplicates = Set<String>()
        for field in fields where !seen.insert(field.key).inserted {
            duplicates.insert(field.key)
        }
        return duplicates
    }

    public struct Field: Codable, Sendable, Equatable {
        public let key: String
        public let label: String
        public let help: String?
        public let kind: Kind

        public init(key: String, label: String, help: String? = nil, kind: Kind) {
            self.key = key
            self.label = label
            self.help = help
            self.kind = kind
        }
    }

    public enum Kind: Codable, Sendable, Equatable {
        case toggle(default: Bool)
        case text(default: String, placeholder: String?)
        case integer(default: Int, range: ClosedRange<Int>)
        case choice(default: String, options: [Option])
    }

    public struct Option: Codable, Sendable, Equatable {
        public let id: String
        public let label: String

        public init(id: String, label: String) {
            self.id = id
            self.label = label
        }
    }
}
