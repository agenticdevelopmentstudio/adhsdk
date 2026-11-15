import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

struct HookEventTypeTests {

    @Test("hook-event-type-002: table name is snake case with events suffix")
    func tableNameIsSnakeCaseWithEventsSuffix() {
        #expect(HookEventType.preToolUse.tableName == "pre_tool_use_events")
    }

    @Test("hook-event-type-004: ambient not activity, unknown is")
    func ambientTypesAreNotActivityAndUnknownTypesAre() {
        #expect(!HookEventType.isActivity("ConfigChange"))
        #expect(HookEventType.isActivity("SomethingNew"))
    }

    @Test("hook-event-type-001: case count is pinned")
    func caseCountIsPinned() {
        #expect(HookEventType.allCases.count == 28)
    }

    @Test("hook-event-type-003: table names for multi-word and single-word cases")
    func tableNamesForOtherCases() {
        #expect(HookEventType.postToolUseFailure.tableName == "post_tool_use_failure_events")
        #expect(HookEventType.statusLine.tableName == "status_line_events")
        #expect(HookEventType.stop.tableName == "stop_events")
        #expect(HookEventType.cwdChanged.tableName == "cwd_changed_events")
    }

    @Test("hook-event-type-004: ambient events are not activity")
    func ambientEventsAreNotActivity() {
        #expect(!HookEventType.isActivity("ConfigChange"))
        #expect(!HookEventType.isActivity("StatusLine"))
        #expect(!HookEventType.isActivity("InstructionsLoaded"))
    }

    @Test("hook-event-type-005: unknown and empty types are activity")
    func unknownAndEmptyAreActivity() {
        #expect(HookEventType.isActivity("SomethingNew"))
        #expect(HookEventType.isActivity(""))
    }

    @Test("hook-event-type-006: activity match is exact")
    func activityMatchIsExact() {
        #expect(HookEventType.isActivity("configchange"))
    }

    @Test("hook-event-type-007: ambient and off-turn events never set turn state")
    func ambientAndOffTurnDoNotSetTurnState() {
        for event in ["ConfigChange", "SubagentStop", "FileChanged", "PreCompact"] {
            #expect(!HookEventType.setsTurnState(event, hookData: [:]), "\(event)")
        }
    }

    @Test("hook-event-type-008: default events set turn state only without agent_id")
    func defaultEventsDependOnAgentId() {
        #expect(HookEventType.setsTurnState("PreToolUse", hookData: [:]))
        #expect(!HookEventType.setsTurnState("PreToolUse", hookData: ["agent_id": "a1"]))
        #expect(HookEventType.setsTurnState("PreToolUse", hookData: ["agent_id": ""]))
    }

    @Test("hook-event-type-009: blocking requests count even from a subagent")
    func blockingRequestsCountFromSubagent() {
        let data: [String: Any] = ["agent_id": "a1"]
        #expect(HookEventType.setsTurnState("PermissionRequest", hookData: data))
        #expect(HookEventType.setsTurnState("Elicitation", hookData: data))
    }

    @Test("hook-event-type-010: only waiting or untyped notifications set turn state")
    func notificationTypesSetTurnState() {
        func sets(_ data: [String: Any]) -> Bool {
            HookEventType.setsTurnState("Notification", hookData: data)
        }
        #expect(!sets(["notification_type": "idle_prompt"]))
        #expect(sets(["notification_type": "permission_prompt"]))
        #expect(sets(["notification_type": "elicitation_dialog"]))
        #expect(sets(["notification_type": ""]))
        #expect(sets([:]))
        #expect(sets(["notification_type": 5]))
    }

    @Test("hook-event-type-011: a compact SessionStart does not set turn state")
    func sessionStartSource() {
        func sets(_ data: [String: Any]) -> Bool {
            HookEventType.setsTurnState("SessionStart", hookData: data)
        }
        #expect(!sets(["source": "compact"]))
        #expect(sets(["source": "startup"]))
        #expect(sets([:]))
    }

    @Test("hook-event-type-012: Stop and unknown events follow the agent_id rule")
    func stopAndUnknownEvents() {
        #expect(HookEventType.setsTurnState("Stop", hookData: [:]))
        #expect(HookEventType.setsTurnState("SomethingNew", hookData: [:]))
        #expect(!HookEventType.setsTurnState("SomethingNew", hookData: ["agent_id": "a1"]))
    }

    @Test("hook-event-type-014: SubagentStop clears the clock")
    func subagentStopClock() {
        #expect(HookEventType.subagentClock("SubagentStop", hookData: [:]) == -1)
        #expect(HookEventType.subagentClock("SubagentStop", hookData: ["agent_id": "a1"]) == -1)
    }

    @Test("hook-event-type-015: subagent hooks stamp the clock")
    func subagentActivityClock() {
        let data: [String: Any] = ["agent_id": "a1"]
        #expect(HookEventType.subagentClock("PreToolUse", hookData: data) == 1)
        #expect(HookEventType.subagentClock("SubagentStart", hookData: data) == 1)
    }

    @Test("hook-event-type-016: a subagent StopFailure clears the clock")
    func subagentStopFailureClock() {
        #expect(HookEventType.subagentClock("StopFailure", hookData: ["agent_id": "a1"]) == -1)
        #expect(HookEventType.subagentClock("StopFailure", hookData: [:]) == 0)
    }

    @Test("hook-event-type-017: no usable agent_id means no subagent clock")
    func noAgentMeansZero() {
        #expect(HookEventType.subagentClock("Stop", hookData: [:]) == 0)
        #expect(HookEventType.subagentClock("PreToolUse", hookData: ["agent_id": ""]) == 0)
        #expect(HookEventType.subagentClock("PreToolUse", hookData: ["agent_id": 7]) == 0)
    }

    @Test("hook-event-type-018: the classification constants have the documented members")
    func classificationConstants() {
        #expect(HookEventType.ambientEventTypes == ["ConfigChange", "StatusLine", "InstructionsLoaded"])
        #expect(HookEventType.offTurnEventTypes == [
            "SubagentStart", "SubagentStop", "TaskCreated", "TaskCompleted",
            "TeammateIdle", "PreCompact", "PostCompact", "FileChanged"
        ])
        #expect(HookEventType.waitingNotificationTypes == ["permission_prompt", "elicitation_dialog"])
        #expect(HookEventType.turnEndingEventTypes == ["Stop", "StopFailure", "SessionEnd"])
        #expect(HookEventType.interruptedEventType == "Interrupted")
    }
}
