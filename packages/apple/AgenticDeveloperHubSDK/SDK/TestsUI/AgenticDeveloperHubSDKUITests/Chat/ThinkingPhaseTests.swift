import Testing
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

@Suite("Thinking phase")
struct ThinkingPhaseTests {

    @Test("a fresh phase machine is idle")
    func startsIdle() {
        #expect(ThinkingPhase.Machine().phase == .idle)
    }

    @Test("a status moves it to thinking and starts the clock")
    func statusStartsThinking() {
        var machine = ThinkingPhase.Machine()
        machine.apply(ChatStatus(kind: .think), at: 100)
        #expect(machine.phase == .thinking)
    }

    @Test("clearing the status settles it and freezes the elapsed time")
    func clearingSettles() {
        var machine = ThinkingPhase.Machine()
        machine.apply(ChatStatus(kind: .think), at: 100)
        machine.apply(nil, at: 108)
        #expect(machine.phase == .done)
        #expect(machine.elapsedSeconds == 8)
    }

    @Test("the frozen time survives later ticks")
    func frozenTimeHolds() {
        var machine = ThinkingPhase.Machine()
        machine.apply(ChatStatus(kind: .think), at: 100)
        machine.apply(nil, at: 108)
        machine.tick(at: 200)
        #expect(machine.elapsedSeconds == 8)
    }

    @Test("an utterance pre-empts the phase but keeps the spinner running")
    func utterancePreempts() {
        var machine = ThinkingPhase.Machine()
        machine.apply(ChatStatus(kind: .think), at: 100)
        machine.say("he just said this", at: 102)
        #expect(machine.phase == .utterance)
        #expect(machine.isSpinning)
    }

    @Test("only phase transitions are announced, never word ticks")
    func announcesTransitionsOnly() {
        var machine = ThinkingPhase.Machine()
        machine.apply(ChatStatus(kind: .think), at: 100)
        #expect(machine.takePendingAnnouncement() != nil)
        machine.tick(at: 101)
        machine.tick(at: 102)
        #expect(machine.takePendingAnnouncement() == nil)
    }
}
