import AppKit
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
private final class RecordingBannerDelegate: GitOperationBannerDelegate {
    private(set) var intents: [GitOperationIntent] = []
    func banner(_ banner: GitOperationBannerViewController, didRequest intent: GitOperationIntent) {
        intents.append(intent)
    }
}

/// The operation banner (recipe `workspace/git/git-views`, "Operation banner").
@Suite("GitOperationBannerViewController")
@MainActor
struct GitOperationBannerViewControllerTests {

    private static let sha = "0123456789abcdef0123456789abcdef01234567"

    @Test("the status names the operation, with each part git recorded")
    func statusText() {
        let text = GitOperationBannerViewController.statusText(for:)
        #expect(text(.none) == nil)
        #expect(text(.merging(head: Self.sha)) == "Merging 0123456")
        #expect(text(.merging(head: nil)) == "Merging")
        #expect(text(.rebasing(branch: "feature", onto: Self.sha, step: 2, total: 5, interactive: false))
            == "Rebasing feature (2/5)")
        #expect(text(.rebasing(branch: "feature", onto: nil, step: nil, total: 5, interactive: true))
            == "Rebasing feature")
        #expect(text(.rebasing(branch: nil, onto: nil, step: 1, total: 3, interactive: false)) == "Rebasing (1/3)")
        #expect(text(.cherryPicking(commit: Self.sha)) == "Cherry-picking 0123456")
        #expect(text(.reverting(commit: Self.sha)) == "Reverting 0123456")
        #expect(text(.reverting(commit: nil)) == "Reverting")
    }

    @Test("none hides the banner; an operation shows it, with Skip only where git takes it")
    func visibility() {
        let banner = GitOperationBannerViewController()
        banner.loadViewIfNeeded()
        #expect(banner.view.accessibilityIdentifier() == "git.banner")
        #expect(banner.view.isHidden)

        banner.state = .merging(head: Self.sha)
        #expect(!banner.view.isHidden)
        #expect(banner.statusLabel.stringValue == "Merging 0123456")
        #expect(banner.skipButton.isHidden, "a merge has no skip")
        #expect(!banner.continueButton.isHidden)
        #expect(!banner.abortButton.isHidden)

        for state: GitOperationState in [
            .rebasing(branch: "b", onto: nil, step: 1, total: 2, interactive: false),
            .cherryPicking(commit: Self.sha), .reverting(commit: Self.sha)
        ] {
            banner.state = state
            #expect(!banner.view.isHidden)
            #expect(!banner.skipButton.isHidden)
        }

        banner.state = .none
        #expect(banner.view.isHidden)
    }

    @Test("a state set before the view loads is shown once it does")
    func stateBeforeLoad() {
        let banner = GitOperationBannerViewController()
        banner.state = .cherryPicking(commit: Self.sha)
        banner.loadViewIfNeeded()
        #expect(!banner.view.isHidden)
        #expect(banner.statusLabel.stringValue == "Cherry-picking 0123456")
    }

    @Test("each button sends its step, and carries its identifier")
    func buttonsSendIntents() throws {
        let banner = GitOperationBannerViewController()
        let delegate = RecordingBannerDelegate()
        banner.delegate = delegate
        banner.state = .rebasing(branch: "b", onto: nil, step: 1, total: 1, interactive: false)
        banner.loadViewIfNeeded()
        let buttons = [banner.continueButton, banner.skipButton, banner.abortButton]
        #expect(buttons.map { $0.accessibilityIdentifier() } == [
            "git.banner.continue", "git.banner.skip", "git.banner.abort"
        ])
        #expect(banner.statusLabel.accessibilityIdentifier() == "git.banner.status")
        for button in buttons {
            let target = try #require(button.target as? NSObject)
            target.perform(button.action, with: button)
        }
        #expect(delegate.intents == [.step(.continue), .step(.skip), .step(.abort)])
    }
}
