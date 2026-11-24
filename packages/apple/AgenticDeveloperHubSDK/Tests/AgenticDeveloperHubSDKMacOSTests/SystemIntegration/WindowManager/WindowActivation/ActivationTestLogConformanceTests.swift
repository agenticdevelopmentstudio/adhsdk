import Foundation
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors window-activation-010 ... 013 for `ActivationTestLog`.
final class ActivationTestLogConformanceTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ActivationTestLogConformance-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    func testV010_memoryOnlyLogFormatsTimestampedEntries() throws {
        let log = ActivationTestLog(fileURL: nil)
        log.append("a")
        log.append("b")

        XCTAssertNil(log.logPath)
        let lines = log.text.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[2], "")
        XCTAssertTrue(log.text.hasSuffix("\n"))

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for (line, message) in zip(lines.prefix(2), ["a", "b"]) {
            XCTAssertTrue(line.hasPrefix("["))
            let closing = try XCTUnwrap(line.firstIndex(of: "]"))
            let timestamp = String(line[line.index(after: line.startIndex)..<closing])
            XCTAssertNotNil(formatter.date(from: timestamp), "not an ISO 8601 fractional timestamp: \(timestamp)")
            XCTAssertTrue(timestamp.contains("."), "timestamp lacks fractional seconds: \(timestamp)")
            XCTAssertEqual(String(line[closing...]), "] \(message)")
        }
    }

    func testV011_clearEmptiesInMemoryLog() {
        let log = ActivationTestLog(fileURL: nil)
        log.append("one")
        log.append("two")
        XCTAssertFalse(log.text.isEmpty)

        log.clear()

        XCTAssertEqual(log.text, "")
    }

    func testV012_fileBackedLogCreatesFileAndMirrorsText() throws {
        let fileURL = tempDirectory.appendingPathComponent("missing.log")
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        let log = ActivationTestLog(fileURL: fileURL)
        XCTAssertEqual(log.logPath, fileURL.path)

        log.append("x")
        log.append("y")

        let onDisk = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(onDisk, log.text)
        XCTAssertEqual(onDisk.split(separator: "\n").count, 2)
        XCTAssertTrue(onDisk.contains("] x\n"))
        XCTAssertTrue(onDisk.hasSuffix("] y\n"))
    }

    func testV013_clearLeavesZeroByteFile() throws {
        let fileURL = tempDirectory.appendingPathComponent("clear.log")
        let log = ActivationTestLog(fileURL: fileURL)
        log.append("first")
        log.append("second")
        XCTAssertGreaterThan(try Data(contentsOf: fileURL).count, 0)

        log.clear()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(try Data(contentsOf: fileURL).count, 0)
        XCTAssertEqual(log.text, "")
    }
}
