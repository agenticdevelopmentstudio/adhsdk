
`CategoryPickerDialog` is the family's category **picker**: a modal that browses
the owner's whole category hierarchy and returns one **place** in it — a category
id, or (when offered) the top level. It is built directly on the shared `Dialog`
primitives (`Dialog`, `DialogContent`, `DialogHeader`, `DialogTitle`,
`DialogDescription`, `DialogActions`, `Input`, `ErrorText`) rather than on
`ListChooser` or `EntityChooser`: those compose a single-field filter/add control
over a **flat** list, and a place in a tree cannot be expressed as a bare name.

The dialog folds the caller's flat `nodes: CategoryTreeNode[]` into a forest with
`buildCategoryTree` (`category-tree.ts`), inside a `useMemo` keyed on `nodes` — so
it recomputes only when the caller's rows actually change, always browsing the
same materialisation Topic Detail ([adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f))
draws for its own rail. Browsing is a real WAI-ARIA `tree` — one roving tab stop,
arrow-key expand/move/collapse — and typing into the field switches the list to a
flat, trail-annotated filter (`role="listbox"`) so a match three levels down is
found by typing its name rather than walking to it.

It is the modal behind a hierarchical category browser's "Move…" gear action —
the host supplies `disabledIds` (the moved category and its own descendants, so a
category can never become its own ancestor) and `allowRoot` (a move can land a
category at the top level, which is why the root row exists at all). Every word
the host controls — `title`, `description`, `confirmLabel`, `rootLabel` — is
supplied by it; the component's own built-in English strings ("No categories
yet.", the filter-match message, `aria-label="Filter categories"` /
`aria-label="Categories"`, the placeholder "Filter categories…", and the
Expand/Collapse `title`) are not props and are not currently overridable — see
Compliance and Localization-adjacent notes below.

