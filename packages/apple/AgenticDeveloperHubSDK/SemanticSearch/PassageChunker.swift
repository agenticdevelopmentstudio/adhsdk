import CryptoKit
import Foundation

/// One passage of a document, ready to embed.
public struct PassageChunk: Sendable, Equatable {
    /// Position in the document, contiguous from 0.
    public let index: Int
    public let content: String

    public init(index: Int, content: String) {
        self.index = index
        self.content = content
    }
}

/// Splits a markdown document into passages on a device, so a document saved
/// here is searchable at once.
///
/// Device passages are temporary: the server splits the same document with
/// `chunkMarkdown` (`adhbackend/src/adh/src/lib/markdown-chunks.ts`) and its
/// passages replace these when they sync down. So this follows the server's
/// rules without promising its exact output:
///
/// - CRLF is read as LF; blocks are runs of text between blank lines, trimmed,
///   and empty blocks are dropped.
/// - A `#` or `##` heading starts a new passage unless the passage is empty.
/// - Blocks are packed up to ``targetCharacters``, joined by a blank line.
/// - A block longer than ``maxCharacters`` is cut at the last whitespace
///   before the limit, or at the limit when there is none.
/// - A passage that fails `fits` — in practice, the embedder's token budget —
///   is halved at the space nearest its middle until every piece fits.
///
/// Deterministic: no clock, no randomness, so the same text and the same
/// budget always give the same passages. Lengths are counted in Characters.
public struct PassageChunker: Sendable {
    public static let defaultTargetCharacters = 1500
    public static let defaultMaxCharacters = 4000

    public let targetCharacters: Int
    public let maxCharacters: Int

    public init(targetCharacters: Int = defaultTargetCharacters, maxCharacters: Int = defaultMaxCharacters) {
        precondition(targetCharacters > 0 && maxCharacters > 0, "chunk sizes must be positive")
        self.targetCharacters = targetCharacters
        self.maxCharacters = maxCharacters
    }

    /// The passages of `markdown`. `fits` is the limit the character bounds
    /// cannot express; ``SemanticTokenBudget/fits(embedder:title:)`` builds the
    /// usual one.
    public func chunk(_ markdown: String, fits: ((String) -> Bool)? = nil) -> [PassageChunk] {
        let blocks = Self.blocks(of: markdown)

        var chunks: [String] = []
        var current: [String] = []
        var currentLength = 0
        func flush() {
            guard !current.isEmpty else { return }
            chunks.append(current.joined(separator: "\n\n"))
            current = []
            currentLength = 0
        }

        for block in blocks {
            if Self.isTopHeading(block) && !current.isEmpty { flush() }
            for piece in Self.hardSplit(block, maxCharacters: maxCharacters) {
                // +2 for the blank-line join. Never flush an empty passage: a
                // single piece longer than the target still lands somewhere.
                if !current.isEmpty && currentLength + piece.count + 2 > targetCharacters { flush() }
                currentLength += piece.count + (current.isEmpty ? 0 : 2)
                current.append(piece)
            }
        }
        flush()

        let fitted = fits.map { fits in chunks.flatMap { Self.splitToFit($0, fits: fits) } } ?? chunks
        return fitted
            .filter { !Self.trim($0).isEmpty }
            .enumerated()
            .map { PassageChunk(index: $0.offset, content: $0.element) }
    }

    // MARK: - Pieces

    static func trim(_ text: some StringProtocol) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Paragraph blocks: split at lines that are empty or hold only
    /// whitespace, each trimmed, empty ones dropped.
    static func blocks(of markdown: String) -> [String] {
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
        var blocks: [String] = []
        var current: [Substring] = []
        func close() {
            let block = trim(current.joined(separator: "\n"))
            if !block.isEmpty { blocks.append(block) }
            current = []
        }
        for line in lines {
            if trim(line).isEmpty { close() } else { current.append(line) }
        }
        close()
        return blocks
    }

    /// A `#` or `##` heading: one or two `#` then whitespace.
    static func isTopHeading(_ block: String) -> Bool {
        let hashes = block.prefix { $0 == "#" }.count
        guard hashes == 1 || hashes == 2 else { return false }
        let after = block.dropFirst(hashes).first
        return after.map { $0.isWhitespace } ?? false
    }

    /// `block` in pieces of at most `maxCharacters`, each cut at the last
    /// whitespace before the limit, or at the limit when there is none.
    static func hardSplit(_ block: String, maxCharacters: Int) -> [String] {
        var out: [String] = []
        func emit(_ piece: Substring) {
            let trimmed = trim(piece)
            if !trimmed.isEmpty { out.append(trimmed) }
        }
        var rest = Substring(block)
        while rest.count > maxCharacters {
            let windowEnd = rest.index(rest.startIndex, offsetBy: maxCharacters)
            let window = rest[rest.startIndex..<windowEnd]
            // The last whitespace in the window that is followed only by
            // non-whitespace up to the window's end; never at position 0, so
            // `rest` always shrinks.
            var cut = windowEnd
            if let lastSpace = window.lastIndex(where: { $0.isWhitespace }), lastSpace > rest.startIndex {
                cut = lastSpace
            }
            emit(rest[rest.startIndex..<cut])
            rest = rest[cut...]
        }
        emit(rest)
        return out
    }

    /// Halves `chunk` at the space nearest its middle (or the middle itself)
    /// until every piece passes `fits`.
    static func splitToFit(_ chunk: String, fits: (String) -> Bool) -> [String] {
        if chunk.count < 2 || fits(chunk) { return [chunk] }
        let characters = Array(chunk)
        let mid = characters.count / 2
        let before = characters[..<min(mid + 1, characters.count)].lastIndex(of: " ")
        let after = characters[mid...].firstIndex(of: " ")
        let candidates = [before, after].compactMap { $0 }.filter { $0 > 0 }
        let cut = candidates.min { abs($0 - mid) < abs($1 - mid) } ?? mid
        return [String(characters[..<cut]), String(characters[cut...])]
            .map { trim($0) }
            .filter { !$0.isEmpty }
            .flatMap { splitToFit($0, fits: fits) }
    }
}

/// The token budget a passage is split to, so the model reads all of it
/// rather than having its tail cut by ``TokenLimit/cap(_:to:)``.
public enum SemanticTokenBudget {
    /// True when `embedder` would read a passage of `title`'s document,
    /// prefix included, in at most ``TokenLimit/maxEmbedTokens`` tokens. A
    /// passage the tokenizer cannot measure is treated as not fitting, so it
    /// is halved rather than embedded whole.
    public static func fits(embedder: any TextEmbedder, title: String?) -> (String) -> Bool {
        { chunk in
            guard let count = try? embedder.tokenCount(chunk, task: .document(title: title)) else { return false }
            return count <= TokenLimit.maxEmbedTokens
        }
    }
}

/// The document version a passage was made from, as the backend writes it in
/// `content.markdown_chunks.source_hash`: the lowercase hex sha256 of the
/// UTF-8 bytes of `title + "\n\n" + content`, a missing title counting as
/// empty (`docSourceHash` in `adhbackend/src/adh/src/lib/knowledge-chunks.ts`).
/// The text is hashed exactly as held — no line-ending or Unicode
/// normalisation — because the server hashes its stored text the same way.
public enum PassageSourceHash {
    public static func of(title: String?, content: String) -> String {
        let digest = SHA256.hash(data: Data(((title ?? "") + "\n\n" + content).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
