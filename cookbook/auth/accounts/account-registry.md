---
id: 98226063-be5d-4fa8-a980-02227df3418b
title: "Account Registry"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "AccountRegistry, the main-actor ordered list of Account objects an app offers, with idempotent add, no-op remove and a single change callback."
platforms:
  - swift
  - macos
  - ios
tags:
  - auth
  - accounts
  - model
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Account Registry

## Overview

`AccountRegistry` is the list of accounts an app offers, kept in display order. An accounts UI renders one entry per account in `accounts` and observes the registry through a single `onChange` closure. Each entry is an `Account`: a reference-type protocol (`AnyObject`) with a stable `id`. The registry is a plain `@MainActor` class in the Foundation-only SDK tier. It does no I/O and never calls an account's own methods. Its source comment says `add` and `remove` exist so the panel's plus and minus controls can be enabled later without touching `Account`.

## Behavioral Requirements

### Data shape

- **accounts-property**: The registry MUST expose `accounts` as a readable array of `any Account`, writable only from inside the registry (`public private(set)`).
- **accounts-order**: `accounts` MUST hold entries in the order they were supplied to the initializer, followed by entries in the order they were added.
- **identity-by-id**: The registry MUST treat two accounts as the same account when their `id` strings are equal. It MUST NOT compare object identity.
- **init-default-empty**: `init(accounts:)` MUST default `accounts` to an empty array.
- **init-stores-as-given**: `init(accounts:)` MUST store the supplied array unchanged, including any duplicate ids it contains.
- **init-silent**: `init(accounts:)` MUST NOT invoke `onChange`.

### Operations

- **add-appends**: `add(_:)` MUST append the account to the end of `accounts` when no existing entry has the same `id`.
- **add-notifies**: `add(_:)` MUST invoke `onChange` exactly once after appending.
- **add-idempotent**: `add(_:)` MUST leave `accounts` unchanged when an entry with the same `id` is already present, and MUST keep the existing entry rather than replace it.
- **add-duplicate-silent**: `add(_:)` MUST NOT invoke `onChange` when it ignores a duplicate.
- **remove-by-id**: `remove(id:)` MUST remove the first entry whose `id` equals the argument and preserve the order of the remaining entries.
- **remove-notifies**: `remove(id:)` MUST invoke `onChange` exactly once after removing.
- **remove-unknown-noop**: `remove(id:)` MUST leave `accounts` unchanged and MUST NOT invoke `onChange` when no entry has that `id`.
- **remove-no-teardown**: `remove(id:)` MUST NOT call `signOut()`, `restore()` or any other method on the removed account, and MUST NOT clear that account's `onChange`.
- **no-error-surface**: Neither operation MUST throw or return a value; both are declared without `throws` and return `Void`. A duplicate add and an unknown remove are reported to the caller only by the absence of an `onChange` call.

### Change notification

- **on-change-slot**: `onChange` MUST be a single closure slot of type `@MainActor () -> Void`, defaulting to an empty closure. Assigning it again replaces the earlier closure.
- **on-change-no-payload**: `onChange` MUST carry no arguments. Observers read `accounts` to learn what changed.
- **on-change-synchronous**: `onChange` MUST run synchronously inside `add` or `remove`, after `accounts` has been mutated, so the closure observes the new array.
- **on-change-scope**: `onChange` MUST fire only for membership changes made through `add` and `remove`. The registry MUST NOT forward the `onChange` of any contained `Account`; each account has its own slot.

### Concurrency

- **main-actor-isolation**: The class MUST be isolated to `@MainActor`, so every property access and call runs on the main actor and calls are serialised. The class declares no explicit `Sendable` conformance; its `@MainActor` isolation is what keeps it in its domain.
- **no-reentrancy-guard**: The registry has no guard against `onChange` calling `add` or `remove`. A nested call runs synchronously inside the outer one, and the outer call has already finished mutating by then.

### Persistence

- **no-persistence**: The registry MUST keep `accounts` in memory only. It reads and writes no files, keychain or defaults, and the list is rebuilt by the app on each launch.
- **retains-accounts**: The registry holds each account strongly, so a registered account lives at least as long as its entry.

## Appearance

Not applicable — this is a model that holds a list, not a visual component.

## States

Not applicable — this is a model that holds a list, not a visual component. The registry has no lifecycle state machine; its only state is the contents of `accounts`.

## Accessibility

