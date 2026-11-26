import Foundation
import os

/// Records each secret field a registry write touches, with the value it held
/// before, so a write that fails part way can put every field back
/// (`secret-write-rollback`). One journal serves one call; it is not shared.
struct ModelSecretJournal {

    private let store: any ModelSecretStore
    private let entry: UUID
    private let logger: Logger
    /// The previous value of each touched field, nil when it had none, in the
    /// order the fields were first touched.
    private var previous: [(field: String, value: String?)] = []

    init(store: any ModelSecretStore, entry: UUID, logger: Logger) {
        self.store = store
        self.entry = entry
        self.logger = logger
    }

    /// Stores `value`, first recording what the field held.
    mutating func set(_ value: String, field: String) throws {
        record(field)
        try store.set(value, for: entry, field: field)
    }

    /// Removes the field, first recording what it held.
    mutating func remove(field: String) throws {
        record(field)
        try store.remove(for: entry, field: field)
    }

    /// Puts every touched field back as it was, newest first. A restore that
    /// fails is logged (field and id only, never a value) and the others still run.
    func rollback() {
        for (field, value) in previous.reversed() {
            do {
                if let value {
                    try store.set(value, for: entry, field: field)
                } else {
                    try store.remove(for: entry, field: field)
                }
            } catch {
                logger.error("""
                    Could not restore secret '\(field, privacy: .public)' of model entry \
                    \(self.entry.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)
                    """)
            }
        }
    }

    private mutating func record(_ field: String) {
        guard !previous.contains(where: { $0.field == field }) else { return }
        previous.append((field, store.value(for: entry, field: field)))
    }
}
