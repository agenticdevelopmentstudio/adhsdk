import Foundation
import Testing
@testable import AgenticDeveloperHubSDKSemanticSearch

struct HalfVectorCodecTests {

    /// The spec's conformance vectors: IEEE binary16, little-endian, as
    /// Python's `struct.pack('<e', x)` gives them.
    static let knownBitPatterns: [(Float, [UInt8])] = [
        (1.0, [0x00, 0x3C]),
        (0.5, [0x00, 0x38]),
        (-2.0, [0x00, 0xC0]),
        (0.1, [0x66, 0x2E]),
        (0.0, [0x00, 0x00]),
        (-0.0, [0x00, 0x80]),
        (65504.0, [0xFF, 0x7B]),
        (0.333333, [0x55, 0x35])
    ]

    @Test func encodesKnownBitPatterns() {
        for (value, bytes) in Self.knownBitPatterns {
            #expect([UInt8](HalfVectorCodec.encode([value])) == bytes, "value \(value)")
        }
    }

    @Test func aVectorIsTwoBytesPerDimension() {
        #expect(HalfVectorCodec.encode([Float](repeating: 0.25, count: 256)).count == 512)
        #expect(HalfVectorCodec.encode([]).isEmpty)
    }

    @Test func roundTripsWithinHalfPrecision() throws {
        var generator = SplitMix64(seed: 3)
        let raw = (0..<256).map { _ in Float(Int(generator.next() % 2001) - 1000) / 1000 }
        let vector = VectorMath.normalized(raw)
        let decoded = try HalfVectorCodec.decode(HalfVectorCodec.encode(vector), dimensions: 256)
        for (got, want) in zip(decoded, vector) {
            #expect(abs(got - want) <= 0.0005)
        }
        #expect(VectorMath.cosine(decoded, vector) > 0.99999)
    }

    @Test func exactValuesRoundTripExactly() throws {
        let vector: [Float] = [1, 0.5, -2, 0, 0.25, -0.125]
        #expect(try HalfVectorCodec.decode(HalfVectorCodec.encode(vector), dimensions: 6) == vector)
    }

    @Test func decodeRefusesTheWrongLength() {
        #expect(throws: HalfVectorCodecError.wrongLength(bytes: 6, dimensions: 4)) {
            try HalfVectorCodec.decode(Data(count: 6), dimensions: 4)
        }
    }

    @Test func decodeIntoFillsOneRowOfAMatrix() {
        var matrix = [Float](repeating: 9, count: 6)
        HalfVectorCodec.decode(HalfVectorCodec.encode([1, 0.5]), into: &matrix, at: 2)
        #expect(matrix == [9, 9, 1, 0.5, 9, 9])
    }
}
