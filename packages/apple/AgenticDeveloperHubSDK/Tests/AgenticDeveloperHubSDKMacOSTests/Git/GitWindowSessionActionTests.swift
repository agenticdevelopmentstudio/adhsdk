import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Stands in for FSEvents: the model refreshes itself after each action.
private final class IdleWatcher: GitRepositoryWatching {
    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {}
    func stop() {}
}

/// Records every request and answers from a script; an empty script answers no.
@MainActor
private final class StubPresenter: GitActionPresenting {
    var confirmations: [GitConfirmation] = []
    var textRequests: [GitTextRequest] = []
    var failures: [String] = []
    var confirmAnswers: [Bool] = []
    var textAnswers: [[String]?] = []
    /// Called as each confirmation or text request arrives, before it is answered.
    var onAsk: (() -> Void)?
    /// Awaited while a confirmation is up, before it is answered: what happens meanwhile.
    var whileConfirming: (() async -> Void)?

    func confirm(_ request: GitConfirmation) async -> Bool {
        onAsk?()
        confirmations.append(request)
        await whileConfirming?()
        return confirmAnswers.isEmpty ? false : confirmAnswers.removeFirst()
    }

    func askForText(_ request: GitTextRequest) async -> [String]? {
        onAsk?()
        textRequests.append(request)
        return textAnswers.isEmpty ? nil : textAnswers.removeFirst()
    }

    func showFailure(title: String, message: String) {
        failures.append("\(title): \(message)")
    }

    /// Every plan the editor was shown, in order.
    var rebasePlans: [GitRebasePlan] = []
    /// What the editor answers for a plan; nil (the default) cancels it.
    var editRebaseAnswer: ((GitRebasePlan) -> GitRebasePlan?)?

    func editRebase(_ plan: GitRebasePlan) async -> GitRebasePlan? {
        rebasePlans.append(plan)
        return editRebaseAnswer?(plan)
    }

    /// Every branch the pull request form was shown for, in order; the form is cancelled.
    var pullRequestHeads: [String] = []

    func createPullRequest(head: String, defaultTitle: String, defaultBody: String,
                           bases: [String]) async -> GitPullRequestDraft? {
        pullRequestHeads.append(head)
        return nil
    }
}

/// The Git window's actions (recipe `workspace/git/git-window`, "Actions"), each run
/// through the session against a real repository in the temp directory, with a
/// presenter that answers from a script. Remotes are bare repositories beside it.
@Suite("GitWindowSession actions")
@MainActor
struct GitWindowSessionActionTests {
    private static let epoch = 1_767_268_800
    private let client = GitClient(configuration: .tests)
    /// Allows the local-path clone a submodule update makes (see `GitClientConflictTests`).
    private let localFileClient = GitClient(configuration: GitClientConfiguration(
        executableURL: GitTestRepository.gitURL, timeout: 60, extraEnvironment: [
        "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_CONFIG_PARAMETERS": "'protocol.file.allow=always'"
    ]))

    // MARK: Fixtures

    private func commitFile(_ repository: GitTestRepository, _ name: String, _ text: String,
                            at offset: Int) async throws {
        try repository.write(text, to: name)
        try await repository.run(["add", "--", name])
        try await repository.commit("\(name) \(offset)", at: Self.epoch + offset)
    }

    private func makeSession(
        _ repository: GitTestRepository, presenter: StubPresenter?, client: GitClient? = nil
    ) async -> (GitRepositoryModel, GitWindowSession) {
        let client = client ?? self.client
        let model = GitRepositoryModel(root: repository.root, client: client, watcher: IdleWatcher())
        await model.start()
        let session = GitWindowSession(model: model, client: client, coloring: nil)
        for pane in [session.overviewPane, session.centre, session.commitPane] as [NSViewController] {
            pane.loadViewIfNeeded()
        }
        session.presenter = presenter
        return (model, session)
    }

    /// Runs `request` and waits for it to finish.
    private func act(_ session: GitWindowSession, _ request: GitWindowSession.Request) async {
        session.perform(request)
        await session.actionTask?.value
    }

    /// `revision` as the history would hand it to a commit intent.
    private func commit(_ repository: GitTestRepository, _ revision: String) async throws -> GitCommit {
        let line = try await repository.run(["rev-list", "--parents", "-n", "1", revision])
        let shas = line.split(whereSeparator: \.isWhitespace).map(String.init)
        let person = GitPerson(name: "Test", email: "test@example.com", date: Date())
        return GitCommit(id: shas[0], parents: Array(shas.dropFirst()), author: person, committer: person,
                         subject: "", body: "")
    }

    private func ref(_ model: GitRepositoryModel, _ fullName: String) throws -> GitRef {
        try #require(model.refs.first { $0.fullName == fullName })
    }

    private func headName(_ repository: GitTestRepository) async throws -> String {
        try await repository.run(["rev-parse", "--abbrev-ref", "HEAD"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func branchExists(_ repository: GitTestRepository, _ name: String) async -> Bool {
        (try? await repository.run(["rev-parse", "--verify", "--quiet", "refs/heads/\(name)"])) != nil
    }

    /// A bare remote, a clone of it whose `main` is pushed and tracked, and a commit on it.
    private func makeRemoteAndClone() async throws -> (GitTestRepository, GitTestRepository) {
        let remote = try await GitTestRepository.makeBare()
        let clone: GitTestRepository
        do {
            clone = try await GitTestRepository.clone(of: remote)
        } catch {
            remote.tearDown()
            throw error
        }
        try await commitFile(clone, "one.txt", "one\n", at: 100)
        try await clone.run(["push", "--quiet", "-u", "origin", "main"])
        return (remote, clone)
    }

    // MARK: One at a time

    @Test("a second fetch while the first runs is ignored, with one busy cycle and the spinner following it")
    func oneActionAtATime() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        let (_, session) = await makeSession(clone, presenter: StubPresenter())
        var busy: [Bool] = []
        var spinnerShown: [Bool] = []
        session.onBusyChange = { [unowned session] value in
            busy.append(value)
            spinnerShown.append(!session.overviewPane.busyIndicator.isHidden)
        }

        session.fetch()
        let first = session.actionTask
        session.fetch()
        #expect(session.actionTask == first)
        await session.actionTask?.value

        #expect(busy == [true, false])
        #expect(spinnerShown == [true, false])
        #expect(session.overviewPane.isBusy == false)
        #expect(session.overviewPane.busyIndicator.accessibilityIdentifier() == "git.window.busy")
    }

    @Test("the spinner is off while a sheet waits and on only while git runs; the action spans both")
    func spinnerOnlyWhileGitRuns() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["tag", "v1"])
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)
        var busyWhileAsked: [Bool] = []
        var actingWhileAsked: [Bool] = []
        presenter.onAsk = { [unowned session] in
            busyWhileAsked.append(session.overviewPane.isBusy)
            actingWhileAsked.append(session.isActing)
        }
        var busy: [Bool] = []
        session.onBusyChange = { busy.append($0) }

        await act(session, .ref(.deleteTag(try ref(model, "refs/tags/v1"))))

