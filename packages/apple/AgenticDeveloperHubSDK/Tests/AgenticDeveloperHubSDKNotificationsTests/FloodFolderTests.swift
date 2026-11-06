import XCTest
@testable import AgenticDeveloperHubSDKNotifications

final class FloodFolderTests: XCTestCase {

    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func notice(_ source: String = "ci", urgency: Notice.Urgency = .fyi) -> Notice {
        Notice(source: source, title: "t", urgency: urgency)
    }

    func testFloodFoldsSixthNotice() {
        var folder = FloodFolder()
        for index in 0..<5 {
            XCTAssertEqual(folder.admit(notice(), at: start.addingTimeInterval(Double(index))), .show)
        }
        XCTAssertEqual(folder.admit(notice(), at: start.addingTimeInterval(5)), .fold(source: "ci", count: 6))
        XCTAssertEqual(folder.admit(notice(), at: start.addingTimeInterval(6)), .fold(source: "ci", count: 7))
    }

    func testNowIsNeverFolded() {
        var folder = FloodFolder()
        for index in 0..<20 {
            let urgency: Notice.Urgency = index.isMultiple(of: 2) ? .now : .emergency
            XCTAssertEqual(folder.admit(notice(urgency: urgency), at: start), .show)
        }
        // Urgent notices were not counted, so a fresh burst still gets its five.
        for _ in 0..<5 {
            XCTAssertEqual(folder.admit(notice(), at: start), .show)
        }
    }

    func testQuietWindowResets() {
        var folder = FloodFolder()
        for _ in 0..<6 { _ = folder.admit(notice(), at: start) }
        XCTAssertEqual(folder.admit(notice(), at: start.addingTimeInterval(20)), .show)
        XCTAssertEqual(folder.admit(notice(), at: start.addingTimeInterval(21)), .show)
    }

    func testSourcesCountedSeparately() {
        var folder = FloodFolder()
        for _ in 0..<5 { _ = folder.admit(notice("ci"), at: start) }
        XCTAssertEqual(folder.admit(notice("ci"), at: start), .fold(source: "ci", count: 6))
        XCTAssertEqual(folder.admit(notice("mail"), at: start), .show)
    }

    func testCustomConfiguration() {
        var folder = FloodFolder(configuration: .init(threshold: 1, window: 5))
        XCTAssertEqual(folder.admit(notice(), at: start), .show)
        XCTAssertEqual(folder.admit(notice(), at: start), .fold(source: "ci", count: 2))
    }
}
