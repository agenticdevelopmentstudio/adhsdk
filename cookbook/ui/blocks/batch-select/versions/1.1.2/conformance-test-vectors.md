
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| batch-select-001 | expose-active-state | `useBatchSelect()` | Returns object with `active: false` |
| batch-select-002 | expose-selected-ids | `useBatchSelect()` | Returns object with `selectedIds` as empty `Set<string>` |
| batch-select-003 | expose-toggle-active | `useBatchSelect()` | Returns object with `toggleActive` function |
| batch-select-004 | expose-count | `useBatchSelect()` with selections | `count` equals `selectedIds.size` |
| batch-select-005 | clear-selection-on-toggle-exit | active=true, selectedIds={id1, id2}, call toggleActive | active becomes false, selectedIds becomes empty Set |
| batch-select-006 | clear-selection-on-toggle-entry | active=false, call `setSelectedIds(new Set(['id1']))`, then call toggleActive | active becomes true, selectedIds becomes empty Set (the seeded id1 is cleared, not carried into batch mode) |
| batch-select-007 | provide-clear-function | active=true, selectedIds={id1}, call clear | active stays true, selectedIds becomes empty Set |
| batch-select-008 | reset-on-reset-key-change | Render with resetKey=1, then resetKey=2, selectedIds={id1} | selectedIds cleared to empty Set during render of resetKey=2 |
| batch-select-009 | reset-on-reset-key-change | Render with resetKey="search:foo", then resetKey="search:foo" (same value) | selectedIds retained, no reset |
| batch-select-010 | set-selected-ids-new-reference | Render, then render again with no call to `setSelectedIds` | selectedIds reference is the same object between the two renders |
| batch-select-011 | button-render-label | BatchSelectButton with active=false, selectLabel="Pick" | Button displays "Pick" |
| batch-select-012 | button-render-label | BatchSelectButton with active=true, doneLabel="Finish" | Button displays "Finish" |
| batch-select-013 | button-default-select-label | BatchSelectButton with active=false, no selectLabel | Button displays "Select" |
| batch-select-014 | button-default-done-label | BatchSelectButton with active=true, no doneLabel | Button displays "Done" |
| batch-select-015 | button-announce-pressed-state | BatchSelectButton with active=false | `aria-pressed="false"` on button element |
| batch-select-016 | button-announce-pressed-state | BatchSelectButton with active=true | `aria-pressed="true"` on button element |
| batch-select-017 | button-toggle-on-click | BatchSelectButton clicked while active=false | batch.toggleActive is called, active becomes true |
| batch-select-018 | set-selected-ids-new-reference | selectedIds={id1}, call `setSelectedIds(new Set(['id1']))` (same contents, different instance) | selectedIds reference is a new object, distinct from the previous render's |
| batch-select-019 | reset-uses-shared-empty-selection | Render with resetKey=1 then resetKey=2 (first reset), then resetKey=3 (second reset) | Both resets set selectedIds to the identical `EMPTY_SELECTION` object (`Object.is` true across the two resets) |
| batch-select-020 | provide-set-selected-ids | `useBatchSelect()`, call `setSelectedIds(new Set(['id1']))` | selectedIds becomes `Set{'id1'}`, count becomes 1 on next render |
| batch-select-021 | Rapid toggles (edge case) | active=false, selectedIds={id1}, call toggleActive three times in quick succession | active ends true (odd number of toggles), selectedIds ends empty Set |
| batch-select-022 | resetKey as non-primitive (edge case) | Render repeatedly with `resetKey={}` (a new object literal each render), selectedIds={id1} | selectedIds is cleared to empty Set on every render, even though the semantic filter value never changed |