Not applicable — this is a model that holds a list, not a visual component.

## Conformance Test Vectors

Vectors 001 to 005 are the cases asserted in `AccountRegistryTests` (`AccountsTests.swift`, suite "AccountRegistry"); the rest follow the source directly.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| account-registry-001 | accounts-order, init-silent | `AccountRegistry(accounts: [a, b])`, ids "a" and "b" (test "keeps accounts in the order given") | `accounts.map(\.id)` is `["a", "b"]` |
| account-registry-002 | add-appends, add-notifies, init-default-empty | Empty registry with a counting `onChange`; `add` account "a" (test "add appends and reports a change") | `accounts.map(\.id)` is `["a"]`; the count is 1 |
| account-registry-003 | add-idempotent, add-duplicate-silent | Registry holding "a"; counting `onChange`; `add` a second account with id "a" (test "add ignores an id already present and reports nothing") | `accounts.count` is 1; the count is 0 |
| account-registry-004 | remove-by-id, remove-notifies | Registry holding "a", "b"; counting `onChange`; `remove(id: "a")` (test "remove drops the account and reports a change") | `accounts.map(\.id)` is `["b"]`; the count is 1 |
| account-registry-005 | remove-unknown-noop | Registry holding "a"; counting `onChange`; `remove(id: "zzz")` (test "remove of an unknown id is a silent no-op") | `accounts.count` is 1; the count is 0 |
| account-registry-006 | add-idempotent | Registry holding object X with id "a"; `add` a different object Y with id "a" | `accounts` still holds X only |
| account-registry-007 | identity-by-id, add-appends | Registry holding "a"; `add` "b" then `add` "a" again | `accounts.map(\.id)` is `["a", "b"]`; `onChange` fired once |
| account-registry-008 | init-stores-as-given | `AccountRegistry(accounts: [a1, a2])` where both have id "a" | `accounts.count` is 2; `onChange` not called |
| account-registry-009 | remove-by-id | Initializer given two accounts with id "a" then `remove(id: "a")` | Only the first is removed; `accounts.count` is 1 |
| account-registry-010 | remove-no-teardown | Registry holding a stub that records `signOut()` calls; `remove` its id | The stub records zero `signOut()` calls |
| account-registry-011 | on-change-synchronous | `onChange` records `accounts.count`; `add` account "a" to an empty registry | The recorded count is 1 |
| account-registry-012 | on-change-slot | Assign closure A, then closure B; `add` a new account | Only B runs |
| account-registry-013 | on-change-scope | Registry holding account "a"; the account's own `onChange` fires (state change) | The registry's `onChange` is not called |

## Edge Cases

- **Duplicate id on add**: The call is ignored, the existing entry is kept and no change is reported. MUST (per `add-idempotent`).
- **Unknown id on remove**: The call is a no-op with no change reported. MUST (per `remove-unknown-noop`).
- **Empty string id**: The registry applies no validation, so `""` is an ordinary id. A second `add` with `""` is ignored as a duplicate. The `Account` protocol documents no id format.
- **Duplicates in the initializer**: The initializer does not de-duplicate, so both entries are kept. `remove(id:)` removes only the first match, and a second call removes the next. MUST (per `init-stores-as-given`).
- **Remove while observed**: A removed account keeps its own `onChange` slot, and its observer is not told. The accounts UI has to drop its observer itself. MUST NOT clear it from the registry.
- **Re-entrant onChange**: An `onChange` that calls `add` or `remove` runs the nested call immediately, which can invoke `onChange` again. The registry has no limit, so a closure that always adds a new account would not terminate. This is a caller concern.
- **Concurrent access**: Not applicable as a race. The class is `@MainActor`, so the compiler confines every call to the main actor and serialises it.
- **Boundary sizes**: An empty registry is valid. Nothing caps the entry count.
- **Error states and offline**: Not applicable. The registry performs no I/O, so there is no dependency to fail and no network state to lose.
- **Cancellation and timeouts**: Not applicable. Both operations are synchronous and finish before returning.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `accounts` (initializer argument) | `[any Account]` | `[]` | The initial accounts, in display order. |
| `onChange` | `@MainActor () -> Void` | empty closure | Observer assigned after construction; fires after a successful `add` or `remove`. |

The registry reads no environment variables or settings keys. Each `Account` is injected by the caller.

## Deep Linking

Not applicable: the registry is an in-memory model and registers no URL or route (`AccountRegistry` has no URL handling).

