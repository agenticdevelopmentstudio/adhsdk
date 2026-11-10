import Foundation
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

/// Wraps the mock normalizer and perturbs its output.
private struct PerturbedNormalizer: Normalizer {
    enum Mode {
        case impure, unstableKeys, wrongRawRef, stateful, throwsAlways, emptyBatches, mangledKey, dropsOne, nonFinite
    }
    let provider = "mock"
    let mode: Mode
    /// Carries state across calls, so output depends on history rather than on the record.
    private let calls = CallCounter()

    private final class CallCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0
        func next() -> Int { lock.lock(); defer { lock.unlock() }; count += 1; return count }
    }

    struct Boom: Error {}

    func normalize(_ record: ArchivedRecord) throws -> NormalizedBatch {
        if mode == .throwsAlways { throw Boom() }
        if mode == .emptyBatches { return NormalizedBatch() }
        if mode == .dropsOne && record.record.dedupKey == "k8" { return NormalizedBatch() }
        var batch = try MockProvider().normalize(record)
        switch mode {
        case .impure:
            for index in batch.events.indices { batch.events[index].summary = "\(Date().timeIntervalSince1970)" }
        case .unstableKeys:
            for index in batch.events.indices { batch.events[index].dedupKey = UUID().uuidString }
        case .wrongRawRef:
            for index in batch.events.indices { batch.events[index].rawRef += 1 }
        case .stateful:
            let number = calls.next()
            for index in batch.events.indices { batch.events[index].summary = "call \(number)" }
        case .mangledKey:
            // Keys stay unique and stable, but one fixture's rows no longer carry its dedup key.
            for index in batch.events.indices where record.record.dedupKey == "k4" {
                batch.events[index].dedupKey = "mangled-\(batch.events[index].dedupKey)"
            }
        case .nonFinite:
            for index in batch.events.indices where record.record.dedupKey == "k4" {
                batch.events[index].attrs["ratio"] = .number(.nan)
            }
        case .throwsAlways, .emptyBatches, .dropsOne:
            break
        }
        return batch
    }
}

