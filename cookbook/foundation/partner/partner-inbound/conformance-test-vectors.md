
Vectors 001 to 004 are asserted in `PartnerModelsTests` (the test name is in the Input column); the rest are derived from the `PartnerInbound` source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-inbound-001 | idle-text, exited-text, text-names-event | `sessionExited(sessionID: "s1", title: "review abc").text` (`inboundTextNamesTheEvent`) | Contains `s1`; equals `Session s1 (review abc) exited.` |
| partner-inbound-002 | will-quit-text, text-names-event | `lifecycle(.willQuit(endingSessions: ["s1"])).text` (`inboundTextNamesTheEvent`) | Contains `quit`; equals `The app is about to quit. These sessions will end: s1` |
| partner-inbound-003 | key-tick, key-none-owner-lifecycle, queue-coalescing-contract | Queue two ticks for job "a" (second with summary "2 queued") and two identical owner messages "hi" (`ticksForSameJobCoalesceAndOwnerMessagesDoNot`) | Queue count is 3; the first `next()` text contains `2 queued` |
| partner-inbound-004 | key-idle, key-exited, key-distinct-kinds | Queue two `sessionIdle` for "s1" and one `sessionExited` for "s1" (`sessionIdleCoalescesPerSessionAndKind`) | Queue count is 2 |
| partner-inbound-005 | tick-text-first-line, tick-text-join | `tick(jobID: "a", jobName: "A", previousTick: nil, summary: nil).text` | Exactly `Timer tick for job A.` |
| partner-inbound-006 | tick-text-previous, tick-text-summary, tick-text-join | Tick with previousTick 2026-11-14T10:00:00Z and summary "2 queued" | Three lines: `Timer tick for job A.`, `Previous tick: 2026-11-14T10:00:00Z`, `2 queued` |
| partner-inbound-007 | tick-text-summary | Tick with summary "" and previousTick nil | `Timer tick for job A.` followed by a newline and an empty line (text ends with a newline) |
| partner-inbound-008 | owner-text, attribution-owner-only | `owner(text: "hi", attribution: nil)` and an owner with an attribution | `text` is `hi` in both; `attribution` is nil, then the given attribution |
| partner-inbound-009 | attribution-owner-only | `attribution` of a tick, idle, exited and lifecycle event | nil for each |
| partner-inbound-010 | started-text | `lifecycle(.started(resumed: true, goneSessions: ["a", "b"]))` and `lifecycle(.started(resumed: false, goneSessions: []))` | `You were started (resumed: true). Sessions gone since last time: a, b` and `You were started (resumed: false). Sessions gone since last time: none` |
| partner-inbound-011 | guidelines-changed-text, turn-timed-out-text | `.guidelinesChanged` and `.turnTimedOut` | The two fixed sentences listed in the requirements |
| partner-inbound-012 | will-quit-text | `willQuit(endingSessions: [])` | `The app is about to quit. These sessions will end: none` |
| partner-inbound-013 | key-none-owner-lifecycle | `coalescingKey` of an owner and of each lifecycle case | nil in every case |
| partner-inbound-014 | key-ignores-payload, queue-coalescing-contract | Queue tick (job "a", summary nil), an owner message, then tick (job "a", summary "x") | Tick keeps position 0 with the new summary; the owner message stays second; count is 2 |
| partner-inbound-015 | value-semantics | Compare two `tick` values differing only in `summary` | Not equal, though their `coalescingKey` values are equal |
| partner-inbound-016 | text-verbatim-ids | `sessionIdle(sessionID: "", title: "")` | `Session  () went idle.` (nothing rejected) |
| partner-inbound-017 | idle-text | `sessionIdle(sessionID: "s1", title: "t")` | `Session s1 (t) went idle.` |

