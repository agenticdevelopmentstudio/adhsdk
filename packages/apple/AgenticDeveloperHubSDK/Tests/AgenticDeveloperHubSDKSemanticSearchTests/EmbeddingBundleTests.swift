import Foundation
import Testing
@testable import AgenticDeveloperHubSDKSemanticSearch

struct EmbeddingBundleTests {

    // MARK: - Stamp

    /// The spec's conformance vector: the stamp the backend's `stampFor`
    /// gives the embeddinggemma-2 bundle.
    @Test func stampMatchesTheBackendForTheShippedBundle() throws {
        let stamp = try SemanticStamp.make(
            name: "embeddinggemma-2",
            modelSHA256: "0137f60d95fc8d0712d2afee6fd259203e1124559bdc3ec0cc853fb0f89170ac",
            tokenizerSHA256: "4d777ef5bdc1aa36227abdfb77c3e49e7b9c892d16e1b6bda41c393504828be4",
            dimensions: 256)
        #expect(stamp == "embeddinggemma-2:0137f60d95fc:4d777ef5bdc1:256")
    }

    @Test func stampRefusesMoreThan96Characters() throws {
        let sha = String(repeating: "a", count: 64)
        // 96 exactly: name + ":" + 12 + ":" + 12 + ":" + "256" = name + 30.
        let fits = String(repeating: "n", count: 66)
        #expect(try SemanticStamp.make(name: fits, modelSHA256: sha, tokenizerSHA256: sha, dimensions: 256).count == 96)
        let tooLong = fits + "n"
        #expect(throws: EmbeddingBundleError.self) {
            try SemanticStamp.make(name: tooLong, modelSHA256: sha, tokenizerSHA256: sha, dimensions: 256)
        }
        // An astral character is one Character but two UTF-16 units, as the
        // backend's `stamp.length` counts it: 65 n + one emoji is 97 units.
        let astral = String(repeating: "n", count: 65) + "\u{1F600}"
        #expect(throws: EmbeddingBundleError.self) {
            try SemanticStamp.make(name: astral, modelSHA256: sha, tokenizerSHA256: sha, dimensions: 256)
        }
    }

    @Test func manifestStampNeedsTheModelAndTokenizer() throws {
        let dir = try TemporaryBundle(files: ["tokenizer.json": Data("{}".utf8)])
        defer { dir.remove() }
        let bundle = try EmbeddingBundle(directory: dir.url)
        #expect(throws: EmbeddingBundleError.missingFile("model.onnx")) { try bundle.manifest.stamp() }
        #expect(EmbeddingBundleError.missingFile("model.onnx").description == "the manifest lists no model.onnx")
    }

    // MARK: - Prefixes

    private let prefixes = EmbeddingPrefixes(
        query: "task: search result | query: ",
        document: "title: {title} | text: ",
        documentUntitled: "title: none | text: ")

    @Test func prefixesFollowTheTask() {
        #expect(prefixes.apply("hi", task: .query) == "task: search result | query: hi")
        #expect(prefixes.apply("hi", task: .document(title: "Trip notes")) == "title: Trip notes | text: hi")
        #expect(prefixes.apply("hi", task: .document(title: nil)) == "title: none | text: hi")
    }

    @Test func anEmptyTitleIsUntitled() {
        #expect(prefixes.apply("hi", task: .document(title: "")) == "title: none | text: hi")
        #expect(EmbeddingTask.document(title: "").documentTitle == nil)
    }

    @Test func onlyTheFirstTitlePlaceholderIsReplacedAndLiterally() {
        let doubled = EmbeddingPrefixes(query: "", document: "{title} / {title}: ", documentUntitled: "")
        #expect(doubled.apply("x", task: .document(title: "$1 & {title}")) == "$1 & {title} / {title}: x")
    }

    // MARK: - Token cap

    @Test func capKeepsShortInputWhole() {
        #expect(TokenLimit.cap([2, 5, 1]) == [2, 5, 1])
        #expect(TokenLimit.cap(Array(0..<1024)).count == 1024)
    }

    @Test func capKeepsTheHeadAndTheLastToken() {
        let ids = [2] + Array(repeating: 7, count: 2000) + [1]
        let capped = TokenLimit.cap(ids)
        #expect(capped.count == 1024)
        #expect(capped.first == 2)
        #expect(capped.last == 1)
        #expect(Array(capped[0..<1023]) == Array(ids[0..<1023]))
        #expect(TokenLimit.cap([2, 3, 4, 5, 1], to: 3) == [2, 3, 1])
    }

    // MARK: - Bundle

    @Test func readsTheManifest() throws {
        let dir = try TemporaryBundle(files: ["model.onnx": Data("m".utf8), "tokenizer.json": Data("t".utf8)])
        defer { dir.remove() }
        let bundle = try EmbeddingBundle(directory: dir.url)
        #expect(bundle.manifest.name == "test-bundle")
        #expect(bundle.manifest.truncateDims == 4)
        #expect(bundle.manifest.prefixes.documentUntitled == "title: none | text: ")
        try bundle.verify()
        #expect(try !bundle.holdsLFSPointers())
        #expect(try bundle.manifest.stamp() == "test-bundle:\(sha("m").prefix(12)):\(sha("t").prefix(12)):4")
    }

    @Test func refusesADirectoryWithoutAManifest() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("no-bundle-\(UUID().uuidString)")
        #expect(throws: EmbeddingBundleError.noManifest(url.path)) { try EmbeddingBundle(directory: url) }
    }

    @Test func refusesAManifestThatCapsTokens() throws {
        let dir = try TemporaryBundle(files: ["model.onnx": Data()], maxTokens: 512)
        defer { dir.remove() }
        #expect(throws: EmbeddingBundleError.truncationRequested(512)) { try EmbeddingBundle(directory: dir.url) }
    }

    @Test func verifyNamesAMissingFile() throws {
        let dir = try TemporaryBundle(files: ["model.onnx": Data("m".utf8)])
        defer { dir.remove() }
        try FileManager.default.removeItem(at: dir.url.appendingPathComponent("model.onnx"))
        #expect(throws: EmbeddingBundleError.fileNotFound("model.onnx")) {
            try EmbeddingBundle(directory: dir.url).verify()
        }
    }

    @Test func verifyNamesAHashMismatch() throws {
        let dir = try TemporaryBundle(files: ["model.onnx": Data("m".utf8)])
        defer { dir.remove() }
        try Data("changed".utf8).write(to: dir.url.appendingPathComponent("model.onnx"))
        let mismatch = EmbeddingBundleError.hashMismatch(file: "model.onnx", actual: sha("changed"), expected: sha("m"))
        #expect(throws: mismatch) {
            try EmbeddingBundle(directory: dir.url).verify()
        }
    }

    @Test func verifyNamesAnLFSPointer() throws {
        let pointer = Data("""
            version https://git-lfs.github.com/spec/v1
            oid sha256:0137f60d95fc8d0712d2afee6fd259203e1124559bdc3ec0cc853fb0f89170ac
            size 313870864

            """.utf8)
        let dir = try TemporaryBundle(files: ["model.onnx": Data("m".utf8)])
        defer { dir.remove() }
        try pointer.write(to: dir.url.appendingPathComponent("model.onnx"))
        let bundle = try EmbeddingBundle(directory: dir.url)
        #expect(try bundle.holdsLFSPointers())
        #expect(throws: EmbeddingBundleError.lfsPointer("model.onnx")) { try bundle.verify() }
    }

    @Test func sha256OfAFile() throws {
        let dir = try TemporaryBundle(files: ["model.onnx": Data("abc".utf8)])
        defer { dir.remove() }
        #expect(try EmbeddingBundle.sha256(of: dir.url.appendingPathComponent("model.onnx"))
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}

