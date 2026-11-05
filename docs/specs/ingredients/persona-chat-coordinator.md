---
id: 412B845B-7496-4347-A710-1BD29325C1BE
title: "Persona Chat Coordinator"
domain: adhsdk://ingredients/chat/persona-chat-coordinator
type: ingredient
version: 1.3.0
status: draft
language: en
created: 2026-08-20
modified: 2026-08-24
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Thin multiplatform client that drives one persona conversation against adh's server-orchestrated chat API and emits the cross-platform chat contract's InboundEvent stream."
platforms:
  - ios
  - macos
  - swift
  - typescript
  - web
  - kotlin
  - windows
tags:
  - chat
  - coordinator
  - adh
  - backend
depends-on: []
related:
  - agenticdevelopercookbook://ingredients/ui/components/ai-chat-control
references: []
---

# Persona Chat Coordinator

## Overview

The coordinator is the client half of a persona conversation. It conforms to the
cross-platform `Backend` contract and translates that contract onto adh's chat
API.

adh orchestrates the turn. It resolves the persona from its slug, assembles the
system prompt from the persona's saved config, reads and writes conversation
history, calls the provider, and streams the reply back as Server-Sent Events.
The coordinator holds no history, no credentials, and no prompt.

This is the A1 split: the server orchestrates, the client relays. The single
clearest evidence is that `Backend.send` receives only the new message — there is
no history parameter anywhere in the contract, because history is not the
client's to carry.

Use this ingredient wherever a chat surface needs to talk to a persona. Do not
use it to talk to a model provider directly; the coordinator has no provider
knowledge and must not acquire any.

## Terminology

| Term | Meaning |
|------|---------|
| **Turn** | One user message plus the assistant reply it produces. |
| **Conversation** | adh's server-side persistence primitive, addressed by id. Pinned to a persona slug and model at creation. |
| **Draft** | The assistant's in-progress reply, before it commits to an immutable `Message`. |
| **Accumulation** | The full text of a draft so far — not the newest fragment. |
| **Coordinator** | An implementation of this ingredient. |

## Behavioral Requirements

### Conversation lifecycle

- **ci-lazy-conversation**: The coordinator MUST NOT create a conversation until
  the first `send`. A constructed-but-unused coordinator MUST perform no network
  I/O.
- **ci-conversation-reuse**: Once created, the coordinator MUST reuse the same
  conversation id for every subsequent turn in its lifetime.
- **ci-conversation-pinning**: The coordinator MUST pin the conversation to the
  persona slug and the configured model at creation time.
- **ci-no-history**: The coordinator MUST NOT send conversation history with a
  turn, and MUST NOT retain history locally. History is adh's.
- **ci-one-turn-at-a-time**: Turns MUST run one at a time, in send order. A
  `send` issued while a turn is in flight MUST be queued rather than started
  alongside it, and MUST still run once the turn ahead of it ends. The
  coordinator carries per-turn state — its cancellation handle and its open
  invocations — in single slots, so two turns in flight corrupt both; and adh
  serves one reply per conversation at a time, so overlapping turns are not a
  state the transcript can represent either. Nothing upstream enforces this: no
  surface disables its composer for the duration of a turn.

### Streaming

- **ci-accumulate**: adh emits `token` events carrying fragments. `draftUpdated`
  carries the accumulation. The coordinator MUST accumulate fragments and emit
  the full text so far on every `draftUpdated`.
- **ci-commit-once**: On `done`, the coordinator MUST emit exactly one
  `messageReceived` carrying the accumulated text as an immutable `Message`,
  followed by `draftCleared` for that participant.
- **ci-no-commit-on-abort**: If the turn is aborted, the coordinator MUST emit
  `draftCleared` and MUST NOT emit `messageReceived`.
- **ci-drop-open**: The leading `open` event is a connection heartbeat. The
  coordinator MUST NOT surface it as a transcript event.
- **ci-unknown-events**: An unrecognized SSE event name MUST be ignored, not
  treated as an error. adh may add events before every client knows them.

### Tool calls

- **ci-tool-invoked**: On `tool_call_started`, the coordinator MUST emit
  `commandInvoked` carrying a `CommandInvocation`.
