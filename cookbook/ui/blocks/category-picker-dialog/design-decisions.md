
**Decision**: Build a tree browser on the base `Dialog` primitives, not on
`ListChooser`/`EntityChooser`'s flat filter-and-add pattern.
**Rationale**: [adhsdk.ingredient.ui.components.inputs.list-chooser](cookbook:40827b84-406e-4091-951b-9498b2f78253)
and [adhsdk.ingredient.ui.components.inputs.entity-chooser](cookbook:79f7ed30-3193-49bc-856b-d7dd01303baa) both pick
a RECORD from a flat set — the correct model when a name is already a unique,
sufficient answer (a document's category via `CategoryField`, or a tag). This
dialog picks a **place** in a tree — a parent — and a place cannot be named
without saying where it sits; "no parent (make it a root)" is a legitimate
answer neither chooser can express (`ListChooser`/`EntityChooser` have no
concept of nesting, let alone an explicit top-level option). So the tree is the
primary control here and the filter is a shortcut into it, the reverse of
`ListChooser`'s filter-is-everything model. `CategoryField`'s own chooser (the
document-level "pick a category by name" control) makes the identical trade the
other way, for the identical reason: names are unique per owner across the whole
hierarchy, so a bare name is already an exact address there, and walking a tree
to find what typing three characters already resolves would be slower, not more
precise. `CategoryField` is shipped but has no recipe of its own yet; the
contrast lives here because a reader comparing the two pickers is most likely to
land on this file first.
**Approved**: pending

**Decision**: Compose the base `Dialog` primitives, not
[adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500)'s
`AlertModal`.
**Rationale**: `AlertModal` is an alert/confirm shape with a single description
slot; this dialog needs an interactive tree body, a search field, and an OK
that is conditionally disabled on a live selection — none of which fits the
alert/confirm contract. Building on the plain `Dialog` primitives keeps the
focus trap, portal and Escape-close shared without forcing an ill-fitting shape
onto them.
**Approved**: pending

**Decision**: The filter result dedupes by category id; the browse tree does
not.
**Rationale**: Browsing shows every real placement (the honest DAG picture
Topic Detail ([adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f)) itself shows for
its own rail); a filter result is read as one answer per id, so showing the
same category twice there would look like two different categories. Deduping
only the filter view keeps both readings correct for what each is for.
**Approved**: pending

**Decision**: `buildCategoryTree` runs again inside this component rather than
accepting a pre-built `CategoryNode[]` prop.
**Rationale**: Taking `nodes: CategoryTreeNode[]` rather than a pre-built
`CategoryNode[]` keeps this component's public contract independent of the
internal fold's shape, and lets any caller with the flat rows open the picker
without importing `buildCategoryTree` itself. The fold runs inside a `useMemo`
keyed on `nodes`, so it recomputes only when the caller's rows actually change
rather than on every render; bounded by `MAX_TREE_NODES`, that memoized
recomputation is cheap enough that this component's contract independence costs
nothing measurable.
**Approved**: pending

**Decision**: No built-in async state.
**Rationale**: `nodes` is a controlled in-memory prop; the host owns fetching,
loading and error, and reports a REJECTED confirm through `error`/`busy` —
consistent with the sibling form controls
([adhsdk.ingredient.ui.components.inputs.list-chooser](cookbook:40827b84-406e-4091-951b-9498b2f78253),
[adhsdk.ingredient.ui.components.inputs.entity-chooser](cookbook:79f7ed30-3193-49bc-856b-d7dd01303baa)).
**Approved**: pending

