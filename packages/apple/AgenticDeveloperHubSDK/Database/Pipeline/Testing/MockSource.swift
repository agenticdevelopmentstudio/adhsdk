import Foundation

/// A scripted `IngestSource` for exercising the source contract without a real agent.
/// Reads a JSONL fixture file (one `MockProvider.payload` per line) from a byte
/// cursor kept in the spool's `source_state`, and appends records and cursor in one
/// transaction (`ProviderSpool.append(_:settingSourceState:to:)`). Lives in the
/// framework (no XCTest) so any test target can use it.
public struct MockSource: IngestSource {
    public let provider = "mock"
    public let fileURL: URL
    /// The `source_state` key holding the cursor: the byte offset just past the last
    /// consumed line, as decimal text.
    public let cursorKey: String
    /// At most this many records per `poll`, so a fixture takes several polls.
    public let maxRecordsPerPoll: Int
    private let deriveKey: @Sendable (_ line: Data, _ offset: Int) -> String
    private let faultInjector: (@Sendable (SourceStep) throws -> Void)?

    /// `deriveKey` gets the line's bytes (no newline) and its starting byte offset; the
    /// default key is `<file name>@<offset>`, which is stable because the file is
    /// append-only.
    public init(fileURL: URL, cursorKey: String? = nil, maxRecordsPerPoll: Int = 50,
                deriveKey: (@Sendable (_ line: Data, _ offset: Int) -> String)? = nil,
                faultInjector: (@Sendable (SourceStep) throws -> Void)? = nil) {
        self.fileURL = fileURL
        self.cursorKey = cursorKey ?? "mock-source:\(fileURL.lastPathComponent)"
        self.maxRecordsPerPoll = max(1, maxRecordsPerPoll)
        let name = fileURL.lastPathComponent
        self.deriveKey = deriveKey ?? { _, offset in "\(name)@\(offset)" }
        self.faultInjector = faultInjector
    }

    public func poll(into spool: ProviderSpool) throws -> Int {
        let start = try cursor(in: spool)
        let data = (try? Data(contentsOf: fileURL)) ?? Data()
        guard start < data.count else { return 0 }
        var records: [RawRecord] = []
        var offset = start
        // Only complete lines: a line still being written has no newline yet.
        while records.count < maxRecordsPerPoll,
              let newline = data[offset...].firstIndex(of: UInt8(ascii: "\n")) {
            let line = Data(data[offset..<newline])
            if !line.isEmpty {
                records.append(RawRecord(
                    provider: provider, sourceKind: "transcript", dedupKey: deriveKey(line, offset),
                    receivedAt: Self.receivedAt(line), payload: line))
            }
            offset = newline + 1
        }
        guard offset > start else { return 0 }
        try faultInjector?(.beforeAppend)
        try spool.append(records, settingSourceState: cursorKey, to: Data(String(offset).utf8))
        try faultInjector?(.afterAppend)
        return records.count
    }

    /// Writes `payloads` as a JSONL fixture file, one per line, replacing any file there.
    public static func writeFixture(_ payloads: [Data], to url: URL) throws {
        var data = Data()
        for payload in payloads {
            data.append(payload)
            data.append(UInt8(ascii: "\n"))
        }
        try data.write(to: url, options: .atomic)
    }

    private func cursor(in spool: ProviderSpool) throws -> Int {
        guard let stored = try spool.sourceState(cursorKey),
              let text = String(data: stored, encoding: .utf8), let value = Int(text) else { return 0 }
        return max(0, value)
    }

    /// The payload's `"t"` (epoch seconds), or the epoch when it has none.
    private static func receivedAt(_ line: Data) -> Date {
        let object = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any]
        return Date(timeIntervalSince1970: object?["t"] as? Double ?? 0)
    }
}
