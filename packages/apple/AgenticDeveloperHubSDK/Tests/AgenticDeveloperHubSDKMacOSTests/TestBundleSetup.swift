import Foundation

/// The bundle's `NSPrincipalClass`: XCTest makes one before it runs a test.
///
/// It turns off AppKit's automatic window animations for the test process.
/// Ordering a window front or closing it starts an `_NSWindowTransformAnimation`
/// that AppKit runs to completion on a global-queue worker thread. In the test
/// host that animation never finishes, so every window the suite shows keeps
/// one worker forever. Past libdispatch's limit of 64, the global queues stop
/// running anything: git reads time out after 30 s (`ReviewGitTests`,
/// `ProjectWindowManagerControllerTests`), and a test that resumes from
/// `DispatchQueue.global()` (`LSPEditorAnnotationTests`) hangs the whole run.
/// Which tests failed depended on how many windows came before them.
///
/// The argument domain is the highest-priority one and is never written to
/// disk, so this changes nothing outside the process.
@objc(AgenticDeveloperHubSDKMacOSTestBundleSetup)
final class TestBundleSetup: NSObject {
    override init() {
        var arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        arguments["NSAutomaticWindowAnimationsEnabled"] = false
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
        super.init()
    }
}
