---
id: e5b8e26f-2869-4a09-8d8e-0bb68ece805d
title: Connector Registry
domain: adhsdk://recipes/connector-registry
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Registry for tracking and querying HTML element instances by unique identifier
  within a React application.
platforms:
- typescript
- web
tags:
- context-provider
- registry
- react
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Connector Registry

## Overview

The Connector Registry is a React context-based store for managing references to DOM elements within a component tree. It allows any descendant component to register and query element instances by string identifier, with automatic notification of subscribers when the registry changes. This enables coordination between components that need to discover or reference each other's elements at runtime without direct coupling. Its primary consumer is the three-pane chat mode, which uses the registered anchor elements to compute and draw the connector lines between panes without hard-coding references to the components that own those anchors.

## Behavioral Requirements

- **provide-context**: The registry MUST be established by a scoped provider that exposes it to descendant views in a subtree, so independent registries can coexist without global state. On the source platform this is `ConnectorRegistryProvider`, backed by React Context (see Platform Notes).
- **register-elements**: The registry MUST accept registration of a platform view handle (an `HTMLElement` on the source web platform) under a unique string identifier via a `register(id, element)` operation.
- **unregister-function**: `register()` MUST return a function that unregisters the element when called.
- **idempotent-reregister**: If an element is registered again under an id it already holds, with the identical element reference, `register()` MUST return a no-op unregister function and MUST NOT notify subscribers.
- **replace-on-conflict**: If an element is registered again under an id it already holds, but with a *different* element reference, the registry MUST replace the stored element and notify subscribers as an ordinary change.
- **update-registry-on-change**: Registering or unregistering an element MUST notify all active subscribers immediately (synchronously, before the call returns).
- **provide-snapshot**: The registry MUST provide a `snapshot()` operation that returns a current `RegistrySnapshot` object containing the full registry state.
- **stable-snapshot-identity**: `snapshot()` MUST return the same `RegistrySnapshot` object reference on repeated calls as long as no registration or unregistration has occurred in between, so a reactive binding (e.g. `useSyncExternalStore` on the source platform) can treat an unchanged snapshot as identical and skip re-rendering.
- **implement-subscription**: The registry MUST support subscription to changes via a `subscribe(listener)` operation, which MUST return an unsubscribe function.
- **expose-has-method**: A `RegistrySnapshot` MUST provide a `has(id)` method that returns a boolean indicating whether an id exists in the registry.
- **expose-get-method**: A `RegistrySnapshot` MUST provide a `get(id)` method that returns the registered element or `undefined` if the id is not present.
- **expose-ids-method**: A `RegistrySnapshot` MUST provide an `ids()` method that returns an array of all registered identifiers in the registry.
- **throw-without-provider**: Accessing the registry handle outside the scope of a provider MUST raise an error identifying the missing provider. On the source platform, `useConnectorRegistry()` throws (see Platform Notes).
- **provide-optional-hook**: The registry MUST also be accessible through an optional accessor that returns the registry handle when a provider is in scope and `null` otherwise, for call sites that must tolerate running without one. On the source platform this is `useConnectorRegistryOptional()`.
- **provide-snapshot-hook**: The registry MUST provide a reactive accessor that returns the current snapshot and automatically subscribes to updates, re-rendering/re-evaluating the consumer on registry changes; because it depends on the provider being in scope, it MUST also raise the same missing-provider error as **throw-without-provider**. On the source platform this is `useRegistrySnapshot()`, which composes `useConnectorRegistry()`.

## Appearance

Not applicable: This ingredient is a functional context provider with no visual representation.

## States

Not applicable: The registry is a stateful container but does not model user-facing states (default, pressed, etc.).

## Accessibility

