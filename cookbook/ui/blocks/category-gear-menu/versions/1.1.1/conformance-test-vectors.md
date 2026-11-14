
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cgm-001 | render-trigger | Default render | Trigger displays labeled "Category actions" |
| cgm-002 | render-five-items | Menu opened | Five items are visible: "Add category…", "Rename…", "Move…", "Also file in…", "Delete…" |
| cgm-003 | show-target-in-labels | targetName="Q3", canEditTarget=true | `Rename "Q3"…`, `Move "Q3"…`, `Also file "Q3" in…`, `Delete "Q3"…` |
| cgm-004 | omit-target-when-not-editable | targetName="Q3", canEditTarget=false | "Rename…", "Move…", "Also file in…", "Delete…" (target name omitted); "Add category…" unaffected |
| cgm-005 | disable-target-actions-when-no-target | canEditTarget=false | "Rename", "Move", "File", "Delete" items are disabled; "Add" is enabled |
| cgm-006 | enable-add-always | canEditTarget=false, no target | "Add category…" is enabled and clickable |
| cgm-007 | render-separators | Menu opened | Two visual separators present: one after "Add", one before "Delete" |
| cgm-008 | invoke-callback-on-action | Click "Add category…" | onAction("add") is called |
| cgm-009 | invoke-callback-on-action | Click `Delete "Q3"…` with canEditTarget=true | onAction("delete") is called |
| cgm-010 | respect-disabled-prop | disabled=true | Trigger is visually disabled and does not open menu |
| cgm-011 | style-delete-destructive | Menu opened | "Delete" item uses the platform's destructive/error styling (e.g., red text via `text-apt-red` on web) |
| cgm-012 | align-to-end | Menu opened, LTR locale | Menu content aligns to the right edge of the trigger |
| cgm-013 | align-to-end | Menu opened, RTL locale | Menu content aligns to the left edge of the trigger (its trailing edge under RTL) |
| cgm-014 | render-trigger | noun="item" | Trigger displays "Item actions"; the "Add item…" item is present |