- **ci-tool-completed**: On `tool_call_completed`, the coordinator MUST emit
  `commandCompleted` carrying a `CommandResult` whose `invocationID` matches the
  invocation it completes.
- **ci-invocation-ids**: The coordinator MUST assign each invocation a fresh,
  unique id. It MUST NOT derive the id from the command name.
- **ci-tool-text-separation**: Tool arguments and results MUST NOT be appended to
  the draft. They are their own channel.

### Failure

- **ci-error-terminal**: An `error` event ends the turn. The coordinator MUST
  emit `messageFailed` for the originating message and MUST NOT emit
  `messageReceived` for it.
- **ci-transport-vs-message**: A failure that occurs before the message reaches
  adh MUST surface as `messageFailed` against the `localID` returned by `send`.
  A failure of the stream itself MUST surface as `transportError`.
- **ci-in-band-errors**: adh returns HTTP 200 even when the turn fails, reporting
  the condition in-band as an `error` event. A coordinator MUST NOT infer success
  from the status code.

### Cancellation

- **ci-destroy-authoritative**: `destroy` MUST cancel any in-flight turn. The
  coordinator MUST own its own cancellation handle rather than binding directly
  to a caller-supplied one, so that `destroy` remains authoritative when a caller
  signal is also present. The guarantee MUST hold for the whole turn,
  including the window before the turn has a handle of its own — conversation
  creation. A turn whose creation request had already resolved when `destroy`
  landed MUST stop there rather than posting the message.
- **ci-no-reuse-after-destroy**: Once destroyed, a coordinator is spent. A
  subsequent `send` MUST fail immediately and MUST NOT reach the network, so a
  caller that keeps a stale reference gets an error rather than a turn whose
  events nothing is listening for.

### Status

- **ci-status-out-of-band**: Retry and progress phases are not transcript events.
  The coordinator MUST report them through the status sink, never through
  `InboundEvent`.

## Appearance

Not applicable — the coordinator has no visual representation. Presentation is
the chat control's concern; see the `ai-chat-control` ingredient.

## States

| State | Entered when | Exited when |
|-------|--------------|-------------|
| `idle` | Constructed, or a turn ends | `send` is called |
| `connecting` | `send` called, conversation being ensured | Stream opens, or fails |
| `streaming` | First SSE block received | `done`, `error`, or abort |
| `failed` | An `error` event or a thrown transport failure | Next `send` |
| `destroyed` | `destroy` called | Terminal — MUST NOT be reused |

## Accessibility

Not applicable — no user-facing surface. The status sink exists so the consuming
control can announce turn progress; announcement is the control's concern.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pcc-001 | ci-lazy-conversation | Construct, never send | Zero network calls |
| pcc-002 | ci-conversation-reuse | Two sends | One conversation POST, two message POSTs |
| pcc-003 | ci-no-history | Send with prior turns present | Request body carries only the new message |
| pcc-004 | ci-accumulate | Tokens `"Hel"`, `"lo"` | `draftUpdated` texts `"Hel"`, `"Hello"` |
| pcc-005 | ci-commit-once | Tokens then `done` | Exactly one `messageReceived`, text `"Hello"`, then `draftCleared` |
| pcc-006 | ci-no-commit-on-abort | Tokens then abort | `draftCleared`, no `messageReceived` |
| pcc-007 | ci-drop-open | Leading `open` | No transcript event emitted |
| pcc-008 | ci-unknown-events | Event `"quux"` | Ignored; stream continues |
| pcc-009 | ci-tool-invoked, ci-tool-completed | `tool_call_started` then `tool_call_completed` | `commandInvoked` then `commandCompleted` with matching `invocationID` |
| pcc-010 | ci-invocation-ids | Two `tool_call_started` with the same name | Two distinct invocation ids |
| pcc-011 | ci-tool-text-separation | Tool events interleaved with tokens | Draft text contains no tool arguments or results |
| pcc-012 | ci-error-terminal | Tokens then `error` | `messageFailed`, no `messageReceived` |
| pcc-013 | ci-in-band-errors | HTTP 200 with `error` event | Treated as failure |
| pcc-014 | ci-destroy-authoritative | `destroy` mid-stream | Request cancelled, `draftCleared`, no `messageReceived` |
| pcc-015 | ci-no-reuse-after-destroy | `send` after `destroy` | Throws; no request issued |
| pcc-016 | ci-status-out-of-band | `status` event, phase `retrying` | Status sink receives retry phase; no `InboundEvent` emitted |
| pcc-017 | ci-one-turn-at-a-time | Two `send`s, first turn still streaming | One message POST; the second is issued only after the first turn ends |
| pcc-018 | ci-destroy-authoritative | `destroy` while conversation creation is in flight | Creation request cancelled; no message POST, even if creation then resolves |

