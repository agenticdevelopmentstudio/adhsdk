import Foundation

/// Turns one archived raw record into normalized rows. Pure: no I/O, no clock,
/// no globals. The same input gives equal output, which is what lets `events.db`
/// be rebuilt from the archive by replay. Every number it emits (attrs values,
/// costs, dates) must be finite: JSON has no NaN or infinity, so the store cannot
/// write one and the batch would fail every pass (`NormalizedBatch.nonFiniteFields`,
/// conformance check `nonFiniteNumber`).
public protocol Normalizer: Sendable {
    var provider: String { get }
    func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch

    /// Whether `incoming`, which arrived under a dedup key the archive already holds
    /// with different bytes, says the same thing as the `archived` record. Identity
    /// is the provider's to define: `true` makes the drainer treat `incoming` as an
    /// ordinary duplicate (the archive keeps the first record, nothing is
    /// quarantined); `false` makes it a conflict, quarantined with its bytes.
    /// Must be pure, like `normalize`. Default: byte-equal payloads only.
    func isEquivalent(archived: RawRecord, incoming: RawRecord) -> Bool
}

extension Normalizer {
    public func isEquivalent(archived: RawRecord, incoming: RawRecord) -> Bool {
        archived.payload == incoming.payload
    }
}
