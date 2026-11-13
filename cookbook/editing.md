---
id: 72243a76-93f2-412b-985d-719511fcd19c
title: "Content Editing"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A generic, type-checked record-editing container: draft/dirty tracking, field validation, layout coverage, a repair pass and nested unsaved-changes guarding."
platforms:
  - typescript
  - web
tags:
  - forms
  - validation
  - editing
  - state
  - logic
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Content Editing

## Overview

`EditingContainer` (`@adh-sdk/editing`) is the one way this platform edits a
record. It is a `"use client"` React container with no visual identity of its
own: it owns a draft copy of a caller-supplied `TRecord`, computes whether the
draft differs from what was loaded, validates it field by field against
caller-declared `FieldDescriptor`s, checks that the caller's `sections` lay
out every declared field exactly once, and renders the shared `FieldGroup`
and `BoundField` controls plus a `ButtonBar` Save/Cancel row from
`@adh-sdk/ui`. Draft and dirty bookkeeping is delegated to
`useDirtyDraft` (`@adh-sdk/ui/hooks/useDirtyDraft`); an
injected `EditingHost` supplies the platform's `UnsavedChangesGuard` and a
one-button `AlertModal`. Containers nest — a row editor inside a page editor
— with each descendant's dirtiness rolling up through `EditingScope` to a
single guard published by the outermost container. A "repair pass" runs once
per loaded record: a field whose stored value fails its own `validate` rule
but which also declares a paired `repair` function is corrected up front and
confirmed with a non-dismissible acknowledgement before the pane is usable,
rather than leaving Save permanently disabled with nothing on screen to fix.
Compile-time generics (`FieldsFor`, `SectionsCheck`, an invariant phantom on
`FieldDescriptor`) reject a large class of misuse before the pane ever
renders; the bound controls that render inside a container are not exported
from the package at all, so there is no import path that produces a wired
control outside one.

## Behavioral Requirements

### Type-level contract (compile-time)

- **field-key-membership**: The `fields` prop MUST be typed so that every key
  corresponds to a property of `TRecord`; a key absent from `TRecord` maps to
  `NotAField<TKey>`, which no `FieldDescriptor` satisfies, so declaring a
  field that does not exist on the record MUST fail to compile
  (`container.tsx` `FieldsFor`; `type-enforcement.tsx` `misspelledFieldName`).
- **descriptor-value-type-match**: A field descriptor's value type MUST match
  the corresponding record property's type invariantly, via the `__value`
  phantom on `FieldDescriptor`; assigning `checkbox()` to a `string` field or
  `text()` to a `boolean` field MUST fail to compile (`descriptors.ts`
  `FieldDescriptor.__value`; `type-enforcement.tsx`
  `wrongControlForTheValueType`, `textControlOnABooleanField`).
- **select-options-match-union-exactly**: A `select()` field's `options` MUST
  cover the record property's literal union exactly; an option value the
  field's type cannot hold, or a field value with no matching option, MUST
  each fail to compile, because `select`'s value type parameter is invariant
  with the field it is assigned to (`descriptors.ts` `select`;
  `type-enforcement.tsx` `selectOfferingAValueTheFieldCannotHold`,
  `selectMissingOneOfTheFieldsValues`).
- **validate-requires-repair**: A field descriptor MUST declare `validate`
  and `repair` together, or declare neither; the `Validation` discriminated
  union rejects a `validate` supplied without a matching `repair`
  (`descriptors.ts` `Validation`; `type-enforcement.tsx`
  `validateWithoutRepair`).
- **repair-context-must-be-supplied**: A field descriptor whose `validate`
  or `repair` reads a `TContext` MUST NOT be assignable to a container whose
  `context` prop does not supply a compatible shape; `TContext` is
  contravariant on the descriptor by construction (`descriptors.ts` module
  docblock; `type-enforcement.tsx` `contextNeededButNotSupplied`,
  `contextOfTheWrongShape`).
- **sections-cover-fields-exactly**: The `sections` prop's declared field
  keys MUST equal the `fields` prop's keys exactly at compile time;
  `SectionsCheck` MUST produce an error object naming `__missingFields` for a
  declared field no section lays out, and `__unknownFields` for a section key
  not among the declared fields (`sections.ts` `SectionsCheck`;
  `type-enforcement.tsx` `aFieldNoSectionLaysOut`,
  `aSectionNamingAFieldThatDoesNotExist`, `aDangerZoneThatForgetsAField`).
- **onsave-receives-the-record**: `onSave` (and `onRepair` when supplied)
  MUST be typed to accept the exact `TRecord` the container edits; a handler
  typed for an unrelated shape MUST fail to compile (`container.tsx`
  `EditingContainerProps.onSave`; `type-enforcement.tsx`
  `onSaveExpectingADifferentRecord`).
- **bound-controls-unreachable-outside-container**: `BoundField` and the
  primitives it wires (`controls.tsx`) MUST NOT be exported from either
  package entry point (`index.ts`, `server.ts`); there MUST be no import
  path producing a value/`onChange`-wired control outside an
  `EditingContainer` (`controls.tsx` module docblock; `package.json`
  `comment:exports`).

### Draft state and Save eligibility

- **draft-seeded-from-record**: On mount, the container's editable draft and
  baseline MUST both be initialized from the `record` prop
  (`container.tsx` `useDirtyDraft<TRecord>(record)`).
- **dirty-computed-by-structural-equality**: `dirty` MUST be true exactly
  when at least one key of the draft differs from the baseline under a
  comparison that treats arrays and plain object literals by deep content
  equality and every other value (scalars, `Date`, `Map`, `RegExp`, class
  instances) by `Object.is` identity, so a setter that hands back a
  structurally-identical-but-new array or object reference MUST NOT mark the
  draft dirty (`useDirtyDraft.ts` `sameValue`, `dirty` memo; consumed by
  `container.tsx`).
- **save-enablement-rule**: `canSave` MUST be true exactly when `dirty` is
  true AND `validateValues` for the current draft returns no field errors
  AND the optional form-level `validate` prop, when supplied, returns `null`
  for the current draft (`container.tsx` `canSave`).
- **required-field-blocks-save**: A field whose descriptor sets
  `required: true` and whose current value is empty (per `isEmptyValue`)
  MUST report `"Required."` and MUST block Save, independent of any
  `validate` result (`validation.ts` `fieldError`, `REQUIRED_MESSAGE`).
