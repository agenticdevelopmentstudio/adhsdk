---
id: ae6b1991-6aed-4d8b-83e1-5d5e02470150
title: "Partner Turn Queue"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A first-in-first-out queue of inbound partner events that collapses repeats by coalescing key and lets urgent notices jump the line (newest first)."
platforms:
  - swift
  - macos
  - ios
tags:
  - foundation
  - partner
  - queue
depends-on:
  - a14bb137-868e-4e8b-827b-4ea0f5e45b81
related: []
references: []
approved-by: ""
approved-date: ""
---

# Partner Turn Queue

## Overview

`PartnerTurnQueue` holds the inbound events waiting for the partner's next turn, oldest first. An event whose `PartnerInbound.coalescingKey` matches one already queued replaces it in place, so a burst of identical timer ticks or idle notices becomes one entry holding the newest payload at the original position. Which events carry a key, and how it is built, is `PartnerInbound`'s rule: owner messages and lifecycle notices have none, so they never coalesce. A second entry point puts a notice ahead of everything queued without coalescing. It is a plain value type with no storage, no I/O and no timers; its owner, the partner controller, decides when to take the next event and starts a turn with it. The controller is `@MainActor` and holds the queue as a stored property; it re-queues a turn that went to a dead process, puts `started`, `willQuit` and `turnTimedOut` notices ahead of the queue with `enqueueFirst`, and keeps the notion of an in-flight turn itself. The source is `Core/Partner/PartnerTurnQueue.swift`, a `public struct` that is `Sendable`, imports only `Foundation` and holds a private `[PartnerInbound]` array; `PartnerInbound` is a sibling type in `Core/Partner/PartnerInbound.swift`.

## Behavioral Requirements

- **value-type**: The queue MUST be a value type that is `Sendable` and starts empty from `init()`.
- **count**: `count` MUST report the number of entries currently queued.
- **fifo-order**: `enqueue` MUST append an inbound event at the back, and `next()` MUST remove and return the front entry, so events leave oldest first.
- **next-on-empty**: `next()` MUST return `nil` and leave the queue empty when nothing is queued.
- **coalesce-replaces-in-place**: `enqueue` MUST, when the inbound event has a non-nil `coalescingKey` equal to the key of an entry already queued, replace that entry with the new event at the same position, so a coalesced event does not move to the back, and leave `count` unchanged.
- **coalesce-first-match**: When more than one queued entry carries the inbound event's key, `enqueue` MUST replace only the first one (nearest the front).
- **no-key-appends**: `enqueue` MUST append an event whose `coalescingKey` is nil, even when an equal event is already queued.
- **key-compared-whole**: Keys MUST be compared as whole strings, and a nil key MUST never match; how a key is built is defined by `PartnerInbound`, not by the queue.
- **enqueue-first**: `enqueueFirst` MUST insert the event at the front of the queue, ahead of every queued entry, and increase `count` by one.
- **enqueue-first-no-coalesce**: `enqueueFirst` MUST NOT coalesce, even when its event carries a key equal to a queued entry's key; both entries remain.
- **enqueue-first-order**: When `enqueueFirst` is called repeatedly, the most recent call MUST be returned first by `next()`.
- **coalesce-targets-front-inserted**: An `enqueue` that follows an `enqueueFirst` MUST be able to coalesce into the front-inserted entry, because coalescing scans every queued entry.
- **no-capacity-limit**: The queue MUST NOT drop entries to enforce a size limit; only coalescing and `next()` reduce `count`.
- **no-persistence**: The queue MUST NOT persist its entries; they exist only as long as the value does.
- **no-side-effects**: The queue MUST NOT perform file, network, process or notification side effects.
- **infallible**: Every queue operation MUST NOT throw or return an error.
- **ownership-and-concurrency**: The queue is a struct with a mutating API and no internal locking, so a caller MUST serialise access to one instance.
## Appearance

Not applicable — this is a queue data structure, not a visual component.

## States

Not applicable — this is a queue data structure, not a visual component. Its only runtime state is the ordered list of entries described under Behavioral Requirements (empty or holding entries).

## Accessibility

Not applicable — this is a queue data structure, not a visual component.

## Conformance Test Vectors

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

## Edge Cases

- **Null / empty input**: `next()` on an empty queue returns `nil` (MUST). An event with a nil `coalescingKey` never matches anything and is always appended (MUST). An owner message with empty text is queued like any other.
- **Boundary values**: One queued entry is both first and last; `next()` empties the queue and `count` returns to 0. There is no upper bound on `count` (MUST NOT drop).
- **Concurrent access**: The queue is a value with no internal synchronisation; the single owner mutates it on the main actor, so ordering is the owner's call order. A port MUST serialise access the same way.
- **Error states**: No operation can fail; there is nothing to raise or return (MUST NOT throw).
- **Offline / disconnected state**: Not applicable: the queue performs no network access; the owner keeps work across a process restart only by re-queuing the interrupted turn with `enqueueFirst`.
- **Cancellation**: Not applicable: every operation completes synchronously and there is no cancel call; the only removals are `next()` and in-place replacement.
- **Duplicate keys from front insertion**: `enqueueFirst` can leave two entries with equal keys; a later `enqueue` with that key replaces the nearest-front one only (MUST).
- **Lossy replacement**: A coalesced event discards the older payload entirely (for example the earlier tick summary); this is the documented contract (MUST).

