
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

