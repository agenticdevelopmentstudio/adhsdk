import Foundation
import XCTest
@testable import AgenticDeveloperHubSDKDatabase

final class MockProviderPipelineTests: XCTestCase {

    private var tmpDir: URL!

    override func setUpWithError() throws {
        let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6))
        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sten-pipe-\(suffix)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    private func path(_ name: String) -> String { tmpDir.appendingPathComponent(name).path }

    private func records(_ count: Int, pad: Int = 0, prefix: String = "r") -> [RawRecord] {
        let ops = ["event", "session", "turn", "message"]
        return (0..<count).map { index in
            MockProvider.record(key: "\(prefix)\(index)", op: ops[index % ops.count], session: "s\(index % 9)",
                                t: 1_800_000_000 + Double((index * 13) % 400), n: index, pad: pad)
        }
    }

    private func replayDump(_ archive: RawArchive, to name: String) throws -> [String] {
        let store = try EventStore(path: path(name))
        let report = try Replayer.replay(archive: archive, normalizer: MockProvider(), into: store, chunk: 100)
        XCTAssertEqual(report.failed, 0, "\(report.failures)")
        return try store.canonicalDump()
    }

    func testEndToEndThousandRecordsWithRandomCrashes() throws {
        let spool = try ProviderSpool(path: path("ingest.db"), provider: "mock")
        let archive = try RawArchive(path: path("raw.db"), provider: "mock")
        let store = try EventStore(path: path("events.db"))
        let input = records(1000)
        var rng = ProviderConformance.SeededGenerator(seed: 42)
        var crashes = 0
        var next = 0
        var pass = 0

        while true {
            if next >= input.count, try spool.pendingCount() == 0 { break }
            if next < input.count {
                let end = min(input.count, next + Int.random(in: 20...80, using: &rng))
                try spool.append(Array(input[next..<end]))
                next = end
            }
            // The first five passes crash at each DrainStep in turn, deterministically;
            // after that about 10 % of passes crash at a random step.
            var crashStep: DrainStep?
            if pass < DrainStep.allCases.count {
                crashStep = DrainStep.allCases[pass]
            } else if Int.random(in: 0..<10, using: &rng) == 0 {
                crashStep = DrainStep.allCases.randomElement(using: &rng)
            }
            struct Crash: Error {}
            let step = crashStep
            // A fresh drainer each pass models a restarted process.
            let drainer = try PipelineDrainer(
                spool: spool, archive: archive, normalizer: MockProvider(), store: store, batchSize: 50,
                faultInjector: { if $0 == step { throw Crash() } })
            if drainer.drainOnce().failed { crashes += 1 }
            pass += 1
            XCTAssertLessThan(pass, 2000, "pipeline is not converging")
            if pass >= 2000 { break }
        }

        XCTAssertGreaterThanOrEqual(crashes, DrainStep.allCases.count)
        for record in input {
            XCTAssertNotNil(try archive.id(forDedupKey: record.dedupKey), "archive lacks \(record.dedupKey)")
        }
        XCTAssertEqual(try archive.count(), input.count)
        XCTAssertEqual(try store.canonicalDump(), try replayDump(archive, to: "replay.db"))
        // The event and session ops each emit one event; turn and message ops one turn / message.
        let counts = try store.counts()
        XCTAssertEqual(counts.events, 500)
        XCTAssertEqual(counts.turns, 250)
        XCTAssertEqual(counts.messages, 250)
    }

    func testHugePayloadsSurvive() throws {
        let spool = try ProviderSpool(path: path("ingest.db"), provider: "mock")
        let archive = try RawArchive(path: path("raw.db"), provider: "mock")
        let store = try EventStore(path: path("events.db"))
        let input = (0..<10).map {
            MockProvider.record(key: "huge\($0)", op: "event", t: 1_800_000_000 + Double($0), n: $0, pad: 10_000_000)
        }
        try spool.append(input)
        let drainer = try PipelineDrainer(spool: spool, archive: archive, normalizer: MockProvider(), store: store,
                                          batchSize: 2)
        let outcome = drainer.drainUntilEmpty()
        XCTAssertFalse(outcome.failed, outcome.failureReason ?? "")
        XCTAssertEqual(try spool.pendingCount(), 0)
        XCTAssertEqual(try store.counts().events, 10)
        for record in input {
            let id = try XCTUnwrap(try archive.id(forDedupKey: record.dedupKey))
            XCTAssertEqual(try archive.record(id: id)?.record.payload, record.payload)
        }
    }

    func testRebuildFromArchiveAfterDeletingEventsDB() throws {
        let spool = try ProviderSpool(path: path("ingest.db"), provider: "mock")
        let archive = try RawArchive(path: path("raw.db"), provider: "mock")
        var before: [String] = []
        do {
            let store = try EventStore(path: path("events.db"))
            try spool.append(records(300))
            try PipelineDrainer(spool: spool, archive: archive, normalizer: MockProvider(), store: store)
                .drainUntilEmpty()
            before = try store.canonicalDump()
        }
        XCTAssertFalse(before.isEmpty)
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: path("events.db") + suffix)
        }
        let rebuilt = try EventStore(path: path("events.db"))
        XCTAssertEqual(try rebuilt.counts().events, 0)
        let report = try Replayer.replay(archive: archive, normalizer: MockProvider(), into: rebuilt)
        XCTAssertEqual(report.failed, 0)
        XCTAssertEqual(try rebuilt.canonicalDump(), before)
    }

    /// Source -> spool -> drainer, with the source crashing on both sides of its append
    /// and restarting from the cursor it committed: nothing lost, nothing spooled twice.
    func testMockSourceCursorSurvivesCrashesEndToEnd() throws {
        let fixture = tmpDir.appendingPathComponent("transcript.jsonl")
        let ops = ["event", "session", "turn", "message"]
        try MockSource.writeFixture((0..<120).map {
            MockProvider.payload(op: ops[$0 % ops.count], session: "s\($0 % 4)", t: 1_800_000_000 + Double($0), n: $0)
        }, to: fixture)
        let spool = try ProviderSpool(path: path("ingest.db"), provider: "mock")
        let archive = try RawArchive(path: path("raw.db"), provider: "mock")
        let store = try EventStore(path: path("events.db"))
        let drainer = try PipelineDrainer(spool: spool, archive: archive, normalizer: MockProvider(), store: store,
                                          batchSize: 30)
        struct Crash: Error {}
        // Poll 2 crashes before its append, poll 4 after it; each crash restarts the source.
        let plan: [Int: SourceStep] = [2: .beforeAppend, 4: .afterAppend]
        var poll = 0
        var crashes = 0
        while poll < 100 {
            poll += 1
            let step = plan[poll]
            let source = MockSource(fileURL: fixture, maxRecordsPerPoll: 25,
                                    faultInjector: { if $0 == step { throw Crash() } })
            do {
                if try source.poll(into: spool) == 0 { break }
            } catch is Crash {
                crashes += 1
            }
            drainer.drainUntilEmpty()
        }
        XCTAssertEqual(crashes, 2)
        XCTAssertEqual(try spool.pendingCount(), 0)
        XCTAssertEqual(try archive.count(), 120)
        let size = try Data(contentsOf: fixture).count
        let source = MockSource(fileURL: fixture)
        XCTAssertEqual(try spool.sourceState(source.cursorKey), Data(String(size).utf8))
        XCTAssertEqual(try store.counts().events, 60)
        XCTAssertEqual(try store.counts().messages, 30)
        XCTAssertEqual(try store.canonicalDump(), try replayDump(archive, to: "replay.db"))
    }
}
