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
}
