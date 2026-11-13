import Foundation

/// An author or committer of a commit: who, and when.
public struct GitPerson: Sendable, Hashable {
    public let name: String
    public let email: String
    public let date: Date

    public init(name: String, email: String, date: Date) {
        self.name = name
        self.email = email
        self.date = date
    }
}
