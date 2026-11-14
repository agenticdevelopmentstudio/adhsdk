---
id: cfb09ec6-c38f-474a-bd79-be8f67ab523c
title: "Chat Coordinator Projection"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-09-23
modified: 2026-09-24
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Projects a chat contract's messages, drafts, and running commands into the web transcript's display model."
platforms:
  - typescript
  - web
tags:
  - chat
  - projection
  - view-model
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Chat Coordinator Projection

## Overview

`chat-coordinator-projection` is the read-only translation layer between the chat package's portable contract (`ChatViewModel`, `Message`, `ActiveDraft`, `ActiveCommand`, `Attachment`) and the web transcript's display model (`ChatMessage`). It has two responsibilities, implemented as pure functions with no I/O of their own:

- `projection/toChatMessages.ts` — `projectMessages` flattens `ChatViewModel.messages` and `ChatViewModel.activeDrafts` into a single ordered `ChatMessage[]`, folding in `activeCommands` for a still-open draft's tool-call display; `draftMessageID` gives a draft's projected id a stable, participant-keyed form.
- `projection/richContent.ts` — `encodeRichDisplay`/`decodeRichDisplay` carry web-only display extras (`content`, `popover`, `toolCalls`) through the portable `Attachment` vocabulary under the vendor media type `RICH_DISPLAY_MEDIA_TYPE`, so a backend can attach transcript-only data without the contract itself knowing about it.

Its only caller is `hooks/useChatSession.ts`, which supplies the `StampFor` clock and re-runs the projection on every `ChatUpdate`.

## Behavioral Requirements

- **empty-display-encoding**: `encodeRichDisplay` MUST return `null` when the given `RichDisplay` has no `content` items, no `popover`, and no `toolCalls` (an undefined or empty-array payload for each field).
- **rich-display-attachment-shape**: `encodeRichDisplay` MUST, for a non-empty `RichDisplay`, return an `Attachment` whose `id` equals the caller-supplied `id`, whose `mediaType.identifier` equals `RICH_DISPLAY_MEDIA_TYPE` (value `application/vnd.adhsdk.rich-display+json`), whose `source` is `{ kind: 'inline', data: <UTF-8 bytes of JSON.stringify(display)> }`, and whose `presentation` is `'inline'`.
- **rich-display-lookup-by-media-type**: `decodeRichDisplay` MUST scan the given attachments in array order and consider only an attachment whose `mediaType.identifier` equals `RICH_DISPLAY_MEDIA_TYPE` and whose `source.kind` equals `'inline'`.
- **rich-display-decode-fallthrough**: `decodeRichDisplay` MUST skip a candidate attachment — continuing the scan rather than returning — whose inline payload fails `JSON.parse`, or whose parsed value is `null` or not of type `object`.
- **rich-display-decode-default**: `decodeRichDisplay` MUST return `{}` when no attachment in the given list matches and decodes successfully, including when the given attachment array is empty.
- **rich-display-decode-non-throwing**: `decodeRichDisplay` MUST NOT throw for any input attachment array; a malformed matching attachment is caught and skipped rather than propagated to the caller.
- **non-rich-display-attachment-coexistence**: A `Message`'s or `ActiveDraft`'s `attachments` MAY contain attachments other than the rich-display payload; `decodeRichDisplay` MUST ignore every attachment whose `mediaType.identifier` is not `RICH_DISPLAY_MEDIA_TYPE`.
- **projection-ordering**: `projectMessages` MUST return committed messages from `view.messages`, in their given order, followed by entries derived from `view.activeDrafts`, in their given order.
- **committed-message-identity**: For each committed message `m`, `projectMessages` MUST set the projected `id` to `m.id` when present, otherwise to `m.localID`.