final class MockProviderConformanceTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-conf-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    static func fixtures() -> [RawRecord] {
        var out: [RawRecord] = []
        let ops = ["event", "session", "turn", "message"]
        for index in 0..<193 {
            // Times deliberately out of order, with ties.
            let time = 1_800_000_000 + Double((index * 37) % 50)
            out.append(MockProvider.record(key: "k\(index)", op: ops[index % ops.count],
                                           session: "s\(index % 5)", t: time, n: index))
        }
        for index in 0..<5 {
            out.append(MockProvider.record(key: "big\(index)", op: "event", session: "s1",
                                           t: 1_800_000_100 + Double(index), n: 1000 + index, pad: 1_000_000))
        }
        // Later and earlier observations of existing turns (k2 and k6 are turn records), with an
        // as_of tie, so turn merging is exercised across records and batches.
        for index in 0..<6 {
            out.append(MockProvider.record(key: "u\(index)", op: "usage", session: "s2",
                                           t: 1_800_000_000 + Double([30, 1, 30, 44, 12, 0][index]),
                                           n: 500 + index, turn: index % 2 == 0 ? "k2#turn" : "k6#turn"))
        }
        out.append(MockProvider.record(key: "u-own", op: "usage", session: "s3", t: 1_800_000_007, n: 600))
        out.append(MockProvider.record(key: "bad0", op: "bad", t: 1_800_000_200))
        // Duplicate deliveries of earlier records.
        out.append(out[3])
        out.append(out[10])
        out.append(out[50])
        return out
    }

    func testMockProviderConforms() throws {
        let failures = try ProviderConformance.check(
            normalizer: MockProvider(), fixtures: Self.fixtures(), malformedKeys: ["bad0"],
            workDirectory: tmpDir.appendingPathComponent("w"))
        XCTAssertEqual(failures, [], "\(failures)")
    }

    func testConformanceCatchesImpureNormalizer() throws {
        let failures = try ProviderConformance.check(
            normalizer: PerturbedNormalizer(mode: .impure), fixtures: Self.fixtures(),
            workDirectory: tmpDir.appendingPathComponent("w"))
        XCTAssertTrue(failures.contains { $0.check == "purity" }, "\(failures)")
    }

    func testConformanceCatchesUnstableKeys() throws {
        let failures = try ProviderConformance.check(
            normalizer: PerturbedNormalizer(mode: .unstableKeys), fixtures: Self.fixtures(),
            workDirectory: tmpDir.appendingPathComponent("w"))
        XCTAssertTrue(failures.contains { $0.check == "keys" }, "\(failures)")
    }

    /// Failures from a perturbed adapter. `wellFormedOnly` drops `bad0` so no unrelated check fires first.
    private func failures(_ mode: PerturbedNormalizer.Mode,
                          wellFormedOnly: Bool = true) throws -> [ConformanceFailure] {
        let fixtures = wellFormedOnly ? Self.fixtures().filter { $0.dedupKey != "bad0" } : Self.fixtures()
        return try ProviderConformance.check(
            normalizer: PerturbedNormalizer(mode: mode), fixtures: fixtures,
            malformedKeys: wellFormedOnly ? [] : ["bad0"], workDirectory: tmpDir.appendingPathComponent("w"))
    }

    func testConformanceCatchesWrongRawRef() throws {
        let found = try failures(.wrongRawRef, wellFormedOnly: false)
        XCTAssertTrue(found.contains { $0.check == "rawRef" && $0.detail.contains("emitted rawRef") }, "\(found)")
    }

    func testConformanceCatchesLiveReplayDivergenceAndRedeliveryDrift() throws {
        let checks = Set(try failures(.stateful, wellFormedOnly: false).map(\.check))
        XCTAssertTrue(checks.contains("liveEqualsReplay"), "\(checks)")
        XCTAssertTrue(checks.contains("idempotentRedelivery"), "\(checks)")
    }

    func testConformanceCatchesNormalizerThatThrowsOnEverything() throws {
        let found = try failures(.throwsAlways)
        XCTAssertTrue(found.contains { $0.check == "normalizerThrew" && $0.detail.contains("threw") }, "\(found)")
    }

    func testConformanceCatchesNormalizerThatEmitsNothing() throws {
        let found = try failures(.emptyBatches)
        XCTAssertTrue(found.contains { $0.check == "emptyBatch" && $0.detail.contains("yielded no rows") }, "\(found)")
    }

    func testConformanceCatchesFixtureWhoseRowsNeverReachTheStore() throws {
        let mangled = try failures(.mangledKey)
        XCTAssertEqual(mangled.filter { $0.check == "unstoredFixture" }.map(\.detail),
                       ["no event, turn or message in the store is keyed by k4"], "\(mangled)")
        let dropped = try failures(.dropsOne)
        XCTAssertTrue(dropped.contains { $0.check == "unstoredFixture" && $0.detail.hasSuffix("by k8") }, "\(dropped)")
    }

    func testConformanceCatchesNaNAndStopsBeforeTheStoreChecks() throws {
        let found = try failures(.nonFinite)
        XCTAssertEqual(found.filter { $0.check == "nonFiniteNumber" }.map(\.detail),
                       ["record k4 emitted NaN or infinity at k4#0.attrs.ratio"], "\(found)")
        // The store-based checks cannot run on unstorable rows, so they are skipped.
        XCTAssertFalse(found.contains { $0.check == "liveEqualsReplay" || $0.check == "crashRecovery" }, "\(found)")
    }

    func testConformanceCatchesKeyCollisionInFixtures() throws {
        var fixtures = Self.fixtures().filter { $0.dedupKey != "bad0" }
        fixtures.append(MockProvider.record(key: "k5", op: "event", t: 1_800_000_999, n: 9_999))
        let found = try ProviderConformance.check(normalizer: MockProvider(), fixtures: fixtures,
                                                  workDirectory: tmpDir.appendingPathComponent("w"))
        XCTAssertEqual(found.filter { $0.check == "keyCollision" }.count, 1, "\(found)")
        XCTAssertTrue(found.contains { $0.check == "keyCollision" && $0.detail.contains("k5") }, "\(found)")
    }

    /// Shared turn keys are legal (`testMockProviderConforms` has them); a turn key that is
    /// another record's event key is not.
    func testConformanceCatchesTurnKeyThatReusesAnEventKey() throws {
        var fixtures = Self.fixtures().filter { $0.dedupKey != "bad0" }
        // A usage record whose turn key is k0's event key.
        fixtures.append(MockProvider.record(key: "u-clash", op: "usage", t: 1_800_000_001, n: 7, turn: "k0#0"))
        let found = try ProviderConformance.check(normalizer: MockProvider(), fixtures: fixtures,
                                                  workDirectory: tmpDir.appendingPathComponent("w"))
        XCTAssertTrue(found.contains { $0.check == "keys" && $0.detail.contains("k0#0") }, "\(found)")
    }

    // MARK: - Sources

    private func writeSourceFixture(_ count: Int = 60) throws -> URL {
        let url = tmpDir.appendingPathComponent("source-\(UUID().uuidString).jsonl")
        let ops = ["event", "session", "turn", "message"]
        try MockSource.writeFixture((0..<count).map {
            MockProvider.payload(op: ops[$0 % ops.count], session: "s\($0 % 3)", t: 1_800_000_000 + Double($0), n: $0)
        }, to: url)
        return url
    }

    func testMockSourceConforms() throws {
        let url = try writeSourceFixture()
        let failures = try ProviderConformance.checkSource(
            provider: "mock", workDirectory: tmpDir.appendingPathComponent("w")) { injector in
            MockSource(fileURL: url, maxRecordsPerPoll: 7, faultInjector: injector)
        }
        XCTAssertEqual(failures, [], "\(failures)")
    }

    func testSourceCheckCatchesConstantDedupKey() throws {
        let url = try writeSourceFixture()
        let failures = try ProviderConformance.checkSource(
            provider: "mock", workDirectory: tmpDir.appendingPathComponent("w")) { injector in
            MockSource(fileURL: url, maxRecordsPerPoll: 7, deriveKey: { _, _ in "same" }, faultInjector: injector)
        }
        let checks = Set(failures.map(\.check))
        XCTAssertTrue(checks.contains("keyCollision"), "\(failures)")
        XCTAssertTrue(checks.contains("sourceDuplicated"), "\(failures)")
    }

    func testSourceCheckCatchesCursorCommittedApartFromAppend() throws {
        let url = try writeSourceFixture()
        let failures = try ProviderConformance.checkSource(
            provider: "mock", workDirectory: tmpDir.appendingPathComponent("w")) { injector in
            CursorFirstSource(fileURL: url, faultInjector: injector)
        }
        XCTAssertTrue(failures.contains { $0.check == "sourceCrash" && $0.detail.contains("beforeAppend") },
                      "\(failures)")
    }

    func testSourceCheckCatchesSourceThatFindsNothing() throws {
        let url = tmpDir.appendingPathComponent("empty.jsonl")
        try MockSource.writeFixture([], to: url)
        let failures = try ProviderConformance.checkSource(
            provider: "mock", workDirectory: tmpDir.appendingPathComponent("w")) { injector in
            MockSource(fileURL: url, faultInjector: injector)
        }
        let checks = Set(failures.map(\.check))
        XCTAssertTrue(checks.contains("sourceEmpty"), "\(failures)")
        XCTAssertTrue(checks.contains("sourceCrash"), "a fault that never fires is reported")
    }

    func testConformanceNeverRemovesCallersDirectory() throws {
        let work = tmpDir.appendingPathComponent("w")
        try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
        let marker = work.appendingPathComponent("keep.txt")
        try Data("x".utf8).write(to: marker)
        _ = try ProviderConformance.check(normalizer: MockProvider(), fixtures: Self.fixtures(),
                                          malformedKeys: ["bad0"], workDirectory: work)
        XCTAssertTrue(FileManager.default.fileExists(atPath: marker.path))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: work.path), ["keep.txt"])
    }
}

