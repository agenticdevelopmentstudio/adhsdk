import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// The one gate every visit passes before it is recorded (the Web Browser
/// Settings Topics recipe's `history-recording-gate`): Record history on,
/// and the pane not in private browsing.
@MainActor
final class BrowserHistoryRecordingTests: XCTestCase {

    /// A private pane records nothing, whatever Record history says.
    func test_privatePaneRecordsNothing() {
        XCTAssertFalse(WebBrowserPaneViewController.recordsHistory(globalRecords: true, paneIsPrivate: true))
    }

    func test_normalPaneRecords() {
        XCTAssertTrue(WebBrowserPaneViewController.recordsHistory(globalRecords: true, paneIsPrivate: false))
    }
}
