
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| popup-001 | accept-items | `items=[{id:"a", label:"Item A"}, {id:"b", label:"Item B"}]` | Both items appear in dropdown |
| popup-002 | accept-selected-id, display-selected-label-on-trigger | `selectedId="a"`, item A has label "Item A" | Trigger displays "Item A" |
| popup-003 | accept-selected-id, display-selected-label-on-trigger | `selectedId=null`, `allLabel="All"` | Trigger displays "All" |
| popup-004 | call-select-callback | User clicks item with `id="x"` | `onSelect("x")` is called |
| popup-005 | call-select-callback | User clicks "All" row | `onSelect(null)` is called |
| popup-006 | render-all-row-when-enabled | `allLabel="All"` | "All" row appears as first item in dropdown |
| popup-007 | omit-all-row-when-disabled | `allLabel=null` | No "All" row in dropdown |
| popup-008 | display-selected-label-on-trigger | `selectedId=null`, `allLabel=null` | Trigger displays empty string |
| popup-009 | render-new-row-when-callback-present | `onNew` callback provided | "New…" row appears as the last entry in the dropdown |
| popup-010 | omit-new-row-when-no-callback | `onNew` not provided | No "New…" row in dropdown |
| popup-011 | render-new-row-when-callback-present | User clicks "New…" row | `onNew()` is called |
| popup-012 | single-select-item-group | `selectedId="a"` in the single-selection group | Item A is marked as checked/selected |
| popup-013 | truncate-long-trigger-labels | Label exceeds trigger width | Computed style includes `overflow: hidden`, `text-overflow: ellipsis`, `white-space: nowrap` (Tailwind's `truncate` utility); label renders visually truncated with an ellipsis glyph |
| popup-014 | accept-aria-label | `ariaLabel="Select focus"` | Trigger has `aria-label="Select focus"` |
| popup-015 | default-affordance-icon | No `icon` prop | Default affordance icon (ChevronsUpDown, 13px) is rendered on trigger |
| popup-016 | accept-custom-icon | `icon={<CustomIcon />}` | Custom icon is rendered instead of the default |
| popup-017 | accept-trigger-class-name | `className="w-auto"` | Trigger merges custom class; `w-auto` overrides default `w-full` |
| popup-018 | hide-icon-from-accessibility | Default or custom icon present | Icon has `aria-hidden` attribute |
| popup-019 | warn-on-sentinel-collision | `items=[{id:"__all__", label:"Item"}]` | Console warning logged: `PopupMenu: item id "__all__" collides with the All sentinel` |
| popup-020 | single-select-item-group | `selectedId` changes from `"a"` to `"b"` | Item B becomes checked and item A becomes unchecked (mutual exclusivity) |
| popup-021 | render-new-row-when-callback-present | `onNew` callback provided | A divider (separator) renders between the last item (or "All" row) and the "New…" row |
| popup-022 | render-new-row-when-callback-present | `onNew` provided, `newLabel="Create item"` | The row displays "Create item" instead of the default "New…" |
| popup-023 | focus-indicator-contrast | Trigger receives keyboard focus | Border color changes to the `apt-gold` token and the default outline is suppressed, meeting WCAG 1.4.11's 3:1 non-text contrast minimum against the adjacent surface |
| popup-024 | display-selected-label-on-trigger | `selectedId="zzz"` (no item has this id), `allLabel="All"` | Trigger displays "All" (same fallback path as `selectedId=null`) |
| popup-025 | accept-items | `items=[{id:"a",label:"First"},{id:"a",label:"Second"}]` (duplicate id) | No warning is logged (the sentinel check only fires for `"__all__"`); both entries share the same selection value, so the caller cannot distinguish which was clicked |