## Configuration

None — the queue reads no environment variable or settings key and takes no parameters; `init()` is empty and every value arrives through `enqueue` and `enqueueFirst`.

## Deep Linking

Not applicable: the queue defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the queue contains no user-facing string; the text the partner reads comes from `PartnerInbound.text`, a separate type.

## Accessibility Options

Not applicable: the queue presents no UI and responds to no accessibility display option.

## Feature Flags

Not applicable: the queue contains no feature-flag reference.

## Analytics

Not applicable: the queue contains no analytics call.

## Privacy

- **Data handled**: The inbound events its caller passes in, which can include owner message text and session titles; it inspects only each event's `coalescingKey`.
- **Storage**: In memory only, in the array held by the struct.
- **Transmission**: None; it performs no network access. The owner later sends a dequeued event's text to the partner process.
- **Retention**: Until `next()` removes an entry or a coalesced event replaces it; nothing survives the value's lifetime.

## Logging

Not applicable: the queue calls no logging API.

## Platform Notes

- **SwiftUI**: A SwiftUI host reads `count` from an observable owner, copying it into published state after each change, rather than observing the struct, which is not observable.
- **Compose**: A small class around an `ArrayDeque`; replacement is `indexOfFirst` plus assignment, front insertion is `addFirst`, `next()` is `removeFirstOrNull`. Hold it in a `ViewModel` and mutate on a single dispatcher (for example `Dispatchers.Main`); expose `count` through `StateFlow` if the UI needs it.
- **React/Web**: A class over an array with `findIndex`, direct assignment, `unshift` and `shift`; JavaScript is single-threaded so ordering needs no lock. Keep `coalescingKey` as `string or null` on the event type.
- **AppKit / UIKit**: The same file serves both unchanged; the macOS controller owns it as a stored property of a `@MainActor` class and copies `count` into its own queued count after each change.
- **WinUI 3**: Implement as a class over `List<PartnerInbound>` (`Insert(0, item)` for front insertion, `FindIndex` plus indexer assignment for coalescing, `RemoveAt(0)` for `Next()`), or a `LinkedList<T>` if front removal cost matters. Return `PartnerInbound?` from `Next()` and expose `Count` as a property. The owner's thread discipline replaces `@MainActor`: call it on the UI `DispatcherQueue`, or guard with a lock if called from tasks. If the UI shows the number waiting, raise `INotifyPropertyChanged` from the owner after each call; the queue itself is not observable. `System.Threading.Channels` is a poor fit because replacement in place and front insertion are required.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Partner/PartnerTurnQueue.swift` | confirmed (1.0.2) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Coalescing replaces the older entry in place rather than dropping the new event or moving it to the back.
**Rationale**: The partner needs the newest payload (for example the latest tick summary) but should still see it where the first occurrence was queued, so a chatty source cannot reorder or flood the queue; the source comment states "it keeps the position and takes the newer payload".
**Approved**: pending

**Decision**: `enqueueFirst` bypasses coalescing.
**Rationale**: The source doc comment says it is "for a notice the partner must read before any waiting event"; the owner uses it for a `started` notice and for re-sending an interrupted turn, which must not be merged into or replaced by an older entry.
**Approved**: pending

**Decision**: Coalescing keys live on `PartnerInbound`, not on the queue, and owner messages and lifecycle notices have no key.
**Rationale**: Each owner message is distinct intent and each lifecycle notice marks a separate moment, so only repeatable status events (ticks, idle, exit) collapse.
**Approved**: pending

**Decision**: The queue has no capacity limit and no thread safety of its own.
**Rationale**: Coalescing already bounds repeatable events, and the sole owner is `@MainActor`, so synchronisation is the owner's isolation, not the struct's.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |

Separation of concerns passes: the queue holds ordering and coalescing only, while event text, keys and the turn machinery live in `PartnerInbound` and the controller. Unit-test coverage passes: `PartnerTurnQueueConformanceTests.swift` covers all eleven vectors, including `next()` on an empty queue, repeated `enqueueFirst` and `enqueueFirst` with an equal key. Explicit error handling passes because no operation can fail and none hides an error.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (PartnerTurnQueueConformanceTests.swift, 11 of 11 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Moved key-building and controller notes out of the requirements into the Overview, merged coalesce-keeps-position, split infallible from no-side-effects, added ios and partner-inbound, and fixed the summary and vector coverage maps. |
