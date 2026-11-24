---
id: a14bb137-868e-4e8b-827b-4ea0f5e45b81
title: "Partner Inbound"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The closed set of events that can start a partner turn, each with the text the partner reads and an optional key that collapses repeats while they wait in the queue."
platforms:
  - swift
  - macos
tags:
  - partner
  - inbound
  - turn-queue
  - events
depends-on: []
related:
  - ae6b1991-6aed-4d8b-83e1-5d5e02470150
  - 1abdd016-954c-4058-8db3-224c52712365
  - 29db699c-56f4-40da-a8f7-b96a0cf820b0
references: []
approved-by: ""
approved-date: ""
---

# Partner Inbound

## Overview

`PartnerInbound` is the value type for "everything that can start a partner turn". The partner is a long-running Claude Code process that works one turn at a time; each turn begins with one inbound event rendered to a line or two of plain text. An event is one of five cases: an owner message, a job timer tick, a session going idle, a session exiting, or an app lifecycle notice. Each case supplies the text the partner reads (`text`), an optional coalescing key (`coalescingKey`) that `PartnerTurnQueue` (Partner Turn Queue ([adhsdk.ingredient.foundation.partner.partner-turn-queue](cookbook:ae6b1991-6aed-4d8b-83e1-5d5e02470150))) uses to collapse repeated events that are still waiting, and, for owner messages only, a chat attribution. The type is pure data and pure formatting: it holds no state and performs no I/O.

## Behavioral Requirements

Shape

- **case-set**: The type MUST be a closed enumeration of exactly these cases: `owner(text:attribution:)`, `tick(jobID:jobName:previousTick:summary:)`, `sessionIdle(sessionID:title:)`, `sessionExited(sessionID:title:)` and `lifecycle(_:)`.
- **lifecycle-set**: The `Lifecycle` payload MUST be a closed enumeration of exactly these cases: `started(resumed:goneSessions:)`, `guidelinesChanged`, `willQuit(endingSessions:)` and `turnTimedOut`.
- **value-semantics**: The type and `Lifecycle` MUST be `Sendable` and `Equatable` value types, so events can cross threads and two events compare equal when their cases and payloads are equal.

Text the partner reads (`text`)

- **owner-text**: For `owner`, `text` MUST be the owner's text exactly as given, with no prefix or suffix, and MUST NOT include the attribution.
- **tick-text-first-line**: For `tick`, `text` MUST begin with the line `Timer tick for job <jobName>.`
- **tick-text-previous**: For `tick`, when `previousTick` is non-nil, `text` MUST contain a second line `Previous tick: <date>` where the date is rendered in the ISO 8601 date-time style in UTC, with whole seconds, no fractional part and a literal `Z` suffix (for example `2026-11-14T10:00:00Z`); when it is nil that line MUST be omitted.
- **tick-text-summary**: For `tick`, when `summary` is non-nil, `text` MUST end with the summary as its own line, unchanged; when it is nil no line is added. A non-nil empty summary adds an empty final line.
- **tick-text-join**: The lines of a tick's `text` MUST be joined with a single newline and MUST NOT end with a trailing newline.
- **idle-text**: For `sessionIdle`, `text` MUST be `Session <sessionID> (<title>) went idle.`
- **exited-text**: For `sessionExited`, `text` MUST be `Session <sessionID> (<title>) exited.`
- **started-text**: For `lifecycle(.started)`, `text` MUST be `You were started (resumed: <true|false>). Sessions gone since last time: <list>` where `<list>` is the gone session ids joined by a comma and a space, or `none` when the list is empty. The sentence has no trailing period after the list.
- **guidelines-changed-text**: For `lifecycle(.guidelinesChanged)`, `text` MUST be `Your guidelines changed and were applied at this restart.`
- **will-quit-text**: For `lifecycle(.willQuit)`, `text` MUST be `The app is about to quit. These sessions will end: <list>` with `<list>` built the same way as for started (ids joined by a comma and a space, or `none`).
- **turn-timed-out-text**: For `lifecycle(.turnTimedOut)`, `text` MUST be `Your previous turn was terminated after the turn timeout and the session resumed.`
- **text-verbatim-ids**: The text builders MUST insert job names, session ids and titles without escaping, truncation or validation, so any string, including an empty one, is rendered as given.