- **duplicate-resolved-ids**: NEEDS REVIEW: Not implemented in source. `projectMessages` resolves a committed message's id as `m.id ?? m.localID` (`projection/toChatMessages.ts`, `projectMessages`) with no uniqueness check. If two entries in `view.messages` resolve to the same id — for example a server-assigned `id` that happens to collide with another message's `localID` — `projectMessages` emits two `ChatMessage` entries sharing one id, and downstream consumers keyed on id (list rendering, `stampFor` lookups) have undefined behavior. Resolving this requires either a documented invariant that `ChatViewModel.messages` never yields colliding ids upstream, or de-duplication logic here — neither of which the given source states. This would need input from whoever owns the `ChatViewModel` implementation that produces `messages`.
- **committed-message-sender**: `projectMessages` MUST set the projected `sender` to `parts.user` when `m.senderID === parts.localParticipantID`, otherwise to `parts.persona`.
- **committed-message-persona-flag**: `projectMessages` MUST set the projected `isPersona` to `true` when `m.senderID !== parts.localParticipantID`, otherwise to `false`.
- **committed-message-text**: `projectMessages` MUST set the projected `text` to `m.text` verbatim.
- **committed-message-rich-display**: `projectMessages` MUST decode `m.attachments` with `decodeRichDisplay` and set the projected `content`, `popover`, and `toolCalls` to the decoded `RichDisplay`'s `content`, `popover`, and `toolCalls` respectively.
- **committed-message-timestamp**: `projectMessages` MUST set the projected `timestamp` to `m.timestamp` when present, otherwise to `stampFor(id)`, using the resolved projected `id` as the key.
- **committed-message-failure**: `projectMessages` MUST set the projected `failure` to `m.deliveryStatus.reason` when `m.deliveryStatus.kind === 'failed'`, otherwise leave `failure` `undefined`.
- **delivery-status-projection**: `projectMessages` MUST carry no `MessageDeliveryStatus` kind other than `failed` into the projection: `composing`, `sending`, `sent`, `delivered` and `received` all project to a `ChatMessage` with `failure` `undefined`, so a port MUST NOT infer send progress from the projected message.
- **committed-message-not-streaming**: `projectMessages` MUST NOT set `isStreaming` on a committed message's projection; the field is omitted, leaving it `undefined`.
- **draft-identity**: `draftMessageID` MUST return the string `draft:` concatenated with `participantID` for a given `participantID`, deterministically and without side effects.
- **draft-projection-id**: For each entry in `view.activeDrafts`, `projectMessages` MUST set the projected `id` to `draftMessageID(draft.participantID)`.
- **draft-projection-sender**: `projectMessages` MUST derive a draft's projected `sender` and `isPersona` the same way as a committed message's, using `draft.participantID` in place of `m.senderID`.
- **draft-projection-timestamp**: `projectMessages` MUST set a draft's projected `timestamp` to `stampFor(draftMessageID(draft.participantID))` unconditionally; `ActiveDraft` carries no timestamp field of its own.
- **draft-projection-streaming-flag**: `projectMessages` MUST set `isStreaming: true` on every entry derived from `view.activeDrafts`.
- **draft-projection-no-failure**: `projectMessages` MUST NOT set a `failure` value on a draft-derived projection.
- **draft-tool-call-precedence**: For a draft, `projectMessages` MUST set the projected `toolCalls` to the mapped result of filtering `view.activeCommands` to entries whose `participantID` equals `draft.participantID`, when that filtered list is non-empty.
- **draft-tool-call-fallback**: For a draft, when no entry in `view.activeCommands` has a matching `participantID`, `projectMessages` MUST set the projected `toolCalls` to the decoded `RichDisplay.toolCalls` from `draft.attachments`.
- **active-command-to-tool-call-running**: `toToolCallInfo` MUST map an `ActiveCommand` whose `result` is `undefined` to `{ name: invocation.commandName, arguments: invocation.argumentsJSON, status: 'started' }`.
- **active-command-to-tool-call-finished**: `toToolCallInfo` MUST map an `ActiveCommand` whose `result` is defined to `{ name: invocation.commandName, arguments: invocation.argumentsJSON, status: result.ok ? 'completed' : 'failed', ok: result.ok, result: result.resultJSON ?? result.errorMessage ?? '' }`.
- **projection-purity**: `projectMessages`, `decodeRichDisplay`, `encodeRichDisplay`, `draftMessageID`, and `toToolCallInfo` MUST NOT mutate `view.messages`, `view.activeDrafts`, `view.activeCommands`, or any `Attachment`, `Message`, `ActiveDraft`, or `ActiveCommand` passed to them; every one of those types is declared with `Readonly`/`ReadonlyArray` members in the contract.
- **projection-one-directional**: `projectMessages` MUST NOT call any mutating `ChatViewModel` method (`submitMessage`, `markRead`, `setLocalTyping`, `respondToWidget`, `respondToPermission`); it is a read-only projection in one direction only.
- **stamp-for-stability**: A `StampFor` implementation MUST return the same `Date` for a given key on every call within a session; `projectMessages` may run once per render, and a fresh timestamp per call would advance every untimed message's or draft's displayed time on each pass.
- **synchronous-execution**: `projectMessages`, `encodeRichDisplay`, `decodeRichDisplay`, `draftMessageID`, and `toToolCallInfo` MUST execute synchronously and MUST NOT perform any asynchronous, network, or file-system operation.