Not applicable: The registry is a programmatic utility layer with no direct user interaction or accessible UI elements.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| registry-001 | provide-context, register-elements | Render `ConnectorRegistryProvider`; call `register("btn1", el)` with an `HTMLElement` | Element is stored in the registry under id `"btn1"` |
| registry-002 | unregister-function | Call `register("btn1", el)`; invoke the returned function | Element is removed from the registry; `snapshot().get("btn1")` returns `undefined` |
| registry-003 | idempotent-reregister | Call `register("btn1", el)`; call `register("btn1", el)` again with the same reference | Second call returns a function that performs no action when invoked; registry state and snapshot are unchanged; no notification occurs |
| registry-004 | replace-on-conflict | Call `register("btn1", elA)`; call `register("btn1", elB)` with a different element reference | `register` proceeds as an ordinary change (not a no-op); subscribers are notified; `snapshot().get("btn1")` returns `elB` |
| registry-005 | update-registry-on-change, implement-subscription | Subscribe a listener; call `register("btn1", el)`; invoke the returned unregister function | Listener is called exactly twice: once synchronously after `register`, once synchronously after unregister; an idempotent re-register or an already-stale unregister call adds zero further calls |
| registry-006 | provide-snapshot, expose-has-method, expose-get-method | Call `snapshot()` immediately after registering an element with id `"btn1"` | `snapshot.has("btn1")` returns `true`; `snapshot.get("btn1")` returns the element |
| registry-007 | stable-snapshot-identity | Call `snapshot()` twice with no `register`/`unregister` call in between | Both calls return the identical (`===`) `RegistrySnapshot` object |
| registry-008 | expose-ids-method | Register elements with ids `"btn1"` and `"btn2"`; call `snapshot().ids()` | Returns an array containing both `"btn1"` and `"btn2"` |
| registry-009 | throw-without-provider | Call `useConnectorRegistry()` in a component not wrapped by `ConnectorRegistryProvider` | Hook throws an error with a message containing `"ConnectorRegistryProvider"` |
| registry-010 | provide-optional-hook | Call `useConnectorRegistryOptional()` outside a provider; call it again inside one | First call returns `null`; second call returns the registry handle |
| registry-011 | provide-snapshot-hook, throw-without-provider | Call `useRegistrySnapshot()` outside a provider; then, inside a provider, render it, register an element, and unregister it | Outside a provider it throws the same error as `useConnectorRegistry()`; inside a provider it returns the current snapshot and the component re-renders once for the register and once for the unregister |
| registry-012 | provide-snapshot, expose-has-method, expose-get-method, expose-ids-method | Call `snapshot()` on a freshly mounted `ConnectorRegistryProvider` with no elements registered | `snapshot().ids()` returns `[]`; `snapshot().has(id)` returns `false` for any id; `snapshot().get(id)` returns `undefined` for any id |
| registry-013 | unregister-function, replace-on-conflict | Call `register("btn1", elA)` and keep its returned function `unregA`; call `register("btn1", elB)`; invoke `unregA` | `elB` remains registered; `snapshot().get("btn1")` still returns `elB`; `unregA` performs no action |
| registry-014 | implement-subscription, update-registry-on-change | Subscribe listener A, which unsubscribes listener B when called, then subscribe listener B; trigger a change via `register()` | Listener B is not called during this notification pass; a later change calls only listener A |

## Edge Cases

- **Empty registry**: An initial `snapshot().ids()` on a fresh provider MUST return an empty array; `has(id)` and `get(id)` MUST return false and undefined respectively.
- **Unregister with mismatched reference**: If `register("btn1", elA)` is called, then the returned function is stored and later invoked after `register("btn1", elB)` is called with a different element, the function MUST NOT unregister elB (it should only unregister if the current element still matches elA).
- **Subscribe after registry populated**: `subscribe()` only adds the listener to the internal set — it does not call the listener to sync current state. A subscriber added after elements are already registered is called only on subsequent `register()`/`unregister()` calls, never on subscription itself.
- **Unsubscribe during notification**: Listeners are iterated with `Set.forEach`. A listener that unsubscribes itself, or another listener, during a notification pass takes effect immediately: a target listener not yet called in the current pass is skipped for that pass, while a listener already called is unaffected.
- **Null/undefined id or element**: Excluded by the TypeScript signature (`register(id: string, el: HTMLElement)`); these values are not assignable and are not part of the runtime contract.

## Configuration

Not applicable: The registry is instantiated by the provider with no configuration options.

## Deep Linking

Not applicable: The registry is a programmatic utility with no URL-based navigation.

## Localization

Not applicable: The registry contains only HTML element references and id strings; no user-facing strings require localization.

## Accessibility Options

Not applicable: The registry is a functional utility layer with no response to platform accessibility display options.

## Feature Flags

Not applicable: The registry is a core utility component with no feature flag gating in the source.

## Analytics

Not applicable: The source code contains no analytics instrumentation or event emission.

## Privacy

Not applicable: The registry stores only references to DOM elements already present in the application; it does not collect, transmit, or retain personal data.

## Logging

Not applicable: The source code contains no logging statements or diagnostic output.

## Platform Notes

