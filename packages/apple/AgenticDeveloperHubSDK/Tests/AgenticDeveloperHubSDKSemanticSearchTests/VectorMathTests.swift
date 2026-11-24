import Foundation
import Testing
@testable import AgenticDeveloperHubSDKSemanticSearch

struct VectorMathTests {

    @Test func dotAndNorm() {
        #expect(VectorMath.dot([1, 2, 3], [4, 5, 6]) == 32)
        #expect(VectorMath.norm([3, 4]) == 5)
        #expect(VectorMath.norm([]) == 0)
    }

    @Test func normalizedIsUnitLength() {
        let unit = VectorMath.normalized([3, 4])
        #expect(abs(unit[0] - 0.6) < 1e-6)
        #expect(abs(unit[1] - 0.8) < 1e-6)
        #expect(abs(VectorMath.norm(unit) - 1) < 1e-6)
    }

    @Test func normalizedLeavesZeroVectorAlone() {
        #expect(VectorMath.normalized([0, 0, 0]) == [0, 0, 0])
    }

    @Test func cosine() {
        #expect(abs(VectorMath.cosine([1, 0], [0, 1])) < 1e-6)
        #expect(abs(VectorMath.cosine([1, 1], [2, 2]) - 1) < 1e-6)
        #expect(abs(VectorMath.cosine([1, 0], [-3, 0]) + 1) < 1e-6)
        #expect(VectorMath.cosine([0, 0], [1, 1]) == 0)
    }

    @Test func truncatedAndNormalizedKeepsThePrefix() {
        let cut = VectorMath.truncatedAndNormalized([3, 4, 100, -100], to: 2)
        #expect(cut.count == 2)
        #expect(abs(cut[0] - 0.6) < 1e-6)
        #expect(abs(cut[1] - 0.8) < 1e-6)
    }

    @Test func dotProductsScoresEveryRow() {
        let matrix: [Float] = [
            1, 0, 0,
            0, 1, 0,
            1, 1, 1,
            -1, 0, 2
        ]
        #expect(VectorMath.dotProducts(query: [1, 2, 3], matrix: matrix) == [1, 2, 6, 5])
        #expect(VectorMath.dotProducts(query: [1, 2, 3], matrix: []).isEmpty)
    }

    @Test func dotProductsMatchesDotOnALargeMatrix() {
        let dims = 256
        let rows = 300
        let query = (0..<dims).map { Float(sin(Double($0))) }
        var matrix: [Float] = []
        var expected: [Float] = []
        for row in 0..<rows {
            let vector = (0..<dims).map { Float(cos(Double($0 * (row + 1)))) }
            matrix += vector
            expected.append(VectorMath.dot(query, vector))
        }
        let scores = VectorMath.dotProducts(query: query, matrix: matrix)
        for (got, want) in zip(scores, expected) {
            #expect(abs(got - want) < 1e-3)
        }
    }

    @Test func topKOrdersBestFirst() {
        let picked = VectorMath.topK([0.1, 0.9, 0.5, 0.7], k: 3)
        #expect(picked.map(\.index) == [1, 3, 2])
        #expect(picked.map(\.score) == [0.9, 0.7, 0.5])
    }

    @Test func topKBreaksTiesByInputOrder() {
        let picked = VectorMath.topK([0.5, 0.8, 0.5, 0.8, 0.5], k: 4)
        #expect(picked.map(\.index) == [1, 3, 0, 2])
    }

    @Test func topKHandlesShortInputZeroKAndNaN() {
        #expect(VectorMath.topK([0.2, 0.1], k: 5).map(\.index) == [0, 1])
        #expect(VectorMath.topK([0.2, 0.1], k: 0).isEmpty)
        #expect(VectorMath.topK([Float.nan, 0.1, Float.nan], k: 3).map(\.index) == [1])
    }

    @Test func topKAgreesWithAFullSort() {
        var generator = SplitMix64(seed: 7)
        let scores = (0..<500).map { _ in Float(generator.next() % 1000) / 1000 }
        let expected = scores.enumerated()
            .sorted { $0.element != $1.element ? $0.element > $1.element : $0.offset < $1.offset }
            .prefix(20)
            .map(\.offset)
        #expect(VectorMath.topK(scores, k: 20).map(\.index) == expected)
    }
}

/// A small deterministic generator, so a test's random input is the same on
/// every run.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