## Appearance

Not applicable — this is a data projection module (pure functions over chat contract types), not a visual component.

## States

Not applicable — this is a data projection module, not a visual component; the runtime states it participates in (a draft's streaming flag, a command's started/completed/failed status) are specified under Behavioral Requirements rather than a visual-state table.

## Accessibility

Not applicable — this is a data projection module, not a visual component; it renders no DOM and exposes no interactive control.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|--------------|-------|----------|
| ccp-001 | empty-display-encoding | `encodeRichDisplay({}, "m1:display")` | Returns `null`. |
| ccp-002 | rich-display-attachment-shape | `encodeRichDisplay({ popover: { title: "Info" } }, "m1:display")` | Returns an `Attachment` with `id: "m1:display"`, `mediaType.identifier` equal to `RICH_DISPLAY_MEDIA_TYPE`, `source: { kind: "inline", data: <UTF-8 bytes of the JSON string `{"popover":{"title":"Info"}}`> }`, `presentation: "inline"`. |
| ccp-003 | rich-display-lookup-by-media-type, non-rich-display-attachment-coexistence | `decodeRichDisplay` on an array of two attachments: one with `mediaType.identifier: "image/png"`, then one produced by `encodeRichDisplay({ content: [{ type: "link", url: "https://x" }] }, "a2")` | Returns `{ content: [{ type: "link", url: "https://x" }] }`. |
| ccp-004 | rich-display-decode-fallthrough, rich-display-decode-non-throwing | `decodeRichDisplay` on one attachment whose `mediaType.identifier` equals `RICH_DISPLAY_MEDIA_TYPE`, `source.kind: "inline"`, and `source.data` is the UTF-8 bytes of the text `not json` | Returns `{}` and does not throw. |
| ccp-005 | rich-display-decode-default | `decodeRichDisplay([])` | Returns `{}`. |
| ccp-006 | projection-ordering, draft-projection-streaming-flag | `projectMessages` with `view.messages` holding one message `m1` (`senderID: "local"`, `localID: "m1"`) and `view.activeDrafts` holding one draft (`participantID: "bot"`) | Returns a 2-entry array: index 0 has `id: "m1"` and `isStreaming: undefined`; index 1 has `id: "draft:bot"` and `isStreaming: true`. |
| ccp-007 | committed-message-timestamp | `projectMessages` with `m1` carrying no `timestamp` and resolving to `id: "abc"`; `stampFor` is a stub that always returns a fixed `Date` `D` and records the keys it was called with | The projected message's `timestamp` is `D`, and `stampFor` was called with `"abc"`. |
| ccp-008 | committed-message-failure | `projectMessages` with `m1.deliveryStatus = { kind: "failed", reason: "network error" }` | The projected message's `failure` is `"network error"`. |
| ccp-009 | draft-tool-call-precedence | `projectMessages` with a draft for `participantID: "bot"` whose `attachments` decode to `toolCalls: [{ name: "old", arguments: "{}", status: "completed" }]`, and `view.activeCommands` holding one entry for `participantID: "bot"` with `invocation: { commandName: "search", argumentsJSON: "{}", ... }` and `result: undefined` | The projected draft's `toolCalls` is `[{ name: "search", arguments: "{}", status: "started" }]`. |
| ccp-010 | draft-tool-call-fallback | Same draft as ccp-009, but `view.activeCommands` has no entry for `"bot"` | The projected draft's `toolCalls` is the decoded `[{ name: "old", arguments: "{}", status: "completed" }]`. |
| ccp-011 | active-command-to-tool-call-finished | `toToolCallInfo` on `{ participantID: "p", invocation: { commandName: "run", argumentsJSON: "{}", ... }, result: { invocationID: "i1", ok: false, errorMessage: "boom", completedAt: D } }` | Returns `{ name: "run", arguments: "{}", status: "failed", ok: false, result: "boom" }`. |
| ccp-012 | draft-identity | `draftMessageID("bot-42")` | Returns `"draft:bot-42"`. |

