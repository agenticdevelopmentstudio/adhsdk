
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