        #expect(busyWhileAsked == [false])
        #expect(actingWhileAsked == [true])
        #expect(busy == [true, false])
        #expect(!session.isActing)
        #expect(!session.overviewPane.isBusy)
    }

    @Test("the spinner sits before Refresh in the overview's accessories")
    func spinnerBeforeRefresh() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        let (_, session) = await makeSession(repository, presenter: nil)
        let views = session.overviewPane.makePaneAccessoryViews()
        #expect(views.first === session.overviewPane.busyIndicator)
        #expect(views.count == 2)
        #expect(session.overviewPane.busyIndicator.isHidden)
    }

    // MARK: Working copy

    @Test("discard confirms, then restores a tracked file and removes an untracked one, in two actions")
    func discardTrackedAndUntracked() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try repository.write("changed\n", to: "a.txt")
        try repository.write("new\n", to: "b.txt")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .workingCopy(.discard(["a.txt", "b.txt"])))

        #expect(presenter.confirmations == [GitConfirmation(
            title: "Discard changes to 2 files?", message: "This cannot be undone.",
            actionTitle: "Discard Changes", isDestructive: true)])
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "a\n")
        #expect(!FileManager.default.fileExists(atPath: repository.url("b.txt").path))
        #expect(model.unstaged.isEmpty)
        #expect(presenter.failures.isEmpty)
    }

    @Test("discard all confirms one file in the singular and declining changes nothing")
    func discardAllDeclined() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try repository.write("changed\n", to: "a.txt")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [false]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .workingCopy(.discardAll))

        #expect(presenter.confirmations.map(\.title) == ["Discard changes to 1 file?"])
        #expect(model.unstaged.map(\.path) == ["a.txt"])
    }

    @Test("without a presenter an action that needs the user does nothing")
    func noPresenterDoesNothing() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try repository.write("changed\n", to: "a.txt")
        let (model, session) = await makeSession(repository, presenter: nil)

        await act(session, .workingCopy(.discardAll))
        await act(session, .newBranch)

        #expect(model.unstaged.map(\.path) == ["a.txt"])
        #expect(try await headName(repository) == "main")
    }

    @Test("staging and unstaging run at once")
    func stageAndUnstage() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try repository.write("changed\n", to: "a.txt")
        let (model, session) = await makeSession(repository, presenter: StubPresenter())

        await act(session, .workingCopy(.stageAll))
        #expect(model.staged.map(\.path) == ["a.txt"])
        await act(session, .workingCopy(.unstage(["a.txt"])))
        #expect(model.staged.isEmpty)
        #expect(model.unstaged.map(\.path) == ["a.txt"])
    }

    @Test("a commit runs, then the box empties and Amend unticks")
    func commitEmptiesTheBox() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try repository.write("changed\n", to: "a.txt")
        try await repository.run(["add", "--", "a.txt"])
        let (model, session) = await makeSession(repository, presenter: StubPresenter())
        session.workingCopy.commitBox.message = "second"

        await act(session, .workingCopy(.commit(message: "second", amend: false)))

        let subject = try await repository.run(["log", "-1", "--format=%s"])
        #expect(subject.trimmingCharacters(in: .whitespacesAndNewlines) == "second")
        #expect(session.workingCopy.commitBox.message.isEmpty)
        #expect(model.staged.isEmpty)
    }

    @Test("a failed commit keeps the message and shows git's error")
    func failedCommitKeepsTheMessage() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)
        session.workingCopy.commitBox.message = "nothing staged"

        await act(session, .workingCopy(.commit(message: "nothing staged", amend: false)))

        #expect(presenter.failures.count == 1)
        #expect(presenter.failures.first?.hasPrefix("Commit failed: ") == true)
        #expect(session.workingCopy.commitBox.message == "nothing staged")
    }

    @Test("ticking Amend over an empty box fills it with the last commit's message; a typed one is kept")
    func amendFillsAnEmptyBox() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try repository.write("a\n", to: "a.txt")
        try await repository.run(["add", "--", "a.txt"])
        try await repository.commit("The subject\n\nThe body.", at: Self.epoch)
        let (_, session) = await makeSession(repository, presenter: StubPresenter())
        let box = session.workingCopy.commitBox
        box.isAmend = true

        await act(session, .workingCopy(.amendChanged(true)))
        #expect(box.message == "The subject\n\nThe body.")

        box.message = "typed"
        await act(session, .workingCopy(.amendChanged(true)))
        #expect(box.message == "typed")
    }

    @Test("Amend can be ticked only once the repository has a commit")
    func canAmendFollowsHasCommits() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        let (model, session) = await makeSession(repository, presenter: StubPresenter())
        #expect(session.workingCopy.canAmend == false)

        try await commitFile(repository, "a.txt", "a\n", at: 100)
        await model.refresh([.refs, .workingCopy])
        #expect(session.workingCopy.canAmend == true)

        // An orphan branch beside `main`: the repository has a commit, HEAD names none.
        try await repository.run(["checkout", "--quiet", "--orphan", "fresh"])
        await model.refresh([.refs, .workingCopy])
        #expect(model.headCommit == nil)
        #expect(session.workingCopy.canAmend == false)
    }

    // MARK: Push, pull, fetch

    @Test("push with no remote shows the no-remote failure")
    func pushWithNoRemote() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        session.push()
        await session.actionTask?.value

        #expect(presenter.failures == ["Push failed: This repository has no remote."])
    }

    @Test("closing the window cancels the running action, which then shows nothing")
    func stopCancelsTheAction() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        session.push()
        session.stop()
        await session.actionTask?.value

        #expect(session.actionTask?.isCancelled == true)
        #expect(presenter.failures.isEmpty)
    }

    @Test("push on a detached HEAD shows that HEAD is not on a branch")
    func pushDetached() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["checkout", "--quiet", "--detach"])
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        session.push()
        await session.actionTask?.value

        #expect(presenter.failures == ["Push failed: HEAD is not on a branch."])
    }

    @Test("push with an upstream pushes the branch")
    func pushWithUpstream() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await commitFile(clone, "two.txt", "two\n", at: 200)
        let presenter = StubPresenter()
        let (_, session) = await makeSession(clone, presenter: presenter)

        session.push()
        await session.actionTask?.value

        #expect(presenter.failures.isEmpty)
        #expect(try await remote.sha("main") == clone.sha("HEAD"))
    }

    @Test("push with no upstream pushes to origin and sets it")
    func pushSettingUpstream() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["checkout", "--quiet", "-b", "topic"])
        try await commitFile(clone, "two.txt", "two\n", at: 200)
        let presenter = StubPresenter()
        let (model, session) = await makeSession(clone, presenter: presenter)

        session.push()
        await session.actionTask?.value

        #expect(presenter.failures.isEmpty)
        #expect(try await remote.sha("topic") == clone.sha("HEAD"))
        #expect(model.headBranch?.upstream == "origin/topic")
    }

    @Test("with push.default=upstream, a branch named unlike its upstream pushes there and keeps tracking it")
    func pushToADifferentlyNamedUpstream() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["config", "push.default", "upstream"])
        try await clone.run(["push", "--quiet", "origin", "main:feature"])
        try await clone.run(["fetch", "--quiet", "origin"])
        try await clone.run(["checkout", "--quiet", "-b", "feat", "--track", "origin/feature"])
        try await commitFile(clone, "two.txt", "two\n", at: 200)
        let presenter = StubPresenter()
        let (model, session) = await makeSession(clone, presenter: presenter)

        session.push()
        await session.actionTask?.value

        #expect(presenter.failures.isEmpty)
        #expect(try await remote.sha("feature") == clone.sha("feat"))
        #expect(await !branchExists(remote, "feat"))
        #expect(model.headBranch?.upstream == "origin/feature")

        try await commitFile(clone, "three.txt", "three\n", at: 300)
        try await clone.run(["checkout", "--quiet", "main"])
        await model.refresh([.refs, .workingCopy])
        await act(session, .ref(.push(try ref(model, "refs/heads/feat"))))

        #expect(presenter.failures.isEmpty)
        #expect(try await remote.sha("feature") == clone.sha("feat"))
        #expect(await !branchExists(remote, "feat"))
        #expect(try ref(model, "refs/heads/feat").upstream == "origin/feature")
    }

    @Test("a branch made from origin/main is never pushed onto main, from HEAD or from the menu")
    func branchFromARemoteBranchIsNotPushedOntoIt() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["config", "push.default", "simple"])
        try await clone.run(["config", "branch.autoSetupMerge", "true"])
        let shared = try await remote.sha("main")
        let presenter = StubPresenter()
        presenter.textAnswers = [["topic"]]
        let (model, session) = await makeSession(clone, presenter: presenter)

        await act(session, .ref(.createBranch(from: try ref(model, "refs/remotes/origin/main"))))
        #expect(try await headName(clone) == "topic")
        #expect(model.headBranch?.upstream == "origin/main")
        try await commitFile(clone, "two.txt", "two\n", at: 200)
        await model.refresh([.refs, .workingCopy])

        session.push()
        await session.actionTask?.value
        #expect(presenter.failures.count == 1)
        #expect(presenter.failures.first?.hasPrefix("Push failed: ") == true)
        #expect(try await remote.sha("main") == shared)
        #expect(await !branchExists(remote, "topic"))

        try await clone.run(["checkout", "--quiet", "main"])
        await model.refresh([.refs, .workingCopy])
        await act(session, .ref(.push(try ref(model, "refs/heads/topic"))))
        #expect(presenter.failures.count == 2)
        #expect(presenter.failures.last?.hasPrefix("Push failed: topic has no push destination.") == true)
        #expect(try await remote.sha("main") == shared)
        #expect(await !branchExists(remote, "topic"))
        #expect(try ref(model, "refs/heads/topic").upstream == "origin/main")
    }

    @Test("a branch with a pushRemote is pushed from the menu to that remote, tracking untouched")
    func menuPushGoesToThePushRemote() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        let fork = try await GitTestRepository.makeBare()
        defer { fork.tearDown() }
        try await clone.run(["remote", "add", "fork", fork.root.path])
        try await clone.run(["config", "push.default", "current"])
        try await clone.run(["push", "--quiet", "origin", "main:pr"])
        try await clone.run(["push", "--quiet", "fork", "main:pr"])
        try await clone.run(["fetch", "--quiet", "--all"])
        try await clone.run(["branch", "--quiet", "--track", "pr", "origin/pr"])
        try await clone.run(["config", "branch.pr.pushRemote", "fork"])
        try await clone.run(["checkout", "--quiet", "pr"])
        try await commitFile(clone, "two.txt", "two\n", at: 200)
        try await clone.run(["checkout", "--quiet", "main"])
        let origin = try await remote.sha("pr")
        let presenter = StubPresenter()
        let (model, session) = await makeSession(clone, presenter: presenter)

        await act(session, .ref(.push(try ref(model, "refs/heads/pr"))))

        #expect(presenter.failures.isEmpty)
        #expect(try await fork.sha("pr") == clone.sha("pr"))
        #expect(try await remote.sha("pr") == origin)
        #expect(try ref(model, "refs/heads/pr").upstream == "origin/pr")
    }

    @Test("a branch tracking a local branch fails to push and keeps its upstream, from HEAD or the menu")
    func localUpstreamFails() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["config", "push.default", "simple"])
        try await clone.run(["checkout", "--quiet", "-b", "loc", "--track", "main"])
        try await commitFile(clone, "two.txt", "two\n", at: 200)
        let main = try await clone.sha("main")
        let presenter = StubPresenter()
        let (model, session) = await makeSession(clone, presenter: presenter)
        #expect(model.headBranch?.upstream == "main")

        session.push()
        await session.actionTask?.value
        #expect(presenter.failures.count == 1)

        try await clone.run(["checkout", "--quiet", "main"])
        await model.refresh([.refs, .workingCopy])
        await act(session, .ref(.push(try ref(model, "refs/heads/loc"))))
        #expect(presenter.failures.count == 2)
        #expect(presenter.failures.last?.hasPrefix("Push failed: loc has no push destination.") == true)
        #expect(try await clone.sha("main") == main)
        #expect(await !branchExists(remote, "loc"))
        #expect(try ref(model, "refs/heads/loc").upstream == "main")
    }

    @Test("the upstream splits at the longest remote name that prefixes it")
    func upstreamSplitsAtItsRemote() {
        let split = GitWindowSession.split("team/origin/feature", among: ["origin", "team", "team/origin"])
        #expect(split?.remote == "team/origin")
        #expect(split?.branch == "feature")
        #expect(GitWindowSession.split("other/feature", among: ["origin"]) == nil)
        #expect(GitWindowSession.split("origin/", among: ["origin"]) == nil)
    }

    @Test("push with no upstream and one remote that is not origin pushes to it")
    func pushToTheOnlyRemote() async throws {
        let remote = try await GitTestRepository.makeBare()
        defer { remote.tearDown() }
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["remote", "add", "upstream", remote.root.path])
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        session.push()
        await session.actionTask?.value

        #expect(presenter.failures.isEmpty)
        #expect(try await remote.sha("main") == repository.sha("HEAD"))
    }

    @Test("pull brings in another clone's commit; fetch of one remote updates its branches")
    func pullAndFetch() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        let other = try await GitTestRepository.clone(of: remote)
        defer { other.tearDown() }
        try await commitFile(other, "two.txt", "two\n", at: 200)
        try await other.run(["push", "--quiet", "origin", "main"])
        let presenter = StubPresenter()
        let (_, session) = await makeSession(clone, presenter: presenter)

        await act(session, .ref(.fetch(remote: "origin")))
        #expect(try await clone.sha("origin/main") == other.sha("HEAD"))

        try await commitFile(other, "three.txt", "three\n", at: 300)
        try await other.run(["push", "--quiet", "origin", "main"])
        session.fetch()
        await session.actionTask?.value
        #expect(try await clone.sha("origin/main") == other.sha("HEAD"))

        session.pull()
        await session.actionTask?.value
        #expect(presenter.failures.isEmpty)
        #expect(try await clone.sha("HEAD") == other.sha("HEAD"))
    }

    // MARK: Branches

    @Test("the toolbar's new branch asks for a name and creates and checks it out at HEAD")
    func newBranchFromTheToolbar() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let presenter = StubPresenter()
        presenter.textAnswers = [["topic"]]
        let (_, session) = await makeSession(repository, presenter: presenter)

        session.newBranch()
        await session.actionTask?.value

        let request = try #require(presenter.textRequests.first)
        #expect(request.fields == [GitTextField(label: "Name", initial: "", isOptional: false)])
        #expect(request.actionTitle == "Create Branch")
        #expect(try await headName(repository) == "topic")
    }

    @Test("a new branch from a commit starts at its sha; from a ref, at the ref")
    func newBranchFromACommitAndARef() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let first = try await commit(repository, "HEAD")
        try await commitFile(repository, "b.txt", "b\n", at: 200)
        let presenter = StubPresenter()
        presenter.textAnswers = [["from-commit"], ["from-ref"]]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.createBranch, first))
        #expect(try await repository.sha("HEAD") == first.id)
        #expect(try await headName(repository) == "from-commit")

        await act(session, .ref(.createBranch(from: try ref(model, "refs/heads/main"))))
        #expect(try await repository.sha("HEAD") == repository.sha("main"))
        #expect(try await headName(repository) == "from-ref")
        #expect(presenter.textRequests.map(\.message) == ["From \(first.shortID)", "From main"])
    }

    @Test("a name beginning with a dash is refused before git runs")
    func dashLedNameRefused() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let presenter = StubPresenter()
        presenter.textAnswers = [["-f"]]
        let (_, session) = await makeSession(repository, presenter: presenter)

        session.newBranch()
        await session.actionTask?.value

        #expect(presenter.failures == ["Create branch failed: A name cannot begin with “-”."])
        #expect(try await headName(repository) == "main")
    }

    @Test("checkout: a local branch by name, a commit detached")
    func checkoutLocalAndCommit() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["branch", "other"])
        let (model, session) = await makeSession(repository, presenter: StubPresenter())

        await act(session, .ref(.checkout(try ref(model, "refs/heads/other"))))
        #expect(try await headName(repository) == "other")

        let head = try await commit(repository, "HEAD")
        await act(session, .commit(.checkout, head))
        #expect(try await headName(repository) == "HEAD")
        #expect(model.headBranch == nil)
    }

    @Test("checkout of a remote branch makes a tracking branch, or checks out the one already tracking it")
    func checkoutRemoteBranch() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["push", "--quiet", "origin", "main:feature"])
        try await clone.run(["fetch", "--quiet", "origin"])
        let presenter = StubPresenter()
        let (model, session) = await makeSession(clone, presenter: presenter)

        await act(session, .ref(.checkout(try ref(model, "refs/remotes/origin/feature"))))
        #expect(try await headName(clone) == "feature")
        #expect(model.headBranch?.upstream == "origin/feature")

        await act(session, .ref(.checkout(try ref(model, "refs/remotes/origin/main"))))
        #expect(try await headName(clone) == "main")
        #expect(presenter.failures.isEmpty)
    }

    @Test("rename asks one field prefilled with the name")
    func renameBranch() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["branch", "old"])
        let presenter = StubPresenter()
        presenter.textAnswers = [["new"]]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .ref(.rename(try ref(model, "refs/heads/old"))))

        let field = GitTextField(label: "Name", initial: "old", isOptional: false)
        #expect(presenter.textRequests.first?.fields == [field])
        #expect(await branchExists(repository, "new"))
        #expect(!(await branchExists(repository, "old")))
    }

    @Test("deleting a merged branch confirms once, destructively")
    func deleteMergedBranch() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["branch", "merged"])
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .ref(.delete(try ref(model, "refs/heads/merged"))))

        #expect(presenter.confirmations.count == 1)
        #expect(presenter.confirmations.first?.isDestructive == true)
        #expect(!(await branchExists(repository, "merged")))
    }

    @Test("deleting an unmerged branch asks twice, the second destructive, then forces it")
    func deleteUnmergedAsksTwice() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "b.txt", "b\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true, true]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .ref(.delete(try ref(model, "refs/heads/side"))))

        #expect(presenter.confirmations.count == 2)
        #expect(presenter.confirmations.first?.isDestructive == true)
        #expect(presenter.confirmations.last?.title == "Delete unmerged branch?")
        #expect(presenter.confirmations.last?.isDestructive == true)
        #expect(presenter.failures.isEmpty)
        #expect(!(await branchExists(repository, "side")))
    }

    @Test("declining the second delete keeps the branch and shows nothing")
    func deleteUnmergedDeclined() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "b.txt", "b\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true, false]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .ref(.delete(try ref(model, "refs/heads/side"))))

        #expect(presenter.confirmations.count == 2)
        #expect(presenter.failures.isEmpty)
        #expect(await branchExists(repository, "side"))
    }

    @Test("deleting a remote branch confirms, then deletes it on its remote")
    func deleteRemoteBranch() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        try await clone.run(["push", "--quiet", "origin", "main:feature"])
        try await clone.run(["fetch", "--quiet", "origin"])
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(clone, presenter: presenter)

        await act(session, .ref(.delete(try ref(model, "refs/remotes/origin/feature"))))

        #expect(presenter.confirmations.first?.isDestructive == true)
        #expect(presenter.failures.isEmpty)
        #expect(await branchExists(remote, "feature") == false)
    }

    // MARK: Tags

    @Test("a tag with a message is annotated, without one lightweight; delete confirms; push picks origin")
    func tags() async throws {
        let (remote, clone) = try await makeRemoteAndClone()
        defer { remote.tearDown(); clone.tearDown() }
        let presenter = StubPresenter()
        presenter.textAnswers = [["v1", "First"], ["v2", ""]]
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(clone, presenter: presenter)
        let head = try await commit(clone, "HEAD")

        await act(session, .commit(.createTag, head))
        await act(session, .commit(.createTag, head))
        #expect(presenter.textRequests.first?.fields.map(\.label) == ["Name", "Message"])
        #expect(presenter.textRequests.first?.fields.last?.isOptional == true)
        #expect(try await clone.run(["cat-file", "-t", "v1"]).hasPrefix("tag"))
        #expect(try await clone.run(["cat-file", "-t", "v2"]).hasPrefix("commit"))

        await act(session, .ref(.pushTag(try ref(model, "refs/tags/v1"))))
        #expect((try? await remote.run(["rev-parse", "--verify", "refs/tags/v1"])) != nil)

        await act(session, .ref(.deleteTag(try ref(model, "refs/tags/v2"))))
        #expect(presenter.confirmations.count == 1)
        #expect(presenter.confirmations.first?.isDestructive == true)
        #expect((try? await clone.run(["rev-parse", "--verify", "--quiet", "refs/tags/v2"])) == nil)
        #expect(presenter.failures.isEmpty)
    }

    // MARK: Stashes

    @Test("stash asks an optional message; pop takes the newest; pop with none does nothing; drop confirms")
    func stashes() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let presenter = StubPresenter()
        presenter.textAnswers = [["kept"], [""]]
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)

        try repository.write("one\n", to: "a.txt")
        session.stash()
        await session.actionTask?.value
        #expect(presenter.textRequests.first?.fields == [GitTextField(label: "Message", initial: "", isOptional: true)])
        #expect(model.stashes.count == 1)
        #expect(model.stashes.first?.message.contains("kept") == true)

        try repository.write("two\n", to: "a.txt")
        session.stash()
        await session.actionTask?.value
        #expect(model.stashes.count == 2)

        session.popStash()
        await session.actionTask?.value
        #expect(model.stashes.count == 1)
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "two\n")

        let stash = try #require(model.stashes.first)
        await act(session, .ref(.dropStash(stash)))
        #expect(presenter.confirmations.first?.isDestructive == true)
        #expect(model.stashes.isEmpty)

        session.popStash()
        await session.actionTask?.value
        #expect(presenter.failures.isEmpty)
    }

    @Test("apply keeps the stash, pop by index removes it")
    func applyAndPopByIndex() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try repository.write("changed\n", to: "a.txt")
        try await repository.run(["stash", "push", "--quiet"])
        let (model, session) = await makeSession(repository, presenter: StubPresenter())
        let stash = try #require(model.stashes.first)

        await act(session, .ref(.applyStash(stash)))
        #expect(model.stashes.count == 1)
        #expect(model.unstaged.map(\.path) == ["a.txt"])

        try await repository.run(["checkout", "--quiet", "--", "a.txt"])
        await act(session, .ref(.popStash(stash)))
        #expect(model.stashes.isEmpty)
    }

    @Test("drop finds the chosen stash by sha when another is pushed after the menu was built")
    func dropFollowsTheStashNotItsIndex() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try repository.write("older\n", to: "a.txt")
        try await repository.run(["stash", "push", "--quiet", "-m", "older"])
        try repository.write("chosen\n", to: "a.txt")
        try await repository.run(["stash", "push", "--quiet", "-m", "chosen"])
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)
        let chosen = try #require(model.stashes.first { $0.message.contains("chosen") })
        #expect(chosen.index == 0)

        // Another tool pushes a stash between building the menu and running git, so
        // stash@{0} now names the newcomer and the chosen one is stash@{1}.
        try repository.write("newcomer\n", to: "a.txt")
        try await repository.run(["stash", "push", "--quiet", "-m", "newcomer"])
        await act(session, .ref(.dropStash(chosen)))
        #expect(presenter.failures.isEmpty)
        let left = try await model.currentStashes().map(\.message)
        #expect(left.count == 2)
        #expect(left.contains { $0.contains("newcomer") })
        #expect(left.contains { $0.contains("older") })
        #expect(!left.contains { $0.contains("chosen") })
    }

    @Test("a stash that is gone by the time git runs fails with a clear message and touches nothing")
    func aVanishedStashFails() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try repository.write("gone\n", to: "a.txt")
        try await repository.run(["stash", "push", "--quiet", "-m", "gone"])
        try repository.write("other\n", to: "a.txt")
        try await repository.run(["stash", "push", "--quiet", "-m", "other"])
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        let gone = try #require(model.stashes.first { $0.message.contains("gone") })

        try await repository.run(["stash", "drop", "--quiet", "stash@{\(gone.index)}"])
        await act(session, .ref(.popStash(gone)))
        #expect(presenter.failures == ["Pop stash failed: That stash no longer exists."])
        #expect(try await model.currentStashes().map(\.message).contains { $0.contains("other") })
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "a\n")
    }

    // MARK: Commits

    @Test("a conflicting cherry-pick shows a failure and the conflicted file appears in the working copy")
    func cherryPickConflict() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "f.txt", "base\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "f.txt", "side\n", at: 200)
        let side = try await commit(repository, "HEAD")
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "f.txt", "main\n", at: 300)
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.cherryPick, side))

        #expect(presenter.failures.count == 1)
        #expect(presenter.failures.first?.hasPrefix("Cherry-pick failed: ") == true)
        let conflicted = (model.staged + model.unstaged).filter { $0.status == .conflicted }.map(\.path)
        #expect(conflicted.contains("f.txt"))
    }

    @Test("reverting a merge commit passes mainline 1")
    func revertMerge() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "b.txt", "b\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "c.txt", "c\n", at: 300)
        try await repository.run(["merge", "--quiet", "--no-ff", "--no-edit", "side"],
                                 environment: GitTestRepository.dated(Self.epoch + 400))
        let merge = try await commit(repository, "HEAD")
        #expect(merge.parents.count == 2)
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.revert, merge))

        #expect(presenter.failures.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: repository.url("b.txt").path))
        #expect(FileManager.default.fileExists(atPath: repository.url("c.txt").path))
    }

    @Test("cherry-picking a merge commit passes mainline 1")
    func cherryPickMerge() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "target"])
        try await repository.run(["checkout", "--quiet", "-b", "side", "main"])
        try await commitFile(repository, "b.txt", "b\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "c.txt", "c\n", at: 300)
        try await repository.run(["merge", "--quiet", "--no-ff", "--no-edit", "side"],
                                 environment: GitTestRepository.dated(Self.epoch + 400))
        let merge = try await commit(repository, "HEAD")
        try await repository.run(["checkout", "--quiet", "target"])
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.cherryPick, merge))

        #expect(presenter.failures.isEmpty)
        #expect(FileManager.default.fileExists(atPath: repository.url("b.txt").path))
    }

    @Test("soft reset runs at once; hard confirms with the branch and short id, and declining keeps HEAD")
    func reset() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let first = try await commit(repository, "HEAD")
        try await commitFile(repository, "b.txt", "b\n", at: 200)
        let second = try await repository.sha("HEAD")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [false, true]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.reset(.hard), first))
        #expect(presenter.confirmations == [GitConfirmation(
            title: "Reset main to \(first.shortID)?", message: "Uncommitted changes are lost.",
            actionTitle: "Reset", isDestructive: true)])
        #expect(try await repository.sha("HEAD") == second)

        await act(session, .commit(.reset(.soft), first))
        #expect(presenter.confirmations.count == 1)
        #expect(try await repository.sha("HEAD") == first.id)
        #expect(model.staged.map(\.path) == ["b.txt"])

        await act(session, .commit(.reset(.hard), first))
        #expect(presenter.confirmations.count == 2)
        #expect(model.staged.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: repository.url("b.txt").path))
    }

    @Test("reset is allowed on a detached HEAD")
    func resetDetached() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let first = try await commit(repository, "HEAD")
        try await commitFile(repository, "b.txt", "b\n", at: 200)
        try await repository.run(["checkout", "--quiet", "--detach"])
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.reset(.mixed), first))

        #expect(presenter.failures.isEmpty)
        #expect(try await repository.sha("HEAD") == first.id)
    }

    // MARK: Reflog and Undo

    /// Three commits, then the third amended to change `c.txt`; returns the pre-amend sha.
    private func makeAmendedRepository() async throws -> (GitTestRepository, String) {
        let repository = try await GitTestRepository.make(prefix: "git-actions-undo")
        do {
            try await commitFile(repository, "a.txt", "a\n", at: 100)
            try await commitFile(repository, "b.txt", "b\n", at: 200)
            try await commitFile(repository, "c.txt", "c\n", at: 300)
            let beforeAmend = try await repository.sha("HEAD")
            try repository.write("c, amended\n", to: "c.txt")
            try await repository.run(["add", "--", "c.txt"])
            try await repository.run(["commit", "--amend", "-m", "c.txt amended"],
                                     environment: GitTestRepository.dated(Self.epoch + 400))
            return (repository, beforeAmend)
        } catch {
            repository.tearDown()
            throw error
        }
    }

    @Test("the model's reflog lists the amend first, and its undo target is the pre-amend commit")
    func undoTargetAfterAmend() async throws {
        let (repository, beforeAmend) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        let (model, _) = await makeSession(repository, presenter: StubPresenter())

        let entries = try await model.reflog(limit: 10)
        #expect(entries.first?.action == "commit (amend)")
        #expect(entries.first?.message == "c.txt amended")
        #expect(model.lastReflogEntry?.action == "commit (amend)")
        #expect(model.undoTarget?.sha == beforeAmend)
    }

    @Test("undo on a clean tree is a mixed reset to HEAD@{1}, at once, leaving the amend's change unstaged")
    func undoClean() async throws {
        let (repository, beforeAmend) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .undo)

        #expect(presenter.confirmations.isEmpty)
        #expect(presenter.failures.isEmpty)
        #expect(try await repository.sha("HEAD") == beforeAmend)
        #expect(model.staged.isEmpty)
        #expect(model.unstaged.map(\.path) == ["c.txt"])
        #expect(try String(contentsOf: repository.url("c.txt"), encoding: .utf8) == "c, amended\n")
    }

    @Test("undo on a dirty tree asks first; declining keeps HEAD, confirming keeps the changes unstaged")
    func undoDirty() async throws {
        let (repository, beforeAmend) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        let afterAmend = try await repository.sha("HEAD")
        try repository.write("a, edited\n", to: "a.txt")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [false, true]
        let (model, session) = await makeSession(repository, presenter: presenter)
        let expected = GitConfirmation(
            title: "Undo \"c.txt amended\"?",
            message: "HEAD moves to \(String(beforeAmend.prefix(8))); changes stay in the working copy.",
            actionTitle: "Undo", isDestructive: false)

        await act(session, .undo)
        #expect(presenter.confirmations == [expected])
        #expect(try await repository.sha("HEAD") == afterAmend)

        await act(session, .undo)
        #expect(presenter.confirmations == [expected, expected])
        #expect(presenter.failures.isEmpty)
        #expect(try await repository.sha("HEAD") == beforeAmend)
        #expect(model.staged.isEmpty)
        #expect(Set(model.unstaged.map(\.path)) == ["a.txt", "c.txt"])
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "a, edited\n")
    }

    @Test("undo with a partly staged file is a soft reset: the staged version survives, and the dialog says so")
    func undoPartlyStaged() async throws {
        let (repository, beforeAmend) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        try repository.write("a, staged\n", to: "a.txt")
        try await repository.run(["add", "--", "a.txt"])
        try repository.write("a, staged\nand not staged\n", to: "a.txt")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .undo)

        #expect(presenter.confirmations == [GitConfirmation(
            title: "Undo \"c.txt amended\"?",
            message: "HEAD moves to \(String(beforeAmend.prefix(8))); "
                + "the undone changes are staged with what is already staged.",
            actionTitle: "Undo", isDestructive: false)])
        #expect(presenter.failures.isEmpty)
        #expect(try await repository.sha("HEAD") == beforeAmend)
        #expect(try await repository.run(["show", ":a.txt"]) == "a, staged\n")
        #expect(try await repository.run(["show", ":c.txt"]) == "c, amended\n")
        #expect(try String(contentsOf: repository.url("a.txt"), encoding: .utf8) == "a, staged\nand not staged\n")
        #expect(Set(model.staged.map(\.path)) == ["a.txt", "c.txt"])
        #expect(model.unstaged.map(\.path) == ["a.txt"])
    }

    @Test("a commit landing while the Undo dialog is up makes Undo refresh instead of resetting past it")
    func undoRereadsAfterConfirming() async throws {
        let (repository, _) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        try repository.write("a, edited\n", to: "a.txt")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)
        presenter.whileConfirming = { try? await self.commitFile(repository, "d.txt", "d\n", at: 500) }

        await act(session, .undo)

        let newTip = try await repository.sha("HEAD")
        #expect(presenter.confirmations.count == 1)
        #expect(try await repository.run(["log", "-1", "--format=%s"]) == "d.txt 500\n")
        #expect(model.undoState.tip == newTip)
    }

    @Test("mid-rebase there is no undo target, and Undo does nothing")
    func undoMidRebase() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions-undo-rebase")
        defer { repository.tearDown() }
        try await commitFile(repository, "a.txt", "base\n", at: 100)
        try await repository.run(["branch", "feature"])
        try await commitFile(repository, "a.txt", "main\n", at: 200)
        try await repository.run(["switch", "-q", "feature"])
        try await commitFile(repository, "a.txt", "feature\n", at: 300)
        _ = try? await repository.run(["rebase", "main"])
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(model.operationState != .none)
        #expect(model.undoTarget == nil)
        let head = try await repository.sha("HEAD")

        await act(session, .undo)

        #expect(presenter.confirmations.isEmpty)
        #expect(try await repository.sha("HEAD") == head)
    }

    @Test("on a branch just created and checked out, Undo is disabled and never moves it onto the old tip")
    func undoAfterCreatingBranch() async throws {
        let (repository, _) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        let tip = try await repository.sha("HEAD")
        try await repository.run(["switch", "-q", "-c", "feature"])
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(model.undoState.ref == "refs/heads/feature")
        #expect(model.undoTarget == nil)

        await act(session, .undo)

        #expect(presenter.confirmations.isEmpty)
        #expect(try await repository.sha("refs/heads/feature") == tip)
        #expect(try await repository.sha("refs/heads/main") == tip)
        #expect(try await headName(repository) == "feature")
    }

    @Test("a reflog step that left the tip in place is skipped: the target is the first different commit")
    func undoSkipsSameShaEntry() async throws {
        let (repository, beforeAmend) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        let tip = try await repository.sha("HEAD")
        // Git 2.54 never logs a ref update that leaves the branch where it was (`reset HEAD`
        // writes only HEAD's reflog), but older gits and other tools do: append that entry.
        let log = try FileHandle(forWritingTo: repository.url(".git/logs/refs/heads/main"))
        try log.seekToEnd()
        let line = "\(tip) \(tip) Test <test@example.com> \(Self.epoch + 450) +0000\treset: moving to HEAD\n"
        try log.write(contentsOf: Data(line.utf8))
        try log.close()
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(model.lastReflogEntry?.sha == tip)
        #expect(model.undoState.entries.dropFirst().first?.sha == tip)
        #expect(model.undoTarget?.sha == beforeAmend)

        await act(session, .undo)

        #expect(presenter.failures.isEmpty)
        #expect(try await repository.sha("HEAD") == beforeAmend)
    }

    @Test("a commit made behind the model's back makes Undo refresh instead of resetting")
    func undoStaleModel() async throws {
        let (repository, _) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        let shownTip = try await repository.sha("HEAD")
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(model.undoState.tip == shownTip)
        try await commitFile(repository, "d.txt", "d\n", at: 500)
        let newTip = try await repository.sha("HEAD")

        await act(session, .undo)

        #expect(presenter.confirmations.isEmpty)
        #expect(presenter.failures.isEmpty)
        #expect(try await repository.sha("HEAD") == newTip)
        #expect(model.undoState.tip == newTip)
        #expect(model.undoTarget?.sha == shownTip)
    }

    @Test("a reflog entry's hard reset confirms; its checkout detaches and its branch is created there")
    func reflogIntents() async throws {
        let (repository, beforeAmend) = try await makeAmendedRepository()
        defer { repository.tearDown() }
        let afterAmend = try await repository.sha("HEAD")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [false]
        presenter.textAnswers = [["from-reflog"]]
        let (model, session) = await makeSession(repository, presenter: presenter)
        let entry = try #require(try await model.reflog(limit: 10).first { $0.sha == beforeAmend })

        await act(session, .reflog(.reset(entry, .hard)))
        #expect(presenter.confirmations == [GitConfirmation(
            title: "Reset main to \(entry.shortSha)?", message: "Uncommitted changes are lost.",
            actionTitle: "Reset", isDestructive: true)])
        #expect(try await repository.sha("HEAD") == afterAmend)

        await act(session, .reflog(.createBranch(entry)))
        #expect(await branchExists(repository, "from-reflog"))
        #expect(try await repository.sha("refs/heads/from-reflog") == beforeAmend)

        await act(session, .reflog(.checkout(entry)))
        #expect(presenter.failures.isEmpty)
        #expect(try await headName(repository) == "HEAD")
        #expect(try await repository.sha("HEAD") == beforeAmend)
    }

    // MARK: Diff staging

    /// Twenty numbered lines, committed, then lines 2 and 18 changed: two hunks.
    private func twoChangedRegions(_ repository: GitTestRepository) async throws {
        let lines = (1...20).map { "line \($0)" }
        try await commitFile(repository, "f.txt", lines.joined(separator: "\n") + "\n", at: 100)
        var changed = lines
        changed[1] = "two"
        changed[17] = "eighteen"
        try repository.write(changed.joined(separator: "\n") + "\n", to: "f.txt")
    }

    private func fileDiff(_ model: GitRepositoryModel, _ target: GitDiffTarget) async throws -> GitFileDiff {
        try #require(try await model.diff(target, options: GitDiffOptions()).files.first)
    }

    @Test("Stage Hunk stages only that hunk")
    func stageHunkFromTheDiff() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await twoChangedRegions(repository)
        let (model, session) = await makeSession(repository, presenter: StubPresenter())
        let file = try await fileDiff(model, .unstaged(paths: ["f.txt"]))
        #expect(file.hunks.count == 2)

        await act(session, .diff(.stage(.hunk(0, of: file))))

        #expect(model.staged.map(\.path) == ["f.txt"])
        let staged = try await fileDiff(model, .staged(paths: ["f.txt"]))
        #expect(staged.hunks.count == 1)
        #expect(staged.hunks.first?.lines.contains { $0.kind == .added && $0.text == "two" } == true)
        let unstaged = try await fileDiff(model, .unstaged(paths: ["f.txt"]))
        #expect(unstaged.hunks.count == 1)
        #expect(unstaged.hunks.first?.lines.contains { $0.kind == .added && $0.text == "eighteen" } == true)
    }

    @Test("the removal alone, then the addition alone, of a changed line stage on their own")
    func stageHalfOfAChangedPair() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "f.txt", "a\nold\nc\n", at: 100)
        try repository.write("a\nnew\nc\n", to: "f.txt")
        let (model, session) = await makeSession(repository, presenter: StubPresenter())
        let file = try await fileDiff(model, .unstaged(paths: ["f.txt"]))
        let lines = file.hunks[0].lines
        let removed = try #require(lines.firstIndex { $0.kind == .removed })

        await act(session, .diff(.stage(GitPatchSelection(file: file, lines: [0: IndexSet([removed])]))))

        #expect(try await repository.run(["show", ":f.txt"]) == "a\nc\n")
        let afterRemoval = try await fileDiff(model, .unstaged(paths: ["f.txt"]))

        let addedLine = try #require(afterRemoval.hunks[0].lines.firstIndex { $0.kind == .added })
        await act(session, .diff(.stage(GitPatchSelection(file: afterRemoval,
                                                          lines: [0: IndexSet([addedLine])]))))

        #expect(try await repository.run(["show", ":f.txt"]) == "a\nnew\nc\n")
    }

    @Test("Unstage Lines unstages only the selected lines")
    func unstageLinesFromTheDiff() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await twoChangedRegions(repository)
        try await repository.run(["add", "--", "f.txt"])
        let (model, session) = await makeSession(repository, presenter: StubPresenter())
        let file = try await fileDiff(model, .staged(paths: ["f.txt"]))
        let first = file.hunks[0].lines
        let changed = IndexSet(first.indices.filter { first[$0].kind == .added || first[$0].kind == .removed })

        await act(session, .diff(.unstage(GitPatchSelection(file: file, lines: [0: changed]))))

        let staged = try await fileDiff(model, .staged(paths: ["f.txt"]))
        #expect(staged.hunks.count == 1)
        #expect(staged.hunks.first?.lines.contains { $0.kind == .added && $0.text == "eighteen" } == true)
        #expect(model.unstaged.map(\.path) == ["f.txt"])
    }

    @Test("Discard Lines confirms; declining changes nothing, confirming removes the line")
    func discardLinesFromTheDiff() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "f.txt", "a\nb\nc\n", at: 100)
        try repository.write("a\nb\nnew\nc\n", to: "f.txt")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [false, true]
        let (model, session) = await makeSession(repository, presenter: presenter)
        let file = try await fileDiff(model, .unstaged(paths: ["f.txt"]))
        let lines = file.hunks[0].lines
        let added = try #require(lines.firstIndex { $0.kind == .added })
        let intent = GitWindowSession.Request.diff(.discard(GitPatchSelection(file: file,
                                                                              lines: [0: IndexSet([added])])))

        await act(session, intent)
        #expect(try String(contentsOf: repository.url("f.txt"), encoding: .utf8) == "a\nb\nnew\nc\n")

        await act(session, intent)
        let confirmation = GitConfirmation(title: "Discard 1 selected line?", message: "This cannot be undone.",
                                           actionTitle: "Discard", isDestructive: true)
        #expect(presenter.confirmations == [confirmation, confirmation])
        #expect(try String(contentsOf: repository.url("f.txt"), encoding: .utf8) == "a\nb\nc\n")
        #expect(model.unstaged.isEmpty)
        #expect(presenter.failures.isEmpty)
    }

    @Test("a diff intent with nothing to patch runs nothing")
    func emptyDiffIntentDoesNothing() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await twoChangedRegions(repository)
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)
        let file = try await fileDiff(model, .unstaged(paths: ["f.txt"]))

        await act(session, .diff(.discard(GitPatchSelection(file: file, lines: [0: IndexSet([0])]))))

        #expect(presenter.confirmations.isEmpty)
        #expect(presenter.failures.isEmpty)
        #expect(model.unstaged.map(\.path) == ["f.txt"])
    }

    // MARK: Merge, rebase and the operation banner

    /// `f.txt` changed on `side` and on `main` from one base, HEAD on `side`.
    private func divergedBranches(_ repository: GitTestRepository) async throws {
        try await commitFile(repository, "f.txt", "base\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "f.txt", "side\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "f.txt", "main\n", at: 300)
        try await repository.run(["checkout", "--quiet", "side"])
    }

    private func isRebasing(_ state: GitOperationState) -> Bool {
        if case .rebasing = state { return true }
        return false
    }

    /// Presses one of the banner's buttons the way AppKit does, and waits for the action.
    private func press(_ button: NSButton, in session: GitWindowSession) async throws {
        let target = try #require(button.target as? NSObject)
        target.perform(button.action, with: button)
        await session.actionTask?.value
    }

    @Test("a merge from the menu fast-forwards the checked-out branch, asking nothing")
    func mergeFastForwards() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "one.txt", "one\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "topic"])
        try await commitFile(repository, "two.txt", "two\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .ref(.merge(try ref(model, "refs/heads/topic"))))

        #expect(presenter.confirmations.isEmpty)
        #expect(presenter.failures.isEmpty)
        let main = try await repository.run(["rev-parse", "main"])
        let topic = try await repository.run(["rev-parse", "topic"])
        #expect(main == topic)
        #expect(session.banner.state == .none)
        #expect(session.banner.view.isHidden)
    }

    @Test("a conflicting rebase shows the failure, the banner and the conflicted file; Continue unresolved keeps it")
    func conflictingRebase() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await divergedBranches(repository)
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(session.banner.view.isHidden)

        await act(session, .ref(.rebaseOnto(try ref(model, "refs/heads/main"))))

        #expect(presenter.confirmations.isEmpty, "the menu was the confirmation")
        #expect(presenter.failures.count == 1)
        #expect(presenter.failures.first?.hasPrefix("Rebase failed: ") == true)
        #expect(isRebasing(session.banner.state))
        #expect(!session.banner.view.isHidden)
        #expect(session.banner.statusLabel.stringValue == "Rebasing side (1/1)")
        #expect(!session.banner.skipButton.isHidden)
        #expect(model.unstaged.map(\.path).contains("f.txt"))

        try await press(session.banner.continueButton, in: session)

        #expect(presenter.failures.count == 2)
        #expect(presenter.failures.last?.hasPrefix("Continue rebase failed: ") == true)
        #expect(isRebasing(session.banner.state), "a failed Continue leaves the banner up")

        try repository.write("resolved\n", to: "f.txt")
        try await repository.run(["add", "--", "f.txt"])
        try await press(session.banner.continueButton, in: session)

        #expect(presenter.failures.count == 2)
        #expect(session.banner.state == .none)
        #expect(session.banner.view.isHidden)
        let text = try String(contentsOf: repository.root.appendingPathComponent("f.txt"), encoding: .utf8)
        #expect(text == "resolved\n")
    }

    @Test("Abort confirms destructively; declining keeps the operation, confirming clears the banner")
    func abortConfirms() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await divergedBranches(repository)
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        await act(session, .ref(.rebaseOnto(try ref(model, "refs/heads/main"))))
        #expect(isRebasing(session.banner.state))

        presenter.confirmAnswers = [false]
        try await press(session.banner.abortButton, in: session)
        #expect(presenter.confirmations.count == 1)
        #expect(presenter.confirmations.first?.title == "Abort the rebase?")
        #expect(presenter.confirmations.first?.actionTitle == "Abort")
        #expect(presenter.confirmations.first?.isDestructive == true)
        #expect(isRebasing(session.banner.state), "declined, nothing ran")

        presenter.confirmAnswers = [true]
        try await press(session.banner.abortButton, in: session)
        #expect(session.banner.state == .none)
        #expect(session.banner.view.isHidden)
        #expect(try await headName(repository) == "side")
        #expect(presenter.failures.count == 1, "only the rebase's own failure")
    }

    @Test("an operation started outside the window shows the banner once the model reads it")
    func outsideOperationShowsTheBanner() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await divergedBranches(repository)
        let (model, session) = await makeSession(repository, presenter: StubPresenter())
        #expect(session.banner.view.isHidden)

        _ = try? await repository.run(["cherry-pick", "main"])
        await model.refresh([.operation])

        guard case .cherryPicking(let commit) = session.banner.state else {
            Issue.record("the banner shows \(session.banner.state)")
            return
        }
        let main = try await repository.run(["rev-parse", "main"]).trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(commit == main)
        #expect(!session.banner.view.isHidden)
        #expect(session.banner.statusLabel.stringValue == "Cherry-picking \(main.prefix(7))")
    }

    @Test("a ref dropped on the history pops up the sidebar's drop menu; a refused ref pops up nothing")
    func historyDropPopsUpTheMenu() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await divergedBranches(repository)
        let (_, session) = await makeSession(repository, presenter: StubPresenter())
        var shown: [NSMenu] = []
        session.sidebar.menuPresenter = { menu, _ in shown.append(menu) }

        session.history.onRefDrop?("refs/heads/side")
        #expect(shown.isEmpty, "HEAD onto itself")
        #expect(session.history.refDropValidator?("refs/heads/side") == false)
        session.history.onRefDrop?("refs/heads/main")
        #expect(shown.count == 1)
        #expect(shown.first?.items.map(\.title) == ["Merge into side", "Rebase side onto main", "", "Cancel"])
    }

    // MARK: Conflicts and the merge view

    /// `f.txt` with two lines changed on `side` and on `main` from one base, HEAD on `side`
    /// merging `main`: one UU conflict over the first line.
    private func bothModifiedConflict(_ repository: GitTestRepository) async throws {
        try await commitFile(repository, "f.txt", "one\ntwo\nthree\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "f.txt", "ONE side\ntwo\nthree\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "f.txt", "ONE main\ntwo\nthree\n", at: 300)
        try await repository.run(["checkout", "--quiet", "side"])
        _ = try? await repository.run(["merge", "--no-edit", "main"])
    }

    @Test("a UU conflict opened in the merge view, chosen ours throughout and saved, is resolved and staged")
    func mergeViewResolvesBothModified() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await bothModifiedConflict(repository)
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(model.conflicts == ["f.txt": .bothModified])
        #expect(session.workingCopy.conflictsList.files.map(\.path) == ["f.txt"])

        await act(session, .workingCopy(.openMerge("f.txt")))
        #expect(session.bottom.content === session.merge)
        #expect(session.merge.path == "f.txt")
        let total = try #require(session.merge.document?.conflictCount)
        #expect(total >= 1)

        session.merge.loadViewIfNeeded()
        for index in 0..<total {
            if index > 0 { session.merge.nextButton.performClick(nil) }
            session.merge.oursButton.performClick(nil)
        }
        #expect(session.merge.saveButton.isEnabled)
        session.merge.saveButton.performClick(nil)
        await session.actionTask?.value

        #expect(presenter.confirmations.isEmpty, "Save does not confirm")
        #expect(presenter.failures.isEmpty)
        let ours = try await repository.run(["show", "side:f.txt"])
        let text = try String(contentsOf: repository.root.appendingPathComponent("f.txt"), encoding: .utf8)
        #expect(text == ours)
        #expect(text == "ONE side\ntwo\nthree\n")
        #expect(model.conflicts.isEmpty)
        #expect(model.staged.isEmpty, "ours is HEAD's version, so the staged file differs from nothing")
        #expect(!model.unstaged.contains { $0.path == "f.txt" })
        let stages = try await repository.run(["ls-files", "--stage", "--", "f.txt"])
        #expect(stages.split(separator: "\n").count == 1 && stages.contains(" 0\tf.txt"), "staged at stage 0")
        #expect(session.bottom.content === session.diff, "the bottom pane returns to the diff")
    }

    @Test("a conflict that does not parse opens as its diff instead")
    func unparsableConflictShowsTheDiff() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await bothModifiedConflict(repository)
        try repository.write("no markers left\n", to: "f.txt")
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        await act(session, .workingCopy(.openMerge("f.txt")))
        #expect(session.bottom.content === session.diff)
        #expect(presenter.failures.isEmpty)
    }

    @Test("a conflicted file over the merge view's cap shows its diff, markers and all")
    func oversizedConflictShowsTheDiff() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await bothModifiedConflict(repository)
        let marked = try String(contentsOf: repository.url("f.txt"), encoding: .utf8)
        #expect(GitConflictDocument.parse(marked) != nil)
        let padding = String(repeating: "padding line\n", count: GitMergeViewController.maximumFileBytes / 13 + 1)
        try repository.write(marked + padding, to: "f.txt")
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        await act(session, .workingCopy(.openMerge("f.txt")))
        #expect(session.bottom.content === session.diff)
        #expect(session.bottom.content !== session.merge)
        #expect(presenter.failures.isEmpty)
    }

    @Test("Mark Resolved stages the file as it stands, asking nothing")
    func markResolvedStages() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await bothModifiedConflict(repository)
        try repository.write("hand merged\n", to: "f.txt")
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .workingCopy(.markResolved(["f.txt"])))
        #expect(presenter.confirmations.isEmpty)
        #expect(model.conflicts.isEmpty)
        #expect(model.staged.map(\.path) == ["f.txt"])
    }

    @Test("Resolve Using Ours… confirms destructively; declined, the conflict stays")
    func resolveConfirms() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await bothModifiedConflict(repository)
        let presenter = StubPresenter()
        presenter.confirmAnswers = [false]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .workingCopy(.resolve(["f.txt"], .ours)))
        #expect(presenter.confirmations.count == 1)
        #expect(presenter.confirmations.first?.isDestructive == true)
        #expect(presenter.confirmations.first?.actionTitle == "Use Ours")
        #expect(model.conflicts == ["f.txt": .bothModified])

        presenter.confirmAnswers = [true]
        await act(session, .workingCopy(.resolve(["f.txt"], .ours)))
        #expect(model.conflicts.isEmpty)
        let text = try String(contentsOf: repository.root.appendingPathComponent("f.txt"), encoding: .utf8)
        #expect(text == "ONE side\ntwo\nthree\n")
        #expect(model.staged.isEmpty, "ours is HEAD's version, so the staged file differs from nothing")
        #expect(!model.unstaged.contains { $0.path == "f.txt" })
    }

    @Test("a UD conflict resolved using theirs, confirmed, removes the file and the conflict")
    func resolveDeletedByThemUsingTheirs() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "f.txt", "base\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "f.txt", "side\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        try await repository.run(["rm", "--quiet", "--", "f.txt"])
        try await repository.commit("delete f.txt", at: Self.epoch + 300)
        try await repository.run(["checkout", "--quiet", "side"])
        _ = try? await repository.run(["merge", "--no-edit", "main"])
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(model.conflicts == ["f.txt": .deletedByThem])

        await act(session, .workingCopy(.resolve(["f.txt"], .theirs)))

        #expect(presenter.confirmations.count == 1)
        #expect(presenter.confirmations.first?.actionTitle == "Use Theirs")
        #expect(presenter.failures.isEmpty)
        #expect(model.conflicts.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: repository.root.appendingPathComponent("f.txt").path))
        let indexed = try await repository.run(["ls-files", "--", "f.txt"])
        #expect(indexed.isEmpty)
    }

    @Test("selecting a UD conflict shows its working file against the base; a UU one opens the merge view")
    func selectingAConflict() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "f.txt", "one\ntwo\nthree\n", at: 100)
        try await commitFile(repository, "gone.txt", "base\n", at: 110)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "f.txt", "ONE side\ntwo\nthree\n", at: 200)
        try await commitFile(repository, "gone.txt", "kept on side\n", at: 210)
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "f.txt", "ONE main\ntwo\nthree\n", at: 300)
        try await repository.run(["rm", "--quiet", "--", "gone.txt"])
        try await repository.commit("delete gone.txt", at: Self.epoch + 310)
        try await repository.run(["checkout", "--quiet", "side"])
        _ = try? await repository.run(["merge", "--no-edit", "main"])
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(model.conflicts == ["f.txt": .bothModified, "gone.txt": .deletedByThem])

        let plain = try await model.diff(.unstaged(paths: ["gone.txt"]), options: GitDiffOptions())
        #expect(plain.files.isEmpty, "a plain diff of an unmerged path is blank")
        let conflicted = try await fileDiff(model, .conflicted(path: "gone.txt"))
        #expect(conflicted.newPath == "gone.txt")
        let lines = conflicted.hunks.flatMap(\.lines).map(\.text)
        #expect(lines.contains("base") && lines.contains("kept on side"))
        #expect(conflicted.oldRevision == ":1")

        let list = session.workingCopy.conflictsList
        #expect(list.files.map(\.path) == ["f.txt", "gone.txt"])
        list.tableView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        #expect(session.bottom.content === session.diff)
        #expect(session.diff.isShowingWorkingCopy)

        list.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        await session.mergeOpenTask?.value
        #expect(session.bottom.content === session.merge)
        #expect(session.merge.path == "f.txt")
        #expect(presenter.failures.isEmpty)
    }

    @Test("a newer selection wins over a merge open still reading, and an open is not dropped while busy")
    func conflictOpenIsUngatedAndLatestWins() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "f.txt", "one\ntwo\nthree\n", at: 100)
        try await commitFile(repository, "gone.txt", "base\n", at: 110)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "f.txt", "ONE side\ntwo\nthree\n", at: 200)
        try await commitFile(repository, "gone.txt", "kept on side\n", at: 210)
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "f.txt", "ONE main\ntwo\nthree\n", at: 300)
        try await repository.run(["rm", "--quiet", "--", "gone.txt"])
        try await repository.commit("delete gone.txt", at: Self.epoch + 310)
        try await repository.run(["checkout", "--quiet", "side"])
        _ = try? await repository.run(["merge", "--no-edit", "main"])
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)
        let list = session.workingCopy.conflictsList
        #expect(list.files.map(\.path) == ["f.txt", "gone.txt"])

        // Marked f.txt, then unmarked gone.txt before f.txt's read returns: gone.txt's diff stays.
        list.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        list.tableView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        await session.mergeOpenTask?.value
        #expect(session.bottom.content === session.diff)
        #expect(session.diff.isShowingWorkingCopy)
        #expect(session.merge.path == nil)

        // Another action running does not drop the open.
        session.isActing = true
        list.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        await session.mergeOpenTask?.value
        #expect(session.bottom.content === session.merge)
        #expect(session.merge.path == "f.txt")
        session.isActing = false
        #expect(presenter.failures.isEmpty)
    }

    @Test("a both-added conflict, with no base stage, diffs against HEAD")
    func bothAddedConflictDiffsAgainstHead() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", "base\n", at: 100)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "new.txt", "side\n", at: 200)
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "new.txt", "main\n", at: 300)
        try await repository.run(["checkout", "--quiet", "side"])
        _ = try? await repository.run(["merge", "--no-edit", "main"])
        let (model, _) = await makeSession(repository, presenter: StubPresenter())
        #expect(model.conflicts == ["new.txt": .bothAdded])

        let file = try await fileDiff(model, .conflicted(path: "new.txt"))
        let lines = file.hunks.flatMap(\.lines)
        #expect(lines.contains { $0.kind == .context && $0.text == "side" }, "HEAD's line is context")
        #expect(lines.contains { $0.kind == .added && $0.text == "main" })
        #expect(file.oldRevision == "HEAD", "the colouring reads the old side where the diff did")
    }

    @Test("an added-by-us conflict whose working file is ours shows the file as added, not a blank detail")
    func addedByUsConflictIsNotBlank() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", "base\n", at: 100)
        try await commitFile(repository, "a.txt", "ours\n", at: 200)
        // A rename/rename: a.txt to b.txt here, to c.txt on side. b.txt is ours alone (stage
        // 2, AU) and its working file is HEAD's, so neither a base nor HEAD shows a change.
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await repository.run(["mv", "--", "a.txt", "c.txt"])
        try await repository.commit("to c", at: Self.epoch + 300)
        try await repository.run(["checkout", "--quiet", "main"])
        try await repository.run(["mv", "--", "a.txt", "b.txt"])
        try await repository.commit("to b", at: Self.epoch + 310)
        _ = try? await repository.run(["merge", "--no-edit", "side"])
        let (model, _) = await makeSession(repository, presenter: StubPresenter())
        #expect(model.conflicts["b.txt"] == .addedByUs)

        let file = try await fileDiff(model, .conflicted(path: "b.txt"))
        #expect(file.newPath == "b.txt")
        #expect(file.oldRevision == nil)
        #expect(file.hunks.flatMap(\.lines).contains { $0.kind == .added && $0.text == "ours" })
    }

    @Test("Discard All Changes… leaves conflicted files alone")
    func discardAllSkipsConflicts() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await bothModifiedConflict(repository)
        try repository.write("scratch\n", to: "new.txt")
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .workingCopy(.discardAll))
        #expect(presenter.confirmations.first?.title == "Discard changes to 1 file?")
        #expect(model.conflicts == ["f.txt": .bothModified])
    }

    @Test("Stage All with a conflict stages only the listed files and leaves the conflict unmerged")
    func stageAllSkipsConflicts() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "other.txt", "first\n", at: 50)
        try await bothModifiedConflict(repository)
        try repository.write("second\n", to: "other.txt")
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)
        #expect(model.conflicts == ["f.txt": .bothModified])

        await act(session, .workingCopy(.stageAll))

        #expect(presenter.confirmations.isEmpty)
        #expect(presenter.failures.isEmpty)
        #expect(model.conflicts == ["f.txt": .bothModified], "the conflict is still unmerged")
        let unmerged = try await repository.run(["ls-files", "--unmerged", "--", "f.txt"])
        #expect(!unmerged.isEmpty)
        #expect(model.staged.map(\.path) == ["other.txt"])
        #expect(session.workingCopy.conflictsList.files.map(\.path) == ["f.txt"])
    }

    @Test("Stage All with only conflicts left runs nothing")
    func stageAllWithOnlyConflicts() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await bothModifiedConflict(repository)
        let presenter = StubPresenter()
        let (model, session) = await makeSession(repository, presenter: presenter)

        await act(session, .workingCopy(.stageAll))

        #expect(presenter.failures.isEmpty)
        #expect(model.conflicts == ["f.txt": .bothModified])
        #expect(model.staged.isEmpty)
    }

    // MARK: Interactive rebase

    /// A repository with `base` and three commits after it, each touching its own file.
    private func makeRebaseRepository() async throws -> GitTestRepository {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        try await commitFile(repository, "base.txt", "base\n", at: 10)
        try await commitFile(repository, "a.txt", "a\n", at: 20)
        try await commitFile(repository, "b.txt", "b\n", at: 30)
        try await commitFile(repository, "c.txt", "c\n", at: 40)
        return repository
    }

    private func subjects(_ repository: GitTestRepository, _ range: String) async throws -> [String] {
        try await repository.run(["log", "--format=%s", "--reverse", range])
            .split(separator: "\n").map(String.init)
    }

    @Test("Interactive Rebase from Here shows the plan with messages filled and runs what the editor returns")
    func interactiveRebaseSwapsTwoCommits() async throws {
        let repository = try await makeRebaseRepository()
        defer { repository.tearDown() }
        let base = try await commit(repository, "HEAD~3")
        let presenter = StubPresenter()
        presenter.editRebaseAnswer = { plan in
            var edited = plan
            edited.entries.swapAt(1, 2)
            return edited
        }
        let (_, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.interactiveRebase, base))

        #expect(presenter.failures.isEmpty)
        let shown = try #require(presenter.rebasePlans.first)
        #expect(presenter.rebasePlans.count == 1)
        #expect(shown.onto == base.id)
        #expect(shown.entries.map(\.subject) == ["a.txt 20", "b.txt 30", "c.txt 40"])
        #expect(shown.entries.map(\.message) == ["a.txt 20", "b.txt 30", "c.txt 40"])
        #expect(shown.entries.allSatisfy { $0.action == .pick })
        #expect(try await subjects(repository, "\(base.id)..HEAD") == ["a.txt 20", "c.txt 40", "b.txt 30"])
    }

    @Test("cancelling the rebase editor runs nothing")
    func interactiveRebaseCancelled() async throws {
        let repository = try await makeRebaseRepository()
        defer { repository.tearDown() }
        let before = try await repository.run(["rev-parse", "HEAD"])
        let base = try await commit(repository, "HEAD~3")
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.interactiveRebase, base))

        #expect(presenter.rebasePlans.count == 1)
        #expect(presenter.failures.isEmpty)
        #expect(try await repository.run(["rev-parse", "HEAD"]) == before)
        #expect(try await subjects(repository, "\(base.id)..HEAD") == ["a.txt 20", "b.txt 30", "c.txt 40"])
    }

    @Test("a range the plan cannot be built for shows Interactive rebase failed and no editor")
    func interactiveRebaseOverAMerge() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        defer { repository.tearDown() }
        try await commitFile(repository, "base.txt", "base\n", at: 10)
        try await repository.run(["checkout", "--quiet", "-b", "side"])
        try await commitFile(repository, "side.txt", "side\n", at: 20)
        try await repository.run(["checkout", "--quiet", "main"])
        try await commitFile(repository, "main.txt", "main\n", at: 30)
        try await repository.run(["merge", "--quiet", "--no-ff", "--no-edit", "side"])
        let base = try await commit(repository, "HEAD~2")
        let presenter = StubPresenter()
        let (_, session) = await makeSession(repository, presenter: presenter)

        await act(session, .commit(.interactiveRebase, base))

        #expect(presenter.rebasePlans.isEmpty)
        #expect(presenter.failures.count == 1)
        #expect(presenter.failures.first?.hasPrefix("Interactive rebase failed: ") == true)
    }

    // MARK: Worktrees and submodules

    /// The worktrees' directories as git lists them, symlinks resolved.
    private func worktreePaths(_ model: GitRepositoryModel) -> Set<String> {
        Set(model.worktrees.map { $0.directory.resolvingSymlinksInPath().path })
    }

    @Test("New Worktree from the header with an empty folder lands beside the repository and opens")
    func newWorktreeAtTheDerivedFolder() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        let derived = repository.root.deletingLastPathComponent()
            .appendingPathComponent("\(repository.root.lastPathComponent)-topic-x", isDirectory: true)
        defer {
            repository.tearDown()
            try? FileManager.default.removeItem(at: derived)
        }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        let presenter = StubPresenter()
        presenter.textAnswers = [["topic/x", ""]]
        let (model, session) = await makeSession(repository, presenter: presenter)
        var opened: [URL] = []
        session.onOpenDirectory = { opened.append($0) }

        await act(session, .ref(.newWorktree(branch: nil)))

        #expect(presenter.failures.isEmpty)
        let request = try #require(presenter.textRequests.first)
        #expect(request.title == "New Worktree")
        #expect(request.actionTitle == "Create Worktree")
        #expect(request.fields == [GitTextField(label: "Branch", initial: "", isOptional: false),
                                   GitTextField(label: "Folder", initial: "", isOptional: true)])
        #expect(opened.map(\.path) == [derived.path])
        #expect(await branchExists(repository, "topic/x"))
        #expect(worktreePaths(model).contains(derived.resolvingSymlinksInPath().path))
        #expect(model.worktrees.contains { $0.branch == "topic/x" })
    }

    @Test("Check Out in New Worktree on an existing branch prefills it and checks it out without a new branch")
    func newWorktreeOnAnExistingBranch() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-actions-side-\(UUID().uuidString)", isDirectory: true)
        defer {
            repository.tearDown()
            try? FileManager.default.removeItem(at: folder)
        }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["branch", "side"])
        let presenter = StubPresenter()
        presenter.textAnswers = [["side", folder.path]]
        let (model, session) = await makeSession(repository, presenter: presenter)
        var opened: [URL] = []
        session.onOpenDirectory = { opened.append($0) }

        await act(session, .ref(.newWorktree(branch: try ref(model, "refs/heads/side"))))

        #expect(presenter.failures.isEmpty)
        #expect(presenter.textRequests.first?.fields.first?.initial == "side")
        #expect(opened.map(\.path) == [folder.path])
        let tree = try #require(model.worktrees.first { !$0.isMain })
        #expect(tree.branch == "side")
        #expect(tree.directory.resolvingSymlinksInPath().path == folder.resolvingSymlinksInPath().path)
    }

    @Test("removing a dirty worktree asks twice and forces; declining the second keeps it")
    func removeDirtyWorktree() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-actions-dirty-\(UUID().uuidString)", isDirectory: true)
        defer {
            repository.tearDown()
            try? FileManager.default.removeItem(at: folder)
        }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["worktree", "add", "-q", "-b", "dirty", folder.path])
        let canonical = folder.canonicalFileURL.path
        try "x\n".write(to: folder.appendingPathComponent("untracked.txt"), atomically: true, encoding: .utf8)
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true, false]
        let (model, session) = await makeSession(repository, presenter: presenter)
        var removed: [URL] = []
        session.onRemoveDirectory = { removed.append($0) }
        let tree = try #require(model.worktrees.first { !$0.isMain })

        await act(session, .ref(.removeWorktree(tree)))
        #expect(presenter.confirmations.count == 2)
        #expect(presenter.failures.isEmpty)
        #expect(model.worktrees.count == 2)
        #expect(removed.isEmpty, "a worktree kept closes no window")

        presenter.confirmAnswers = [true, true]
        await act(session, .ref(.removeWorktree(tree)))

        #expect(presenter.failures.isEmpty)
        let titles = presenter.confirmations.map(\.title)
        #expect(titles == ["Remove worktree \(tree.directory.lastPathComponent)?",
                           "Remove worktree with uncommitted changes?",
                           "Remove worktree \(tree.directory.lastPathComponent)?",
                           "Remove worktree with uncommitted changes?"])
        #expect(presenter.confirmations.allSatisfy { $0.isDestructive })
        #expect(presenter.confirmations.first?.actionTitle == "Remove")
        #expect(model.worktrees.count == 1)
        #expect(!FileManager.default.fileExists(atPath: folder.path))
        #expect(removed.map(\.path) == [canonical])
    }

    @Test("a clean worktree is removed after one confirmation")
    func removeCleanWorktree() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-actions")
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-actions-clean-\(UUID().uuidString)", isDirectory: true)
        defer {
            repository.tearDown()
            try? FileManager.default.removeItem(at: folder)
        }
        try await commitFile(repository, "a.txt", "a\n", at: 100)
        try await repository.run(["worktree", "add", "-q", "-b", "clean", folder.path])
        let canonical = folder.canonicalFileURL.path
        let presenter = StubPresenter()
        presenter.confirmAnswers = [true]
        let (model, session) = await makeSession(repository, presenter: presenter)
        var removed: [URL] = []
        session.onRemoveDirectory = { removed.append($0) }
        let tree = try #require(model.worktrees.first { !$0.isMain })

        await act(session, .ref(.removeWorktree(tree)))

        #expect(presenter.confirmations.count == 1)
        #expect(presenter.failures.isEmpty)
        #expect(model.worktrees.count == 1)
        #expect(removed.map(\.path) == [canonical], "the removed worktree's window is told to close")
    }

    @Test("a new worktree's folder: blank derives it, relative is beside the root, ~ is home, absolute is kept")
    func worktreeFolderSpellings() {
        let root = URL(fileURLWithPath: "/work/app", isDirectory: true)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        func folder(_ typed: String, _ branch: String = "topic/x") -> String {
            GitWindowSession.worktreeFolder(typed, branch: branch, root: root).path
        }

        #expect(folder("") == "/work/app-topic-x")
        #expect(folder("  \t\n ") == "/work/app-topic-x", "whitespace alone is blank")
        #expect(folder("side") == "/work/side")
        #expect(folder("../elsewhere/side") == "/elsewhere/side")
        #expect(folder(" side ") == "/work/side", "the typed folder is trimmed")
        #expect(folder("~/trees/side") == (home as NSString).appendingPathComponent("trees/side"))
        #expect(folder("/abs/side") == "/abs/side")
    }

    @Test("Update on an uninitialized submodule initializes and checks it out")
    func updateUninitializedSubmodule() async throws {
        let library = try await GitTestRepository.make(prefix: "git-actions-library")
        let superproject = try await GitTestRepository.make(prefix: "git-actions-super")
        var clone: GitTestRepository?
        defer {
            library.tearDown()
            superproject.tearDown()
            clone?.tearDown()
        }
        try await commitFile(library, "lib.txt", "lib\n", at: 100)
        try await commitFile(superproject, "app.txt", "app\n", at: 100)
        try await superproject.run(["-c", "protocol.file.allow=always", "submodule", "add", "-q",
                                    library.root.path, "lib"])
        try await superproject.run(["commit", "-q", "-m", "add lib"])
        let cloned = try await GitTestRepository.clone(of: superproject, prefix: "git-actions-clone")
        clone = cloned
        let presenter = StubPresenter()
        let (model, session) = await makeSession(cloned, presenter: presenter, client: localFileClient)
        let submodule = try #require(model.submodules.first)
        #expect(submodule.state == .uninitialized)

        await act(session, .ref(.updateSubmodule(submodule)))

        #expect(presenter.failures.isEmpty)
        #expect(model.submodules.map(\.state) == [.current])
        #expect(FileManager.default.fileExists(atPath: cloned.url("lib/lib.txt").path))
    }
}
