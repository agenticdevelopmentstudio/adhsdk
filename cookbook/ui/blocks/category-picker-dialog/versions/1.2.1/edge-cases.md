
- **Empty vocabulary.** `nodes=[]` renders no category rows in browse mode; the
  root row still renders when `allowRoot` is set (it does not depend on `nodes`),
  and the **show-empty-messages** text ("No categories yet.") renders alongside
  it in the same pass — the message names the absence of categories, not the
  absence of rows generally, so the root row does not suppress it. Never an
  error state; see T12.
- **A category filed under two parents.** It draws once per placement in browse
  mode (the same node, two different `path`s — `categoryKey` disambiguates the
  React keys), but the FILTER list dedupes it to one option by `id`, keeping the
  first placement's trail — a filter result is one id, so it must read as one
  option (see `category-picker-dialog.tsx`'s `dedupeById`); see T17.
- **A cycle in legacy data.** The dialog never sees the raw edges — `nodes` is
  the caller's flat `CategoryTreeNode[]` rows, unfolded. This component is the
  one that calls `buildCategoryTree` (memoized on `nodes`), and that fold's own
  cycle-breaking (re-seeding an orphaned branch as a root) is what determines
  what the tree shows; see the tree-fold's own contract for `buildCategoryTree`.
  The dialog adds no cycle handling of its own — it only walks what the
  fold hands back.
- **The `MAX_TREE_NODES` cap (4000).** A forest at the cap still renders and is
  still fully keyboard-navigable — the fold stops MATERIALISING nodes, not the
  dialog from walking whatever it received; a picker over a capped forest simply
  cannot offer the nodes that were never drawn.
- **Whitespace-only filter text.** Trimmed before matching; an all-whitespace
  filter behaves as no filter (browse mode, not an empty-match message); see T18.
- **`null` selection is the root row, not "nothing picked."** With `allowRoot` set and no `initialSelectedId`, the dialog opens with "Top level" already selected and confirmable — clicking Confirm immediately calls `onConfirm(null)`. Typing any filter text makes the root row unconfirmable again (see **disable-confirm-when-unpickable**) even though it stays the pending selection, closing what would otherwise be a silent move-to-root once the list no longer shows the root row as the obvious pick; see T23, T24.
- **Reopening on a stale `initialSelectedId`.** If the id no longer exists in
  `nodes`, no row renders as selected — the lookup that drives the highlight
  finds nothing to match — but **disable-confirm-when-unpickable** checks only
  `disabledIds` membership, not existence in `nodes`; a stale id that is not
  itself in `disabledIds` leaves Confirm enabled, and clicking it calls
  `onConfirm` with an id no visible row matches. The dialog does not fall back
  to the root or the first row, and performs no validation of
  `initialSelectedId` against `nodes` on its own; see T19.

