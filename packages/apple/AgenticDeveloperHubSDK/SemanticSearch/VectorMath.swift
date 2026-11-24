import Accelerate
import Foundation

/// Vector maths for semantic search, over Accelerate's vDSP.
public enum VectorMath {

    /// The dot product. Both vectors must have the same length.
    public static func dot(_ lhs: [Float], _ rhs: [Float]) -> Float {
        precondition(lhs.count == rhs.count, "dot of vectors of length \(lhs.count) and \(rhs.count)")
        return vDSP.dot(lhs, rhs)
    }

    /// The Euclidean length.
    public static func norm(_ vector: [Float]) -> Float {
        vDSP.sumOfSquares(vector).squareRoot()
    }

    /// `vector` scaled to unit length. A zero vector has no direction, so it
    /// comes back unchanged rather than as NaNs.
    public static func normalized(_ vector: [Float]) -> [Float] {
        let length = norm(vector)
        guard length > 0 else { return vector }
        return vDSP.divide(vector, length)
    }

    /// The cosine of the angle between two vectors: their dot product over
    /// the product of their lengths, 0 when either is zero. For the unit
    /// vectors an embedder returns, this equals ``dot(_:_:)``.
    public static func cosine(_ lhs: [Float], _ rhs: [Float]) -> Float {
        let lengths = norm(lhs) * norm(rhs)
        guard lengths > 0 else { return 0 }
        return dot(lhs, rhs) / lengths
    }

    /// The model's full output cut to its first `dimensions` and renormalised
    /// to unit length — Matryoshka truncation, as the bundle's
    /// `truncate_dims` and `renormalize_after_truncate` ask.
    public static func truncatedAndNormalized(_ vector: [Float], to dimensions: Int) -> [Float] {
        precondition(dimensions > 0 && dimensions <= vector.count,
                     "cannot keep \(dimensions) of \(vector.count) dimensions")
        return normalized(Array(vector.prefix(dimensions)))
    }

    /// The dot product of `query` with each row of `matrix`, a row-major
    /// buffer of `matrix.count / query.count` rows. One `vDSP_mmul` call, so
    /// a brute-force scan over thousands of vectors stays a single pass.
    public static func dotProducts(query: [Float], matrix: [Float]) -> [Float] {
        let dims = query.count
        precondition(dims > 0 && matrix.count % dims == 0,
                     "a matrix of \(matrix.count) floats does not hold rows of \(dims)")
        let rows = matrix.count / dims
        guard rows > 0 else { return [] }
        var out = [Float](repeating: 0, count: rows)
        matrix.withUnsafeBufferPointer { matrixPtr in
            query.withUnsafeBufferPointer { queryPtr in
                out.withUnsafeMutableBufferPointer { outPtr in
                    // (rows x dims) * (dims x 1) = (rows x 1)
                    vDSP_mmul(matrixPtr.baseAddress!, 1, queryPtr.baseAddress!, 1, outPtr.baseAddress!, 1,
                              vDSP_Length(rows), 1, vDSP_Length(dims))
                }
            }
        }
        return out
    }

    /// One scored row of a top-k selection.
    public struct Scored: Sendable, Equatable {
        /// The row's position in the scores it was chosen from.
        public let index: Int
        public let score: Float
        public init(index: Int, score: Float) {
            self.index = index
            self.score = score
        }
    }

    /// The `k` highest scores, best first. Equal scores keep their input
    /// order, so the same scores always select and order the same way; a NaN
    /// score is never selected.
    public static func topK(_ scores: [Float], k count: Int) -> [Scored] {
        guard count > 0 else { return [] }
        var best: [Scored] = []
        best.reserveCapacity(min(count, scores.count) + 1)
        for (index, score) in scores.enumerated() where !score.isNaN {
            if best.count == count, let worst = best.last, score <= worst.score { continue }
            // Insert after every entry scoring >= this one: input order breaks ties.
            var low = 0
            var high = best.count
            while low < high {
                let mid = (low + high) / 2
                if best[mid].score >= score { low = mid + 1 } else { high = mid }
            }
            best.insert(Scored(index: index, score: score), at: low)
            if best.count > count { best.removeLast() }
        }
        return best
    }
}
