
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-two-panes | `items` + `children` | rail and pane both render, rail on left (desktop) |
| T2 | mark-selected | `selectedId="x"` | item x shows the gold bar + `aria-current="true"` |
| T3 | report-selection | click item "y" | `onSelect("y")` fires |
| T4 | skip-disabled | click a `disabled: true` item | no `onSelect` fires; item text dimmed; no hover bar |
| T5 | render-empty-label | `items=[]` | `emptyLabel` shown in the rail |
| T6 | support-rail-slot | `railSlot={(c)=>…}` + `railSlotActive: true`, collapsed | slot above topics; gold bar on the slot; render-prop gets `collapsed: true` → icon-only `+` |
| T7 | render-label | `items=[{id: "x", label: "A"}]` | text "A" shown on the row |
| T8 | render-label-suffix | `{label: "A", labelSuffix: "v2"}` | text "A v2" on the row (suffix distinct) |
| T9 | render-inline-sublabel | `{label: "A", sublabel: "b.com", inlineSublabel: true}` | single line: "A" (full width) "b.com" (dim, shrinks) |
| T10 | render-stacked-sublabel | `{label: "A", sublabel: "b.com"}` (no inlineSublabel) | two lines: "A" then "b.com" (dim, smaller) |
| T11 | render-preview | `{preview: "My note", previewLines: 2}` | three lines: label, sublabel (if set), preview (dim, 2-line clamp) |
| T12 | clamp-preview | `{preview: "Text", previewLines: 0}` | no preview shown (label/sublabel only) |
| T13 | render-icon | `{icon: <ChevronRight />}` | 16px icon rendered |
| T14 | render-icon | item with no `icon` prop | neutral ring icon (16px) fills in |
| T15 | hide-label-when-collapsed | `collapsed: true` | row shows only icon, label in `aria-label`, tooltip on hover/focus |
| T16 | render-divider-after | `{dividerAfter: true}` | separator line below the item, in expanded list and in collapsed/covered icon strips alike (tighter inset when collapsed) |
| T17 | render-spacer-after | `{spacerAfter: true}` at position 2 in 5-item list | items 3–5 sit at the rail's bottom edge |
| T18 | respond-mobile | viewport 375px width | single-column grid: rail (unchanged vertical list, left bar, `border-r`) stacks above the pane; collapse toggle and drag-resize handle hidden |
| T19 | collapse-rail | click the `«` toggle (toggle hidden at ≤768px) | rail narrows to 48px icon strip; icons keep gold bar; toggle becomes `»` |
| T20 | support-controlled-collapse | `collapsed: true`, `onCollapsedChange` set | toggling calls `onCollapsedChange(false)`; rail follows `collapsed` prop |
| T21 | support-drag-resize | drag trailing edge to 100px then 50px | `onResize(100)` fired; then snap to collapsed (48px) when crossing threshold |
| T22 | render-blocked-marker | `{blocked: true}` | amber dot on icon; `aria-label` says ", needs attention"; `data-blocked="true"` on row |
| T23 | support-delete-action | `{onDelete: async () => { … }}` | hover reveals trash button; click opens confirm dialog; confirm runs `onDelete` |
| T24 | support-delete-label | `{onDelete: () => {}, deleteLabel: "Workspace"}` | trash button `aria-label="Delete Workspace"`; dialog title `"Delete Workspace?"` |
| T25 | support-delete-confirm | `{onDelete: () => {}, deleteConfirm: "Permanent loss."}` | dialog body says "Permanent loss." |
| T26 | support-trailing-accessory | `{trailing: <Badge count={3} />}` | badge right-justified in expanded list (hidden when collapsed) |
| T27 | support-header-slot | `headerSlot={<Filter />}`, `title: "Users"` | filter strip below titled header (hidden when collapsed) |
| T28 | support-titled-header | `title: "Topics"` | titled header with divider, title left-aligned, `+` and toggle right-justified |
| T29 | support-create-affordance | `onNew: () => {}, newLabel: "New Topic"` | `+` button in header; `aria-label="New Topic"`; tints gold when `newActive: true` |
| T30 | show-busy-indicator | `busy: true` | spinner visible in header / top-right; `aria-live` region says "Loading" |
| T31 | support-back-slot | `backSlot={<Back />}` (untitled) | Back button top-left of header |
| T32 | support-left-control | `leftControl={<Toggle />}`, `showToggle: false` | Toggle top-left; desktop collapse toggle hidden |
| T33 | support-footer | `footer={<Stats />}` | Stats strip pinned at rail bottom (with top border) |
| T34 | support-close-button | `onClose: () => {}, closeLabel: "Dismiss"` | ✕ button top-right of header; `aria-label="Dismiss"` |
| T35 | support-row-disclosure | `rowDisclosure: true` | ChevronRight (14px) on every non-disabled row (expanded list only) |
| T36 | support-covered-style | `covered: true` | rows left-aligned icon strip; click already-selected row is no-op |
| T37 | support-marker-selection | `selectionStyle: "marker"`, `isRoot: true` | selected root row shows full-height left dash instead of bar |
| T38 | support-hover-bar | `hoverBar: false` | no left bar appears on row hover |
| T39 | hide-row-icons | `hideItemIcons: true` | leading icon hidden in expanded list (collapsed/covered unaffected) |
| T40 | support-prefetch | `onPrefetch: (id) => { … }`, hover row "x" for 100ms | `onPrefetch("x")` fires once after dwell |
| T41 | support-batch-mode | `checkable: true` | checkbox on every expanded-list row; unchecked by default |
| T42 | manage-batch-checked | `checkedIds: new Set(["x"])` | checkbox on item x is checked |
| T43 | fit-width | `onFit: (w) => {}` | `onFit` called with row width in px (clamped to 150–420) before paint |
| T44 | support-pane-padding | `panePadding: false` | pane content is edge-to-edge (no inset) |
| T45 | transition-collapse | drag the trailing edge (dragging active) | width transition suppressed while dragging; with `prefers-reduced-motion: reduce`, the collapse/expand transition duration is zeroed via `--apt-anim-scale` |
| T46 | support-covered-shadow | `coveredShadow: true` | rail casts a left drop-shadow (`shadow-[-10px_0_22px_-8px_var(--color-shadow)]`) |
| T47 | support-delete-action | `{onDelete: () => { throw new Error() }}`, confirm the dialog | dialog remains open, spinner clears, item is not removed; user can retry or cancel |
| T48 | support-prefetch | `onPrefetch` provided; hover the already-selected row for 100ms | `onPrefetch` does NOT fire for that row |
| T49 | manage-batch-checked | click an unchecked row's checkbox | `onToggleChecked(id)` fires; the row's own single selection is unaffected |
| T50 | fit-width | `onFit` provided; simulate `document.fonts.ready` resolving after initial measure | `onFit` is called a second time with the post-font-load width |
| T51 | support-dense-bottom | `denseBottom: true` | list's bottom padding is `pb-2` instead of the default `pb-8` |
| T52 | support-rail-slot | `railSlot` omitted | no slot renders; first topic row sits at the list's top padding, not the reserved slot height |
| T53 | skip-disabled, support-delete-action | `{disabled: true, onDelete: () => {}}` | row button disabled and non-interactive; trash button still renders enabled, hover/focus-revealed, and opens the confirm dialog |