Coalescing (`coalescingKey`)

- **key-tick**: For `tick`, `coalescingKey` MUST be `tick:<jobID>`, so it is keyed by the job id, not the job name.
- **key-idle**: For `sessionIdle`, `coalescingKey` MUST be `idle:<sessionID>`.
- **key-exited**: For `sessionExited`, `coalescingKey` MUST be `exit:<sessionID>`.
- **key-distinct-kinds**: An idle event and an exited event for the same session MUST have different keys, so one never replaces the other.
- **key-none-owner-lifecycle**: For `owner` and every `lifecycle` case, `coalescingKey` MUST be nil, so those events never collapse.
- **key-ignores-payload**: A key MUST depend only on the case and its id, never on the title, name, summary or previous-tick date, so that an event with the same key as an earlier one can stand in for it in a queue.
- **queue-honors-key**: The key is the only coalescing input this type provides. What a queue does with equal keys (replace in place, append, `enqueueFirst`) is specified by Partner Turn Queue ([adhsdk.ingredient.foundation.partner.partner-turn-queue](cookbook:ae6b1991-6aed-4d8b-83e1-5d5e02470150)), not here.

Attribution

- **attribution-owner-only**: `attribution` MUST return the attribution carried by an `owner` event, which may be nil, and MUST return nil for every other case.

Concurrency and side effects

- **pure-and-stateless**: Every computed property MUST be a pure function of the value, with no I/O, no clock read and no shared state, so it is safe from any thread and may be called repeatedly with the same result.

## Appearance

Not applicable — this is an event value type that renders to plain text for a language model, not a visual component.

## States

Not applicable — this is an immutable value type, not a visual component. It has no runtime state machine; each value is exactly one case.

## Accessibility

Not applicable — this is an event value type, not a visual component.

## Conformance Test Vectors

Vectors 001 and 002 are asserted in `PartnerModelsTests` (the test name is in the Input column); the rest are derived from the `PartnerInbound` source. The queue behavior that uses these keys has its vectors in Partner Turn Queue ([adhsdk.ingredient.foundation.partner.partner-turn-queue](cookbook:ae6b1991-6aed-4d8b-83e1-5d5e02470150)).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-inbound-001 | idle-text, exited-text | `sessionExited(sessionID: "s1", title: "review abc").text` (`inboundTextNamesTheEvent`) | Contains `s1`; equals `Session s1 (review abc) exited.` |
| partner-inbound-002 | will-quit-text | `lifecycle(.willQuit(endingSessions: ["s1"])).text` (`inboundTextNamesTheEvent`) | Contains `quit`; equals `The app is about to quit. These sessions will end: s1` |
| partner-inbound-003 | key-tick, key-none-owner-lifecycle | `coalescingKey` of two ticks for job "a" (the second with summary "2 queued") and of two identical owner messages "hi" | `tick:a` for both ticks; nil for both owner messages |
| partner-inbound-004 | key-idle, key-exited, key-distinct-kinds | `coalescingKey` of two `sessionIdle` for "s1" and one `sessionExited` for "s1" | `idle:s1` for both idle events and `exit:s1` for the exit, so the two kinds differ |
| partner-inbound-005 | tick-text-first-line, tick-text-join | `tick(jobID: "a", jobName: "A", previousTick: nil, summary: nil).text` | Exactly `Timer tick for job A.` |
| partner-inbound-006 | tick-text-previous, tick-text-summary, tick-text-join | Tick with previousTick 2026-11-14T10:00:00Z and summary "2 queued" | Three lines: `Timer tick for job A.`, `Previous tick: 2026-11-14T10:00:00Z`, `2 queued` |
| partner-inbound-007 | tick-text-summary | Tick with summary "" and previousTick nil | `Timer tick for job A.` followed by a newline and an empty line (text ends with a newline) |
| partner-inbound-008 | owner-text, attribution-owner-only | `owner(text: "hi", attribution: nil)` and an owner with an attribution | `text` is `hi` in both; `attribution` is nil, then the given attribution |
| partner-inbound-009 | attribution-owner-only | `attribution` of a tick, idle, exited and lifecycle event | nil for each |
| partner-inbound-010 | started-text | `lifecycle(.started(resumed: true, goneSessions: ["a", "b"]))` and `lifecycle(.started(resumed: false, goneSessions: []))` | `You were started (resumed: true). Sessions gone since last time: a, b` and `You were started (resumed: false). Sessions gone since last time: none` |
| partner-inbound-011 | guidelines-changed-text, turn-timed-out-text | `.guidelinesChanged` and `.turnTimedOut` | The two fixed sentences listed in the requirements |
| partner-inbound-012 | will-quit-text | `willQuit(endingSessions: [])` | `The app is about to quit. These sessions will end: none` |
| partner-inbound-013 | key-none-owner-lifecycle | `coalescingKey` of an owner and of each lifecycle case | nil in every case |
| partner-inbound-014 | key-ignores-payload | `coalescingKey` of tick (job "a", summary nil) and tick (job "a", summary "x") | Both are `tick:a` |
| partner-inbound-015 | value-semantics | Compare two `tick` values differing only in `summary` | Not equal, though their `coalescingKey` values are equal |
| partner-inbound-016 | text-verbatim-ids | `sessionIdle(sessionID: "", title: "")` | `Session  () went idle.` (nothing rejected) |
| partner-inbound-017 | idle-text | `sessionIdle(sessionID: "s1", title: "t")` | `Session s1 (t) went idle.` |

