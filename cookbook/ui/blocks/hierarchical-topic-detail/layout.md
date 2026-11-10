
```
┌──────────────────────────────────────────────────────────────────────────┐
│ workspace ▸ feature ▸ entity ▸ topic ▸ leaf            [?] help (right)    │  ← one full-width breadcrumb
├─────────┬──────────┬──────────┬──────────┬────────────────────────────────┤
│ Wksp  + │ Feat     │ Ent    + │ Topic    │ ‹ Back  Delete │ Cancel Save [?]│  ← titled header: title left, New "+" right
│ ◻ Wksp  │ ◻ Feat 1 │ ◻ Ent A  │ ◻ Topic1 │ ┌────────────────────────────┐ │
│ ◻ Wksp2 │ ◻ Feat 2 │ ◻ Ent B  │ ◻ Topic2 │ │  left-justified content     │ │
│         │ ◻ …      │          │ ◻ …      │ │  fills vertically; min-width│ │
│  «      │  «       │  «       │  «       │ │  horizontal scroll if tiny  │ │
└─────────┴──────────┴──────────┴──────────┴─┴────────────────────────────┴─┘
  fixed-width, resizable, disclosable topic lists   flexible, min-width detail
  (narrower → leftmost lists COVER/slide OFF-SCREEN; hover a peek to open every on-screen list — parents and children alike)
```

**Narrow mode** (only a detail fits, or a phone) — the same stack as a navigation controller:

```
┌────────────────────┐   select    ┌────────────────────┐   select    ┌────────────────────┐
│ wksp ▸ feat        │  ────────▶  │ wksp ▸ feat ▸ ent  │  ────────▶  │ … ▸ ent ▸ topic    │  ← breadcrumb still spans the top
├────────────────────┤             ├────────────────────┤             ├────────────────────┤
│ Entities        +  │   ◀────     │ Topics          +  │   ◀────     │ ‹  detail          │
│ ◻ Ent A            │    Back     │ ‹ ◻ Topic 1        │    Back     │                    │
│ ◻ Ent B            │             │   ◻ Topic 2        │             │  full width        │
└────────────────────┘             └────────────────────┘             └────────────────────┘
   ONE full-width pane: the frontier list, then the detail. Push in from the right, Back pops out.
```

- **Top edges** of every rail + the detail pane align on one row under the breadcrumb;
  **bottom edges** align (all fill to the container height). The first row of each rail aligns via the
  uniform titled header (no reserved leading slot); the first topic sits directly under the header.
- **Rails**: `bg-apt-nav`, fixed width ≈ widest topic + padding, right divider, a titled **header** with
  a disclosure/cover `«`/`»` control (left) + a left-aligned `title` + a right-justified New **`+`**
  (`onNew`) and a divider beneath. Undisclosed/covered = an icon strip (32px covered peek / 48px `minimized` strip); in the stack
  selection is the **marker** (root dash + parent→child connectors), not a per-rail bar. Hovering a
  covered rail reveals the whole BRANCH — that rail AND its children, full rows + headers, chained side
  by side above the detail. In **narrow** mode a rail is instead the full-width pane (bar selection, a
  top-left Back, no cover/resize affordances).
- **Detail pane**: `bg-apt-surface`, flexible width with a minimum (horizontal scroll
  below it), fills height; its leaf's action bar (Save/Cancel/Delete, and Back when drilled) renders at the top of the
  pane — never a separate centered title, since the full-width breadcrumb already names the pane — with a
  right-justified help icon. Colour only via `apt-*` tokens; no raw hex; no `!important`.
- **Breadcrumb**: `bg-apt-nav`, mono `text-xs`, `›` separators, ancestor crumbs are
  buttons, current crumb `aria-current` in `apt-gold`; help button right-justified.