## Edge Cases

- **Empty view (null/empty input)**: `view.messages: []` and `view.activeDrafts: []` — `projectMessages` MUST return `[]`.
- **Empty attachment list (null/empty input)**: `attachments: []` passed to `decodeRichDisplay` — MUST return `{}`.
- **Fully empty display (null/empty input)**: `display` with `content: []`, `popover: undefined`, `toolCalls: []` passed to `encodeRichDisplay` — MUST return `null`, per **empty-display-encoding**.
- **Empty in-progress draft (null/empty input)**: a draft whose `text` is `""` — MUST still be projected as an entry with `text: ""` and `isStreaming: true`; no draft is skipped for being textually empty.
- **Multiple matching attachments (boundary value)**: more than one attachment in a list carries `mediaType.identifier === RICH_DISPLAY_MEDIA_TYPE` — `decodeRichDisplay` MUST use the first one, in array order, whose inline payload parses to a non-null object, and MUST continue past any preceding match whose payload fails to parse, per **rich-display-decode-fallthrough**.
- **Matching media type on a remote source (boundary value)**: an attachment has `mediaType.identifier === RICH_DISPLAY_MEDIA_TYPE` but `source.kind === "remote"` — `decodeRichDisplay` MUST skip it and keep scanning, per **rich-display-lookup-by-media-type**.
- **Concurrent access**: Not applicable — every function described here is a synchronous, side-effect-free pure function over its arguments. JavaScript's single-threaded execution model serializes all calls, and no data here is shared mutable state; every contract type these functions read (`Message`, `ActiveDraft`, `ActiveCommand`, `Attachment`) declares its members `Readonly`/`ReadonlyArray`.
- **Error states (dependency unavailable/error)**: Not applicable in the network/database/file-system sense — this module calls no dependency of that kind. The one internal error path, a malformed inline attachment payload, is handled by `decodeRichDisplay` catching the `JSON.parse` failure and continuing rather than throwing, per **rich-display-decode-non-throwing**; no error is surfaced to the caller.
- **Offline/disconnected state**: Not applicable — this module makes no network call of its own; it operates entirely on data already resolved into `ChatViewModel`/`Attachment` values by its caller.
- **Duplicate resolved message ids**: see the open question on **duplicate-resolved-ids**.
- **Structurally valid but unrecognized JSON shape (malformed input)**: a matching attachment's payload parses to a JSON array, or to an object with none of `content`/`popover`/`toolCalls` — `decodeRichDisplay`'s `typeof parsed !== 'object' || parsed === null` check accepts it unchanged (an array is `typeof "object"` and not `null`), so the projected `content`, `popover`, and `toolCalls` end up `undefined` with no distinct error signaled; documented further under Design Decisions.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `view` | `Pick<ChatViewModel, 'messages' \| 'activeDrafts' \| 'activeCommands'>` | required | The slice of chat state `projectMessages` reads; only these three fields are consulted. |
| `parts` | `ProjectionParticipants` (`{ persona, user, localParticipantID }`) | required | Which `ChatParticipant` represents the local user versus the persona, and the id that marks a sender as local. |
| `stampFor` | `StampFor` (`(key: string) => Date`) | required | Caller-supplied clock for a message or draft with no timestamp of its own; MUST be stable per key (see **stamp-for-stability**). `useChatSession.ts` backs this with a per-session `Map`. |
| `id` (to `encodeRichDisplay`) | `string` | required | The identifier assigned to the produced `Attachment`; the function does not generate or validate it. |
| `display` (to `encodeRichDisplay`) | `RichDisplay` (`{ content?, popover?, toolCalls? }`) | required | The payload to encode; an all-empty value encodes to `null` rather than an attachment. |
| `attachments` (to `decodeRichDisplay`) | `ReadonlyArray<Attachment>` | required | The list scanned for a rich-display payload; an empty array decodes to `{}`. |
| `RICH_DISPLAY_MEDIA_TYPE` | `string` constant | `application/vnd.adhsdk.rich-display+json` | The vendor media type identifying a rich-display attachment; not caller-configurable, but consumers on either side of the wire rely on its exact value for interop. |

