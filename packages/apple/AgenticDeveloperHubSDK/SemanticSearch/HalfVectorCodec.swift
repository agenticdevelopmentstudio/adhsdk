import Accelerate
import Foundation

/// A vector's storage form: IEEE 754 half-precision floats (binary16),
/// little-endian, packed with no header — 2 bytes per dimension, so a
/// 256-dimension vector is a 512-byte BLOB.
///
/// It is the layout of the backend's `halfvec(256)` column: pgvector stores a
/// half-precision vector the same way, so a vector rounded here and one
/// rounded by the server hold the same 256 values, and Phase 4's pull-only
/// passages can arrive without changing precision. Rounding to half precision
/// moves a unit vector's components by at most about 0.0005 and its cosine
/// against another by far less than the 0.999 parity floor.
///
/// The conversion is vImage's, not Swift's `Float16`, which does not exist on
/// Intel Macs.
public enum HalfVectorCodec {

    /// `vector` rounded to half precision (round to nearest) and packed.
    public static func encode(_ vector: [Float]) -> Data {
        guard !vector.isEmpty else { return Data() }
        var halves = [UInt16](repeating: 0, count: vector.count)
        var source = vector
        source.withUnsafeMutableBytes { src in
            halves.withUnsafeMutableBytes { dst in
                var srcBuffer = vImage_Buffer(
                    data: src.baseAddress, height: 1, width: vImagePixelCount(vector.count), rowBytes: src.count)
                var dstBuffer = vImage_Buffer(
                    data: dst.baseAddress, height: 1, width: vImagePixelCount(vector.count), rowBytes: dst.count)
                let status = vImageConvert_PlanarFtoPlanar16F(&srcBuffer, &dstBuffer, vImage_Flags(kvImageNoFlags))
                precondition(status == kvImageNoError, "vImageConvert_PlanarFtoPlanar16F failed: \(status)")
            }
        }
        var data = Data(capacity: halves.count * 2)
        for half in halves {
            withUnsafeBytes(of: half.littleEndian) { data.append(contentsOf: $0) }
        }
        return data
    }

    /// The floats packed in `data`. Throws unless `data` holds exactly
    /// `dimensions` halves.
    public static func decode(_ data: Data, dimensions: Int) throws -> [Float] {
        guard data.count == dimensions * 2 else {
            throw HalfVectorCodecError.wrongLength(bytes: data.count, dimensions: dimensions)
        }
        var out = [Float](repeating: 0, count: dimensions)
        decode(data, into: &out, at: 0)
        return out
    }

    /// Unpacks `data` into `buffer` starting at `offset`, for filling one
    /// contiguous matrix row by row. `data` must hold `count` halves that fit.
    public static func decode(_ data: Data, into buffer: inout [Float], at offset: Int) {
        let count = data.count / 2
        precondition(data.count % 2 == 0 && offset + count <= buffer.count, "half vector does not fit")
        guard count > 0 else { return }
        var halves = [UInt16](repeating: 0, count: count)
        data.withUnsafeBytes { raw in
            for index in 0..<count {
                halves[index] = UInt16(littleEndian: raw.loadUnaligned(fromByteOffset: index * 2, as: UInt16.self))
            }
        }
        halves.withUnsafeMutableBytes { src in
            buffer.withUnsafeMutableBytes { all in
                let dst = UnsafeMutableRawBufferPointer(rebasing: all[(offset * 4)..<((offset + count) * 4)])
                var srcBuffer = vImage_Buffer(
                    data: src.baseAddress, height: 1, width: vImagePixelCount(count), rowBytes: src.count)
                var dstBuffer = vImage_Buffer(
                    data: dst.baseAddress, height: 1, width: vImagePixelCount(count), rowBytes: dst.count)
                let status = vImageConvert_Planar16FtoPlanarF(&srcBuffer, &dstBuffer, vImage_Flags(kvImageNoFlags))
                precondition(status == kvImageNoError, "vImageConvert_Planar16FtoPlanarF failed: \(status)")
            }
        }
    }
}

public enum HalfVectorCodecError: Error, Sendable, Equatable {
    case wrongLength(bytes: Int, dimensions: Int)
}
