import Foundation

/// One `event:`/`data:` block from a Server-Sent Events body.
struct SSEBlock: Equatable {
    let event: String
    let data: String
}

/// Incremental SSE reader.
///
/// Buffers across chunk boundaries, because a block can arrive split anywhere —
/// mid-word, mid-separator — and a parser that assumes one chunk is one block
/// works right up until the reply is long enough to matter.
struct SSEParser {
    private var buffer = Data()
    private static let separator = Data([0x0A, 0x0A])

    mutating func consume(_ chunk: Data) -> [SSEBlock] {
        buffer.append(chunk)
        var blocks: [SSEBlock] = []
        while let range = buffer.range(of: Self.separator) {
            let raw = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            if let text = String(data: raw, encoding: .utf8), !text.isEmpty {
                blocks.append(Self.parse(text))
            }
        }
        return blocks
    }

    /// Split one block into its event name and payload. `:` comments and
    /// `id:` / `retry:` fields are ignored.
    private static func parse(_ block: String) -> SSEBlock {
        var event = "message"
        var dataLines: [String] = []
        for line in block.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("event:") {
                event = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data:") {
                var value = String(line.dropFirst(5))
                if value.hasPrefix(" ") { value.removeFirst() }
                dataLines.append(value)
            }
        }
        return SSEBlock(event: event, data: dataLines.joined(separator: "\n"))
    }
}
