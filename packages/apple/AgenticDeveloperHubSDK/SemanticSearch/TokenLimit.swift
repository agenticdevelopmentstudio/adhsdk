import Foundation

/// The cap on what one embed reads.
///
/// The model's context is 262,144 positions and its bundle truncates nothing,
/// but time and memory climb steeply past about a thousand tokens: in the
/// parity spike 4,099 tokens took 7.4 s and 2.3 GB. The backend caps at the
/// same number (`MAX_EMBED_TOKENS` in `llm/local-embedder.ts`), so a device and
/// the server read the same tokens of any input.
public enum TokenLimit {
    /// The longest input embedded, in tokens, `<bos>` and `<eos>` included.
    public static let maxEmbedTokens = 1024

    /// `ids` cut to at most `limit` tokens. The tokenizer ends every input
    /// with `<eos>`, and the model was trained to pool up to it, so a cut
    /// input keeps its first `limit - 1` tokens and its LAST token.
    public static func cap(_ ids: [Int], to limit: Int = maxEmbedTokens) -> [Int] {
        precondition(limit >= 2, "a token limit below 2 cannot keep <bos> and <eos>")
        guard ids.count > limit, let last = ids.last else { return ids }
        return Array(ids.prefix(limit - 1)) + [last]
    }
}
