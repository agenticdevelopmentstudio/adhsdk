
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