## Edge Cases

- **Empty or missing values**: An empty list of sessions renders as `none` (MUST); a nil `previousTick` or `summary` omits its line (MUST); an empty `summary` still adds an empty line (MUST, as stated in tick-text-summary).
- **Empty strings in ids and titles**: Rendered as given; the type does not validate them (MUST, text-verbatim-ids). An empty job id still produces the key `tick:`, which every other empty-id tick shares.
- **Same id, different titles**: Two idle events with the same session id and different titles share a key (`key-ignores-payload`); what the queue then keeps is specified by Partner Turn Queue ([adhsdk.ingredient.foundation.partner.partner-turn-queue](cookbook:ae6b1991-6aed-4d8b-83e1-5d5e02470150)).
- **Ids containing separators**: An id that contains a colon is not escaped. Keys of different kinds cannot collide because each kind has its own prefix, and the separator is not parsed back.
- **Repeated owner messages**: Identical owner messages never collapse; each starts its own turn (MUST).
- **Lifecycle notices**: A lifecycle event never collapses with another lifecycle event, including two of the same case (MUST).
- **Date rendering**: `previousTick` is always rendered in UTC regardless of the device time zone (MUST, tick-text-previous).
- **Concurrent access, network, timeouts, offline**: Not applicable — the type is immutable and does no I/O; ordering and concurrency belong to `PartnerTurnQueue` and the controller that owns it.
- **Boundary values**: Not applicable — there are no numeric limits; string length is unbounded.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `owner.text` | string | none (required) | The owner's message, passed through unchanged |
| `owner.attribution` | optional `ChatMessage.Attribution` | nil | Provenance of an owner line in a merged transcript |
| `tick.jobID`, `tick.jobName` | strings | none (required) | Id used for the key, name used in the text |
| `tick.previousTick` | optional date | nil | When set, adds the previous-tick line |
| `tick.summary` | optional string | nil | When set, adds a final line, such as the queue counts the app prepares |
| `sessionIdle` / `sessionExited` fields | `sessionID`, `title` strings | none (required) | Session identity and display title |
| `Lifecycle.started` fields | `resumed` bool, `goneSessions` strings | none (required) | Whether the partner resumed, and which sessions vanished meanwhile |
| `Lifecycle.willQuit.endingSessions` | strings | none (required) | Sessions that will end when the app quits |

## Deep Linking

Not applicable: the type is a plain value with no URL surface; nothing in the source routes by URL.

## Localization

Not applicable: every string is a prompt line read by the partner's language model, not text shown to a user, and the source externalises none of them; a port keeps them verbatim because the partner's guidelines refer to the events by these phrases.

## Accessibility Options

Not applicable: the type renders no visual output, so Reduce Motion, Increase Contrast and Differentiate Without Color do not reach it.

## Feature Flags