- **Source platform (web, React)**: Implemented in `packages/web/packages/chat/src/modes/three-pane/connectors/ConnectorRegistry.tsx`. `ConnectorRegistryProvider` scopes one registry instance per mounted subtree (a `useRef`-held `Map`/`Set`, via React Context), not a global singleton. `register()`, `snapshot()`, and `subscribe()` are exposed through the context value; `useConnectorRegistry()` reads it and throws when there is no provider, `useConnectorRegistryOptional()` returns `null` instead, and `useRegistrySnapshot()` wraps `useSyncExternalStore` around `subscribe`/`snapshot` for reactive re-rendering.
- **SwiftUI**: Model the registry as an `@Observable` class instantiated by whichever view owns the subtree (e.g. the three-pane container) and injected into descendants via `.environment(_:)` — one instance per owning subtree, not an app-wide singleton. `register`/`unregister` mutate an internal dictionary and the `@Observable` machinery notifies observing views automatically; `snapshot()` returns a lightweight read-only view over that state.
- **Compose**: Provide the registry through a `CompositionLocal` created per subtree (`compositionLocalOf`), backed by a class holding a `mutableStateMapOf<String, LayoutCoordinates>` (or similar) so Compose's snapshot state system drives recomposition automatically when entries change — no manual `SnapshotMutationPolicy` is needed.
- **AppKit / UIKit**: Give each owning view controller (e.g. the three-pane container) its own registry instance — not a singleton — using an `NSMapTable`/`Dictionary` for id-to-view storage and a delegate or closure-based listener list; pass the instance down to descendants that need it (e.g. via initializer injection) rather than reaching it through shared global state.
- **WinUI 3**: Give each owning control (e.g. the three-pane container) its own registry instance — not a static class — backed by a `Dictionary<string, UIElement>`; expose `Register(id, element)` returning an unregister action, `GetSnapshot()` returning a read-only snapshot, and an event (e.g. `RegistryChanged`) for subscriber notification; pass the instance down via constructor injection or an attached property scoped to the subtree.

## Design Decisions

**Decision**: `snapshot()` returns the same `RegistrySnapshot` object reference between changes, but that snapshot's `has()`/`get()` methods close over the live underlying `Map` rather than a frozen copy — only `ids()` is captured as a fixed array at the time the snapshot was built.
**Rationale**: A stable object reference lets `useSyncExternalStore`-style consumers treat an unchanged snapshot as identical (`===`) and skip re-rendering, while avoiding the cost of deep-copying the `Map` on every change; `ids()` is copied because callers commonly iterate or diff it.
**Approved**: pending

**Decision**: Re-registering the same id with the identical element reference is a no-op: `register()` returns an empty unregister function and does not notify subscribers.
**Rationale**: This prevents unnecessary subscriber notifications when a component re-registers itself on every render without its element having actually changed.
**Approved**: pending

**Decision**: Subscribers are notified synchronously, immediately after a state change, and the snapshot is rebuilt before any listener runs, so every listener in a given notification pass observes the same snapshot.
**Rationale**: Keeps consumers consistent with each other and with the change that triggered them, without introducing asynchronous scheduling.
**Approved**: pending

**Decision**: `useRegistrySnapshot()` is implemented with React's `useSyncExternalStore` rather than `useState`/`useEffect`.
**Rationale**: `useSyncExternalStore` is the API React provides for subscribing to state that lives outside React, and it guarantees hydration safety and tearing-free reads under concurrent rendering.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`separation-of-concerns` passes: `ConnectorRegistry.tsx` cleanly layers its concerns — the `RegistrySnapshot`/`RegistryHandle` types, the `ConnectorRegistryProvider` (owning the `Map`/listener `Set`/snapshot refs and the `register`/`snapshot`/`subscribe` methods), and three hooks that each add one thing on top (`useConnectorRegistry` requires a provider, `useConnectorRegistryOptional` tolerates its absence, and `useRegistrySnapshot` composes the required hook with `useSyncExternalStore`) — with no component doing double duty. `explicit-error-handling` passes: the one error path in the module, a missing provider, is handled deliberately rather than left to throw an unhelpful `null`-access error — `useConnectorRegistry` throws a descriptive `Error` naming `ConnectorRegistryProvider`, and `useConnectorRegistryOptional` exists specifically so call sites that cannot guarantee a provider get `null` instead of a thrown exception. `unit-test-coverage` fails: `ConnectorRegistry.test.tsx` contains exactly one test, and despite being named "registers and unregisters anchors by id" it never calls an unregister function — it only renders a provider with two anchors and asserts `snapshot().has(id)` for both. None of `idempotent-reregister`, `replace-on-conflict`, `update-registry-on-change`'s notification count, `stable-snapshot-identity`, `throw-without-provider`, `provide-optional-hook`, `provide-snapshot-hook`, or any Edge Case is exercised by an automated test — of the fourteen Conformance Test Vectors above, only a fragment of registry-001 is actually automated.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, added stable-snapshot-identity and replace-on-conflict requirements with test vectors, corrected the snapshot-immutability and subscribe-on-add claims, made requirements platform-neutral and moved hook names into Platform Notes, corrected the SwiftUI/Compose/AppKit/WinUI notes to match per-subtree scoping, reformatted Design Decisions, dropped the inapplicable Compliance section, tightened test-vector precision and added edge-case vectors, and expanded the Overview |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Restored a genuine Compliance section (separation-of-concerns/explicit-error-handling passed, unit-test-coverage failed: only one shallow test exists). |