- **empty-optional-value-skips-validation**: A non-required field's
  `validate` function MUST NOT be invoked when the field's current value is
  empty; an empty value on such a field MUST be treated as valid
  (`validation.ts` `fieldError`; `validation.test.ts` "does not run a format
  rule against an empty optional value").
- **select-value-off-the-option-list-is-an-error**: A `select` field holding
  a non-empty value that is not `Object.is`-equal to any of its declared
  `options[].value` MUST report `"<value>" is not one of the available
  choices."` even when the field declares no `validate`, so a retired option
  still stored on a row is surfaced rather than silently accepted
  (`validation.ts` `fieldError`, `unlistedChoiceMessage`; `validation.test.ts`
  "reports the stored value instead of passing it as valid").
- **validation-error-precedence**: When a field is both required-and-empty
  and would also fail `validate`, the required message MUST take precedence
  and `validate` MUST NOT run; when a `select` value is both required-and-
  empty and off its option list, the required message MUST also take
  precedence over the unlisted-choice message (`validation.ts` `fieldError`
  order; `validation.test.ts` "reports a required field left blank before it
  reports anything else", "still asks for a required select before
  complaining about the list").
- **validate-receives-context**: A non-empty field's `validate(value,
  context)` MUST be invoked with the exact `context` prop passed to the
  container (`validation.ts` `fieldError`; `validation.test.ts` "runs the
  field's own rule on a non-empty value, with the container's context").
- **form-level-validate-blocks-save**: When the container's own `validate`
  prop returns a non-null message for the current draft, Save MUST be
  blocked and the message MUST be rendered above the Save bar, independent
  of every individual field's own validity (`container.tsx` `formError`,
  `canSave`; `container.test.tsx` "is blocked by a cross-field rule, with
  the reason on the pane").
- **save-blocked-while-in-flight**: While `onSave` is in flight (`saving`),
  or while `canSave` is false, invoking Save again MUST be a no-op and MUST
  NOT invoke `onSave` a second time (`container.tsx` `handleSave` guard
  `if (!canSave || saving) return`; `container.test.tsx` "cannot be pressed
  twice while a write is in flight").

### Layout coverage checked at runtime

- **duplicate-field-layout-detected-at-runtime**: The container MUST detect,
  at render time, every field key that appears in more than one section
  (including twice within a single section) and MUST report each such key
  once, in first-seen order — `"These fields are laid out in more than one
  section: <keys>."` — even when `sections` loses its literal `const`
  inference (built dynamically, widened through a `let`) and the compile-time
  `SectionsCheck` cannot see it (`sections.ts` `duplicatedKeys`;
  `container.tsx` `layoutFaults`; `container.test.tsx` "reports a field laid
  out twice"; `sections.test.ts` "reports a thrice-listed key once", "catches
  a key repeated inside a single section").
- **unlaid-field-detected-at-runtime**: The container MUST report, at render
  time, every declared field key no section's `keys` include —
  `"These fields are declared but no section lays them out: <keys>."`
  (`container.tsx` `layoutFaults`; `container.test.tsx` "reports a field no
  section lays out").
- **unknown-section-field-detected-at-runtime**: The container MUST report,
  at render time, every section key naming a field not present in `fields`
  — `Section "<title>" lays out unknown field "<key>".` (`container.tsx`
  `layoutFaults`; `container.test.tsx` "reports a section naming a field
  that does not exist").
- **layout-faults-logged-and-rendered**: Each layout fault MUST be logged via
  `console.error` prefixed `[@adh-sdk/editing]` and rendered
  in a `role="alert"` block above the sections; rendering MUST continue
  rather than throwing (`container.tsx` `layoutFaults` effect + JSX;
  `container.test.tsx` "says nothing about a layout that covers every field
  exactly once" as the negative case).

### Saving

- **save-invokes-handler-with-full-draft**: Activating Save MUST call
  `onSave` with the entire current draft record (`container.tsx`
  `handleSave`; `container.test.tsx` "hands the whole edited record to
  onSave and goes quiet once it lands").
- **save-commits-baseline-on-success**: On `onSave` resolving without
  throwing, the container MUST adopt the saved values as the new baseline
  (clearing `dirty` and any prior save error) via `adopt`
  (`container.tsx` `handleSave`; `container.test.tsx` "hands the whole
  edited record to onSave and goes quiet once it lands").
- **save-failure-preserves-draft-and-shows-reason**: If `onSave` rejects, the
  container MUST leave the draft and dirty state untouched and MUST render
  the rejection's message — an `Error`'s `.message`, a string as itself, or
  `"Unknown error."` for anything else — in a `role="alert"` element
  (`container.tsx` `handleSave` catch, `messageOf`; `container.test.tsx`
  "keeps the draft and shows the reason when the write is refused").

### Cancel

- **cancel-discards-draft**: Activating Cancel, when there is no declined
  refetch pending, MUST reset the draft to the current baseline and clear
  any save error (`container.tsx` `handleCancel`; `container.test.tsx`
  "throws the draft away and tells the pane it is done").
- **cancel-adopts-a-declined-refetch**: If a new `record` identity arrived
  while the draft was dirty and was declined (see re-seeding below), Cancel
  MUST adopt that declined record as the new baseline instead of resetting
  to the original baseline (`container.tsx` `handleCancel`;
  `container.test.tsx` "is picked up by Cancel, which is when it stops
  being a threat").
- **cancel-invokes-oncancel**: After discarding the draft, Cancel MUST call
  the optional `onCancel` callback exactly once, if supplied
  (`container.tsx` `handleCancel`).
- **cancel-rearms-the-repair-inspection**: Cancel MUST clear the repair
  pass's "already inspected" marker and advance its inspection epoch, so a
  baseline restored by Cancel that still fails its own validation
  re-triggers the repair prompt rather than leaving Save permanently
  disabled with the prompt already spent (`container.tsx` `handleCancel`,
  `inspectedRef`/`inspectionEpoch`; `repair-flow.test.tsx` "asks again
  rather than leaving the pane sitting on data it rejects").
- **cancel-availability**: The Cancel action MUST be offered whenever the
  draft is dirty, or whenever an `onCancel` callback was supplied (so a
  clean pane with somewhere to return to can still be dismissed)
  (`container.tsx` `ButtonBar` `actions.canCancel`).

### Re-seeding on a new record identity

- **clean-draft-adopts-new-record**: When the `record` prop's identity
  changes while the draft is clean, the container MUST adopt the new record
  as both draft and baseline (`container.tsx` re-seeding effect;
  `container.test.tsx` "is adopted while the draft is clean").
- **dirty-draft-declines-new-record**: When the `record` prop's identity
  changes while the draft is dirty, the container MUST NOT overwrite the
  draft; it MUST retain the incoming record for Cancel to use, and MUST
  still advance its internal notion of the last-seen record identity so a
  later clean render does not silently adopt a now-stale intermediate value
  (`container.tsx` re-seeding effect, `seededRef`/`declinedRef`;
  `container.test.tsx` "does not overwrite what the user has typed").
- **declined-record-cleared-once-superseded**: Once a save or any other
  adoption has run, a previously declined record MUST NOT be re-adopted
  afterward (`container.tsx` `adopt` clears `declinedRef.current = null`;
  `container.test.tsx` "is not adopted AFTER the save that superseded it").

### The repair pass

- **repair-plan-computed-once-per-baseline**: For a non-read-only container,
  the container MUST compute a repair plan (`planRepairs(baseline, fields,
  context)`) exactly once for each distinct baseline identity, not once per
  render (`container.tsx` `inspectedRef` effect; `repair-flow.test.tsx`
  "prompts once, not once per render").
- **repair-plan-defines-broken**: A field counts as broken in the repair
  plan when it declares a `repair` function, its loaded value is non-empty,
  and `fieldError` for that value is non-null (`repair.ts` `planRepairs`;
  `repair.test.ts` "repairs the stored value that made Save unreachable").
- **repair-skips-empty-values**: `planRepairs` MUST NOT attempt to repair a
  field whose loaded value is empty, even when the field declares
  `validate`/`repair`, since repairing "" would invent a value never entered
  (`repair.ts` `planRepairs`; `repair.test.ts` "never repairs an empty value
  into an invented one").
- **repair-skips-required-empty-fields**: A `required` field left empty MUST
  NOT be treated as broken by the repair pass — there is nothing to derive
  the missing value from, and it stays a visible field error the user must
  fill in themselves (`descriptors.ts` `RequirableFieldOptions.required`;
  `repair.test.ts` "ignores a required field left blank — that is the
  user's to fill in").
- **repair-plan-no-op-preserves-identity**: When no field is broken, the
  repair plan's `repaired` record MUST be the same reference as the input
  record (`changed: false`), so an unchanged plan can be distinguished from
  one that altered every field's reference (`repair.ts` `planRepairs`;
  `repair.test.ts` "finds nothing to do for a record every rule already
  accepts", "leaves the input untouched").
- **repair-prompt-blocks-editing**: When the plan has at least one broken
  field and no unrepaired field, the container MUST show a non-dismissible,
  single-button "Repair required" acknowledgement (description "This data
  needs some repair and will be saved.") and MUST NOT invoke `onSave` or
  `onRepair` until the user confirms (`container.tsx` `repairAlert`
  "prompt" case; `host.tsx` `EditingAlertProps.dismissible`;
  `repair-flow.test.tsx` "asks first, repairs, confirms, and leaves a pane
  that works", "does not write when Escape is pressed on the prompt",
  "offers no ✕ on the prompt, so there is no pointer dismissal either").
- **repair-confirm-writes-then-adopts**: Confirming the repair prompt MUST
  call `onRepair` (defaulting to `onSave`) with the repaired record; on
  success it MUST mark the repaired record already-inspected before adopting
  it as the new baseline, then show a dismissible "Repair succeeded"
  acknowledgement (`container.tsx` `applyRepair`; `repair-flow.test.tsx`
  "writes on the button, and the acknowledgement that follows IS
  dismissible").
- **repair-write-failure-keeps-draft-editable**: If the repair write
  rejects, the container MUST leave the baseline unchanged, MUST set the
  repaired values as the (now dirty, editable) draft via `patch`, and MUST
  show a dismissible "Repair failed" acknowledgement carrying the
  rejection's message (`container.tsx` `applyRepair` catch;
  `repair-flow.test.tsx` "keeps the repaired values in the draft when the
  write is refused").
- **unrepairable-value-blocks-write-entirely**: If any repaired field still
  fails its own `validate` after `repair` runs, the container MUST NOT call
  `onSave`/`onRepair` at all, MUST log
  `[@adh-sdk/editing] repair() left a value still invalid —
  <key>: <message>` via `console.error`, and MUST show a "Repair failed"
  acknowledgement naming every such field (`container.tsx` repair effect
  `plan.unrepaired.length > 0` branch; `repair.ts`
  `RepairPlan.unrepaired`; `repair-flow.test.tsx` "refuses to save a repair
  that produced another invalid value").
- **repair-uses-onrepair-when-distinct**: When `onRepair` is supplied
  separately from `onSave`, the repair write MUST call only `onRepair`,
  never `onSave` (`container.tsx` `onRepair = props.onRepair ?? onSave`;
  `repair-flow.test.tsx` "sends the repair write to onRepair when the
  caller separates the two").
- **repair-suppressed-in-read-only**: The repair-inspection effect MUST NOT
  run at all when the container is `readOnly` (`container.tsx`
  `if (readOnly) return`; `container.test.tsx` "offers no Save bar, arms no
  guard, and repairs nothing").
- **repair-acknowledgement-busy-lock**: While a confirmed repair write is in
  flight, its acknowledgement MUST render as busy with its confirm control
  disabled, so it cannot be confirmed a second time concurrently
  (`container.tsx` `repairAlert` "applying" case, `EditingAlertProps.busy`;
  `repair-flow.test.tsx` "cannot be acknowledged twice while the repairing
  write is running").

### Nesting and the navigation guard

- **dirty-rolls-up-to-parent-scope**: A container nested inside another
  (rendered via `children`) MUST report its own aggregate dirtiness (its own
  dirty state OR any of its own descendants') to the enclosing
  `EditingScope`, keyed by a stable per-instance id from `React.useId()`
  (`scope.tsx` `useDirtyRollup`; `nesting.test.tsx` "marks the enclosing
  container dirty even though its own fields are untouched").
- **exactly-one-guard-per-page**: Only the outermost container — the one
  with `parent === null`, i.e. `isRoot` — MUST render `host.
  UnsavedChangesGuard`; a nested container MUST NOT render its own
  (`container.tsx` `{isRoot && <host.UnsavedChangesGuard>}`;
  `nesting.test.tsx` "publishes exactly one navigation guard for the page").
- **guard-reflects-aggregate-not-own-dirty**: The root's guard MUST be armed
  (`when={aggregateDirty}`) when it or any descendant container is dirty,
  even when the root's own fields are untouched (`container.tsx`;
  `nesting.test.tsx` "arms the page guard from a row the outer pane knows
  nothing about").
- **child-saves-independently-of-parent**: A nested container's own Save
  MUST be enabled and invoked purely by its own `canSave`/`onSave`,
  independent of whether the enclosing container is dirty or savable; saving
  the child MUST NOT invoke the parent's `onSave` and MUST NOT by itself
  disarm the parent's guard while the parent's own fields remain dirty
  (`container.tsx`; `nesting.test.tsx` "keeps the two Save buttons
  independent", "saves the row on its own and disarms the page guard",
  "keeps the guard armed when the row is saved but the pane is not").
- **unmount-clears-child-report**: When a nested container unmounts, it
  MUST report `dirty: false` to its parent scope so a dismissed row does not
  leave the page permanently marked dirty (`scope.tsx` `useDirtyRollup`
  unmount effect; `nesting.test.tsx` "stops speaking for a row that is
  dismissed mid-edit", "keeps the guard armed when one of two rows is
  dismissed").
- **rollup-propagates-through-multiple-levels**: Dirtiness MUST roll up
  correctly through more than two levels of nested containers
  (`scope.tsx`; `nesting.test.tsx` "rolls dirtiness up through more than one
  level").
- **root-guard-renders-even-when-root-is-read-only**: A read-only root
  container MUST still render the navigation guard, with its own
  dirtiness contribution forced to `false`, so an editable descendant's
  unsaved work remains protected (`container.tsx` `useDirtyRollup(dirty &&
  !readOnly)`, comment above `isRoot && <host.UnsavedChangesGuard>`;
  `nesting.test.tsx` "still guards an editable row inside a read-only
  pane").

### Read-only containers

- **read-only-suppresses-save-bar-and-repair**: When `readOnly` is true, the
  container MUST NOT render the Save/Cancel bar, MUST force its own dirty
  contribution to `false`, and MUST NOT run repair inspection
  (`container.tsx` `readOnly` uses; `container.test.tsx` "offers no Save
  bar, arms no guard, and repairs nothing").
- **read-only-locks-every-control**: When `readOnly` is true, every bound
  control MUST render locked regardless of its own descriptor's `disabled`
  value, and MUST NOT accept input (`controls.tsx` `BoundField`
  `disabled = locked || descriptor.disabled`; `container.tsx`
  `locked={readOnly || saving}`; `container.test.tsx` "locks every
  control", "does not let a click through the lock").

### Bound controls

- **checkbox-control-shape**: A `checkbox` field MUST render as the checkbox
  control with its `label` text beside it inside one `<label>`, rather than
  through the caption-above-control `Field` wrapper used by other kinds, and
  MUST report its value as `value === true` (`controls.tsx` checkbox branch;
  `controls.test.tsx` "labels itself beside the box and toggles both ways",
  "reflects the stored value on the way in").
- **textarea-control-rows**: A `textarea` field MUST render with its
  descriptor's `rows` option applied to the underlying control
  (`controls.tsx` textarea branch; `controls.test.tsx` "renders as a
  textarea at the declared height and carries its value").
- **select-control-preserves-value-type**: Selecting an option in a
  `select` control MUST hand back that option's own `value` — its declared
  string or number type — never the DOM's string representation
  (`controls.tsx` select `onChange` mapping back through `options.find`;
  `controls.test.tsx` "gives back a number, not the DOM's string").
- **select-shows-unlisted-stored-value**: When the current value is not
  among a `select` field's declared `options`, the control MUST render an
  extra option holding exactly that value (label `"—"` only when the value
  is the empty string), so the browser's default of the first listed option
  never silently substitutes for a stored-but-retired value
  (`controls.tsx` select branch `unlisted`; `controls.test.tsx` "shows a
  stored value the options do not contain, instead of the first option").
- **select-adds-no-extra-option-when-listed**: When the current value IS
  among the declared options, the control MUST NOT render any extra option
  (`controls.tsx`; `controls.test.tsx` "adds no such option when the stored
  value IS on the list").
- **rdid-lowercases-on-input**: An `rdid` field MUST lowercase every
  keystroke as it is entered; a `text` field MUST NOT
  (`controls.tsx` `lowercase = descriptor.kind === "rdid"`;
  `controls.test.tsx` "lowercases as the user types, so the shift key is not
  a decision").
- **field-disabled-independent-of-siblings**: A field descriptor's own
  `disabled: true` MUST lock only that control, leaving sibling fields
  interactive (`controls.tsx` `shared.disabled`; `controls.test.tsx` "is
  disabled on its own, without locking the rest of the pane").
- **all-controls-locked-while-saving**: Every bound control in a container
  MUST be locked for the duration of an in-flight `onSave` call and MUST
  unlock once it settles (`container.tsx` `locked={readOnly || saving}`;
  `controls.test.tsx` "is locked while a save is in flight").
- **error-replaces-hint**: A field's error message, when present, MUST be
  shown in place of its `hint` rather than alongside it, and the control
  MUST carry `aria-invalid="true"` (`controls.tsx` `Field`/`FieldFootnote`
  usage, `aria-invalid={error ? true : undefined}`; `controls.test.tsx`
  "shows the error in place of the hint, and marks itself invalid").

### Descriptors and the server-safe entry point

- **descriptor-defaults**: A field descriptor's `required` and `disabled`
  MUST default to `false` when the caller does not supply them
  (`descriptors.ts` `common`).
- **no-numeric-control**: The package MUST NOT offer a numeric control kind;
  `ControlKind` is exactly `"text" | "textarea" | "rdid" | "checkbox" |
  "select"`, because a number input's in-progress editing state ("", "-",
  "1.") is a string the container's record-shaped draft model has no place
  for (`descriptors.ts` `ControlKind` docblock).
- **server-entry-has-no-react-dependency**: The `./server` export path MUST
  re-export only the plain-data halves — `checkbox`, `rdid`, `select`,
  `text`, `textarea`, `dangerZone`, `section`, and their types — and MUST
  import no React and no `"use client"` module, so it can be evaluated in a
  Server Component (`server.ts`; built as its own tsup chunk graph per
  `package.json` `comment:exports`).

### Execution context, persistence and side effects

- **single-threaded-execution**: The container performs no locking or actor
  isolation of its own; every file in the package (`container.tsx`,
  `controls.tsx`, `host.tsx`, `scope.tsx`) is marked `"use client"` and runs
  entirely on the browser's single JS thread through React's `useState`/
  `useEffect` scheduler, so overlapping user interactions are serialized by
  the event loop, not by this code.
- **no-own-persistence**: The container itself persists nothing; `draft` and
  `baseline` live in React state only and are discarded on unmount.
  Persisting the record is entirely the responsibility of the caller-
  supplied `onSave`/`onRepair` functions, which the container treats as
  opaque (no `fetch`, `localStorage`, `IndexedDB`, or similar API appears
  anywhere in `container.tsx`, `repair.ts`, `validation.ts`, `descriptors.ts`
  or `sections.ts`).
- **side-effects-limited-to-callbacks-and-two-log-sites**: The only side
  effects this package performs directly are the two documented
  `console.error` calls (layout faults; an unrepaired repair) and invoking
  the caller-supplied `onSave`, `onRepair`, and `onCancel` callbacks; it
  opens no network connection, file handle or process of its own
  (`container.tsx`).

## Appearance

Not applicable — this is a data-editing container with no visual identity of
its own; every visible element it produces (`FieldGroup`, `BoundField`,
`ButtonBar`, `AlertModal`) is a shared component from
`@adh-sdk/ui` with its own recipe.

## States

Not applicable — this is a logic container, not a visual component. Its
runtime state machines (draft/dirty, the repair pass's `prompt` /
`applying` / `succeeded` / `failed` phases, saving in flight) are specified
under Behavioral Requirements above, not as a visual-state table.

## Accessibility

Not applicable — this is a logic container with no rendered surface of its
own; the accessibility contract belongs to the shared controls it composes
(`FieldGroup`, `BoundField`'s underlying `Input`/`Textarea`/`Select`/
`Checkbox`, `ButtonBar`, `AlertModal`, `UnsavedChangesGuard`), each with its
own recipe. The one accessibility-relevant behavior this package itself adds
is `aria-invalid` toggling on a failing control, captured under
`error-replaces-hint` above.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| content-editing-001 | field-key-membership | `fields.displayNam` misspelled against `Team.displayName` | Fails to compile — `type-enforcement.tsx: misspelledFieldName` |
| content-editing-002 | descriptor-value-type-match | `checkbox()` assigned to `Team.displayName` (a string) | Fails to compile — `type-enforcement.tsx: wrongControlForTheValueType` |
| content-editing-003 | descriptor-value-type-match | `text()` assigned to `Team.archived` (a boolean) | Fails to compile — `type-enforcement.tsx: textControlOnABooleanField` |
| content-editing-004 | select-options-match-union-exactly | `select` options for `visibility` include `"unlisted"`, not in `Team["visibility"]` | Fails to compile — `type-enforcement.tsx: selectOfferingAValueTheFieldCannotHold` |
| content-editing-005 | select-options-match-union-exactly | `select` options for `visibility` omit `"public"`, a value the field can hold | Fails to compile — `type-enforcement.tsx: selectMissingOneOfTheFieldsValues` |
| content-editing-006 | validate-requires-repair | `rdid()` descriptor supplies `validate` with no `repair` | Fails to compile — `type-enforcement.tsx: validateWithoutRepair` |
| content-editing-007 | repair-context-must-be-supplied | A field's `repair` reads `context.orgSlug`; container's `context` prop omitted | Fails to compile — `type-enforcement.tsx: contextNeededButNotSupplied` |
| content-editing-008 | repair-context-must-be-supplied | Same field; container's `context` is `{ teamSlug }` instead of `{ orgSlug }` | Fails to compile — `type-enforcement.tsx: contextOfTheWrongShape` |
| content-editing-009 | sections-cover-fields-exactly | `fields` declares `archived`; `sections` lays out only `displayName` | Fails to compile — `type-enforcement.tsx: aFieldNoSectionLaysOut` |
| content-editing-010 | sections-cover-fields-exactly | `sections` lays out `identifier`, a key `fields` never declares | Fails to compile — `type-enforcement.tsx: aSectionNamingAFieldThatDoesNotExist` |
| content-editing-011 | sections-cover-fields-exactly | `dangerZone(["archived"])` is the only section; `displayName` is declared but uncovered | Fails to compile — `type-enforcement.tsx: aDangerZoneThatForgetsAField` |
| content-editing-012 | onsave-receives-the-record | `onSave` typed for `{ noteId: string }`, container edits `Team` | Fails to compile — `type-enforcement.tsx: onSaveExpectingADifferentRecord` |
| content-editing-013 | dirty-computed-by-structural-equality | Draft untouched, no `set`/`patch` called | `dirty === false` — `container.test.tsx: "is inert until something actually changes"` |
| content-editing-014 | dirty-computed-by-structural-equality | `set("displayName", "x")` then `set("displayName", <original value>)` | `dirty` goes `true` then back to `false` — `container.test.tsx: "lights up on the first edit and goes dark again when it is undone"` |
| content-editing-015 | required-field-blocks-save | `displayName` set to `""`, field is `required: true` | `canSave === false`; error shown is `"Required."` — `container.test.tsx: "names the empty required field rather than going dead in silence"` |
| content-editing-016 | empty-optional-value-skips-validation | Optional `rdid` field value `""`, `validate` would reject any string | `fieldError` returns `null` — `validation.test.ts: "does not run a format rule against an empty optional value"` |
| content-editing-017 | select-value-off-the-option-list-is-an-error | `fieldError(visibility, "retired", undefined)` where `"retired"` is not an option | Returns `'"retired" is not one of the available choices.'` — `validation.test.ts: "reports the stored value instead of passing it as valid"` |
| content-editing-018 | select-value-off-the-option-list-is-an-error | `fieldError(retries, "2", undefined)` where options are numeric `1`/`2` | Returns the unlisted-choice message (string `"2"` does not `Object.is`-match numeric `2`) — `validation.test.ts: "matches on the option's own value, not on the DOM's string of it"` |
| content-editing-019 | validation-error-precedence | Field `required: true`, value `"  "` (blank), `validate` also configured to fail | Returns `"Required."`, `validate` not invoked — `validation.test.ts: "reports a required field left blank before it reports anything else"` |
| content-editing-020 | form-level-validate-blocks-save | Every field individually valid; container's `validate` prop returns a message | `canSave === false`; message rendered above the Save bar — `container.test.tsx: "is blocked by a cross-field rule, with the reason on the pane"` |
| content-editing-021 | save-blocked-while-in-flight | Save clicked while a prior `onSave` promise is still pending | `onSave` invoked exactly once total — `container.test.tsx: "cannot be pressed twice while a write is in flight"` |
| content-editing-022 | save-invokes-handler-with-full-draft, save-commits-baseline-on-success | Draft edited, Save clicked, `onSave` resolves | `onSave` called with the whole draft record; `dirty` becomes `false` afterward — `container.test.tsx: "hands the whole edited record to onSave and goes quiet once it lands"` |
| content-editing-023 | save-failure-preserves-draft-and-shows-reason | Draft edited, Save clicked, `onSave` rejects with `new Error("no")` | Draft unchanged, `dirty` still `true`, `"no"` rendered in a `role="alert"` element — `container.test.tsx: "keeps the draft and shows the reason when the write is refused"` |
| content-editing-024 | cancel-discards-draft, cancel-invokes-oncancel | Draft edited (no declined refetch), Cancel clicked | Draft resets to baseline, `dirty === false`, `onCancel` called once — `container.test.tsx: "throws the draft away and tells the pane it is done"` |
| content-editing-025 | dirty-draft-declines-new-record | `record` prop identity changes while draft is dirty | Draft keeps the user's edits — `container.test.tsx: "does not overwrite what the user has typed"` |
| content-editing-026 | clean-draft-adopts-new-record | `record` prop identity changes while draft is clean | Draft and baseline both adopt the new record — `container.test.tsx: "is adopted while the draft is clean"` |
| content-editing-027 | declined-record-cleared-once-superseded | A record is declined while dirty; a save then commits a newer value | The declined (now-stale) record is not adopted afterward — `container.test.tsx: "is not adopted AFTER the save that superseded it"` |
| content-editing-028 | cancel-adopts-a-declined-refetch | A record is declined while dirty; Cancel is then clicked | The declined record becomes the new baseline, not the original one — `container.test.tsx: "is picked up by Cancel, which is when it stops being a threat"` |
| content-editing-029 | duplicate-field-layout-detected-at-runtime | `sections` lists `identifier` in two different sections | Fault `"These fields are laid out in more than one section: identifier."` logged and rendered — `container.test.tsx: "reports a field laid out twice"` |
| content-editing-030 | unlaid-field-detected-at-runtime | `fields` declares `archived`; no section's `keys` include it | Fault `"These fields are declared but no section lays them out: archived."` — `container.test.tsx: "reports a field no section lays out"` |
| content-editing-031 | unknown-section-field-detected-at-runtime | A section named `"Team"` lists key `"nickname"`, absent from `fields` | Fault `'Section "Team" lays out unknown field "nickname".'` — `container.test.tsx: "reports a section naming a field that does not exist"` |
| content-editing-032 | repair-plan-defines-broken, repair-plan-no-op-preserves-identity | `planRepairs` over a record every field already passes `validate` | `broken === []`, `repaired` is the same object reference as the input — `repair.test.ts: "finds nothing to do for a record every rule already accepts"`, `"leaves the input untouched"` |
| content-editing-033 | repair-plan-defines-broken | `planRepairs` over a record with one field failing `validate` and declaring `repair` | Field appears in `broken`; `repaired` carries the corrected value — `repair.test.ts: "repairs the stored value that made Save unreachable"`, `"repairs every broken field in one pass"` |
| content-editing-034 | repair-skips-empty-values | `planRepairs` over a record whose repairable field is `""` | Field is not treated as broken — `repair.test.ts: "never repairs an empty value into an invented one"` |
| content-editing-035 | repair-skips-required-empty-fields | `planRepairs` over a record whose `required` field is blank | Field is not treated as broken by the repair pass — `repair.test.ts: "ignores a required field left blank — that is the user's to fill in"` |
| content-editing-036 | unrepairable-value-blocks-write-entirely | `planRepairs` where `repair()` itself returns a value that still fails `validate` | Field appears in `unrepaired` as well as `broken` — `repair.test.ts: "reports a repair that produces another invalid value instead of accepting it"` |
| content-editing-037 | repair-prompt-blocks-editing, repair-confirm-writes-then-adopts | Container loads a record with one broken, repairable field; user confirms the prompt | "Repair required" shown first (not dismissible); confirming calls `onRepair`/`onSave` with the repaired record and the pane becomes usable — `repair-flow.test.tsx: "asks first, repairs, confirms, and leaves a pane that works"` |
| content-editing-038 | repair-prompt-blocks-editing | Repair prompt open; user presses Escape | No write occurs — `repair-flow.test.tsx: "does not write when Escape is pressed on the prompt"` |
| content-editing-039 | repair-prompt-blocks-editing | Repair prompt open | No dismiss ("✕") control is offered — `repair-flow.test.tsx: "offers no ✕ on the prompt, so there is no pointer dismissal either"` |
| content-editing-040 | repair-plan-computed-once-per-baseline | Container re-renders repeatedly with the same baseline | `planRepairs` runs (and the prompt appears) only once — `repair-flow.test.tsx: "prompts once, not once per render"` |
| content-editing-041 | repair-acknowledgement-busy-lock | Repair prompt confirmed; `onRepair` promise still pending | Acknowledgement is busy and cannot be confirmed again — `repair-flow.test.tsx: "cannot be acknowledged twice while the repairing write is running"` |
| content-editing-042 | repair-write-failure-keeps-draft-editable | Repair confirmed; `onRepair` rejects | Draft holds the repaired (now dirty) values; baseline unchanged; "Repair failed" shown with the rejection's message — `repair-flow.test.tsx: "keeps the repaired values in the draft when the write is refused"` |
| content-editing-043 | unrepairable-value-blocks-write-entirely | Loaded record's repair function itself produces an invalid value | `onSave`/`onRepair` never called; "Repair failed" names the still-invalid field — `repair-flow.test.tsx: "refuses to save a repair that produced another invalid value"` |
| content-editing-044 | repair-uses-onrepair-when-distinct | Container supplies both `onSave` and a distinct `onRepair`; repair prompt confirmed | Only `onRepair` is called — `repair-flow.test.tsx: "sends the repair write to onRepair when the caller separates the two"` |
| content-editing-045 | cancel-rearms-the-repair-inspection | Repair-required baseline restored via Cancel | Repair prompt reappears rather than leaving the pane silently unsaveable — `repair-flow.test.tsx: "asks again rather than leaving the pane sitting on data it rejects"` |
| content-editing-046 | repair-suppressed-in-read-only, read-only-suppresses-save-bar-and-repair | Container rendered with `readOnly: true` over a record that would otherwise trigger repair | No Save bar, no guard, no repair prompt — `container.test.tsx: "offers no Save bar, arms no guard, and repairs nothing"` |
| content-editing-047 | read-only-locks-every-control | Container rendered with `readOnly: true` | Every control is locked and unclickable — `container.test.tsx: "locks every control"`, `"does not let a click through the lock"` |
| content-editing-048 | exactly-one-guard-per-page | Container with one nested child container, both dirty | Exactly one `UnsavedChangesGuard` instance is rendered — `nesting.test.tsx: "publishes exactly one navigation guard for the page"` |
| content-editing-049 | guard-reflects-aggregate-not-own-dirty | Root container's own fields untouched; nested child is dirty | Root's guard is armed — `nesting.test.tsx: "arms the page guard from a row the outer pane knows nothing about"` |
| content-editing-050 | child-saves-independently-of-parent | Nested child container saved on its own | Child's `dirty` clears and its contribution to the parent's guard drops, while the parent's own dirtiness (if any) remains — `nesting.test.tsx: "saves the row on its own and disarms the page guard"`, `"keeps the guard armed when the row is saved but the pane is not"` |
| content-editing-051 | unmount-clears-child-report | A dirty nested child unmounts | Parent's aggregate dirtiness drops if no other descendant is dirty — `nesting.test.tsx: "stops speaking for a row that is dismissed mid-edit"` |
| content-editing-052 | root-guard-renders-even-when-root-is-read-only | Root container `readOnly: true`, editable child container dirty | Guard is still rendered and armed by the child's dirtiness — `nesting.test.tsx: "still guards an editable row inside a read-only pane"` |
| content-editing-053 | select-control-preserves-value-type | User picks the option whose `value` is numeric `2` | `onChange` receives the number `2`, not the string `"2"` — `controls.test.tsx: "gives back a number, not the DOM's string"` |
| content-editing-054 | select-shows-unlisted-stored-value | Field value is `"retired"`, not among the rendered options | An extra `<option value="retired">retired</option>` is rendered — `controls.test.tsx: "shows a stored value the options do not contain, instead of the first option"` |
| content-editing-055 | rdid-lowercases-on-input | User types `"ADH.Team"` into an `rdid` control | Reported value is `"adh.team"` — `controls.test.tsx: "lowercases as the user types, so the shift key is not a decision"` |
| content-editing-056 | field-disabled-independent-of-siblings | One field descriptor sets `disabled: true`; sibling fields do not | Only the disabled field is locked — `controls.test.tsx: "is disabled on its own, without locking the rest of the pane"` |
| content-editing-057 | error-replaces-hint | Field has both a `hint` and a validation `error` | Only the error text renders, with `aria-invalid="true"` — `controls.test.tsx: "shows the error in place of the hint, and marks itself invalid"` |
| content-editing-058 | root-guard-renders-even-when-root-is-read-only | (transport) Guarded page's `beforeunload`/in-app-link interception | Prompt raised on close/navigate while dirty, cleared on save/cancel/unmount — `guard.test.tsx: "raises the platform's one unsaved-changes prompt"`, `"is clear once the work is saved"`, `"is clear once the edit is cancelled"`, `"is clear once the pane unmounts mid-edit"` |

## Edge Cases

- **Null/empty field values** (MUST): `null`, `undefined`, a blank
  (whitespace-only) string, and an empty array all count as "empty" via
  `isEmptyValue`; `false` and `0` do NOT, so a deliberately unticked
  required checkbox is a valid answer, never a missing one
  (`validation.ts` `isEmptyValue`; `validation.test.ts` "treats false and
  zero as entered values, not as absence").
- **Structurally-identical replacement values** (MUST): setting a field to
  a new array or plain-object reference that is deep-equal to its current
  value MUST NOT mark the draft dirty, so a child component that hands back
  a fresh object per keystroke does not permanently light Save
  (`useDirtyDraft.ts` `sameValue`, `set`/`patch` bail-outs).
- **A `select` field holding a value its own options do not list** (MUST):
  the control renders an extra option instead of silently defaulting to the
  first listed one, and validation reports it as an error rather than
  passing a value the row does not truly hold (`controls.tsx`; `validation.
  ts` `fieldError`).
- **A repair function that produces another invalid value** (MUST): the
  container never saves such a value; it stops, logs, and tells the user
  the repair failed rather than silently corrupting the row a second time
  (`repair.ts` `RepairPlan.unrepaired` docblock).
- **Dismissing a "Repair failed" acknowledgement for an unrepairable value**
  (MUST): this leaves the field's original, still-invalid value in the
  draft with Save still blocked by the same validation failure that made
  repair necessary in the first place; the container offers no further
  remediation path from the UI once the field's own `repair` function is
  itself defective — fixing it requires a code change, not a user action.
- **A background refetch landing mid-edit** (MUST): the container never
  overwrites a dirty draft with a fresh `record`; it defers the incoming
  value until Cancel or until a later save supersedes it
  (`container.tsx` re-seeding effect).
- **Concurrent nested containers** (MUST): each `EditingContainer` instance
  keeps its own independent draft, dirty state and repair state; two sibling
  nested containers editing different rows at once do not interfere with
  each other, and only their aggregate dirtiness is shared, through
  `EditingScope` (`scope.tsx`; `nesting.test.tsx` "keeps the two Save
  buttons independent").
- **A rapid double Save** (MUST): a second Save activation while the first
  is still in flight is a no-op; `onSave` is invoked exactly once per
  successful click sequence (`container.tsx` `handleSave` guard).
- **Offline or unreachable server** (MUST, by delegation): the container
  performs no network I/O of its own — `onSave`/`onRepair` are opaque
  caller-supplied functions, so any rejection they produce, including one
  caused by lost connectivity, is handled uniformly by the generic failure
  path (`save-failure-preserves-draft-and-shows-reason` /
  `repair-write-failure-keeps-draft-editable` above); the container itself
  does not detect connectivity, retry or queue a write.
- **A required field validator and a repair function both declared** (MUST
  NOT, structurally): the type system makes `required` and the repair pass
  independent concerns — `required` never enters `planRepairs`, so an empty
  required field is never "fixed" on the caller's behalf
  (`descriptors.ts` `RequirableFieldOptions.required` docblock).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `record` | `TRecord` | required | The row as loaded. A new identity re-seeds the draft unless it is dirty. |
| `fields` | `TFields` (a map of `FieldDescriptor`) | required | What is editable and how; typically hoisted to module scope as a constant. |
| `sections` | `TSections` (a list of `SectionSpec`, from `section()`/`dangerZone()`) | required | How the fields are grouped; must cover every declared field exactly once. |
| `onSave` | `(values: TRecord) => void \| Promise<void>` | required | Persists the edited record; also carries the repair pass's write unless `onRepair` is supplied. |
| `onRepair` | `(values: TRecord) => void \| Promise<void>` | `onSave` | Persists a repaired record; use when `onSave` has side effects (closing a pane, navigating) that a system-initiated repair write should not trigger. |
| `onCancel` | `() => void` | `undefined` | Extra work Cancel should do after the draft is discarded. |
| `context` | `TContext` | `undefined` | Whatever the record's field `validate`/`repair` functions need. |
| `readOnly` | `boolean` | `false` | Renders the values without controls, Save bar, repair pass, or (own) contribution to the navigation guard. |
| `validate` | `(values: TRecord) => string \| null` | `undefined` | A cross-field rule no single field descriptor can express; a non-null return blocks Save. |
| `children` | `React.ReactNode` | `undefined` | Rendered after the sections — the usual place for a nested container (a table of rows). |
| `className` | `string` | `undefined` | Extra class names on the outer container `div`. |
| Field option: `label` | `string` | required | Caption above the control (or beside it, for `checkbox`). |
| Field option: `hint` | `React.ReactNode` | `undefined` | Dim helper text below the control; replaced by the error when the field is invalid. |
| Field option: `disabled` | `boolean` | `false` | Locks this control independent of the container's own `readOnly`/`saving` state. |
| Field option: `required` | `boolean` | `false` | Blocks Save while empty and shows `"Required."`; not applicable to `checkbox`. |
| Field option: `placeholder` | `string` | `undefined` | Greyed sample text; `text`, `rdid`, `textarea` only. |
| Field option: `rows` | `number` | `undefined` | `textarea` only. |
| Field option: `options` | `readonly { value, label }[]` | required for `select` | The closed choice list. |
| Field option: `validate` / `repair` | `(value, context) => string \| null` / `(value, context) => value` | `undefined` / `undefined` | Declared together or not at all; `repair` is how the repair pass fixes stored data that fails `validate`. |

## Deep Linking

Not applicable: the container has no route or URL of its own — it renders
inline wherever a caller places it, and neither `container.tsx` nor any of
its sibling source files parse or construct a URL.

## Localization

Not marked not-applicable: the package's own English strings are user-facing
and hardcoded, with no localization mechanism in the given sources.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (required-field) | `Required.` | Shown under a required field left empty (`validation.ts` `REQUIRED_MESSAGE`). |
| (unlisted-choice) | `"<value>" is not one of the available choices.` | Shown under a `select` field holding a value off its own option list (`validation.ts` `unlistedChoiceMessage`). |
| (layout-duplicate) | `These fields are laid out in more than one section: <keys>.` | Runtime layout-fault text, also logged (`container.tsx`). |
| (layout-uncovered) | `These fields are declared but no section lays them out: <keys>.` | Runtime layout-fault text, also logged (`container.tsx`). |
| (layout-unknown) | `Section "<title>" lays out unknown field "<key>".` | Runtime layout-fault text, also logged (`container.tsx`). |
| (repair-prompt-title) | `Repair required` | Title of the non-dismissible repair acknowledgement (`container.tsx` `repairAlert`). |
| (repair-prompt-description) | `This data needs some repair and will be saved.` | Body of the repair prompt and its busy state (`container.tsx` `repairAlert`). |
| (repair-succeeded-title) | `Repair succeeded` | Title of the dismissible success acknowledgement (`container.tsx` `repairAlert`). |
| (repair-failed-title) | `Repair failed` | Title of the dismissible failure acknowledgement; its description is the caller's own error/fault message, not a fixed string (`container.tsx` `repairAlert`). |
| (unknown-error-fallback) | `Unknown error.` | Shown when a rejected `onSave`/`onRepair` throws something that is neither an `Error` nor a string (`container.tsx` `messageOf`). |
| (default-alert-confirm) | `OK` | `EditingAlertProps.confirmLabel` default, applied by the platform's `AlertModal` (`host.tsx` `PlatformAlert`). |

## Accessibility Options

Not applicable: none of the given sources reference Reduce Motion, Increase
Contrast, or Differentiate Without Color — the container renders no
animation, and its only color-carrying affordance (the danger-zone section's
red border/text) is paired with the section's own title text, not color
alone, but that pairing is fixed rather than driven by a Differentiate
Without Color setting.

## Feature Flags

Not applicable: no feature-flag key, environment variable, or conditional
gate appears anywhere in `container.tsx` or its sibling source files — the
container's behavior depends only on its own props.

## Analytics

Not applicable: none of the given sources emit an analytics or telemetry
event; the package has no dependency on an analytics client.

## Privacy

- **Data collected**: None beyond what the caller already holds. The
  container is a generic, caller-typed editor with no field kind specific to
  credentials, tokens, or other sensitive data; every field's sensitivity is
  defined entirely by the caller's `TRecord` type, not by this package.
- **Storage**: None of its own. `draft`/`baseline` live in React state for
  the lifetime of the mounted component and are discarded on unmount;
  nothing is written to `localStorage`, `IndexedDB`, or any other browser
  storage.
- **Transmission**: None of its own. The container performs no network
  I/O — every write goes through the caller-supplied, opaque `onSave`/
  `onRepair` functions.
- **Retention**: None beyond the component's own lifetime; see Storage
  above.

## Logging

Subsystem: `@adh-sdk` | Category: `editing`

| Event | Level | Message |
|-------|-------|---------|
| Layout fault detected | error | `[@adh-sdk/editing] <fault text>` — once per fault, on every render where `layoutFaults` is non-empty (`container.tsx`). |
| Repair produced a still-invalid value | error | `[@adh-sdk/editing] repair() left a value still invalid — <key>: <message>[; <key>: <message> ...]` (`container.tsx`). |

## Platform Notes

- **SwiftUI**: Model the draft with an `@Observable` (or `ObservableObject`)
  editor type holding `draft`/`baseline` and computing `dirty` with an
  `Equatable` record type (Swift's structural `==` on a `struct` gives the
  array/object-content comparison `useDirtyDraft` hand-rolls in TypeScript
  for free). Field descriptors become an enum or protocol-witness list
  (`FieldDescriptor<Value, Context>` as a generic `struct`); layout coverage
  can be checked at compile time with a `CaseIterable` key enum rather than
  TypeScript's mapped-type trick. The repair pass and `EditingScope` rollup
  (an `@Environment`-injected parent reporter) both port directly; the
  navigation guard maps to `.interactiveDismissDisabled` plus a
  confirmation `.alert`.
- **Compose**: A `ViewModel` holding `MutableStateFlow<Draft<T>>` plays the
  role of `useDirtyDraft`; `derivedStateOf`/`combine` compute `dirty` and
  `canSave`. Field descriptors are sealed classes or data classes per
  `ControlKind`; section coverage is best checked with a lint rule or a
  `CoveredKeys`-style compile-time helper generated from a `sealed interface`
  of field keys, since Kotlin's type system cannot replicate the TS
  literal-tuple inference exactly. Nesting/rollup maps to
  `CompositionLocal` for the scope and Jetpack Navigation's
  `BackHandler`/predictive-back APIs for the guard.
  `NavigationEventDispatcher` or the two-argument `PredictiveBackHandler`
  covers the confirm-before-leaving prompt.
- **React/Web**: This is the source. `container.tsx` is the container;
  `controls.tsx` holds the (unexported) bound primitives; `descriptors.ts`
  and `sections.ts` are the declarative, framework-agnostic halves also
  re-exported from `server.ts` for Server Components; `repair.ts` and
  `validation.ts` are pure functions with their own unit tests; `scope.tsx`
  is the nesting/rollup Context; `host.tsx` is the dependency-injection
  point for the platform's `UnsavedChangesGuard`/`AlertModal`. Compile-time
  enforcement (generics, `SectionsCheck`, `@ts-expect-error` tests checked
  via `tsc --noEmit`) is specific to this platform's type system and has no
  literal equivalent elsewhere.
- **AppKit / UIKit**: There is no direct visual analogue since this is a
  data layer, not a control; a UIKit/AppKit port would center the same
  `EditingController` object (an `NSObject`/plain class, not a view)
  holding `draft`/`baseline`/`dirty` via KVO or a delegate callback, with
  `NSFormatter`/manual field wiring standing in for `BoundField`. The
  repair pass and navigation guard translate to a modal
  `UIAlertController`/`NSAlert` (mirroring the non-dismissible
  single-button prompt) and `UIViewController`'s
  `isModalInPresentation`/window-close interception, respectively.
- **WinUI 3**: Represent `draft`/`baseline` as two instances of a
  `partial class` implementing `INotifyPropertyChanged`, with `dirty`
  computed by comparing them field-by-field (or via a generated
  `IEquatable<T>` on a C# `record`, which gives structural equality the way
  `useDirtyDraft`'s `sameValue` does for plain objects/arrays). Field-level
  errors surface through `INotifyDataErrorInfo` so bound `TextBox`/
  `ComboBox`/`CheckBox` controls show validation state natively instead of
  through a hand-rolled error prop; `TextBox.MaxLength`/`InputScope` cover
  `placeholder`/`rows`-equivalent options, and a `ComboBox` bound to an
  `ObservableCollection<SelectOption>` needs an explicit "insert the current
  unlisted value as an extra item" step to match
  `select-shows-unlisted-stored-value`, since WinUI's `ComboBox` has no
  built-in equivalent. The repair pass's non-dismissible prompt maps to a
  `ContentDialog` with `CloseButtonText` unset and `IsPrimaryButtonEnabled`
  bound to the "not yet applying" state, `DefaultButton` set so Enter
  confirms, and no `system-close` handling — WinUI's `ContentDialog` does
  not raise Escape as a distinct event the way a web `Escape` keydown does,
  so the equivalent guard is simply omitting the close (`X`) affordance
  that `ContentDialog` would otherwise show. Section/field coverage has no
  compile-time equivalent in C#'s type system (no literal-tuple inference);
  the nearest practical equivalent is a source generator or a unit test
  that walks a `[Field(nameof(...))]`-attributed list against the view
  model's declared sections at build time, rather than the compiler itself
  rejecting the mismatch. The navigation guard maps to `Frame.Navigating`
  (or `NavigationView`'s equivalent) combined with a `ContentDialog`
  confirmation and `Window.Closing` for the app-exit case, rolled up across
  nested edit surfaces via a shared `IEditingScope` service registered per
  `Frame`/`Page` rather than React Context.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/editing/src/` | unverified |

## Design Decisions

**Decision**: `dirty` is computed from `useDirtyDraft`'s structural
equality (deep-equal for arrays and plain objects, `Object.is` for
everything else) rather than a shallow reference comparison.
**Rationale**: several call sites hand a facet's whole config object back
per keystroke; a reference-only comparison would latch `dirty` true on the
first render and never release it, permanently lighting Save and arming the
navigation guard on an untouched pane (`useDirtyDraft.ts` docblock).
**Approved**: pending

**Decision**: `required` is deliberately excluded from the repair pass.
**Rationale**: repair fixes a value that is present but wrong; an empty
required value has nothing to derive a correction from, so inventing one
would be worse than leaving Save grey with a visible `"Required."` message
the user can act on (`descriptors.ts` `RequirableFieldOptions.required`
docblock; `repair.ts` module docblock).
**Approved**: pending

**Decision**: the repair prompt's acknowledgement is the one alert in the
flow that is not dismissible, so Escape, the backdrop and the close
control are all ignored instead of being routed to its confirm action.
**Rationale**: the prompt's confirm performs a real write (the repair
save); on a dismissible one-button alert every dismissal gesture routes to
that confirm, so "get this out of my way" would trigger the write — making
the prompt non-dismissible is how the container closes off every
dismissal path except the button itself (`container.tsx` `repairAlert`
"prompt" case comment; `host.tsx` `EditingAlertProps.dismissible`
docblock).
**Approved**: pending

**Decision**: a declined mid-edit refetch is tracked separately from the
baseline and is only ever adopted via Cancel, never silently merged into
the draft.
**Rationale**: overwriting the user's in-progress edits with a background
refetch would lose work with no warning; deferring the refetch to Cancel
makes "discard my edits" the one moment adopting fresher data is safe
(`container.tsx` re-seeding effect comment).
**Approved**: pending

**Decision**: dirtiness rolls up through nested containers to exactly one
navigation guard at the outermost container, rather than each container
publishing its own.
**Rationale**: two guards on one page would produce two prompts for one
navigation decision; publishing once from the root, informed by every
descendant, matches the platform's one-guard-per-navigation-action rule
(`scope.tsx` module docblock).
**Approved**: pending

**Decision**: the bound controls in `controls.tsx` are not exported from
either package entry point.
**Rationale**: an export boundary makes "a control cannot be used outside a
container" structural rather than a convention a linter must catch — there
is no import path that produces a wired control anywhere else, so the
misuse has no syntax to write (`controls.tsx` module docblock; `package.
json` `comment:exports`).
**Approved**: pending

**Decision**: `./server` is built as a separate chunk graph rather than
merely a separate source file re-exported from the same build.
**Rationale**: the build tool's `"use client"`-hoisting plugin stamps that
directive onto every entry sharing a chunk with a client module; sharing a
chunk graph with the main barrel would silently turn the declarative,
Server-Component-safe entry into a client-only one with no compiler error
(`server.ts` module docblock).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | Privacy and Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |

`explicit-error-handling` passes: every asynchronous write the container
performs itself — `onSave`, the repair write, and the repair pass's own
"still invalid after repair" case — is caught and surfaced, either as a
rendered `role="alert"` message or as a logged-and-shown repair failure;
nothing given in the sources swallows an error silently. `separation-of-
concerns` passes: the container owns draft state, validation, layout
coverage and the repair decision, but delegates persistence to the caller's
`onSave`/`onRepair`, control rendering to `@adh-sdk/ui`, and
the navigation guard/alert chrome to an injected `EditingHost`.
`unit-test-coverage` is partial: the package's own nine test files exercise
validation, sections, the repair plan, the container's save/cancel/re-
seeding/layout-fault paths, nesting/rollup, every control kind, the guard
integration and the full repair UX flow in detail, plus a dedicated
compile-time suite for the generic contract — but `useDirtyDraft`'s own
equality semantics are tested in the `ui` package rather than duplicated
here, and nothing in this package's tests exercises two containers editing
the *same* record concurrently. `graceful-degradation` passes: a layout
fault renders as a visible alert and the pane continues rendering rather
than throwing; an unlisted `select` value is shown rather than crashing or
silently substituting the first option. `fault-tolerance` passes: a
`repair()` that produces another invalid value is caught before any write
is attempted, and a rejected repair write leaves the pane in a working,
retryable state rather than a stuck one. `data-minimization` and
`data-retention-policy` pass: the container adds no storage or retention of
its own beyond the mounted component's lifetime, as detailed under Privacy
above. `string-externalization` fails: every user-facing string this
package produces — `"Required."`, the unlisted-choice and layout-fault
messages, the three repair-flow alert titles and their description — is a
hardcoded English literal with no localization key or i18n library
involved, as detailed under Localization above.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-09-25 | Mike Fullerton | Repair-prompt Design Decision corrected: non-dismissible means Escape/backdrop/close are ignored, not routed to confirm; Change History 1.0.0 row's blank Date/Author filled per K14d (history-table finding, authorized exception). |
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