## Deep Linking

Not applicable: neither `richContent.ts` nor `toChatMessages.ts` performs navigation or constructs a URL; a projected message or draft carries no route or deep-link data.

## Localization

Not applicable: this module passes caller-supplied strings through unchanged (`m.text`, `deliveryStatus.reason`, the decoded `RichDisplay` fields) and introduces no user-facing string of its own to localize.

## Accessibility Options

Not applicable: this is a data projection module with no visual rendering, so it responds to none of Reduce Motion, Increase Contrast, or Differentiate Without Color.

## Feature Flags

Not applicable: neither source file reads a feature-flag key or gates a branch on one.

## Analytics

Not applicable: neither source file emits an analytics event or calls a tracking API.

## Privacy

Not applicable: this module defines no credential, token, or account-identifying field. It serializes only caller-supplied display data (`content`, `popover`, `toolCalls`) into an `Attachment` byte payload and performs no storage or transmission of its own — those are the concerns of `ChatBackendAdapter` and whatever persistence layer sits behind it, not of this projection.

## Logging

Not applicable: neither `richContent.ts` nor `toChatMessages.ts` calls a console or logging API.

## Platform Notes

- **SwiftUI**: no view is involved on either side of this port. Represent `RichDisplay` as a `Codable` struct and port `encodeRichDisplay`/`decodeRichDisplay` as free functions built on `JSONEncoder`/`JSONDecoder` and `Data` in place of `TextEncoder`/`TextDecoder` and `Uint8Array`; port `projectMessages` as a pure, `Sendable` function returning `[ChatMessage]` so a `@MainActor` view model's `@Published` array can be assigned from it without the projection itself needing main-actor isolation.
- **Compose**: analogous to the SwiftUI port — a plain Kotlin `data class RichDisplay` serialized with `kotlinx.serialization`, and a pure `fun projectMessages(...): List<ChatMessage>` feeding a `StateFlow<List<ChatMessage>>`; no `@Composable` annotation belongs on this layer, matching the source's separation of projection from rendering.
- **React/Web** (source platform): `packages/web/packages/chat/src/projection/richContent.ts` and `projection/toChatMessages.ts` — plain, framework-free TypeScript functions with zero React imports; `TextEncoder`/`TextDecoder` handle the UTF-8 round trip. The only React involvement is at the call site, `hooks/useChatSession.ts`, which re-invokes `projectMessages` inside a `useMemo` keyed on a version counter that bumps on every `ChatUpdate`.
- **AppKit / UIKit**: the same Swift port described under SwiftUI applies unchanged — the projection is UI-framework-agnostic, so an `NSTableView` or `UITableView` data source is fed from the same `[ChatMessage]` array rather than from any AppKit/UIKit-specific type.
- **WinUI 3**: represent `RichDisplay` as a C# record serialized with `System.Text.Json` (`JsonSerializer.Serialize`/`Deserialize`) into a `byte[]` in place of `Uint8Array`; port `projectMessages` as a pure method producing (or diffing into) an `ObservableCollection<ChatMessage>` for `x:Bind`, with `ChatMessage` implementing `INotifyPropertyChanged` only if a bound property changes after creation — a freshly-created transcript entry does not need it. `StampFor` maps to a `Func<string, DateTimeOffset>` backed by a `Dictionary<string, DateTimeOffset>` cache the view model owns, mirroring `useChatSession`'s `stamps` `Map`. No `HttpClient`, `Windows.Storage`, or `Task`/`async` belongs in this port: the source performs no I/O of its own, and the coordinator that supplies `view` is where those APIs apply.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/projection/` | unverified |

## Design Decisions

**Decision**: Web-only display extras (`content`, `popover`, `toolCalls`) ride through the contract as one `Attachment` under a vendor media type rather than as fields on `Message`.
**Rationale**: The contract's message vocabulary is deliberately portable; a platform that does not recognize the vendor media type can ignore the attachment entirely without knowing anything about it, while `ThreePaneChat` and `InlineChat` build their popover and content rendering entirely from it.
**Approved**: pending

