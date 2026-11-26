import AgenticDeveloperHubSDKCore
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
///
/// It also gives `UserSettings.shared` an in-memory store of this process's
/// own. The default store writes `UserDefaults.standard`, which in a test run
/// is the xctest tool's domain, and every parallel worker process shares it
/// through cfprefsd: one worker's key-command binding or "active pane follows
/// mouse" write landed in another worker's test part way through it
/// (`KeyCommandMenuBridgeTests`, `ComposableTabsActivePaneConformanceTests`
/// CTA15 and CTA16). `ExclusiveAccess` orders the tests inside one process; it
/// cannot see another. In memory, nothing is left on disk either (a defaults
/// suite leaves an empty plist behind after its domain is removed).
///
/// And it points CodeEditLanguages' `Bundle.module` at this bundle's
/// resources (``ensureEditorLanguageResourcesLocated()``) before any test
/// constructs a `CodeLanguage`. Without it, whichever suite first detected a
/// file's language decided whether the process crashed: `FileEditorStateTests`
/// passed in a full run behind a suite that set the override, and crashed
/// every test when run alone.
@objc(AgenticDeveloperHubSDKMacOSTestBundleSetup)
final class TestBundleSetup: NSObject {
    override init() {
        var arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        arguments["NSAutomaticWindowAnimationsEnabled"] = false
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
        super.init()
        ensureEditorLanguageResourcesLocated()
        MainActor.assumeIsolated { Self.isolateUserSettings() }
    }

    @MainActor
    private static func isolateUserSettings() {
        UserSettings.shared = UserSettings(with: InMemorySettingsStorageProvider())
    }
}
