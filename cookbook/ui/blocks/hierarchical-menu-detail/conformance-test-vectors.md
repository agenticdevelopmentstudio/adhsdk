
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hmd-001 | render-levels | 2 `levels`; level 0 has 3 items and `selectedId="a"`, level 1 has 2 items and `selectedId=null` | Both levels render as columns with correct item counts. |
| hmd-002 | scope-by-selection | 3 levels; level 0 `selectedId="a"`, level 1 `selectedId=null`, level 2 `selectedId="c"` | Level 0 and level 1 render (level 1 is the frontier: all its items visible, none selected); level 2 does not render. |
| hmd-003 | show-breadcrumb | `showBreadcrumb=true`, `rootLabel="Root"`, level 0 selected | Breadcrumb shows "Root" + selected item label. |
| hmd-004 | navigate-breadcrumb | Breadcrumb crumb clicked for level 0 | `onClear()` called for levels 1+; level 0 selection unchanged. |
| hmd-005 | deselect-on-reclick | Row with `id="x"` already selected, row clicked again | `onClear()` called for that level. |
| hmd-006 | disclosure-styles | `disclosureStyle` set to each of "minimized", "covered", "cascading" | Each style renders lists with correct layout/hiding strategy. |
| hmd-007 | autohide | `autoHideTopics=true`, `disclosureStyle="covered"`, wide mode, 3 levels; levels 0 and 1 have selections, level 2 `selectedId=null` (frontier), no pins | Only frontier (level 2) disclosed; levels 0–1 hidden (covered to a 40px peek). Root header toggle exists. |
| hmd-008 | pin-precedence | `autoHideTopics=true`, level 0 pinned disclosed (`pins["level-0"]=false`) | Level 0 remains visible despite autoHide. |
| hmd-009 | minimized-manual-pin | `disclosureStyle="minimized"`, `manualCollapse=true`, list header toggle clicked | List pin state flips; layout re-renders immediately. |
| hmd-010 | render-detail | `children` provided with text "Detail" | Text "Detail" appears in the rightmost pane, beside the list columns. |
| hmd-011 | render-toolbar | `toolbar` with a button | Button renders in strip above breadcrumb. |
| hmd-012 | min-detail-width | `minDetailWidth="28rem"`, `layoutMode="wide"`, `disclosureStyle="covered"`, container width 44rem, 2 levels at 10rem each; level 0 selected, level 1 `selectedId=null` (frontier) | Detail pane is at least 28rem wide; level 1 (frontier) is disclosed at 10rem; level 0 is covered to its 40px peek. |
| hmd-013 | default-select | Level 0 appears with `defaultSelectedId="x"` and `selectedId=null` | `onSelect("x", { replace: true })` called once. Subsequent renders do not re-fire. |
| hmd-014 | guard-exit | `exitGuard` with `isDirty=true`, breadcrumb crumb clicked | Unsaved-changes alert shown; navigation blocked until user confirms. |
| hmd-015 | cascading-layout | `disclosureStyle="cascading"`, 2 levels selected | Root list spans full height; level 1 opens to right of root, below root header. |
| hmd-016 | render-connectors | Wide mode, 2 levels, both with selections | Elbow path, in the selection accent colour, drawn from level 0 selected row to level 1 selected row. |
| hmd-017 | narrow-mode | `layoutMode="narrow"` or "auto" on phone, 2 levels | One full-width pane visible; Back button shows to switch panes. |
| hmd-018 | render-trailing-crumbs | `trailingCrumbs=[{label:"Leaf"}]` | "Leaf" appears after level crumbs, non-interactive. |
| hmd-019 | hover-reveal | `disclosureStyle="covered"`, pointer ENTER on covered list row | Ancestor lists reveal at full width for pointer duration. |
| hmd-020 | covered-peek | `disclosureStyle="covered"`, 2 levels, level 0 covered by width pressure | Level 0 renders clipped to a 40px peek (icon only); level 1 casts a left drop-shadow; no Back button appears. |
| hmd-021 | pin-parent-toggle | `disclosureStyle="covered"`, 2 levels, level 0 selected | Level 1 header carries a `«`/`»` toggle that covers or uncovers level 0; level 0 header has no such toggle. |
| hmd-022 | frontier-cover-toggle | `disclosureStyle="cascading"`, 2 levels both selected | Frontier list has no cover toggle; the detail strip shows the immersion toggle. |
| hmd-023 | pin-reset-on-autohide | Level 0 pinned (`pins["level-0"]=false`), root auto-hide toggle clicked | Every pin is cleared. |
