import Foundation
@preconcurrency import OnnxRuntimeBindings
@preconcurrency import Tokenizers
import AgenticDeveloperHubSDKSemanticSearch

/// Why the ONNX embedder could not answer.
public enum ONNXEmbedderError: Error, Sendable, CustomStringConvertible {
    /// The model returned no tensor under the manifest's output name.
    case missingOutput(String)
    /// The model returned fewer dimensions than the manifest keeps.
    case shortOutput(got: Int, need: Int)

    public var description: String {
        switch self {
        case .missingOutput(let name): "the model gave no \(name) output"
        case let .shortOutput(got, need): "the model gave \(got) dimensions, the manifest keeps \(need)"
        }
    }
}

/// Semantic search vectors from a model bundle, run on the device with ONNX
/// Runtime.
///
/// Ported from the parity spike (`tools/embedding-parity/swift`, which
/// matched all 25 golden cases on macOS and the iOS simulator) and kept in
/// step with the backend's `llm/local-embedder.ts`:
///
/// - the bundle's hashes are checked before anything loads (an LFS pointer is
///   named as one);
/// - the bundle's pinned `tokenizer.json` is the tokenizer, through
///   swift-transformers, and it adds `<bos>`/`<eos>` itself;
/// - the manifest's prefixes go in front of the text;
/// - input is capped at ``TokenLimit/maxEmbedTokens`` (first 1,023 tokens
///   and the last);
/// - the model's pooled `sentence_embedding` is cut to `truncate_dims` and
///   renormalised.
///
/// Embeds run ONE AT A TIME: at about 1 GB loaded and over 2 GB at peak, two
/// long inputs at once could take a phone past its memory. They run on a
/// private serial queue, off Swift's cooperative pool, since one can block
/// for seconds.
///
/// The SDK never downloads a model: an app ships the bundle inside itself and
/// passes its directory.
///
/// `@unchecked Sendable`: every stored property is a `let`; the ONNX session
/// is used only on `modelQueue`, and the tokenizer only under `tokenizerLock`.
public final class ONNXEmbedder: TextEmbedder, @unchecked Sendable {
    public let bundle: EmbeddingBundle
    public let stamp: String
    public let dimensions: Int

    private let tokenizer: any Tokenizer
    private let tokenizerLock = NSLock()
    private let env: ORTEnv
    private let session: ORTSession
    private let modelQueue = DispatchQueue(label: "ONNXEmbedder.model", qos: .userInitiated)

    /// Loads the bundle in `directory`. With `verify` (the default) every
    /// file's sha256 is checked against the manifest first; turning it off
    /// is for a caller that has just verified the same files itself.
    public init(bundleDirectory directory: URL, verify: Bool = true) async throws {
        let bundle = try EmbeddingBundle(directory: directory)
        if verify { try bundle.verify() }
        self.bundle = bundle
        self.stamp = try bundle.manifest.stamp()
        self.dimensions = bundle.manifest.truncateDims

        tokenizer = try await AutoTokenizer.from(modelFolder: directory)
        env = try ORTEnv(loggingLevel: .warning)
        let options = try ORTSessionOptions()
        try options.setGraphOptimizationLevel(.all)
        session = try ORTSession(env: env, modelPath: bundle.url(of: "model.onnx").path, sessionOptions: options)
    }

    /// `text` with the bundle's prefix for `task`.
    public func prefixed(_ text: String, task: EmbeddingTask) -> String {
        bundle.manifest.prefixes.apply(text, task: task)
    }

    /// The tokenizer's IDs for already-prefixed text, uncapped.
    public func tokenIDs(prefixed text: String) -> [Int] {
        tokenizerLock.withLock { tokenizer.encode(text: text) }
    }

    /// The IDs the model reads for `text` under `task`: prefixed, tokenized
    /// and capped.
    public func inputTokenIDs(_ text: String, task: EmbeddingTask) -> [Int] {
        TokenLimit.cap(tokenIDs(prefixed: prefixed(text, task: task)))
    }

    public func tokenCount(_ text: String, task: EmbeddingTask) throws -> Int {
        tokenIDs(prefixed: prefixed(text, task: task)).count
    }

    public func embed(_ text: String, task: EmbeddingTask) async throws -> [Float] {
        try await embed(tokenIDs: inputTokenIDs(text, task: task))
    }

    /// Runs the model on `ids` as given — no prefix, no cap. The golden test
    /// uses it to feed the golden set's own IDs.
    public func embed(tokenIDs ids: [Int]) async throws -> [Float] {
        try await withCheckedThrowingContinuation { continuation in
            modelQueue.async { [self] in
                continuation.resume(with: Result { try self.run(ids) })
            }
        }
    }

    private func run(_ ids: [Int]) throws -> [Float] {
        let output = bundle.manifest.output
        let inputIDs = NSMutableData(length: ids.count * MemoryLayout<Int64>.size)!
        let mask = NSMutableData(length: ids.count * MemoryLayout<Int64>.size)!
        let idPtr = inputIDs.mutableBytes.assumingMemoryBound(to: Int64.self)
        let maskPtr = mask.mutableBytes.assumingMemoryBound(to: Int64.self)
        for (index, id) in ids.enumerated() {
            idPtr[index] = Int64(id)
            maskPtr[index] = 1
        }
        let shape: [NSNumber] = [1, NSNumber(value: ids.count)]
        let outputs = try session.run(
            withInputs: [
                "input_ids": try ORTValue(tensorData: inputIDs, elementType: .int64, shape: shape),
                "attention_mask": try ORTValue(tensorData: mask, elementType: .int64, shape: shape)
            ],
            outputNames: [output],
            runOptions: nil
        )
        guard let value = outputs[output] else { throw ONNXEmbedderError.missingOutput(output) }
        let data = try value.tensorData() as Data
        let full = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        guard full.count >= dimensions else { throw ONNXEmbedderError.shortOutput(got: full.count, need: dimensions) }
        return VectorMath.truncatedAndNormalized(full, to: dimensions)
    }
}