**Decision**: `encodeRichDisplay` returns `null` for an empty payload rather than an attachment carrying `{}`.
**Rationale**: An empty attachment list already spells "no extras"; giving the same state two spellings is one more check every consumer of `Message.attachments` would have to make.
**Approved**: pending

**Decision**: Rich display data is JSON-encoded into an inline attachment rather than mapped onto `AttachmentSource.remote`.
**Rationale**: `remote` holds a parsed `URL`, and a relative `src` — which `ImageContent` permits — has no absolute form until something supplies a base. Lossless beats semantically tidy for a payload whose only reader is the bubble it came from.
**Approved**: pending

**Decision**: A draft's projected id is keyed by participant (`draft:${participantID}`) rather than freshly generated on every update.
**Rationale**: A draft that grows over dozens of `draftUpdated` events keeps one id, and so one React key and one DOM node, across the whole stream; a new id per token would remount the bubble on every character, losing focus, restarting animations, and defeating scroll anchoring.
**Approved**: pending

**Decision**: A draft's `toolCalls` come from the live `activeCommands` channel when any exist for that participant, and from the decoded display payload only otherwise — never merged.
**Rationale**: The live list is the truth while the turn is open; a payload the backend chose to record is the frozen truth once the message has committed. Preferring one over the other, rather than combining them, avoids double-counting or conflicting entries during the handoff between the two.
**Approved**: pending

**Decision**: A rich-display attachment that fails to decode is treated as absent rather than surfaced as an error.
**Rationale**: A hand-rolled attachment under this vendor media type is the sender's bug, not the transcript's; letting a malformed payload throw inside a render pass would take the whole conversation down with it.
**Approved**: pending

**Decision**: The open question on **duplicate-resolved-ids** (colliding resolved ids) is left unresolved by this module rather than guessed at.
**Rationale**: This module does not construct message ids; picking a de-duplication policy here would require guessing which of two colliding messages is canonical, a call only the id's producer — the `ChatViewModel` implementation — can make correctly.
**Approved**: pending

**Decision**: The projection surfaces only the `failed` delivery kind (**delivery-status-projection**); the other `MessageDeliveryStatus` kinds are dropped rather than carried on `ChatMessage`.
**Rationale**: No consumer in the given source reads a "sending" versus "delivered" distinction from `ChatMessage`; whether the transcript should ever show it is a product decision for whoever owns the chat UI contract, not one this projection can make on its own.
**Approved**: pending

**Decision**: `decodeRichDisplay` accepts any non-null value of type `object` from a matching attachment's JSON, including a JSON array, rather than validating against the `RichDisplay` shape.
**Rationale**: `typeof parsed !== 'object'` is JavaScript's coarsest possible type check, but the cost of accepting an unrecognized shape is benign — the decoded value simply carries none of `content`, `popover`, or `toolCalls`, and every dependent field renders as absent, which is indistinguishable from "no extras." The source accepts this rather than adding a schema validator for a payload only its own encoder ever produces.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |

`separation-of-concerns` is passed: `toChatMessages.ts` and `richContent.ts` are framework-free, I/O-free pure functions over the chat contract's types, and `projection-one-directional` explicitly forbids calling any mutating `ChatViewModel` method — the read side and the write side never mix in this module. `unit-test-coverage` is failed: no test file in the `chat` package references `projectMessages`, `encodeRichDisplay`, `decodeRichDisplay`, `draftMessageID`, or `toToolCallInfo` — `RichContent.test.tsx` exercises the differently-named `components/RichContent.tsx` React component, not this projection module, and `useChatSession.test.ts` (the only caller) never touches these functions either. `explicit-error-handling` is passed: `decodeRichDisplay` explicitly catches a `JSON.parse` failure on a matching attachment and falls through to the next candidate rather than letting a malformed payload throw, per `rich-display-decode-fallthrough` and `rich-display-decode-non-throwing`. `fault-tolerance` is partial: decoding a malformed attachment is handled cleanly, but the open question on **duplicate-resolved-ids** means `projectMessages` performs no uniqueness check when a committed message's resolved id (`m.id ?? m.localID`) collides with another message's, leaving downstream id-keyed consumers with undefined behavior on that unpredictable-state case.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-09-24 | Mike Fullerton | Compliance section rewritten as linked checks against the compliance catalog |
| 1.0.2 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