Not applicable: the source reads no flag; behavior is fixed.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: Whatever the caller puts in the event: the owner's message, job names, session ids and session titles.
- **Storage**: None; the value holds data only in memory for its lifetime.
- **Transmission**: The type transmits nothing; the rendered text is passed on by the caller to the partner process.
- **Retention**: Until the value is released; a queue holds waiting events until the next turn takes them.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: The source is in the `AgenticDeveloperHubSDKCore` framework and imports only `Foundation`. A SwiftUI view never renders this type; it only affects what the partner is told. The date line uses the Foundation `formatted` call with the ISO 8601 style, which formats in UTC by default. Tests are in `PartnerModelsTests`, with the queue types.
- **Compose**: Port as a Kotlin `sealed interface` with data classes for each case and a nested sealed interface for the lifecycle payload; data classes give the same value equality. Format the date with `java.time.Instant.toString()` or `DateTimeFormatter.ISO_INSTANT` truncated to whole seconds to match the UTC form `2026-11-14T10:00:00Z`.
- **React/Web**: Port as a TypeScript discriminated union keyed on a `kind` field, with `text` and `coalescingKey` as pure functions over it. Render the date with `new Date(ms).toISOString()` and drop the fractional seconds so it matches the source's whole-second UTC form. Compare events structurally (for example with a deep-equal helper) because JavaScript has no value equality for objects.
- **AppKit / UIKit**: Identical to the SwiftUI note: the type has no UI-framework dependency. Its consumer is the `@MainActor` `PartnerController`, which enqueues events and reads `text` when it starts a turn.
- **WinUI 3**: Port as a C# `abstract record` base with one `sealed record` per case (and a nested record hierarchy for the lifecycle), which gives value equality (`IEquatable<T>`) for free; the immutable records are safe to pass between threads. Implement `Text` as a `switch` expression and `CoalescingKey` as a nullable string. Format the previous tick with `DateTimeOffset.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture)` so it does not vary with the user's locale. Join lines with `string.Join("\n", ...)`. The type needs no Windows storage or UI API; the queue that consumes it would be a `List<PartnerInbound>` guarded by the owning class.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerInbound.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The coalescing key is built from the case and its id only, not from the payload.
**Rationale**: The queue exists so that a burst of ticks or idle events for the same job or session becomes one entry carrying the newest payload; including a summary or title in the key would stop repeats from collapsing.
**Approved**: pending

**Decision**: Owner and lifecycle events have no key.
**Rationale**: Owner messages are distinct instructions and lifecycle notices are one-off facts; collapsing either would lose information the partner must read. The source's own doc comment states that they never collapse.
**Approved**: pending

**Decision**: Idle and exited events for one session use different key prefixes (`idle` and `exit`).
**Rationale**: A session that went idle and then exited are two different facts; the exit must not overwrite or be overwritten by the idle notice.
**Approved**: pending

**Decision**: The event text is fixed English prose with ids inserted as given.
**Rationale**: The text is the partner's input, and the partner's guidelines and base prompt (Partner Base Prompt ([adhsdk.ingredient.foundation.partner.partner-base-prompt](cookbook:1abdd016-954c-4058-8db3-224c52712365))) refer to the events by these phrases. The text is not validated or escaped, so the partner reads exactly what the app knows.
**Approved**: pending

**Decision**: The text of a tick uses UTC ISO 8601 for the previous tick.
**Rationale**: The default ISO 8601 style is locale independent, so the partner reads the same instant regardless of the host's time zone.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

The type does one thing, formatting and keying events, with no I/O, so separation of concerns passes. `PartnerInboundConformanceTests` (Core/Partner) covers all 17 vectors: the tick, idle, exited, started, guidelines, timeout and quit text, every coalescing key and the attribution accessor, so unit-test coverage passes. `no-hardcoded-strings` passes because the strings are prompt lines for a language model, not text shown to a user.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerInboundConformanceTests.swift, 17 of 17 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Handed queue behavior to partner-turn-queue by rewriting the queue requirement and vectors 003, 004 and 014 as key-only, dropped text-names-event, added related links, stated the whole-second UTC date format, set no-hardcoded-strings to passed and removed the hard-coded source path. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
