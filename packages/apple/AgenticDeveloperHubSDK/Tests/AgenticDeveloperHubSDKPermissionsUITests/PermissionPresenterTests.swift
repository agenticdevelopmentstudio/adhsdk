import Foundation
import Testing
import AgenticDeveloperHubSDKPermissions
@testable import AgenticDeveloperHubSDKPermissionsUI

private struct FixedChecker: PermissionChecking {
    let result: PermissionStatus
    func status(_ permission: Permission) async -> PermissionStatus { result }
    func request(_ permission: Permission) async -> PermissionStatus { result }
}

@MainActor
@Suite("Permission presenter", .serialized)
struct PermissionPresenterTests {

    private func opened(_ status: PermissionStatus) async -> [URL] {
        var urls: [URL] = []
        let original = PermissionPresenter.openURL
        PermissionPresenter.openURL = { urls.append($0) }
        defer { PermissionPresenter.openURL = original }
        await PermissionPresenter.present(
            .fullDiskAccess(statusFilePath: "/tmp/none"), shownAs: status, using: FixedChecker(result: status))
        return urls
    }

    @Test("Full Disk Access always opens the Privacy_AllFiles pane, whatever the status",
          arguments: [PermissionStatus.granted, .denied, .undetermined])
    func fullDiskAccessOpensItsPane(status: PermissionStatus) async {
        let urls = await opened(status)
        #expect(urls.map(\.absoluteString)
            == ["x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"])
    }
}
