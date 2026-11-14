---
id: a7cbe25c-53d1-4aec-b76e-59b1c0876728
title: "CRUD Permissions"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Data model for CRUD capability permissions (create, read, update, delete) with defaults and parent-clamping."
platforms:
  - typescript
  - web
tags:
  - permissions
  - access-control
  - crud
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# CRUD Permissions

## Overview

The Crud data model represents four independent permission capabilities: create, read, update, and delete. It is used across the platform wherever permission sets are managed — application→schema grants, bucket access grants, and other access-control contexts. The model provides three core capabilities: definition via independent boolean flags, defaults for the most-restrictive and read-only access patterns, and a parent-clamping utility to ensure child permissions never exceed a parent's permissions.

## Behavioral Requirements

- **export-interface**: The Crud interface MUST export four boolean properties: `create`, `read`, `update`, `delete`, each representing an independent permission capability.
- **provide-key-list**: An exported constant `CRUD_KEYS` MUST be an ordered array of the four capability names in the order: `["create", "read", "update", "delete"]`.
- **exported-key-type**: `CRUD_KEYS` MUST be declared as a readonly tuple (via `as const`), and an exported `CrudKey` union type MUST be derived from it (`"create" | "read" | "update" | "delete"`); `CRUD_LETTER` MUST be keyed by `CrudKey`.
- **provide-letter-mapping**: An exported `CRUD_LETTER` object MUST map each key to its canonical single-letter representation: `create` → `"C"`, `read` → `"R"`, `update` → `"U"`, `delete` → `"D"`.
- **provide-no-access-default**: A `noAccess()` function MUST return a Crud instance with all four properties set to `false`.
- **provide-read-only-default**: A `readOnly()` function MUST return a Crud instance with `read` set to `true` and all other properties set to `false`.
- **not-mutate-inputs**: `clampToParent()` MUST NOT mutate either of its input objects; the `child` and `parent` arguments MUST retain their original property values after the call.
- **fresh-instance-per-call**: `noAccess()` and `readOnly()` MUST return a newly created object on each call; two separate calls MUST NOT return the same object reference.
- **clamp-child-to-parent**: A `clampToParent(child: Crud, parent: Crud)` function MUST return a new Crud instance where each capability is the logical AND of the child and parent values: if either the child or parent denies a capability, the result MUST deny it.

## Appearance

Not applicable: Crud is a data model with no visual representation.

## States

Not applicable: Crud is a data model representing static permission flags, not an interactive component with state transitions.

## Accessibility

Not applicable: Crud is a data model with no user-facing interface.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| crud-001 | export-interface | Compile-time type check: `expectTypeOf<Crud>().toEqualTypeOf<{ create: boolean; read: boolean; update: boolean; delete: boolean }>()` | Assertion compiles without a type error |
| crud-002 | provide-key-list | Access CRUD_KEYS constant | Array equals `["create", "read", "update", "delete"]` in that order |
| crud-003 | exported-key-type | Compile-time type check: `expectTypeOf<CrudKey>().toEqualTypeOf<"create" \| "read" \| "update" \| "delete">()` | Assertion compiles without a type error |
| crud-004 | provide-letter-mapping | Access CRUD_LETTER["create"], CRUD_LETTER["read"], CRUD_LETTER["update"], CRUD_LETTER["delete"] | Returns `"C"`, `"R"`, `"U"`, `"D"` respectively |
| crud-005 | provide-no-access-default | Call noAccess() | Returns `{ create: false, read: false, update: false, delete: false }` |
| crud-006 | provide-read-only-default | Call readOnly() | Returns `{ create: false, read: true, update: false, delete: false }` |
| crud-007 | clamp-child-to-parent | Call clampToParent({ create: true, read: true, update: false, delete: false }, { create: true, read: false, update: true, delete: true }) | Returns `{ create: true, read: false, update: false, delete: false }` |
| crud-008 | clamp-child-to-parent | Call clampToParent({ create: false, read: false, update: false, delete: false }, { create: true, read: true, update: true, delete: true }) | Returns `{ create: false, read: false, update: false, delete: false }` |
| crud-009 | clamp-child-to-parent | Call clampToParent({ create: true, read: true, update: true, delete: true }, noAccess()) | Returns `{ create: false, read: false, update: false, delete: false }` |
| crud-010 | clamp-child-to-parent | Call clampToParent(x, x) where x = `{ create: true, read: false, update: true, delete: false }` | Returns an object equal in value to `x` |
| crud-011 | clamp-child-to-parent | Call clampToParent({ create: true, read: true, update: true, delete: true }, readOnly()) | Returns `{ create: false, read: true, update: false, delete: false }` |
| crud-012 | not-mutate-inputs | Call clampToParent(child, parent) with fixed `child`/`parent` objects, then re-read both after the call | `child` and `parent` are unchanged from their original values |
| crud-013 | fresh-instance-per-call | Call noAccess() twice and compare the two results with `===` | Comparison is `false` — the two calls return different object references |

