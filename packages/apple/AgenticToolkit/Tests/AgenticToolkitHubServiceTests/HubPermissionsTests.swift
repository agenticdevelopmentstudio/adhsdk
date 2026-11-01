import AgenticDeveloperHubClient
import AgenticToolkitPermissions
import XCTest
@testable import AgenticToolkitHubAuth
@testable import AgenticToolkitHubService

final class HubPermissionsTests: XCTestCase {
    /// The service asks for exactly one grant — its Keychain entry — so a
    /// host's permissions panel never lists grants the hub never uses.
    func testRequiredIsTheSessionKeychainOnly() {
        XCTAssertEqual(HubPermissions.required, [.keychain(service: HubKeychainHelper.service)])
    }
}