func sha(_ text: String) -> String {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("sha-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: dir) }
    // Hash through the same reader the bundle uses, from a real file.
    try? Data(text.utf8).write(to: dir)
    return (try? EmbeddingBundle.sha256(of: dir)) ?? ""
}

/// A bundle directory in the temporary folder holding `files` and a
/// manifest that lists each with its true sha256. A test removes it with
/// `defer { dir.remove() }`.
struct TemporaryBundle {
    let url: URL

    init(files: [String: Data], maxTokens: Int? = nil) throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("bundle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        var listed: [String: Any] = [:]
        for (name, data) in files {
            let fileURL = url.appendingPathComponent(name)
            try data.write(to: fileURL)
            listed[name] = ["sha256": try EmbeddingBundle.sha256(of: fileURL), "bytes": data.count]
        }
        let manifest: [String: Any] = [
            "name": "test-bundle",
            "output": "sentence_embedding",
            "prefixes": [
                "query": "task: search result | query: ",
                "document": "title: {title} | text: ",
                "document_untitled": "title: none | text: "
            ],
            "max_tokens": maxTokens.map { $0 as Any } ?? NSNull(),
            "truncate_dims": 4,
            "files": listed
        ]
        try JSONSerialization.data(withJSONObject: manifest).write(to: url.appendingPathComponent("manifest.json"))
    }

    func remove() { try? FileManager.default.removeItem(at: url) }
}