## Edge Cases

- **Null or undefined input**: The interface defines the shape but does not validate input at runtime. Callers MUST ensure they pass valid Crud objects; functions do not perform null checking or type validation.
- **All capabilities true**: When all four properties are `true`, the object represents full access. This state is valid and supported.
- **All capabilities false**: The `noAccess()` function produces this state intentionally as the most-restrictive default. It is valid.
- **Clamping identity (child equals parent)**: When the child and parent are identical, `clampToParent()` MUST return an equivalent object (all values AND'd with themselves) equal in value to the input. See crud-010.
- **Asymmetric parent restrictions**: The parent may restrict any subset of capabilities independently. For example, a parent may allow create and read but deny update and delete, and the clamping function MUST correctly AND each capability. See crud-011.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| create | boolean | false | Whether the create capability is allowed. Set independently of other capabilities. |
| read | boolean | false | Whether the read capability is allowed. Set independently of other capabilities. |
| update | boolean | false | Whether the update capability is allowed. Set independently of other capabilities. |
| delete | boolean | false | Whether the delete capability is allowed. Set independently of other capabilities. |

`Crud` is a plain interface with no constructor, so these "Default" values are not applied automatically. They describe the object `noAccess()` returns (all `false`) and, for `read`, the object `readOnly()` returns (`read: true`). A caller building a `Crud` object by hand must set every field explicitly.

## Deep Linking

Not applicable: Crud is a data model with no user-facing navigation.

## Localization

Not fully inert: `CRUD_LETTER` exports the single-letter labels `"C"`, `"R"`, `"U"`, `"D"` as hardcoded English identifiers with no localization lookup. These values MUST be treated as internal identifiers, not user-facing text — a caller MUST NOT display `CRUD_LETTER`'s values directly to end users without localizing them first, and SHOULD instead expose its own localizable label keyed by `CrudKey`.

## Accessibility Options

Not applicable: Crud is a data model with no user-facing interface.

## Feature Flags

Not applicable: Crud is a foundational data model used by permission UIs across the platform; its availability is not feature-flagged.

## Analytics

Not applicable: Crud is a data model and does not emit events itself. Analytics for permission changes occur at the UI layer that uses this model.

## Privacy

Not applicable: Crud is a data model representing access permissions, not a data collection mechanism. It does not store, transmit, or retain user data.

## Logging

Not applicable: Crud is a data model with no runtime behavior to log.

## Platform Notes

- **Source**: Crud is a TypeScript interface and set of pure functions defined in `packages/web/packages/ui/src/components/crud.tsx` — that is where the code currently lives, not a claim that a data model belongs in a components directory. It is a plain data model with no view-layer dependency. Callers import `Crud`, `CrudKey`, `CRUD_KEYS`, `CRUD_LETTER`, `noAccess()`, `readOnly()`, and `clampToParent()` directly; its current consumers are the schema-grant UI and the bucket-grant UI.
- **SwiftUI**: Not yet implemented in the native Apple packages. Because Crud has no view-layer behavior, a Swift `struct Crud: Equatable, Sendable { var create, read, update, delete: Bool }` with `static let noAccess`, `static let readOnly`, and `static func clampToParent(_ child: Crud, _ parent: Crud) -> Crud` would provide equivalent semantics for direct use in SwiftUI view models.
- **Compose**: Not yet implemented for Android. A Kotlin `data class Crud(val create: Boolean, val read: Boolean, val update: Boolean, val delete: Boolean)` with companion object functions `Crud.noAccess()`, `Crud.readOnly()`, and `Crud.clampToParent(child, parent)` would provide equivalent semantics.
- **AppKit / UIKit**: Same target as SwiftUI above — Crud has no view-layer dependency, so AppKit and UIKit callers use the same Swift `Crud` struct and its `noAccess`, `readOnly`, and `clampToParent` members directly.
- **WinUI 3**: Not yet implemented for Windows. A C# `readonly struct Crud { public bool Create { get; init; } public bool Read { get; init; } public bool Update { get; init; } public bool Delete { get; init; } }` with static methods `Crud.NoAccess()`, `Crud.ReadOnly()`, and `Crud.ClampToParent(Crud child, Crud parent)` would provide equivalent semantics, following C# naming conventions (PascalCase for types and public members).
- **Shared pattern**: Across all platforms, the four capabilities MUST be independent booleans (not an enum or bitflags type), to ensure each capability can be toggled independently and the parent-clamping logic (AND per-capability) is unambiguous.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/crud.tsx` | unverified |

## Design Decisions

**Decision**: Represent permission state as four independent booleans, not a bitmask or enum.
**Rationale**: Four separate boolean properties make each capability explicitly named and independently readable, settable, and reasoned about, avoiding bit-shifting or mask operations. This keeps the permission model immediately readable and debuggable for a model used across many features.
**Approved**: pending

**Decision**: Default `noAccess()` to deny-all; provide `readOnly()` as a convenience default for read-only access.
**Rationale**: This follows the principle of least privilege — a newly constructed or reset permission should assume no access until explicitly granted. `readOnly()` reduces boilerplate for the common read-only pattern.
**Approved**: pending

**Decision**: `clampToParent()` combines child and parent capabilities with logical AND, and returns a new object without mutating either input.
**Rationale**: ANDing each capability preserves the permission hierarchy — a child's grant can never be more permissive than its parent allows — and returning a fresh, unmutated object keeps the function safe to call with shared or cached `Crud` instances.
**Approved**: pending

**Decision**: The interface and its functions perform no runtime validation of input shape or boolean-ness.
**Rationale**: Validation is left to the caller and to TypeScript's static type checking, keeping the model lightweight enough for use in strict TypeScript contexts where the compiler already guarantees well-formed input.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Status rests on `crud.tsx` hardcoding the literal English letters `"C"`, `"R"`, `"U"`, and `"D"` in `CRUD_LETTER` with no localization lookup; the source itself never renders these values, so whether a caller displays them to end users untranslated is outside what this file can confirm. `separation-of-concerns` passes because `crud.tsx` is a pure logic module — capability booleans, defaults, and the parent-clamping rule — with no rendering of any kind; `unit-test-coverage` passes because `crud.test.ts` directly exercises `CRUD_KEYS`/`CRUD_LETTER` agreement, `noAccess`, `readOnly`, and `clampToParent` with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and added exported-key-type/not-mutate-inputs/fresh-instance-per-call requirements with vectors, made crud-001 a compile-time assertion and added clamping-identity/readOnly-as-input vectors, reformatted Design Decisions into Decision/Rationale/Approved blocks and removed the unsourced memory-footprint and "all web applications" claims, replaced the Compliance row with a sourced Internationalization check, retitled to "CRUD Permissions", clarified the Configuration defaults and Localization framing, gave concrete per-platform types in Platform Notes, and fixed the frontmatter `modified` quoting. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web source `packages/web/packages/ui/src/components/crud.tsx`. |