## Localization

Not applicable: the registry holds and emits no user-facing strings; display text lives on each `Account` (`displayName`, `summary`, `message`).

## Accessibility Options

Not applicable: the registry is a model with no visual or motion behavior, so it responds to no display option.

## Feature Flags

Not applicable: `AccountRegistry` reads no flag or setting.

## Analytics

Not applicable: `AccountRegistry` records no events.

## Privacy

Not applicable: the registry stores only references to caller-supplied `Account` objects in memory. It reads and transmits nothing itself, and any credential an account holds stays inside that account.

## Logging

Not applicable: `AccountRegistry` makes no log calls, and a duplicate add or unknown remove is silent by design.

## Platform Notes

- **SwiftUI**: The source platform. `AccountRegistry` is a non-observable class, so a SwiftUI view would wrap it in an `ObservableObject` or `@Observable` adapter and set `onChange` to publish a change. Because `onChange` is a single slot, only one adapter can observe at a time.
- **Compose**: Use a `MutableStateFlow` of `List<Account>` in a `ViewModel`. Implement `add` as an update that appends when no `id` matches, and `remove` as removal of the first match. Flow collection replaces the single callback, and `StateFlow` equality already suppresses duplicate emissions.
- **React/Web**: Keep an array in a store, or `useReducer`, with `add` and `remove` actions that return the same array when nothing changes, so a re-render is skipped. Subscribers replace the single `onChange` slot. JavaScript is single-threaded, so no extra serialisation is needed.
- **AppKit / UIKit**: The source's consumer is `AccountsSettingsPanelViewController` on macOS, which sets `onChange` to rebuild its per-account panels. The source file is `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Accounts/AccountRegistry.swift`, in a Foundation-only tier that imports neither AppKit nor UIKit. Tests are in `AccountsTests.swift`, written with Swift Testing and `@MainActor`.
- **WinUI 3**: Port as a C# class on the UI thread, with `ObservableCollection<IAccount>` holding the entries so a bound `ListView` updates by itself. `ObservableCollection` raises `CollectionChanged` instead of a single `onChange`; keep an `Action` property if the one-slot contract must hold. `Add` checks `Any(a => a.Id == account.Id)` before `Add`, and `Remove(string id)` finds the first match with `FirstOrDefault` and calls `Remove`. Marshal calls through `DispatcherQueue.TryEnqueue`, which stands in for `@MainActor`. Define `IAccount` as an interface with `INotifyPropertyChanged` for state. There is no persistence, so no `Windows.Storage` use is needed.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Accounts/AccountRegistry.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: `add` ignores a duplicate `id` silently instead of throwing or replacing the entry.
**Rationale**: The source comment calls this idempotency. Repeated registration by app setup code is harmless, and the existing account object keeps its live state and observer.
**Approved**: pending

**Decision**: Accounts are matched by `id` string, not object identity.
**Rationale**: `remove(id:)` takes a string, so a caller needs no reference to the account. `add` uses the same key to stay consistent.
**Approved**: pending

**Decision**: `onChange` is a single closure slot with no payload, not a list of observers.
**Rationale**: The accounts panel is the one observer, matching the single-slot design of `Account.onChange`. A later assignment replaces the earlier observer, and the observer re-reads `accounts`.
**Approved**: pending

**Decision**: `remove` does not sign the account out or release its observer.
**Rationale**: The registry only lists accounts. Teardown belongs to the account and its UI. The source comment says add and remove exist so plus and minus can be enabled later without touching `Account`, and the registry has no teardown hook.
**Approved**: pending

**Decision**: The initializer accepts duplicate ids without de-duplicating.
**Rationale**: Only `add` has the idempotency guard in source. The initializer assigns the array directly. A port keeps this difference rather than tightening it, so existing app setup behaves the same.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | performance |

The registry does one job, holding an ordered list, and leaves sign-in, rendering and storage to `Account` and the UI (separation-of-concerns). The unit tests in `AccountsTests.swift` cover order, add, duplicate add, remove and unknown remove, but not the initializer duplicates or re-entrant `onChange`, so coverage is partial (unit-test-coverage). A duplicate add is idempotent by design (idempotent-operations). Neither operation does blocking work, so the main actor is not held (main-thread-freedom). Error handling is partial: duplicate and unknown ids are deliberate silent no-ops that the caller cannot tell from success except through `onChange`, and nothing is logged.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