Each vector MUST be observed failing for its stated reason before it is trusted.
A vector that has never failed has proved nothing.

## Edge Cases

- **Empty reply.** `done` with no preceding tokens commits an empty `Message`
  rather than nothing, so the transcript records that the turn happened.
- **Conversation creation fails.** No conversation id exists, so the failure is
  reported against the `localID` from `send` and the coordinator stays `idle`.
- **Stream ends without `done`.** The connection closed mid-turn. Treated as a
  transport failure, not a completed turn — a truncated reply MUST NOT commit as
  though complete.
- **Parallel same-name tool calls.** adh's `tool_call_completed` carries a name,
  not an invocation id. Correlation is by name and arrival order. Two in-flight
  invocations of the same command cannot be distinguished; the coordinator
  correlates to the oldest open invocation of that name. Recorded in Design
  Decisions.
- **`destroy` during conversation creation.** The creation request is cancelled
  and no conversation is retained. A transport that cannot honour the abort in
  time is covered too: the turn re-checks after the await rather than trusting
  the cancellation to have taken.
- **A second `send` during a turn.** Queued behind it, not raced against it (see
  `ci-one-turn-at-a-time`). The queue is a chain of turns, and one turn's failure
  MUST NOT break the chain for the turns behind it.
- **Reuse after `destroy`.** A destroyed coordinator MUST fail fast rather than
  silently reconnecting.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `personaSlug` | string | — (required) | Persona to converse with. |
| `model` | string? | `nil` | Overrides the persona's configured model when set. |
| `baseURL` | string | `/api` | Root of the adh chat API. |
| `authorize` | injected | — (required) | Attaches credentials to each request. |
| `onStatus` | sink? | `nil` | Receives turn-phase transitions. |
| `participantID` | string | `personaSlug` | Identifies the persona in emitted events. |

Credentials are **injected, never imported**. The coordinator MUST NOT depend on
any auth module directly; doing so closes a dependency cycle in every consumer
that already builds auth on top of chat.

## Deep Linking

Not applicable.

## Localization

The coordinator emits no user-facing prose except failure messages relayed from
adh. Those are relayed verbatim and are not localized by the coordinator.
Consumers that need localized failure text MUST map from the classified failure,
not from the message string.

## Accessibility Options

Not applicable.

## Feature Flags

None. Tool-call support is driven by what adh emits, not by a client flag.

## Analytics

The coordinator emits no analytics. Turn counts and latency are observable from
the event stream by the consumer.

## Privacy

Message text passes through the coordinator to adh and is persisted server-side.
The coordinator MUST NOT log message text, tool arguments, or tool results at any
level. It MUST NOT persist message content locally.

## Logging

| Event | Level | Contents |
|-------|-------|----------|
| Conversation created | debug | conversation id, persona slug |
| Turn started | debug | conversation id, localID |
| Turn ended | debug | conversation id, localID, outcome |
| Transport failure | error | conversation id, failure reason — never message text |

## Platform Notes

- **TypeScript / React (Web)** — `inboundEvents` is an async iterator. The
  coordinator is stable per `(personaSlug, model)`; memoize it at the call site
  so a re-render does not reset the conversation. Cancellation uses
  `AbortController`.

- **Swift (iOS / macOS)** — `inboundEvents` is an `AsyncStream<InboundEvent>`.
  The coordinator is an `actor` so concurrent `send` calls serialize.
  Cancellation uses structured concurrency: the streaming task is stored and
  cancelled by `destroy`. SSE is parsed from `URLSession.bytes`; note that
  `AsyncBytes.lines` collapses blank lines, which SSE uses as its block
  separator, so a line splitter that preserves them is required.

