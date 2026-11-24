import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@Suite("GitPullRequestViewController")
@MainActor
struct GitPullRequestViewControllerTests {

    private static let updatedAt = Date(timeIntervalSince1970: 1_767_268_800)

    private static let pullRequest = GitPullRequest(
        number: 7, title: "Add the parser", state: "OPEN", isDraft: false, author: "octocat",
        headRefName: "feature", baseRefName: "main", url: URL(string: "https://github.com/o/r/pull/7")!,
        updatedAt: updatedAt, checks: GitPullRequestChecks(passing: 3, failing: 1, pending: 0),
        reviewDecision: "APPROVED")

    @Test("the detail shows the pull request's fields")
    func fields() {
        let controller = GitPullRequestViewController()
        controller.loadViewIfNeeded()
        controller.show(Self.pullRequest)

        #expect(controller.view.accessibilityIdentifier() == "git.pullRequest")
        #expect(controller.titleLabel.stringValue == "Add the parser")
        #expect(controller.numberLabel.stringValue == "#7")
        #expect(controller.stateLabel.stringValue == "Open")
        #expect(controller.authorLabel.stringValue == "octocat")
        #expect(controller.branchesLabel.stringValue == "feature → main")
        #expect(controller.reviewLabel.stringValue == "Approved")
        #expect(controller.checksLabel.stringValue == "3 passing, 1 failing, 0 pending")
        #expect(controller.updatedLabel.stringValue
            == GitPullRequestViewController.dateFormatter.string(from: Self.updatedAt))
    }

    @Test("a draft reads Draft, and no checks read None")
    func draftAndNoChecks() {
        let controller = GitPullRequestViewController()
        controller.loadViewIfNeeded()
        let open = Self.pullRequest
        let draft = GitPullRequest(
            number: open.number, title: open.title, state: "OPEN", isDraft: true, author: open.author,
            headRefName: open.headRefName, baseRefName: open.baseRefName, url: open.url,
            updatedAt: open.updatedAt, checks: nil, reviewDecision: nil)
        controller.show(draft)

        #expect(controller.stateLabel.stringValue == "Draft")
        #expect(controller.checksLabel.stringValue == "None")
        #expect(controller.reviewLabel.stringValue == "None")
    }

    @Test("the buttons carry their identifiers and send open and checkout intents")
    func buttons() {
        let controller = GitPullRequestViewController()
        controller.loadViewIfNeeded()
        #expect(!controller.openButton.isEnabled)
        #expect(!controller.checkoutButton.isEnabled)

        controller.show(Self.pullRequest)
        var intents: [GitPullRequestIntent] = []
        controller.onIntent = { intents.append($0) }

        #expect(controller.openButton.accessibilityIdentifier() == "git.pullRequest.open")
        #expect(controller.checkoutButton.accessibilityIdentifier() == "git.pullRequest.checkout")
        #expect(controller.openButton.isEnabled)
        controller.openButton.performClick(nil)
        controller.checkoutButton.performClick(nil)
        #expect(intents == [.openInBrowser(Self.pullRequest), .checkout(Self.pullRequest)])
    }

    @Test("every caption carries git.pullRequest.caption.<field>")
    func captionIdentifiers() {
        let controller = GitPullRequestViewController()
        controller.loadViewIfNeeded()
        var identifiers: [String] = []
        var pending: [NSView] = [controller.view]
        while let view = pending.popLast() {
            if let label = view as? NSTextField, label.accessibilityIdentifier().hasPrefix("git.pullRequest.caption.") {
                identifiers.append(label.accessibilityIdentifier())
            }
            pending.append(contentsOf: view.subviews)
        }
        let names = ["number", "state", "author", "branches", "review", "checks", "updated"]
        #expect(Set(identifiers) == Set(names.map { "git.pullRequest.caption.\($0)" }))
    }

    @Test("Check Out is off for the checked-out branch's own pull request")
    func checkoutOffForTheHead() {
        let controller = GitPullRequestViewController()
        controller.loadViewIfNeeded()
        controller.show(Self.pullRequest)
        #expect(controller.checkoutButton.isEnabled)
        controller.checkedOutBranch = "feature"
        #expect(!controller.checkoutButton.isEnabled)
        #expect(controller.openButton.isEnabled)
        controller.checkedOutBranch = "main"
        #expect(controller.checkoutButton.isEnabled)
    }

    @Test("Check Out stays on for a fork's pull request whose branch shares the local name")
    func checkoutOnForAFork() {
        let controller = GitPullRequestViewController()
        controller.loadViewIfNeeded()
        let fork = GitPullRequest(
            number: 9, title: "From a fork", state: "OPEN", isDraft: false, author: "stranger",
            headRefName: "feature", baseRefName: "main", url: URL(string: "https://github.com/o/r/pull/9")!,
            updatedAt: Self.updatedAt, checks: nil, reviewDecision: nil, isCrossRepository: true)
        controller.checkedOutBranch = "feature"
        controller.show(fork)
        #expect(controller.checkoutButton.isEnabled)
    }

    @Test("showing nil empties the fields and turns both buttons off")
    func showNilEmpties() {
        let controller = GitPullRequestViewController()
        controller.loadViewIfNeeded()
        controller.show(Self.pullRequest)
        controller.show(nil)
        #expect(controller.pullRequest == nil)
        #expect(controller.titleLabel.stringValue.isEmpty)
        #expect(controller.stateLabel.stringValue.isEmpty)
        #expect(!controller.openButton.isEnabled)
        #expect(!controller.checkoutButton.isEnabled)
    }
}
