
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-turn-queue-001 | coalesce-replaces-in-place, no-key-appends, count, fifo-order | Enqueue tick for job `a` with no summary, tick for job `a` with summary `2 queued`, then two identical owner messages `hi`. | `count` is 3 and the first `next()` is the tick whose text contains `2 queued` (test: ticksForSameJobCoalesceAndOwnerMessagesDoNot). |
| partner-turn-queue-002 | key-compared-whole, coalesce-replaces-in-place | Enqueue `sessionIdle` for `s1` twice, then `sessionExited` for `s1`. | `count` is 2: the idle events collapse, the exit event stays separate (test: sessionIdleCoalescesPerSessionAndKind). |
| partner-turn-queue-003 | enqueue-first, fifo-order | Enqueue owner message `waiting`, then `enqueueFirst(.lifecycle(.turnTimedOut))`. | `count` is 2, the first `next()` equals `.lifecycle(.turnTimedOut)` and the second has text `waiting` (test: enqueueFirstGoesAheadOfEverything). |
| partner-turn-queue-004 | next-on-empty, infallible | A new queue; call `next()`. | `nil`, `count` stays 0. |
| partner-turn-queue-005 | coalesce-replaces-in-place | Enqueue tick job `a`, owner `hi`, then tick job `a` with summary `later`. | `count` is 2; `next()` returns the tick carrying `later` first, then the owner message. |
| partner-turn-queue-006 | coalesce-targets-front-inserted | `enqueueFirst` a tick for job `a`, then `enqueue` a tick for job `a` with summary `new`. | The front-inserted tick is replaced by the `new` tick: `count` is 1 and `next()` returns the `new` tick. |
| partner-turn-queue-007 | enqueue-first-no-coalesce | Enqueue tick job `a`, then `enqueueFirst` a tick job `a`. | `count` is 2; both ticks are returned, the front-inserted one first. |
| partner-turn-queue-008 | enqueue-first-order | `enqueueFirst` owner `one`, then `enqueueFirst` owner `two`. | `next()` returns `two` then `one`. |
| partner-turn-queue-009 | no-key-appends | Enqueue `.lifecycle(.guidelinesChanged)` twice. | `count` is 2. |
| partner-turn-queue-010 | key-compared-whole | Enqueue tick job `a` and tick job `b`. | `count` is 2. |
| partner-turn-queue-011 | coalesce-first-match, enqueue-first-no-coalesce | Enqueue tick job `a`, then `enqueueFirst` a tick job `a` (two equal keys), then `enqueue` a tick job `a` with summary `new`. | `count` is 2; the front-inserted tick was replaced by the `new` tick and the originally queued tick is unchanged behind it. |

Vectors 004 to 011 are derived from the source rather than from a named test; the three named tests cover vectors 001 to 003.

