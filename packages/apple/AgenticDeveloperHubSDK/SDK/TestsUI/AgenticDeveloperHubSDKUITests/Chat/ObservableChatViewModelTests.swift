import Testing
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@MainActor
private func waitUntil(timeout: TimeInterval = 2.0, _ condition: () -> Bool) async throws {
    struct TimedOut: Error {}
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline { throw TimedOut() }
        await Task.yield()
        try? await Task.sleep(nanoseconds: 1_000_000)
    }
}

private func label(_ update: ChatUpdate) -> String {
    switch update {
    case .messagesChanged: return "messagesChanged"
    case .participantsChanged: return "participantsChanged"
    case .typingChanged: return "typingChanged"
    case .readMarkersChanged: return "readMarkersChanged"
    case .activeDraftsChanged: return "activeDraftsChanged"
    case .pendingPermissionsChanged: return "pendingPermissionsChanged"
    case .pendingWidgetsChanged: return "pendingWidgetsChanged"
    case .displayConfigChanged: return "displayConfigChanged"
    case .commandActivityChanged: return "commandActivityChanged"
    case .statusChanged: return "statusChanged"
    case .error(let message): return "error(\(message))"
    }
}

@MainActor
@Suite("ObservableChatViewModel")
struct ObservableChatViewModelTests {

    private func makeViewModel(localParticipantID: String = "user-1") -> (ObservableChatViewModel, FakeBackend) {
        let backend = FakeBackend()
        let viewModel = ObservableChatViewModel(backend: backend, localParticipantID: localParticipantID)
        return (viewModel, backend)
    }

    // MARK: Init defaults

