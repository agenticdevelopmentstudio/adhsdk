---
id: 07fab18a-2390-4899-b4ee-a273abc3a3eb
title: "Persisted State"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A state value that starts at a default, hydrates once from JSON in local storage under a key, and writes every change back, with caller-supplied decode and encode."
platforms:
  - typescript
  - web
tags:
  - persistence
  - local-storage
  - state
  - hooks
depends-on: []
related:
  - 3f2ae6c1-bc07-40ab-b15c-bb4b8c77986b
  - dcfe8ed6-2129-44ea-a084-eb30b640c0e3
  - f97631a6-531f-45c9-98a9-c5a292a2e6ea
references: []
approved-by: ""
approved-date: ""
---

# Persisted State

## Overview

Persisted State is a state value that survives a reload. It takes a storage `key`, an `initial` value, a `decode` function and an optional `encode` function, and returns a pair: the current value and a setter shaped like the platform's ordinary state setter (it accepts either a value or an updater function). The value is stored as JSON in the browser's local storage under `key`.

The state starts at `initial` on the first render and reads storage afterwards, in an effect, so the first paint matches what a server render would produce. In this spec "first render" means the first presentation of the value, and "effect" means work that runs after that first presentation; a port maps both onto its own view lifecycle. It reads storage once per key. `decode` turns the parsed JSON back into the value type and returns `undefined` for anything it does not recognise, such as a value written by an older build or edited by hand, which keeps the default instead of producing a shape the view never expected. `encode` turns the value into JSON-safe data before it is written; it defaults to the identity.

The module also exports `decodeBoolean`, a decoder that accepts only a boolean.

Its callers are the dashboard's gear settings. The source-filter state ([adhsdk.ingredient.status.dashboard.state.source-filter](cookbook:3f2ae6c1-bc07-40ab-b15c-bb4b8c77986b)) stores each pane's selected sources as an array under a per-pane key, and the overview tab stores its canceled-deploys flag, its in-progress-or-failed flag and its stats time span. The doc comment names two siblings with the same shape: the environment filter ([adhsdk.ingredient.status.dashboard.state.env-filter](cookbook:dcfe8ed6-2129-44ea-a084-eb30b640c0e3)) and the activity age-out ([adhsdk.ingredient.status.dashboard.state.activity-ttl](cookbook:f97631a6-531f-45c9-98a9-c5a292a2e6ea)).

## Behavioral Requirements

### Public operations

- **signature**: The state MUST take a string `key`, an `initial` value, a `decode` function from an unknown value to the value type or `undefined`, and an optional `encode` function from the value type to a JSON-serialisable value, and MUST return a two-element pair: the value and a setter.
- **encode-default**: When `encode` is omitted, the state MUST write the value itself as the JSON to store (the identity).
- **setter-shape**: The setter MUST accept either a next value or a function from the previous value to the next value, with the same meaning as the platform's ordinary state setter.
- **boolean-decoder**: The exported `decodeBoolean` MUST return its input when it is a boolean and `undefined` for every other input, including the strings `"true"` and `"false"`, numbers and `null`.

### Initial state and hydration

- **initial-first-render**: On the first render of a mount, the value MUST equal `initial`, regardless of what storage holds, so the first paint matches a render with no storage.
- **hydrate-after-render**: The state MUST read storage after the first render, not during it, so server rendering and first paint agree.
- **hydrate-once-per-key**: The state MUST read storage once per mount and again only when `key` changes.
- **hydrate-decoded**: When storage holds a string under `key`, the state MUST parse it as JSON, pass the parsed value to `decode`, and when `decode` returns anything other than `undefined`, set the value to the result.
- **hydrate-missing-key**: When storage holds no entry under `key`, the state MUST keep its current value.
- **hydrate-unrecognised**: When `decode` returns `undefined`, the state MUST keep its current value.
- **hydrate-bad-json**: When the stored string is not valid JSON, the state MUST keep its current value and MUST NOT throw.
- **hydrate-storage-unavailable**: When reading storage throws (storage blocked or absent), the state MUST keep its current value and MUST NOT throw.
- **hydrate-decode-throws**: When `decode` throws, the state MUST keep its current value and MUST NOT throw, because the read, parse and decode run inside one guarded block.
- **hydrate-no-write**: Hydration MUST NOT write to storage; an entry is written only by the setter.
- **decode-read-once**: The state MUST use the `decode` supplied on the render in which hydration runs and MUST NOT re-hydrate when a caller passes a new inline function on a later render; the source's comment gives the reason: re-hydration would "clobber the reader's choice."

