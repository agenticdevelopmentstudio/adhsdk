# Port Plan — Persona Chat Coordinator on Windows (.NET / C#)

Derived from [`docs/specs/ingredients/persona-chat-coordinator.md`](../../specs/ingredients/persona-chat-coordinator.md).
Status: **planned, not implemented.** Nothing in `packages/windows/` builds yet.

This plan exists so the port is a translation exercise rather than a design
exercise. Every decision below is downstream of the ingredient spec; where the
platform forces a choice the spec does not make, the choice is recorded here and
marked so it can be argued with before code exists.

## What ships

```
packages/windows/
  AgenticDeveloperHubSDK.sln
  src/AgenticDeveloperHubSDK/
    AgenticDeveloperHubSDK.csproj              # net8.0, C# 12, <Nullable>enable</Nullable>
    Contract/                          # mirrors packages/apple/AgenticDeveloperHubSDK/SDK/Sources one-to-one
      Backend/IBackend.cs
      Backend/InboundEvent.cs
      Messages/IMessage.cs
      Commands/CommandInvocation.cs
      ...
    Coordinator/PersonaChatCoordinator.cs
    Coordinator/SseParser.cs
  tests/AgenticDeveloperHubSDK.Tests/
    PersonaChatCoordinatorTests.cs
```

Target `net8.0` rather than a Windows-specific TFM. The coordinator is HTTP and
async plumbing with no UI and no Win32 surface; pinning it to `net8.0-windows`
would keep it out of a cross-platform consumer for no benefit. A future WinUI
chat control is a separate assembly and a separate plan.

The contract folder is a straight transliteration and carries no decisions —
port it first, in one pass, before touching the coordinator.

## Contract mapping

| Contract element | C# expression | Why |
|---|---|---|
| `InboundEvent` (sum type) | `abstract record InboundEvent` with a private constructor and nested `sealed record` cases | See below. |
| `IBackend.InboundEvents` | `IAsyncEnumerable<InboundEvent>` over `Channel<InboundEvent>` | `Channel.Reader.ReadAllAsync()` is the direct analogue of Swift's `AsyncStream` and the TypeScript `EventQueue`. |
| `IBackend.SendAsync` | `Task<string> SendAsync(string text, IReadOnlyList<IAttachment> attachments)` | Returns the `localID`; the reply arrives on the event stream. |
| `Destroy` | `void Destroy()` — **not** `Task` | `destroy` must be authoritative the instant it returns; awaiting it lets a `SendAsync` win the race. |
| `Authorize` | `Func<HttpRequestMessage, Task<HttpResponseMessage>>` | Credentials are injected, never imported (spec, Configuration). |
| Turn cancellation | a `CancellationTokenSource` the coordinator owns | Never a caller-supplied token — see below. |

### The sum type is the one real impedance mismatch

C# has no discriminated unions. Two shapes are available and the choice matters,
because `InboundEvent` gains cases over time — `commandInvoked` and
`commandCompleted` were added while the first two ports were being written.

Use a **closed record hierarchy**: an `abstract record InboundEvent` whose only
constructor is private, with `sealed record` cases nested inside it. External
code cannot add a case, and `switch` expressions pattern-match on type cleanly.

The cost is honest and worth stating: C# does **not** check exhaustiveness over
a type hierarchy the way Swift's `enum` and Kotlin's `sealed interface` do. A new
case compiles everywhere and fails at runtime. Mitigate with a
`_ => throw new UnreachableException(...)` arm in every switch — a loud failure
in a test run instead of a silently dropped event. Do not use a
`Kind` enum plus a wide struct; it makes every consumer re-check invariants the
type system should be carrying.

### Cancellation is ours, never the caller's

`ci-destroy-authoritative` requires the coordinator to own its cancellation
handle. There is a strong pull on .NET toward adding a `CancellationToken`
parameter to `SendAsync` because every other async method has one — resist it.

The ingredient spec previously carried a requirement to forward a caller-supplied
signal (`ci-forward-caller-signal`). It was removed in spec v1.1.0 as
unimplementable: `Backend.send` takes no signal in any platform's contract, so
there is nothing to forward. `ci-no-reuse-after-destroy` replaced it. Adding a
token here would diverge this port from the contract rather than enrich it.

