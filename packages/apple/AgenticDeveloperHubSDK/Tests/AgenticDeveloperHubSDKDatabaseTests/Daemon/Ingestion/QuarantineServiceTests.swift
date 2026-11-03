import AgenticDeveloperHubSDKCore
import XCTest
import Foundation
@testable import AgenticDeveloperHubSDKDatabase

/// The file-backed half of the quarantine: counts, listing and clearing work
/// from the errors directory and its sidecars alone, with no database attached.
final class QuarantineServiceTests: XCTestCase {

    private var errorsDir: URL!

    override func setUpWithError() throws {
        errorsDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quarantine-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: errorsDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: errorsDir)
    }

    private func quarantineFile(_ name: String) throws -> URL {
        let url = errorsDir.appendingPathComponent(name)
        try Data("{}".utf8).write(to: url)
        return url
    }

    func testAQuarantinedEventIsCountedListedAndNotYetExhausted() throws {
        let service = QuarantineService(errorsDirectory: errorsDir)
        let url = try quarantineFile("error-one.json")

        service.recordInitialQuarantine(eventURL: url, reason: "constraint failed", code: 19, parsed: nil)

        XCTAssertEqual(service.count(), 1, "the sidecar is not a second entry")
        XCTAssertEqual(service.exhaustedCount(), 0)
        let listed = service.list()
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.filename, "error-one.json")
        XCTAssertEqual(listed.first?.reason, "constraint failed")
    }

    func testAnEventQuarantinedWithItsBudgetSpentIsExhausted() throws {
        let service = QuarantineService(errorsDirectory: errorsDir)
        let first = try quarantineFile("error-one.json")
        let second = try quarantineFile("error-two.json")

        service.recordInitialQuarantine(eventURL: first, reason: "r", code: nil, parsed: nil)
        service.recordInitialQuarantine(eventURL: second, reason: "r", code: nil, parsed: nil, retryCount: 3)

        XCTAssertEqual(service.count(), 2)
        XCTAssertEqual(service.exhaustedCount(), 1)
        XCTAssertEqual(service.counts().exhausted, 1)
    }

    func testClearRemovesEveryEventAndSidecar() throws {
        let service = QuarantineService(errorsDirectory: errorsDir)
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)

        service.clear()

        XCTAssertEqual(service.count(), 0)
        let left = try FileManager.default.contentsOfDirectory(atPath: errorsDir.path)
        XCTAssertTrue(left.isEmpty, "nothing, sidecars included, may survive: \(left)")
    }

    // MARK: - Preserving and holding

    private struct Refused: Error {}

    private final class Preserved: @unchecked Sendable {
        private let lock = NSLock()
        private var names: [String] = []
        func add(_ url: URL) { lock.withLock { names.append(url.lastPathComponent) } }
        var all: [String] { lock.withLock { names } }
    }

    private func sampleEvent() -> ParsedEvent {
        ParsedEvent(
            eventType: "PreToolUse",
            timestamp: "2026-04-14T10:00:00Z",
            hookData: ["session_id": "s1"],
            context: nil, accountEmail: "")
    }

    /// Clear hands each event file to `preserveRaw` before it deletes anything.
    func testClearPreservesEveryEventFileFirst() throws {
        let preserved = Preserved()
        let service = QuarantineService(errorsDirectory: errorsDir, preserveRaw: { preserved.add($0) })
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)

        service.clear()

        XCTAssertEqual(preserved.all, ["error-one.json"])
        XCTAssertEqual(service.count(), 0)
    }

    /// A file `preserveRaw` cannot keep is not deleted: it stays, sidecar and all.
    func testClearKeepsAFileItCouldNotPreserve() throws {
        let service = QuarantineService(errorsDirectory: errorsDir, preserveRaw: { _ in throw Refused() })
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)

        service.clear()

        XCTAssertEqual(service.count(), 1, "an unpreserved file must survive clear")
        XCTAssertEqual(service.list().first?.filename, "error-one.json")
    }

    /// An untrackable event a retry discards is preserved before it is deleted.
    func testASkippedRetryPreservesTheFileBeforeDiscardingIt() throws {
        let preserved = Preserved()
        let service = QuarantineService(errorsDirectory: errorsDir, preserveRaw: { preserved.add($0) })
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)

        let result = service.retryDueBatch(
            limit: 10, parse: { _ in .skip(reason: "no session_id") }, ingest: { _ in })

        XCTAssertEqual(result.recovered, 1)
        XCTAssertEqual(preserved.all, ["error-one.json"])
        XCTAssertEqual(service.count(), 0)
    }

    /// A skipped file that cannot be preserved stays quarantined and is charged.
    func testASkippedRetryThatCannotPreserveKeepsTheFile() throws {
        let service = QuarantineService(errorsDirectory: errorsDir, preserveRaw: { _ in throw Refused() })
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)

        let result = service.retryDueBatch(
            limit: 10, parse: { _ in .skip(reason: "no session_id") }, ingest: { _ in })

        XCTAssertEqual(result.stillFailing, 1)
        XCTAssertEqual(service.count(), 1)
    }

    /// Clear deletes the quarantined event files and their sidecars only: a stray
    /// file, a non-`error-` json and an orphaned sidecar are left where they are.
    func testClearLeavesAnythingThatIsNotAQuarantinedEventAlone() throws {
        let preserved = Preserved()
        let service = QuarantineService(errorsDirectory: errorsDir, preserveRaw: { preserved.add($0) })
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)
        _ = try quarantineFile("notes.txt")
        _ = try quarantineFile("renamed-capture.json")
        _ = try quarantineFile("error-gone.meta.json")

        service.clear()

        XCTAssertEqual(preserved.all, ["error-one.json"])
        let left = Set(try FileManager.default.contentsOfDirectory(atPath: errorsDir.path))
        XCTAssertEqual(left, ["notes.txt", "renamed-capture.json", "error-gone.meta.json"])
    }

    /// A retry hands the file to `preserveRaw` before re-feeding it, so the exact
    /// bytes are kept even though the re-capture re-encodes the event.
    func testARetriedEventIsPreservedBeforeItIsIngested() throws {
        let order = Preserved()
        let service = QuarantineService(errorsDirectory: errorsDir, preserveRaw: { order.add($0) })
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)
        let event = sampleEvent()

        let result = service.retryDueBatch(
            limit: 10, parse: { _ in .event(event) },
            ingest: { _ in order.add(URL(fileURLWithPath: "/ingested")) })

        XCTAssertEqual(result.recovered, 1)
        XCTAssertEqual(order.all, ["error-one.json", "ingested"], "preserved first, then ingested")
        XCTAssertEqual(service.count(), 0)
    }

    /// A retried event whose bytes cannot be preserved is not ingested and stays.
    func testARetriedEventThatCannotBePreservedIsKeptAndNotIngested() throws {
        let service = QuarantineService(errorsDirectory: errorsDir, preserveRaw: { _ in throw Refused() })
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)
        let event = sampleEvent()
        let ingested = Preserved()

        let result = service.retryDueBatch(
            limit: 10, parse: { _ in .event(event) }, ingest: { _ in ingested.add(url) })

        XCTAssertEqual(result.stillFailing, 1)
        XCTAssertTrue(ingested.all.isEmpty)
        XCTAssertEqual(service.count(), 1)
    }

    /// A retry whose ingest has nowhere to go (`QuarantineRetryHeld`) keeps the
    /// file untouched and charges nothing against its retry budget.
    func testAHeldRetryKeepsTheFileAndItsBudget() throws {
        let service = QuarantineService(errorsDirectory: errorsDir, maxRetries: 1)
        let url = try quarantineFile("error-one.json")
        service.recordInitialQuarantine(eventURL: url, reason: "r", code: nil, parsed: nil)
        let event = sampleEvent()

        for _ in 0..<3 {
            let result = service.retryDueBatch(
                limit: 10, parse: { _ in .event(event) },
                ingest: { _ in throw QuarantineRetryHeld("no pipeline") })
            XCTAssertEqual(result.recovered, 0)
            XCTAssertEqual(result.stillFailing, 0, "a held retry is not a failure")
        }

        XCTAssertEqual(service.count(), 1)
        XCTAssertEqual(service.exhaustedCount(), 0, "held retries must not spend the budget")
        XCTAssertEqual(service.list().first?.retryCount, 0)
    }
}
