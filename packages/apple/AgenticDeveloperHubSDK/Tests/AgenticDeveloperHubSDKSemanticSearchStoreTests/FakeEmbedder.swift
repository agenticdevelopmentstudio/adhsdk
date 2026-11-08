import Foundation
import AgenticDeveloperHubSDKSemanticSearch

/// A deterministic stand-in for the model: each word (lowercased, synonyms
/// folded) adds 1 to one of `dimensions` slots, and the sum is normalised.
/// Texts sharing words point the same way, and a synonym pair embeds alike
/// while sharing no keyword — which is what tells semantic search apart from
/// keyword search in a test. It counts its embeds.
final class FakeEmbedder: TextEmbedder, @unchecked Sendable {
    let stamp: String
    let dimensions: Int
    private let synonyms: [String: String]
    private let lock = NSLock()
    private var embeds = 0

    init(stamp: String = "fake:000000000000:000000000000:64", dimensions: Int = 64,
         synonyms: [String: String] = ["automobile": "car", "vehicle": "car"]) {
        self.stamp = stamp
        self.dimensions = dimensions
        self.synonyms = synonyms
    }

    var embedCount: Int { lock.withLock { embeds } }

    func tokenCount(_ text: String, task: EmbeddingTask) throws -> Int {
        words(text).count + 2
    }

    func embed(_ text: String, task: EmbeddingTask) async throws -> [Float] {
        lock.withLock { embeds += 1 }
        return vector(text)
    }

    /// The vector `embed` gives, without counting.
    func vector(_ text: String) -> [Float] {
        var out = [Float](repeating: 0, count: dimensions)
        for word in words(text) {
            out[slot(word)] += 1
        }
        return VectorMath.normalized(out)
    }

    private func words(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { synonyms[String($0)] ?? String($0) }
    }

    /// FNV-1a, so the slot is the same on every run (Swift's `hashValue` is not).
    private func slot(_ word: String) -> Int {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in word.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3
        }
        return Int(hash % UInt64(dimensions))
    }
}
