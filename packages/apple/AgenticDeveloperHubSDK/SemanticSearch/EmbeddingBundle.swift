import CryptoKit
import Foundation

/// A model bundle's `manifest.json`, as `symanticsearchmodel` writes it.
/// Everything model-specific is read from here, so swapping the model means
/// swapping the bundle, not code.
public struct EmbeddingBundleManifest: Sendable, Decodable {
    public struct File: Sendable, Decodable {
        public let sha256: String
        public let bytes: Int?
    }

    public let name: String
    public let output: String
    public let prefixes: EmbeddingPrefixes
    /// Always `null` in a bundle this SDK loads: the cap is ours to apply
    /// (``TokenLimit``), and a bundle that asks for its own is refused.
    public let maxTokens: Int?
    public let truncateDims: Int
    public let files: [String: File]

    enum CodingKeys: String, CodingKey {
        case name, output, prefixes, files
        case maxTokens = "max_tokens"
        case truncateDims = "truncate_dims"
    }

    /// The bundle's provenance stamp; see ``SemanticStamp``.
    public func stamp() throws -> String {
        guard let model = files["model.onnx"] else { throw EmbeddingBundleError.missingFile("model.onnx") }
        guard let tokenizer = files["tokenizer.json"] else { throw EmbeddingBundleError.missingFile("tokenizer.json") }
        return try SemanticStamp.make(
            name: name, modelSHA256: model.sha256, tokenizerSHA256: tokenizer.sha256, dimensions: truncateDims)
    }
}

/// Why a bundle could not be used.
public enum EmbeddingBundleError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The directory holds no `manifest.json`.
    case noManifest(String)
    /// The manifest lists no entry for this file.
    case missingFile(String)
    /// A listed file is absent from the directory.
    case fileNotFound(String)
    /// A file is a git LFS pointer, not the file: the bundle was checked out
    /// without `git lfs pull`.
    case lfsPointer(String)
    /// A file's sha256 is not the manifest's.
    case hashMismatch(file: String, actual: String, expected: String)
    /// The manifest asks for a token limit of its own.
    case truncationRequested(Int)
    /// The stamp would not fit the backend's `semantic_stamp varchar(96)`.
    case stampTooLong(String)

    public var description: String {
        switch self {
        case .noManifest(let dir): "\(dir) holds no manifest.json"
        case .missingFile(let name): "the manifest lists no \(name)"
        case .fileNotFound(let name): "\(name) is listed in the manifest but missing from the bundle"
        case .lfsPointer(let name): "\(name) is a git LFS pointer; run git lfs pull in the bundle's checkout"
        case let .hashMismatch(file, actual, expected): "\(file) has sha256 \(actual), the manifest says \(expected)"
        case .truncationRequested(let limit):
            "this SDK applies its own token limit, and the manifest asks for max_tokens \(limit)"
        case .stampTooLong(let stamp): "stamp \(stamp) is longer than semantic_stamp holds"
        }
    }
}

/// The provenance stamp stored beside every vector.
///
/// It is byte-for-byte the backend's `stampFor` (`llm/local-embedder.ts`):
/// `<bundle name>:<first 12 hex of model.onnx's sha256>:<first 12 hex of
/// tokenizer.json's sha256>:<dimensions kept>`, at most 96 characters. A vector
/// whose stamp is not the running embedder's is stale and is never compared.
public enum SemanticStamp {
    /// The longest stamp the backend's `semantic_stamp` column holds.
    public static let maxLength = 96

    public static func make(
        name: String, modelSHA256: String, tokenizerSHA256: String, dimensions: Int
    ) throws -> String {
        let stamp = "\(name):\(modelSHA256.prefix(12)):\(tokenizerSHA256.prefix(12)):\(dimensions)"
        // UTF-16 code units, as the backend's `stamp.length` counts them, so
        // both sides refuse exactly the same names.
        guard stamp.utf16.count <= maxLength else { throw EmbeddingBundleError.stampTooLong(stamp) }
        return stamp
    }
}

/// A model bundle directory: `manifest.json` beside the files it lists. The
/// SDK never downloads one; an app ships it inside itself (consuming
/// `symanticsearchmodel` as a submodule) and passes its directory URL.
public struct EmbeddingBundle: Sendable {
    public let directory: URL
    public let manifest: EmbeddingBundleManifest

    /// Reads the manifest. Refuses one that asks for its own token limit.
    /// Checks no hashes; call ``verify()`` for that.
    public init(directory: URL) throws {
        let manifestURL = directory.appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw EmbeddingBundleError.noManifest(directory.path)
        }
        let manifest = try JSONDecoder().decode(EmbeddingBundleManifest.self, from: Data(contentsOf: manifestURL))
        if let limit = manifest.maxTokens { throw EmbeddingBundleError.truncationRequested(limit) }
        self.directory = directory
        self.manifest = manifest
    }

    public func url(of file: String) -> URL { directory.appendingPathComponent(file) }

    /// Fails unless every file the manifest lists is present with its
    /// recorded sha256. A bundle checked out without git LFS holds pointer
    /// files instead, and this names that rather than reporting a bare hash
    /// mismatch.
    public func verify() throws {
        for (name, file) in manifest.files.sorted(by: { $0.key < $1.key }) {
            let url = url(of: name)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw EmbeddingBundleError.fileNotFound(name)
            }
            if try Self.isLFSPointer(url) { throw EmbeddingBundleError.lfsPointer(name) }
            let actual = try Self.sha256(of: url)
            guard actual == file.sha256 else {
                throw EmbeddingBundleError.hashMismatch(file: name, actual: actual, expected: file.sha256)
            }
        }
    }

    /// True when any listed file is a git LFS pointer — the cheap check a test
    /// uses to skip, without hashing 350 MB.
    public func holdsLFSPointers() throws -> Bool {
        try manifest.files.keys.contains { name in
            let url = url(of: name)
            return FileManager.default.fileExists(atPath: url.path) ? try Self.isLFSPointer(url) : false
        }
    }

    /// The sha256 of a file as lowercase hex, read a megabyte at a time.
    public static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// The first line every git LFS pointer file starts with.
    static let lfsPointerHeader = Data("version https://git-lfs.github.com/spec/v1".utf8)

    static func isLFSPointer(_ url: URL) throws -> Bool {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let head = try handle.read(upToCount: lfsPointerHeader.count) ?? Data()
        return head == lfsPointerHeader
    }
}
