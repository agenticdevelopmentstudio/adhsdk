import Foundation
import Testing
import AgenticDeveloperHubSDKSemanticSearch
@testable import AgenticDeveloperHubSDKSemanticSearchStore

/// Checks ``ONNXEmbedder`` against the bundle's golden set — the conformance
/// vectors of `docs/specs/ingredients/semantic-search.md`: the same prefixed
/// text and token IDs for every case, a vector within the bundle's cosine
/// floor of the reference for every case the cap leaves whole, and the
/// capped path for the one that is not.
///
/// `EMBEDDING_BUNDLE` names the bundle directory, as in the parity spike.
/// Under xcodebuild set `TEST_RUNNER_EMBEDDING_BUNDLE`; the runner strips the
/// prefix. The suite is skipped when it is unset, names no bundle, or the
/// bundle holds git LFS pointers instead of files.
@Suite(.enabled(if: GoldenBundle.directory != nil, GoldenBundle.skipReason))
struct GoldenConformanceTests {

    @Test func theStampIsTheBackendStamp() async throws {
        let embedder = try await GoldenBundle.embedder()
        #expect(embedder.stamp == "embeddinggemma-2:0137f60d95fc:4d777ef5bdc1:256")
        #expect(embedder.dimensions == 256)
    }

    @Test func goldenSet() async throws {
        let golden = try GoldenBundle.golden()
        let embedder = try await GoldenBundle.embedder()
        #expect(golden.modelSHA256 == embedder.bundle.manifest.files["model.onnx"]?.sha256,
                "golden.json was made from a different model")
        #expect(golden.dims == embedder.dimensions)
        #expect(golden.cases.count == 25)

        var compared = 0
        for item in golden.cases {
            let task: EmbeddingTask = item.kind == "query" ? .query : .document(title: item.title)
            #expect(embedder.prefixed(item.text, task: task) == item.prefixed, "\(item.id): prefixed text differs")
            let ids = embedder.tokenIDs(prefixed: item.prefixed)
            #expect(ids == item.inputIDs, "\(item.id): token IDs differ")
            #expect(try embedder.tokenCount(item.text, task: task) == item.inputIDs.count)

            if item.inputIDs.count <= TokenLimit.maxEmbedTokens {
                let vector = try await embedder.embed(item.text, task: task)
                let cosine = VectorMath.cosine(vector, item.vector)
                #expect(cosine >= golden.minCosine, "\(item.id): cosine \(cosine)")
                #expect(abs(VectorMath.norm(vector) - 1) < 1e-4)
                compared += 1
            } else {
                // The backend does the same: past the cap, the model reads the
                // first 1,023 tokens and <eos>, and still gives a unit vector.
                let input = embedder.inputTokenIDs(item.text, task: task)
                #expect(input.count == TokenLimit.maxEmbedTokens)
                #expect(input.last == 1)
                #expect(Array(input.prefix(1023)) == Array(item.inputIDs.prefix(1023)))
                let vector = try await embedder.embed(item.text, task: task)
                #expect(vector.count == 256)
                #expect(abs(VectorMath.norm(vector) - 1) < 1e-4)
            }
        }
        #expect(compared > 20, "too few golden cases fit the cap to mean anything")
    }

    @Test func halfPrecisionStorageKeepsParity() async throws {
        let golden = try GoldenBundle.golden()
        let embedder = try await GoldenBundle.embedder()
        let item = try #require(golden.cases.first { $0.id == "document-titled" })
        let vector = try await embedder.embed(item.text, task: .document(title: item.title))
        let stored = try HalfVectorCodec.decode(HalfVectorCodec.encode(vector), dimensions: 256)
        #expect(VectorMath.cosine(stored, item.vector) >= golden.minCosine)
    }
}

/// The bundle under test, from the environment.
enum GoldenBundle {

    struct Golden: Decodable {
        struct Case: Decodable {
            let id: String
            let kind: String
            let title: String?
            let text: String
            let prefixed: String
            let inputIDs: [Int]
            let vector: [Float]

            enum CodingKeys: String, CodingKey {
                case id, kind, title, text, prefixed, vector
                case inputIDs = "input_ids"
            }
        }

        let name: String
        let modelSHA256: String
        let dims: Int
        let minCosine: Float
        let cases: [Case]

        enum CodingKeys: String, CodingKey {
            case name, dims, cases
            case modelSHA256 = "model_sha256"
            case minCosine = "min_cosine"
        }
    }

    /// The bundle directory, or `nil` with the reason in ``skipReason``.
    static let directory: URL? = {
        guard let path = ProcessInfo.processInfo.environment["EMBEDDING_BUNDLE"], !path.isEmpty else { return nil }
        let url = URL(fileURLWithPath: path)
        guard let bundle = try? EmbeddingBundle(directory: url),
              let pointers = try? bundle.holdsLFSPointers(), !pointers else { return nil }
        return url
    }()

    static var skipReason: Comment {
        guard let path = ProcessInfo.processInfo.environment["EMBEDDING_BUNDLE"], !path.isEmpty else {
            return "set EMBEDDING_BUNDLE (TEST_RUNNER_EMBEDDING_BUNDLE under xcodebuild) to the model bundle directory"
        }
        return "\(path) is not a usable bundle, or holds git LFS pointers (run git lfs pull)"
    }

    static func golden() throws -> Golden {
        let url = try #require(directory).appendingPathComponent("golden.json")
        return try JSONDecoder().decode(Golden.self, from: Data(contentsOf: url))
    }

    /// One embedder for the whole suite: loading verifies 330 MB of hashes
    /// and a 1 GB session, so it is done once.
    static func embedder() async throws -> ONNXEmbedder {
        try await shared.value
    }

    private static let shared = Task<ONNXEmbedder, any Error> {
        guard let directory else { throw EmbeddingBundleError.noManifest("EMBEDDING_BUNDLE") }
        return try await ONNXEmbedder(bundleDirectory: directory)
    }
}
