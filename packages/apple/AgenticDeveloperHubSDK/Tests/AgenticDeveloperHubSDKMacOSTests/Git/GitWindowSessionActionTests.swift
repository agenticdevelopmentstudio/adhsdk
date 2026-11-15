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

    func confirm(_ request: GitConfirmation) async -> Bool {
        onAsk?()
        confirmations.append(request)
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
}

/// The Git window's actions (recipe `workspace/git/git-window`, "Actions"), each run
/// through the session against a real repository in the temp directory, with a
/// presenter that answers from a script. Remotes are bare repositories beside it.
@Suite("GitWindowSession actions", .serialized)
@MainActor
struct GitWindowSessionActionTests {
    private static let epoch = 1_767_268_800
    private let client = GitClient(configuration: .default)

    // MARK: Fixtures

    private func commitFile(_ repository: GitTestRepository, _ name: String, _ text: String,
                            at offset: Int) async throws {
        try repository.write(text, to: name)
        try await repository.run(["add", "--", name])
        try await repository.commit("\(name) \(offset)", at: Self.epoch + offset)
    }

    private func makeSession(
        _ repository: GitTestRepository, presenter: StubPresenter?
    ) async -> (GitRepositoryModel, GitWindowSession) {
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
}