    @Test("starts empty")
    func initDefaults() {
        let (viewModel, _) = makeViewModel()
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.participants.isEmpty)
        #expect(viewModel.activeDrafts.isEmpty)
        #expect(viewModel.typingParticipants.isEmpty)
        #expect(viewModel.readMarkers.isEmpty)
        #expect(viewModel.pendingPermissions.isEmpty)
        #expect(viewModel.pendingWidgets.isEmpty)
        #expect(viewModel.statuses.isEmpty)
        #expect(viewModel.listCommands().isEmpty)
    }

    @Test("conversation carries the given id and mirrors participants")
    func conversationTracksParticipants() {
        let (viewModel, _) = makeViewModel()
        viewModel.handle(.participantJoined(FixtureParticipant.persona()))
        #expect(viewModel.conversation.participants.map(\.id) == ["persona-1"])
    }

    // MARK: draftUpdated — the replace-not-append invariant

    @Test("draftUpdated REPLACES the draft's text rather than appending to it")
    func draftUpdatedReplacesRatherThanAppends() {
        let (viewModel, _) = makeViewModel()
        viewModel.handle(.draftUpdated(participantID: "persona-1", text: "Hel", attachments: []))
        viewModel.handle(.draftUpdated(participantID: "persona-1", text: "Hello", attachments: []))
        #expect(viewModel.activeDrafts.count == 1)
        #expect(viewModel.activeDrafts.first?.text == "Hello")
    }

    @Test("draftCleared removes the draft")
    func draftClearedRemovesDraft() {
        let (viewModel, _) = makeViewModel()
        viewModel.handle(.draftUpdated(participantID: "persona-1", text: "Hi", attachments: []))
        viewModel.handle(.draftCleared(participantID: "persona-1"))
        #expect(viewModel.activeDrafts.isEmpty)
    }

    @Test("draftUpdated/draftCleared notify activeDraftsChanged")
    func draftEventsNotify() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        viewModel.handle(.draftUpdated(participantID: "persona-1", text: "Hi", attachments: []))
        viewModel.handle(.draftCleared(participantID: "persona-1"))
        #expect(observer.updates.map(label) == ["activeDraftsChanged", "activeDraftsChanged"])
    }

    // MARK: statusChanged — the out-of-band invariant

    @Test("statusChanged never produces a Message or a draft, but does notify")
    func statusChangedIsOutOfBand() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        let before = viewModel.messages.count

        viewModel.handle(.statusChanged(participantID: "persona-1", status: ChatStatus(kind: .think)))
        #expect(viewModel.messages.count == before)
        #expect(viewModel.activeDrafts.isEmpty)
        #expect(viewModel.statuses["persona-1"]?.kind == .think)

        viewModel.handle(.statusChanged(participantID: "persona-1", status: nil))
        #expect(viewModel.statuses["persona-1"] == nil)
        #expect(viewModel.messages.count == before)
        #expect(viewModel.activeDrafts.isEmpty)

        // The half that was missing. Both edges are observable, because the
        // indicator has to learn about the settle as well as the start —
        // without the second one it spins forever on a finished turn.
        #expect(observer.updates.map(label) == ["statusChanged", "statusChanged"])
    }

    // MARK: Message lifecycle

    @Test("submitMessage records an optimistic local echo and returns the backend's localID")
    func submitMessageAddsOptimisticEcho() async throws {
        let (viewModel, backend) = makeViewModel()
        backend.sendResult = .success("local-42")
        let observer = RecordingObserver()
        viewModel.addObserver(observer)

        let localID = try await viewModel.submitMessage(text: "hello", attachments: [])
        #expect(localID == "local-42")
        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages.first?.localID == "local-42")
        #expect(viewModel.messages.first?.text == "hello")
        #expect(viewModel.messages.first?.deliveryStatus == .sending)
        #expect(observer.updates.map(label) == ["messagesChanged"])
    }

    @Test("submitMessage propagates a backend failure and adds nothing")
    func submitMessagePropagatesFailure() async {
        let (viewModel, backend) = makeViewModel()
        backend.sendResult = .failure(FakeSendError(message: "offline"))
        await #expect(throws: FakeSendError.self) {
            _ = try await viewModel.submitMessage(text: "hello", attachments: [])
        }
        #expect(viewModel.messages.isEmpty)
    }

    @Test("messageAccepted resolves the matching optimistic echo")
    func messageAcceptedResolvesEcho() async throws {
        let (viewModel, backend) = makeViewModel()
        backend.sendResult = .success("local-1")
        _ = try await viewModel.submitMessage(text: "hi", attachments: [])

        let at = Date()
        viewModel.handle(.messageAccepted(localID: "local-1", serverID: "server-1", at: at))
        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages.first?.id == "server-1")
        #expect(viewModel.messages.first?.deliveryStatus == .sent)
    }

    @Test("messageDelivered marks the message delivered")
    func messageDeliveredUpdatesStatus() async throws {
        let (viewModel, backend) = makeViewModel()
        backend.sendResult = .success("local-1")
        _ = try await viewModel.submitMessage(text: "hi", attachments: [])
        viewModel.handle(.messageAccepted(localID: "local-1", serverID: "server-1", at: Date()))

        viewModel.handle(.messageDelivered(messageID: "server-1", at: Date()))
        #expect(viewModel.messages.first?.deliveryStatus == .delivered)
    }

    @Test("messageFailed marks the message failed with its reason")
    func messageFailedUpdatesStatus() async throws {
        let (viewModel, backend) = makeViewModel()
        backend.sendResult = .success("local-1")
        _ = try await viewModel.submitMessage(text: "hi", attachments: [])

        viewModel.handle(.messageFailed(localID: "local-1", reason: "timed out"))
        #expect(viewModel.messages.first?.deliveryStatus == .failed(reason: "timed out"))
    }

    @Test("messageReceived appends a new message and upserts a repeated localID")
    func messageReceivedAppendsAndUpserts() {
        let (viewModel, _) = makeViewModel()
        let incoming = FixtureMessage(id: "server-9", localID: "server-9", senderID: "persona-1", text: "hello there", timestamp: Date())
        viewModel.handle(.messageReceived(incoming))
        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages.first?.text == "hello there")

        let updated = FixtureMessage(id: "server-9", localID: "server-9", senderID: "persona-1", text: "hello there!", timestamp: Date())
        viewModel.handle(.messageReceived(updated))
        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages.first?.text == "hello there!")
    }

    // MARK: Read markers

    @Test("readMarkerAdvanced upserts a marker per participant")
    func readMarkerAdvancedUpserts() {
        let (viewModel, _) = makeViewModel()
        viewModel.handle(.readMarkerAdvanced(participantID: "persona-1", upToMessageID: "m1", at: Date()))
        viewModel.handle(.readMarkerAdvanced(participantID: "persona-1", upToMessageID: "m2", at: Date()))
        #expect(viewModel.readMarkers.count == 1)
        #expect(viewModel.readMarkers.first?.upToMessageID == "m2")
    }

    @Test("markRead advances the local participant's own cursor")
    func markReadAdvancesLocalCursor() async throws {
        let (viewModel, _) = makeViewModel(localParticipantID: "user-1")
        try await viewModel.markRead(messageID: "m1")
        #expect(viewModel.readMarkers.first?.participantID == "user-1")
        #expect(viewModel.readMarkers.first?.upToMessageID == "m1")
    }

    // MARK: Participants

    @Test("participantJoined adds, participantDeparted removes")
    func participantLifecycle() {
        let (viewModel, _) = makeViewModel()
        viewModel.handle(.participantJoined(FixtureParticipant.persona()))
        #expect(viewModel.participants.map(\.id) == ["persona-1"])
        viewModel.handle(.participantDeparted(participantID: "persona-1"))
        #expect(viewModel.participants.isEmpty)
    }

    // MARK: Typing

    @Test("typing adds without duplicates and removes on false")
    func typingTracksParticipants() {
        let (viewModel, _) = makeViewModel()
        viewModel.handle(.typing(participantID: "persona-1", isTyping: true))
        viewModel.handle(.typing(participantID: "persona-1", isTyping: true))
        #expect(viewModel.typingParticipants == ["persona-1"])
        viewModel.handle(.typing(participantID: "persona-1", isTyping: false))
        #expect(viewModel.typingParticipants.isEmpty)
    }

    @Test("setLocalTyping forwards to the backend")
    func setLocalTypingForwards() async throws {
        let (viewModel, backend) = makeViewModel()
        try await viewModel.setLocalTyping(true)
        #expect(backend.typingCalls == [true])
    }

    // MARK: Widgets

    @Test("widgetPresented appends to pendingWidgets and notifies")
    func widgetPresentedAppends() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        viewModel.handle(.widgetPresented(messageID: "m1", widget: FixtureWidget()))
        #expect(viewModel.pendingWidgets.count == 1)
        #expect(observer.updates.map(label) == ["pendingWidgetsChanged"])
    }

    @Test("respondToWidget forwards to the backend")
    func respondToWidgetForwards() async throws {
        let (viewModel, backend) = makeViewModel()
        let response = FixtureWidgetResponse(widgetID: "w1", respondingParticipantID: "user-1")
        try await viewModel.respondToWidget(response)
        #expect(backend.widgetResponses.count == 1)
        #expect(backend.widgetResponses.first?.widgetID == "w1")
    }

    // MARK: Permissions (contract gap: nothing ever populates pendingPermissions)

    @Test("respondToPermission is safe to call and notifies even with nothing pending")
    func respondToPermissionIsSafe() async throws {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        try await viewModel.respondToPermission(promptID: "does-not-exist", decision: .allowOnce)
        #expect(viewModel.pendingPermissions.isEmpty)
        #expect(observer.updates.map(label) == ["pendingPermissionsChanged"])
    }

    // MARK: Commands

    @Test("commandInvoked appends a running activity and notifies")
    func commandInvokedAppendsRunningActivity() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        let invocation = FixtureCommandInvocation(commandName: "search", invokerID: "persona-1")

        viewModel.handle(.commandInvoked(participantID: "persona-1", invocation: invocation))

        #expect(viewModel.commandActivity.count == 1)
        #expect(viewModel.commandActivity.first?.id == invocation.id)
        #expect(viewModel.commandActivity.first?.isRunning == true)
        #expect(observer.updates.map(label) == ["commandActivityChanged"])
    }

    @Test("commandCompleted fills the result in place rather than appending a second row")
    func commandCompletedFillsResultInPlace() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        let invocation = FixtureCommandInvocation(commandName: "search", invokerID: "persona-1")

        viewModel.handle(.commandInvoked(participantID: "persona-1", invocation: invocation))
        viewModel.handle(.commandCompleted(
            participantID: "persona-1",
            result: FixtureCommandResult(invocationID: invocation.id, ok: false, errorMessage: "no such file")))

        #expect(viewModel.commandActivity.count == 1)
        #expect(viewModel.commandActivity.first?.isRunning == false)
        #expect(viewModel.commandActivity.first?.result?.ok == false)
        #expect(viewModel.commandActivity.first?.result?.errorMessage == "no such file")
        #expect(observer.updates.map(label) == ["commandActivityChanged", "commandActivityChanged"])
    }

    @Test("a result whose invocation was never seen is dropped, not synthesised")
    func orphanResultIsDropped() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)

        viewModel.handle(.commandCompleted(
            participantID: "persona-1",
            result: FixtureCommandResult(invocationID: "never-invoked")))

        #expect(viewModel.commandActivity.isEmpty)
        #expect(observer.updates.map(label) == ["commandActivityChanged"])
    }

    @Test("parallel invocations of the same command complete independently, matched by id")
    func parallelInvocationsMatchByID() {
        let (viewModel, _) = makeViewModel()
        let first = FixtureCommandInvocation(id: "inv-1", commandName: "grep", invokerID: "persona-1")
        let second = FixtureCommandInvocation(id: "inv-2", commandName: "grep", invokerID: "persona-1")

        viewModel.handle(.commandInvoked(participantID: "persona-1", invocation: first))
        viewModel.handle(.commandInvoked(participantID: "persona-1", invocation: second))
        viewModel.handle(.commandCompleted(
            participantID: "persona-1", result: FixtureCommandResult(invocationID: "inv-2")))

        #expect(viewModel.commandActivity.map(\.id) == ["inv-1", "inv-2"])
        #expect(viewModel.commandActivity[0].isRunning == true)
        #expect(viewModel.commandActivity[1].isRunning == false)
    }

    // MARK: Transport errors

    @Test("transportError notifies .error with the message")
    func transportErrorNotifies() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        viewModel.handle(.transportError(message: "socket closed"))
        #expect(observer.updates.map(label) == ["error(socket closed)"])
    }

    // MARK: Observer registry

    @Test("removed observers stop receiving updates")
    func removedObserverStopsReceiving() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        viewModel.handle(.transportError(message: "first"))
        #expect(observer.updates.count == 1)
        viewModel.removeObserver(observer)
        viewModel.handle(.transportError(message: "second"))
        #expect(observer.updates.count == 1)
    }

    @Test("a deallocated observer is dropped without crashing (weak registry)")
    func deallocatedObserverIsDropped() {
        let (viewModel, _) = makeViewModel()
        do {
            let observer = RecordingObserver()
            viewModel.addObserver(observer)
        }
        // `observer` is gone; notifying must not crash even though the
        // registry only ever held it weakly.
        viewModel.handle(.transportError(message: "boom"))
    }

    @Test("observers receive ChatUpdate values in the order events were handled")
    func observersReceiveUpdatesInOrder() {
        let (viewModel, _) = makeViewModel()
        let observer = RecordingObserver()
        viewModel.addObserver(observer)
        viewModel.handle(.participantJoined(FixtureParticipant.persona()))
        viewModel.handle(.typing(participantID: "persona-1", isTyping: true))
        viewModel.handle(.draftUpdated(participantID: "persona-1", text: "Hi", attachments: []))
        #expect(observer.updates.map(label) == ["participantsChanged", "typingChanged", "activeDraftsChanged"])
    }

    // MARK: Wired end-to-end through Backend.inboundEvents

    @Test("events emitted on the real Backend.inboundEvents stream reach the view model")
    func inboundEventsFromBackendAreConsumed() async throws {
        let (viewModel, backend) = makeViewModel()
        backend.emit(.typing(participantID: "persona-1", isTyping: true))
        try await waitUntil { viewModel.typingParticipants.contains("persona-1") }
        #expect(viewModel.typingParticipants == ["persona-1"])
    }

    @Test("a message emitted on the real Backend.inboundEvents stream is added")
    func inboundMessageFromBackendIsAdded() async throws {
        let (viewModel, backend) = makeViewModel()
        let incoming = FixtureMessage(id: "server-1", localID: "server-1", senderID: "persona-1", text: "hi there", timestamp: Date())
        backend.emit(.messageReceived(incoming))
        try await waitUntil { !viewModel.messages.isEmpty }
        #expect(viewModel.messages.first?.text == "hi there")
    }

    // MARK: A whole turn through ScriptedBackend — the end-to-end contract proof

    /// Drives `ObservableChatViewModel` from a real `ScriptedBackend` through
    /// a whole turn — user message, status `think`, status `respond`, draft
    /// updates, `draftCleared`, `messageReceived` — the same shape a live
    /// `PersonaChatCoordinator` turn takes. Proves the contract is wired
    /// end to end, not just that individual `InboundEvent` cases apply.
    ///
    /// `.onFirstSend` and a non-zero delay are what make the asserted *order*
    /// meaningful rather than lucky. `submitMessage` appends its optimistic
    /// local echo only after `await backend.send(...)` returns, and `messages`
    /// is arrival-ordered with no sort, so a script replaying from `init` with
    /// no delay is free to land its reply ahead of the message being replied
    /// to — the transcript would read `["Hello!", "hi"]` on an unlucky
    /// schedule. Waiting for the send, then pausing, pins the echo first.
    @Test("a whole turn — think, respond, draft, clear, receive — ends with the user message and the reply, and no draft left over")
    func wholeTurnThroughScriptedBackend() async throws {
        let backend = ScriptedBackend(
            script: [
                .statusChanged(participantID: "persona-1", status: ChatStatus(kind: .think)),
                .statusChanged(participantID: "persona-1", status: ChatStatus(kind: .respond)),
                .draftUpdated(participantID: "persona-1", text: "Hel", attachments: []),
                .draftUpdated(participantID: "persona-1", text: "Hello!", attachments: []),
                .draftCleared(participantID: "persona-1"),
                .messageReceived(FixtureMessage(
                    id: "server-1", localID: "server-1", senderID: "persona-1",
                    text: "Hello!", timestamp: Date())),
                .statusChanged(participantID: "persona-1", status: nil),
            ],
            start: .onFirstSend,
            delayBetweenEvents: .milliseconds(20))
        let viewModel = ObservableChatViewModel(backend: backend, localParticipantID: "user-1")

        _ = try await viewModel.submitMessage(text: "hi", attachments: [])
        try await waitUntil { viewModel.messages.count == 2 }

        #expect(viewModel.messages.count == 2)
        #expect(viewModel.messages.map(\.text) == ["hi", "Hello!"])
        #expect(viewModel.activeDrafts.isEmpty)
    }
}
