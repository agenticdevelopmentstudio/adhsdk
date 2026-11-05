# Port Plan — Persona Chat Coordinator on Android (Kotlin)

Derived from [`docs/specs/ingredients/persona-chat-coordinator.md`](../../specs/ingredients/persona-chat-coordinator.md).
Status: **planned, not implemented.** Nothing in `packages/android/` builds yet.

This plan exists so the port is a translation exercise rather than a design
exercise. Every decision below is downstream of the ingredient spec; where the
platform forces a choice the spec does not make, the choice is recorded here and
marked so it can be argued with before code exists.

## What ships

```
packages/android/
  settings.gradle.kts
  build.gradle.kts
  adh-sdk/                     # library module
    build.gradle.kts
    src/main/kotlin/com/mikefullerton/agenticdeveloperhubsdk/
      contract/                        # mirrors packages/apple/AgenticDeveloperHubSDK/SDK/Sources one-to-one
        backend/Backend.kt
        backend/InboundEvent.kt
        messages/Message.kt
        commands/CommandInvocation.kt
        ...
      coordinator/PersonaChatCoordinator.kt
      coordinator/SseParser.kt
    src/test/kotlin/.../PersonaChatCoordinatorTest.kt
```

The contract package is a straight transliteration and carries no decisions —
`Message`, `CommandInvocation`, `CommandResult`, `Attachment` and friends already
exist in TypeScript and Swift. Port those first, in one pass, before touching the
coordinator; a half-ported contract makes the coordinator impossible to compile
and impossible to review.

## Contract mapping

| Contract element | Kotlin expression | Why |
|---|---|---|
| `InboundEvent` (sum type) | `sealed interface InboundEvent` with a `data class` per case | Kotlin's `when` is exhaustive over a sealed hierarchy, so a new case is a compile error at every consumer — the same guarantee Swift's `enum` gives. |
| `Backend.inboundEvents` | `Flow<InboundEvent>` backed by `Channel(UNLIMITED).receiveAsFlow()` | See below. |
| `Backend.send` | `suspend fun send(text: String, attachments: List<Attachment>): String` | Matches the contract's async-returning-localID shape. |
| `Backend.destroy` | `fun destroy()` — **not** `suspend` | `destroy` must be authoritative the instant it returns; a suspending destroy lets a `send` win the race. |
| `Authorize` | `typealias Authorize = suspend (Request) -> Response` | Credentials are injected, never imported (spec, Configuration). |
| Turn cancellation | `CoroutineScope(SupervisorJob() + Dispatchers.IO)` owned by the coordinator | |

### The event stream is hot, not cold

The spec's Platform Notes currently say "cold `Flow`". That is wrong and the
port must not follow it. `inboundEvents` is a **push** source: events originate
from a turn that is already running, not from the act of collecting. A cold
`Flow` restarts its producer per collector, which would mean a second collector
starts a second conversation.

Use `Channel<InboundEvent>(capacity = UNLIMITED)` exposed as
`channel.receiveAsFlow()`. That reproduces the exact semantics the other two
platforms already have — Swift's `AsyncStream` buffering continuation and the
TypeScript `EventQueue`: single consumer (the contract names the orchestrator as
the only one), buffers events that arrive before collection begins, and
terminates on `close()`. Do not reach for `MutableSharedFlow`; multiplexing to
several observers is the orchestrator's job, and `SharedFlow` with `replay = 0`
would silently drop events emitted before the collector attaches.

`Channel.trySend` is safe to call from outside a coroutine, which is what makes
the synchronous `destroy()` above possible.

## Cancellation, and the trap that cost two mutation rounds

`destroy()` does three things, in this order:

1. Flip a destroyed flag (`AtomicBoolean`) and cancel the scope.
2. `channel.trySend(InboundEvent.DraftCleared(participantId))`.
3. `channel.close()`.

Step 2 is not optional and does not belong in the turn's own `finally`.
Cancellation unwinds asynchronously; by the time the cancelled turn's cleanup
runs, the channel is closed and its `draftCleared` goes nowhere — leaving a chat
surface holding a half-written draft forever. Both shipped implementations emit
it from `destroy` itself for exactly this reason.

Two failure modes were found by mutation testing on the shipped ports. Both are
"the guarantee is held twice, so breaking one guard proves nothing", and both
will recur here:

- **`ci-no-reuse-after-destroy` is guarded twice.** The explicit
  `if (destroyed) throw` in `send`, and the turn-adoption check that refuses to
  register a new turn on a dead coordinator. Keep both — but know that a test
  which only removes one still passes, so the vector must be exercised against
  both being broken.
- **`ci-commit-once` is two claims, not one.** "Exactly one `messageReceived`"
  and "`draftCleared` comes after it". A mutation that moves the clear into a
  `finally` block does not break the ordering, because `finally` still runs
  after the commit. Test the count and the order separately.

## Transport

**OkHttp**, with our own SSE parser over `ResponseBody.source()` — not
`okhttp-sse`.

The spec requires that an unknown event name be ignored (`ci-unknown-events`),
that a stream ending without `done` be a transport failure rather than a
completed turn (Edge Cases), and that an HTTP 200 carrying an `error` event be
treated as failure (`ci-in-band-errors`). Those are decisions about our
vocabulary, and an off-the-shelf `EventSource` puts its own policy in the middle
of them. Porting `SSEParser.swift` is roughly forty lines and makes the parser
unit-testable against a `ByteArray` without a socket.

Parse **chunks, not lines**. The Swift port learned this the expensive way:
`AsyncBytes.lines` collapses the blank line that separates SSE blocks, which is
the only thing marking where one event ends. Buffer bytes, split on `\n\n`, and
keep the remainder.

## Conformance

`pcc-001` … `pcc-016` from the spec are the acceptance criterion, one test each,
named for the requirement they hold the coordinator to. Plus the five Edge Cases
as their own tests — empty reply, conversation-creation failure, truncated
stream, parallel same-name tool calls, destroy-during-creation.

- **JUnit 5** + `kotlinx-coroutines-test` (`runTest`, `advanceUntilIdle`).
- **Turbine** for `Flow` assertions — `awaitItem()` / `expectNoEvents()` express
  "no transcript event was emitted" (`pcc-007`, `pcc-016`) directly, which is
  awkward with a raw `toList()`.
- Fake transport: an `Authorize` lambda that records requests and returns a
  scripted byte sequence. No `MockWebServer`; the vectors are about our parsing
  and event vocabulary, not about HTTP.

The spec's standard applies without exception: *each vector MUST be observed
failing for its stated reason before it is trusted.* Both shipped ports were
proved with a mutation harness that breaks one requirement at a time and asserts
that the vector claiming it — and ideally only that vector — fails. Write the
Kotlin equivalent; the two harnesses in this repo's history are the model.

## Open questions

1. **Minimum API level.** Affects nothing in the coordinator itself, but decides
   whether `java.time` is available directly or needs desugaring for `Message`
   timestamps.
2. **Is the contract package published separately from the coordinator?** Web
   splits them (`@adh-sdk/chat/contract`); Apple does not. A
   consumer writing its own `Backend` wants the contract without OkHttp.
3. **Compose UI.** Out of this port's scope — this is the coordinator only. The
   chat control is a separate ingredient (`ai-chat-control`) and a separate plan.

## Settled — do not re-litigate

A1 orchestration (the server owns history; `send` carries no history),
`draftUpdated` carrying the accumulation rather than the newest fragment, and
tool activity being its own event channel rather than draft text. All three are
recorded with rationale in the ingredient spec's Design Decisions and are load-
bearing across all four platforms.