### Setting

- **set-updates-value**: The setter MUST update the in-memory value to the next value (or to the updater's result).
- **set-persists**: The setter MUST write `JSON.stringify` of `encode(next)` to storage under `key` each time it applies a value.
- **set-functional-update**: When given a function, the setter MUST pass it the latest previous value, so several updates in one batch compose instead of overwriting each other.
- **set-persists-same-value**: The setter MUST write to storage even when the next value equals the previous one; it does no equality check.
- **set-write-failure**: When writing storage throws (quota exceeded, storage blocked, or `encode` or `JSON.stringify` throwing), the setter MUST ignore the failure, MUST still apply the in-memory value, and MUST NOT throw; the source comment says "the in-memory choice still applies."
- **set-updater-throws**: When a caller's updater function throws, the state MUST NOT catch the exception, because the updater runs outside the guarded block; the host state machinery decides where it surfaces.
- **set-write-in-updater**: The storage write MUST happen inside the state update function, so it runs once for each application of that update; the environment MAY apply an update more than once for the same input, and each application writes the same string.
- **set-key-bound**: The setter MUST write to the `key` of the render that produced it; its identity MUST stay stable across renders while `key` is unchanged, and MUST change when `key` changes.
- **set-encode-captured**: The setter MUST use the `encode` supplied on the render that created it and MUST NOT pick up a new `encode` from later renders while `key` is unchanged.

### Key changes

- **key-change-rehydrates**: When `key` changes, the state MUST read storage again under the new key and apply the hydration rules.
- **key-change-keeps-value**: When `key` changes to a key with no usable stored value, the state MAY keep the value it held under the old key rather than reset to `initial`; the source keeps it, and no current caller changes its key, so a port may choose either.

### Ordering, concurrency and scope

- **single-threaded**: All updates MUST apply in the order issued, on the single execution thread.
- **per-instance-state**: Each use MUST hold its own in-memory value; two uses of the same `key` do not observe each other's changes until one of them re-reads storage (a remount or a key change).
- **no-cross-tab-sync**: The state MUST NOT subscribe to storage change events; a write in another tab does not change the value.
- **no-network**: The state MUST NOT make network requests, log, or start timers.
- **client-only**: The state MUST touch storage only on the client; it reads storage only in an effect, which never runs during a server render, so the state can be rendered on the server at `initial`.

## Appearance

Not applicable — this is a state hook, not a visual component.

## States

Not applicable — this is a state hook, not a visual component.

## Accessibility

Not applicable — this is a state hook, not a visual component.

## Conformance Test Vectors

Vectors 001–003 are the assertions in `use-persisted-state.dom.test.tsx` (the third drives it through the source-filter state); the rest are derived from the source. Run in a browser-like environment with clean storage before each case.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pstate-001 | set-persists, hydrate-decoded, boolean-decoder | test "restores a value set in an earlier mount": mount with key `k`, initial `false`, `decodeBoolean`; set `true`; unmount; mount again with the same arguments | the second mount's value is `true` |
| pstate-002 | hydrate-unrecognised, boolean-decoder | test "keeps the default for a stored value the decoder doesn't recognise": storage holds `"yes"` (JSON string) under `k`; mount with initial `false` and `decodeBoolean` | value stays `false` |
| pstate-003 | set-key-bound, set-persists, hydrate-decoded | test "persists each pane's source filter under its own key": toggle `glitchtip` off through the source filter under key `src-activity`, remount | `src-activity` no longer has `glitchtip` selected, and `src-problems` still has it |
| pstate-004 | hydrate-missing-key, initial-first-render | storage empty; mount with initial `7` | value is `7`, and storage is still empty after mount |
| pstate-005 | hydrate-bad-json | storage holds the text `{oops` under `k`; mount with initial `false` | value is `false`, no exception |
| pstate-006 | hydrate-storage-unavailable | the storage read throws; mount with initial `false` | value is `false`, no exception |
| pstate-007 | set-functional-update | mount with initial `0`; in one batch call the setter with `p => p + 1` twice | value is `2` and storage holds `2` |
| pstate-008 | set-write-failure | the storage write throws; mount with initial `false`; call the setter with `true` | value is `true`, no exception |
| pstate-009 | encode-default, set-persists | mount with initial `false` and no `encode`; set `true` | storage holds the text `true` |
| pstate-010 | set-persists, hydrate-decoded | mount with `encode` mapping a set to an array and a `decode` mapping an array back to a set; set the set `{a, b}`; remount | storage holds `["a","b"]` and the second mount's value is a set containing `a` and `b` |
| pstate-011 | boolean-decoder | `decodeBoolean` called with `true`, `false`, `"true"`, `1`, `null` | `true`, `false`, `undefined`, `undefined`, `undefined` |
| pstate-012 | key-change-rehydrates, key-change-keeps-value | mount with key `a` and value set to `true`; re-render with key `b` that has no stored entry | value is `true` in the source, which keeps the old key's value (a port MAY reset instead); with a stored `false` under `b` it becomes `false` |
| pstate-013 | decode-read-once | mount with an inline `decode`; re-render several times with a new inline `decode` and the same `key` | storage is read once and the value is unchanged by the re-renders |
| pstate-014 | hydrate-decode-throws | `decode` throws on the stored value; mount | value stays at `initial`, no exception |
| pstate-015 | set-persists-same-value | mount with initial `false`; storage is cleared; call the setter with `false` | storage holds the text `false` after the call, even though the value did not change |
| pstate-016 | set-encode-captured | mount with an inline `encode` that wraps the value in an array; re-render with the same `key` and an `encode` that wraps it in an object; call the setter with `1` | storage holds the text `[1]`, from the `encode` of the render that created the setter |
| pstate-017 | set-key-bound | mount with key `a`; capture the setter; re-render with key `a`, then with key `b`; call the captured setter and the current setter | the setter's identity is the same across the re-render with key `a` and different after the change to `b`; the captured setter writes to `a` |
| pstate-018 | set-updater-throws | mount with initial `0`; call the setter with an updater that throws | the exception is not caught by the state, no write happens for that call (the throw unmounts the hook's tree, so there is no value left to read) |
| pstate-019 | hydrate-once-per-key | mount with key `k`, re-render three times with the same key, then change the key to `j` | storage is read once for `k` and once more for `j`, and not on the re-renders |
| pstate-020 | hydrate-no-write | storage holds `true` under `k`; mount with `decodeBoolean` and initial `false` | the value becomes `true`, and no write call is made to storage during hydration |
| pstate-021 | per-instance-state | two mounts with the same key; call one setter with `true` | the other mount's value stays `false`; storage holds `true` |
| pstate-022 | no-cross-tab-sync | mount with key `k`; dispatch a storage change event for `k` with a new value | the value does not change |
## Edge Cases

- **Null and empty input**: a stored `null` MUST be passed to `decode`; the default `decodeBoolean` returns `undefined` for it and the value stays at its default. An empty stored string is invalid JSON and MUST keep the value, per hydrate-bad-json.
- **Boundary — missing and unrecognised data**: no entry, a value from an older build and a hand-edited value MUST all leave the value unchanged; the caller's `decode` is the only validation, so a `decode` that returns a wrongly shaped value is accepted as given.
- **Boundary — first write after a rejected hydration**: the first setter call writes over whatever unusable entry was in storage.
- **Boundary — key change**: a new key with no usable entry keeps the previous key's value in memory, and the next write goes to the new key, so the old key's value is carried across.
- **Concurrent access — same key, two uses**: two mounted uses of one key hold separate values and each write overwrites the last; the later write wins in storage and neither use sees the other until it re-reads. Another tab writing the same key is not observed.
- **Concurrent access — repeated update application**: when the environment applies an update function twice for the same input, the storage write runs twice with the same string; the result is the same.
- **Error states — storage blocked or full**: reads and writes MUST fail silently; the value still changes in memory and is lost on reload. No error is surfaced to the caller or logged.
- **Error states — caller's updater throws**: the state does not catch it, because the updater runs outside the guarded block, and no write happens for that call.
- **Error states — unserialisable value**: `JSON.stringify` of a value `encode` leaves unserialisable (a circular object, a `BigInt`) throws inside the guarded write and is ignored; the value is kept in memory only. An encoded value of `undefined` makes `JSON.stringify` return `undefined`, which local storage stores as the text `undefined`; that text is not valid JSON, so the next hydration keeps the default.
- **Offline or disconnected state**: not applicable — the state reads and writes only the browser's local storage and has no network dependency.
- **Cancellation and timeouts**: not applicable — every operation is synchronous.
- **Server rendering**: storage is read only inside an effect, so a server render never touches storage and always renders `initial`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `key` | string | none — required | The local-storage key; each setting owns its own key (the dashboard caller's keys are examples only: `adh-status-show-canceled`, `adh-status-in-progress-or-failed-only` and `adh-status-stats-span`; a host chooses its own prefix, and the source filter takes its key from its caller). |
| `initial` | value of the state's type | none — required | The value before hydration and whenever storage yields nothing usable. |
| `decode` | function from an unknown value to the value or `undefined` | none — required | Turns parsed JSON into the value; `undefined` means "not recognised, keep the default." |
| `encode` | function from the value to JSON-serialisable data | identity | Turns the value into what is written; needed when the value has no JSON form of its own (a set, an object holding a derived field). |

The state reads no environment variables or settings keys beyond these arguments, and its only injected dependency is the browser's local storage, resolved as a global at the time of each read or write.

## Deep Linking

Not applicable: the state reads and writes local storage and registers no route or URL.

## Localization

Not applicable: the state produces no user-facing text; it moves values between memory and storage.

## Accessibility Options

Not applicable: the state has no visual output and responds to no display setting.

## Feature Flags

Not applicable: the state reads no flag and branches on no configuration; it is the storage layer behind some of the dashboard's gear settings.

## Analytics

Not applicable: the state emits no events.

## Privacy

- **Data collected**: the values callers choose to persist; the dashboard's callers store reader preferences only (a boolean flag, a time-span key, a list of selected source names).
- **Storage**: browser local storage under the caller's key, as JSON text, unencrypted and readable by any script on the same origin.
- **Transmission**: none; the data never leaves the browser through this module.
- **Retention**: until the browser's storage is cleared or the same key is overwritten; the module never deletes or expires an entry.

## Logging

Not applicable: the state never logs; a failed read or write is ignored silently.

## Platform Notes

- **SwiftUI**: Start from `@AppStorage` for a plain boolean, string or integer, which reads `UserDefaults` synchronously and needs no hydration step. For a value that needs a custom decode (a set, a validated enum) write a small property wrapper or an `@Observable` model that reads `UserDefaults.standard.data(forKey:)` in `init`, decodes with `JSONDecoder` inside a `do`/`catch` that keeps the default, and writes with `JSONEncoder` in `didSet`. The first-paint concern disappears because the read is synchronous. Unlike local storage, `UserDefaults` does not throw on write.
- **Compose**: Start from Jetpack DataStore Preferences or `SharedPreferences`. Expose a `StateFlow` from a `ViewModel` that collects `dataStore.data`, maps the stored string through a decode function returning null for unrecognised input, and writes in `dataStore.edit` from `viewModelScope.launch`. DataStore is asynchronous, so render the default first and update when the first emission arrives, which matches the source's hydrate-after-render order. Catch `IOException` and `SerializationException` and keep the default.
- **React/Web**: Source platform. `packages/web/packages/status-web/src/hooks/use-persisted-state.ts` holds the hook and `decodeBoolean`; `use-persisted-state.dom.test.tsx` beside it is the jsdom suite behind vectors 001–003. It begins with the `"use client"` directive. Callers are `use-source-filter.ts` (a set stored as an array) and `OverviewTab.tsx` (two booleans and a time-span key). The hook uses `useState`, a `useEffect` keyed on the storage key for hydration, and a `useCallback` setter; the source disables two lint rules there on purpose (`set-state-in-effect`, because hydration is a one-shot external-store sync, and `exhaustive-deps`, so `decode` and `encode` are not dependencies). Specific to the web platform: local storage is synchronous, throws when blocked (private modes, quota), and is shared by every tab of an origin without notifying a React state; React's strict mode may call an updater twice in development, which is why the write inside the updater is safe only because it is idempotent.
- **AppKit / UIKit**: Use `UserDefaults` with `Codable` values and a small wrapper class owned by the view model; set the default before the view loads. Observe `UserDefaults.didChangeNotification` only if cross-window sync is wanted, since the source does not.
- **WinUI 3**: Start from `Windows.Storage.ApplicationData.Current.LocalSettings.Values` (packaged apps) or a JSON file under `ApplicationData.Current.LocalFolder` read with `System.Text.Json` for larger values. Implement a generic `PersistedState<T> : INotifyPropertyChanged` holding the value, a `Func<JsonElement, T?> Decode` and `Func<T, object?> Encode`; read once in its constructor inside `try`/`catch (JsonException)`, keep the default when the decoder returns null, and in the `Value` setter write `JsonSerializer.Serialize(Encode(value))` inside `try`/`catch` and raise `PropertyChanged`. `LocalSettings` is synchronous for small values but limited (strings up to 4 KB per value), so a set stored as an array may need a file instead. Bind the property in XAML with `x:Bind Mode=TwoWay`. Unlike the browser, writes from other app instances are not observed unless you add a file watcher.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-web/src/hooks/use-persisted-state.ts` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Start at `initial` and hydrate from storage in an effect, not during the first render.
**Rationale**: The source's doc comment: it "starts at `initial` on first render and hydrates from storage in an effect, so SSR/first-paint match." Reading storage during render would produce different markup on the server and the client.
**Approved**: pending

**Decision**: The caller supplies `decode`, and it returns `undefined` for anything it does not recognise.
**Rationale**: Doc comment: a value "written by an older build, or hand-edited" must "keep the default rather than rendering a shape the view never expected." The module cannot know the value's shape, so validation belongs to the caller.
**Approved**: pending

**Decision**: `decode` and `encode` are read once and are not dependencies of the hydration effect or the setter.
**Rationale**: Source comment: "a caller passing an inline function must not re-hydrate (and clobber the reader's choice) on every render." The cost is that a later change to `decode` or `encode` is ignored until the key changes.
**Approved**: pending

**Decision**: Storage failures are ignored silently on both read and write.
**Rationale**: Source comments: "localStorage unavailable / bad JSON — keep the default" and "ignore persistence failure — the in-memory choice still applies." A preference that cannot be saved must not break the page. The consequence is that nothing tells the reader or a developer the setting will not survive a reload.
**Approved**: pending

**Decision**: The storage write happens inside the state update function.
**Rationale**: It gives the write access to the resolved next value, including when the caller passes an updater. The write is idempotent, so a repeated application of the update is harmless; the trade-off is a side effect inside what is normally a pure function.
**Approved**: pending

**Decision**: A key change keeps the value held under the old key when the new key has nothing usable.
**Rationale**: Hydration returns early on a missing entry and never resets to `initial`. All current callers use a fixed key per mount, so the behavior is not exercised; a port that supports changing keys should decide whether to reset.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.privacy-and-data.secure-data-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9d865cfa-ff98-5b90-b5da-58a611d3535b) | partial | privacy-and-data |

**Separation of Concerns**: The hook knows nothing about what it stores. Shape validation lives in the caller's `decode`, serialisation in `encode`, and the meaning of each setting in the source-filter state and the overview tab.

**Unit Test Coverage**: `use-persisted-state.dom.test.tsx` has one passing test for each of the 22 conformance vectors, including the bad-JSON, blocked-storage, write-failure, functional-update, key-change and decode-once paths.

**Explicit Error Handling**: Every failure on read and write is caught and ignored by design, with a comment on each; none is surfaced or logged, so a setting that cannot be saved looks identical to one that can. That is deliberate and documented, but not explicit to the caller.

**Graceful Degradation**: With storage blocked or corrupt the hook keeps working in memory at the default, so the dashboard's gear settings still function for the session.

**Secure Data Storage**: Values are written as plain JSON to origin-shared local storage with no encryption. That is acceptable for the reader preferences the dashboard stores, and nothing in the module stops a future caller from persisting sensitive data.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (use-persisted-state.dom.test.tsx, 22 of 22 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Added tags, rewrote single-threaded and client-only, fixed the decodeBoolean requirement name, lowered key-change-keeps-value to MAY, marked config keys as examples, defined first render and effect for ports, and added vectors pstate-015 to pstate-022. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from `use-persisted-state.ts` |
