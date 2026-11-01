import Foundation
import XCTest
@testable import AgenticToolkitDatabase

/// Wraps the mock normalizer and perturbs its output.
private struct PerturbedNormalizer: Normalizer {
    enum Mode { case impure, unstableKeys, wrongRawRef, stateful, throwsAlways, emptyBatches }
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
        case .throwsAlways, .emptyBatches:
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

    private func failingChecks(_ mode: PerturbedNormalizer.Mode) throws -> Set<String> {
        let failures = try ProviderConformance.check(
            normalizer: PerturbedNormalizer(mode: mode), fixtures: Self.fixtures(), malformedKeys: ["bad0"],
            workDirectory: tmpDir.appendingPathComponent("w"))
        return Set(failures.map(\.check))
    }

    func testConformanceCatchesWrongRawRef() throws {
        XCTAssertTrue(try failingChecks(.wrongRawRef).contains("rawRef"))
    }

    func testConformanceCatchesLiveReplayDivergenceAndRedeliveryDrift() throws {
        let checks = try failingChecks(.stateful)
        XCTAssertTrue(checks.contains("liveEqualsReplay"), "\(checks)")
        XCTAssertTrue(checks.contains("idempotentRedelivery"), "\(checks)")
    }

    func testConformanceCatchesNormalizerThatThrowsOnEverything() throws {
        XCTAssertTrue(try failingChecks(.throwsAlways).contains("dataLoss"))
    }

    func testConformanceCatchesNormalizerThatEmitsNothing() throws {
        XCTAssertTrue(try failingChecks(.emptyBatches).contains("dataLoss"))
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
