
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