- **Kotlin / Compose (Android)** — `inboundEvents` is a `Flow<InboundEvent>`
  backed by `Channel(UNLIMITED).receiveAsFlow()`. It is a push source, so it must
  not be a cold `Flow` — a cold one restarts its producer per collector, which
  would start a second conversation. Cancellation is a coordinator-owned
  `CoroutineScope`, not the caller's. Planned; see
  `docs/planning/ports/android-coordinator.md`.

- **Windows** — `inboundEvents` is an `IAsyncEnumerable<InboundEvent>` over a
  `Channel<InboundEvent>`. Cancellation is a coordinator-owned
  `CancellationTokenSource`; `send` takes no `CancellationToken`, because the
  contract has no signal parameter to forward. `HttpClient` must be called with
  `HttpCompletionOption.ResponseHeadersRead` or nothing streams. Planned; see
  `docs/planning/ports/windows-coordinator.md`.

## Design Decisions

**Decision**: The server owns conversation history; the coordinator sends only
the new message.
**Rationale**: A1. Keeps every platform port thin and keeps prompt assembly in
one place. The contract already reflects this — `Backend.send` has no history
parameter.
**Approved**: yes

**Decision**: `draftUpdated.text` carries the accumulation, not the newest
fragment.
**Rationale**: Settled by the reference implementation — `DefaultOrchestrator`
assigns `text: event.text` into the draft, replacing wholesale. A coordinator
that emitted fragments would render every reply with its prefixes dropped.
**Approved**: yes

**Decision**: Tool calls get two new `InboundEvent` cases rather than being
folded into the draft.
**Rationale**: `CommandInvocation` and `CommandResult` already exist in the
contract with no event carrying them — tool calls could be described but not
observed. adh emits real tool events today, so the gap is now load-bearing.
**Approved**: pending

**Decision**: Retry and progress phases go to a status sink, not `InboundEvent`.
**Rationale**: `InboundEvent` is a transcript vocabulary. A retry is not
something that happened in the conversation. Mapping it onto `typing` would be a
lie the UI cannot distinguish from the persona actually typing.
**Approved**: pending

**Decision**: Parallel invocations of the same command correlate by arrival
order.
**Rationale**: adh's `tool_call_completed` carries no invocation id, so exact
correlation is impossible client-side. Oldest-open-first is the least surprising
rule. The real fix is an invocation id on the wire, which is an adh change.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| if-frontmatter-complete | passed | Artifact Formatting |
| if-type-field | passed | Artifact Formatting |
| if-title-heading | passed | Artifact Formatting |
| if-section-order | passed | Artifact Formatting |
| if-platform-notes | passed | Artifact Formatting |
| if-change-history | passed | Artifact Formatting |

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.0 | 2026-08-24 | Mike Fullerton | Added `ci-one-turn-at-a-time` and extended `ci-destroy-authoritative` over the conversation-creation window. Both were behaviors the implementation silently lacked: overlapping turns shared one cancellation handle and one invocation map, and a `destroy` during creation left the request in flight and let the turn post afterwards. Added vectors pcc-017 and pcc-018. |
| 1.0.0 | 2026-08-20 | Mike Fullerton | Initial creation |
| 1.2.0 | 2026-08-20 | Mike Fullerton | Rewrote the Kotlin and Windows platform notes to match the port plans in `docs/planning/ports/`. The Kotlin note called for a cold `Flow`, which cannot express a push source; the Windows note called for `CancellationToken`, which the contract has no parameter to carry. |
| 1.1.0 | 2026-08-20 | Mike Fullerton | Replaced `ci-forward-caller-signal` with `ci-no-reuse-after-destroy`. The original requirement was unimplementable as written: `Backend.send` takes no cancellation signal, so there is no caller signal to forward. `ci-destroy-authoritative` already carries the cancellation guarantee; what was untested was the state a destroyed coordinator is left in. Re-pointed `pcc-015` accordingly. |