/// Breaks the source contract: commits the cursor in its own transaction before the
/// append, so a crash between them skips the batch.
private struct CursorFirstSource: IngestSource {
    let provider = "mock"
    let fileURL: URL
    let faultInjector: (@Sendable (SourceStep) throws -> Void)?
    private let key = "cursor-first"

    init(fileURL: URL, faultInjector: (@Sendable (SourceStep) throws -> Void)?) {
        self.fileURL = fileURL
        self.faultInjector = faultInjector
    }

    func poll(into spool: ProviderSpool) throws -> Int {
        let start = (try spool.sourceState(key)).flatMap { String(bytes: $0, encoding: .utf8) }.flatMap { Int($0) } ?? 0
        let data = try Data(contentsOf: fileURL)
        var offset = start
        var records: [RawRecord] = []
        while records.count < 5, offset < data.count,
              let newline = data[offset...].firstIndex(of: UInt8(ascii: "\n")) {
            records.append(RawRecord(provider: provider, sourceKind: "transcript", dedupKey: "line@\(offset)",
                                     receivedAt: Date(timeIntervalSince1970: 0), payload: Data(data[offset..<newline])))
            offset = newline + 1
        }
        guard !records.isEmpty else { return 0 }
        try spool.setSourceState(key, Data(String(offset).utf8))
        try faultInjector?(.beforeAppend)
        try spool.append(records)
        try faultInjector?(.afterAppend)
        return records.count
    }
}