`Destroy()` does three things, in this order:

1. Set `_destroyed = true` and `_cts.Cancel()`.
2. `_channel.Writer.TryWrite(new InboundEvent.DraftCleared(_participantId))`.
3. `_channel.Writer.TryComplete()`.

Step 2 is not optional and does not belong in the turn's own `finally`.
Cancellation unwinds asynchronously; by the time the cancelled turn's cleanup
runs, the channel is completed and its `draftCleared` goes nowhere — leaving a
chat surface holding a half-written draft forever. Both shipped implementations
emit it from `destroy` itself for exactly this reason.

### Two traps mutation testing already found

Both are "the guarantee is held twice, so breaking one guard proves nothing", and
both will recur here:

- **`ci-no-reuse-after-destroy` is guarded twice** — the explicit
  `if (_destroyed) throw` in `SendAsync`, and the turn-registration check that
  refuses to adopt a turn on a dead coordinator. Keep both, but know that a test
  which breaks only one still passes.
- **`ci-commit-once` is two claims** — "exactly one `messageReceived`" and
  "`draftCleared` comes after it". A mutation that moves the clear into a
  `finally` does not break the ordering, because `finally` runs after the commit.
  Test the count and the order separately.

## Transport

`HttpClient`, with our own SSE parser over the response stream.

**`HttpCompletionOption.ResponseHeadersRead` is mandatory.** The default
(`ResponseContentRead`) buffers the entire response before returning, so a
streaming turn arrives all at once at the end and every draft vector passes
vacuously while the actual UX is broken. This is the single easiest thing to get
wrong in this port.

Read the stream as **bytes, not lines**. The Swift port learned this the
expensive way: a line-oriented reader collapses the blank line separating SSE
blocks, which is the only thing marking where one event ends. Buffer bytes, split
on `\n\n`, keep the remainder. `SseParser.swift` is the reference and is roughly
forty lines.

Do not take a dependency on an SSE client library. `ci-unknown-events`,
`ci-in-band-errors`, and the truncated-stream edge case are decisions about our
vocabulary, and a general-purpose client puts its own reconnect and error policy
in the middle of them.

`SendAsync` starts the turn on a background `Task` stored in the coordinator's
turn control and returns the `localID` immediately. No `async void` anywhere —
an unobserved exception in an `async void` turn tears down the process.

## Conformance

`pcc-001` … `pcc-016` from the spec are the acceptance criterion, one test each,
named for the requirement they hold the coordinator to. Plus the five Edge Cases
as their own tests — empty reply, conversation-creation failure, truncated
stream, parallel same-name tool calls, destroy-during-creation.

- **xUnit**, with `await foreach` over `InboundEvents` behind a timeout so a
  never-arriving event fails as an assertion rather than hanging the run.
- Fake transport: an `Authorize` delegate that records requests and returns a
  scripted `byte[]` sequence as the response content. No `WireMock`; the vectors
  are about our parsing and event vocabulary, not about HTTP.

The spec's standard applies without exception: *each vector MUST be observed
failing for its stated reason before it is trusted.* Both shipped ports were
proved with a mutation harness that breaks one requirement at a time and asserts
that the vector claiming it fails. Write the .NET equivalent.

## Open questions

1. **Is the contract assembly published separately from the coordinator?** Web
   splits them (`@adh-sdk/chat/contract`); Apple does not. A
   consumer writing its own `IBackend` wants the contract without `HttpClient`.
2. **Naming convention.** .NET convention wants `SendAsync` / `InboundEvents`
   where the contract says `send` / `inboundEvents`. Following .NET convention
   costs cross-platform greppability; ignoring it makes the library feel foreign.
   Recommend following .NET convention and stating the mapping in a doc comment
   on each member.
3. **Packaging.** NuGet package versus source inclusion in a consuming solution.

## Settled — do not re-litigate

A1 orchestration (the server owns history; `send` carries no history),
`draftUpdated` carrying the accumulation rather than the newest fragment, and
tool activity being its own event channel rather than draft text. All three are
recorded with rationale in the ingredient spec's Design Decisions and are load-
bearing across all four platforms.
