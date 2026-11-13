import Foundation

/// Undoes git's C-style path quoting (`"a\tb"`, `"\303\274.txt"`).
enum GitPathUnquoting {
    /// Returns `quoted` unchanged unless it is wrapped in double quotes; otherwise
    /// resolves the escapes, decoding octal byte runs together as UTF-8
    /// (ISO Latin-1 when they are not valid UTF-8).
    static func unquote(_ quoted: String) -> String {
        let bytes = Array(quoted.utf8)
        let quote = UInt8(ascii: "\"")
        guard bytes.count >= 2, bytes.first == quote, bytes.last == quote else { return quoted }
        var out: [UInt8] = []
        out.reserveCapacity(bytes.count)
        var index = 1
        let end = bytes.count - 1
        while index < end {
            let byte = bytes[index]
            guard byte == UInt8(ascii: "\\"), index + 1 < end else {
                out.append(byte)
                index += 1
                continue
            }
            let next = bytes[index + 1]
            if let octal = octalByte(bytes, at: index + 1, end: end) {
                out.append(octal)
                index += 4
                continue
            }
            out.append(escaped(next) ?? next)
            index += 2
        }
        return String(bytes: out, encoding: .utf8) ?? String(bytes: out, encoding: .isoLatin1) ?? quoted
    }

    private static func escaped(_ byte: UInt8) -> UInt8? {
        switch byte {
        case UInt8(ascii: "t"): return 0x09
        case UInt8(ascii: "n"): return 0x0A
        case UInt8(ascii: "r"): return 0x0D
        case UInt8(ascii: "a"): return 0x07
        case UInt8(ascii: "b"): return 0x08
        case UInt8(ascii: "f"): return 0x0C
        case UInt8(ascii: "v"): return 0x0B
        default: return nil // `\"`, `\\` and anything unknown stand for themselves
        }
    }

    /// Three octal digits starting at `start`, as one byte.
    private static func octalByte(_ bytes: [UInt8], at start: Int, end: Int) -> UInt8? {
        guard start + 3 <= end else { return nil }
        var value = 0
        for byte in bytes[start..<start + 3] {
            guard byte >= UInt8(ascii: "0"), byte <= UInt8(ascii: "7") else { return nil }
            value = value * 8 + Int(byte - UInt8(ascii: "0"))
        }
        return value <= 0xFF ? UInt8(value) : nil
    }
}
