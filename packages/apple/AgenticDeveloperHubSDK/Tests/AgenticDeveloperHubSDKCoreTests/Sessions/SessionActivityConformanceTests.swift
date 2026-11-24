import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct SessionActivityConformanceTests {

    private let idleTurns = ["Stop", "StopFailure", "Interrupted", "SessionStart", "SessionEnd", ""]
    private let waitingTurns = ["Notification", "PermissionRequest", "Elicitation"]

    private func derive(_ type: String, active: Bool = true, subagent: Bool = false) -> SessionActivity {
        SessionActivity.derive(isActive: active, lastEventType: type, subagentWorking: subagent)
    }

    @Test("V1: finished turns read as idle")
    func testV1_finishedTurnsIdle() {
        for type in idleTurns {
            #expect(derive(type) == .idle)
        }
    }

    @Test("V2: requests for the user read as waiting")
    func testV2_requestsWaiting() {
        for type in waitingTurns {
            #expect(derive(type) == .waiting)
        }
    }

    @Test("V3: a turn in flight reads as working")
    func testV3_turnInFlightWorking() {
        for type in ["UserPromptSubmit", "PreToolUse", "PostToolUse", "PostToolUseFailure"] {
            #expect(derive(type) == .working)
        }
    }

    @Test("V4: an ended session is idle")
    func testV4_endedSessionIdle() {
        #expect(derive("PreToolUse", active: false) == .idle)
    }

    @Test("V5: a live subagent promotes idle to working")
    func testV5_subagentPromotesIdle() {
        for type in idleTurns {
            #expect(derive(type, subagent: true) == .working)
        }
    }

    @Test("V6: a live subagent never overrides waiting")
    func testV6_subagentNeverOverridesWaiting() {
        for type in waitingTurns {
            #expect(derive(type, subagent: true) == .waiting)
        }
    }

    @Test("V7: an ended session is idle even with a subagent stamp")
    func testV7_endedWithSubagentIdle() {
        #expect(derive("Stop", active: false, subagent: true) == .idle)
    }

    @Test("V8: an unknown event reads as working")
    func testV8_unknownEventWorking() {
        #expect(SessionActivity.turnActivity(lastEventType: "SomeFutureEvent") == .working)
    }

    @Test("V9: event matching is exact")
    func testV9_exactMatch() {
        for type in ["stop", "STOP", " Stop"] {
            #expect(SessionActivity.turnActivity(lastEventType: type) == .working)
        }
    }

    @Test("V10: an ended session is idle, not waiting")
    func testV10_endedNotWaiting() {
        #expect(derive("PermissionRequest", active: false) == .idle)
    }

    @Test("V11: cases and raw values")
    func testV11_casesAndRawValues() {
        #expect(SessionActivity.allCases == [.working, .idle, .waiting])
        #expect(SessionActivity.allCases.map(\.rawValue) == ["working", "idle", "waiting"])
    }

    @Test("V12: turnActivity takes only the event type")
    func testV12_turnIgnoresLiveness() {
        let function: (String) -> SessionActivity = SessionActivity.turnActivity(lastEventType:)
        #expect(function("SessionEnd") == .idle)
    }

    @Test("V13: derive and turnActivity are total")
    func testV13_total() {
        var count = 0
        for type in ["", "Stop", "Notification", "SomeFutureEvent"] {
            let turn: SessionActivity = SessionActivity.turnActivity(lastEventType: type)
            #expect(SessionActivity.allCases.contains(turn))
            for active in [true, false] {
                for subagent in [true, false] {
                    let result: SessionActivity = derive(type, active: active, subagent: subagent)
                    #expect(SessionActivity.allCases.contains(result))
                    count += 1
                }
            }
        }
        #expect(count == 16)
    }

    @Test("V14: a subagent changes nothing when the turn is already working")
    func testV14_subagentNoChangeWhenWorking() {
        #expect(derive("PreToolUse", subagent: true) == .working)
    }
}
