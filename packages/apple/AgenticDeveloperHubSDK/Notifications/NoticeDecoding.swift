import Foundation

// Shared helpers for reading stored notice settings tolerantly. One unknown
// value must cost only the element that holds it, never the whole value:
// settings storage falls back to defaults when a decode throws.

extension Double {
    /// The value pinned into `range`.
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

/// One array element, or nil when it does not decode. Decoding an array of
/// these never throws for a bad element, so the rest of the array survives.
private struct LossyElement<Element: Decodable>: Decodable {
    let value: Element?

    init(from decoder: Decoder) throws {
        value = try? Element(from: decoder)
    }
}

extension KeyedDecodingContainer {
    /// The array at `key` without the elements that fail to decode (an
    /// unknown style, target or urgency, say); nil when the key is absent.
    func decodeLossyArrayIfPresent<Element: Decodable>(
        _ type: [Element].Type, forKey key: Key
    ) throws -> [Element]? {
        try decodeIfPresent([LossyElement<Element>].self, forKey: key)?.compactMap(\.value)
    }
}
