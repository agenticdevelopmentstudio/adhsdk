
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-view-001 | layout-toggle-visible-on-wide-viewport | Wide viewport (≥64rem) | Layout toggle group renders with tabbed and split options |
| split-view-002 | layout-toggle-hidden-on-narrow-viewport | Narrow viewport (<64rem) | Layout toggle group does not render |
| split-view-003 | separator-between-toggles-in-tabbed-mode | Wide viewport, effective layout tabbed | Vertical separator (1px, bg-apt-border) renders between layout and pane toggles |
| split-view-004 | separator-between-toggles-in-tabbed-mode | Wide viewport, effective layout split | Separator does not render |
| split-view-005 | pane-toggle-visible-only-in-tabbed-layout | Effective layout tabbed | Pane toggle group renders with edit and preview options |
| split-view-006 | pane-toggle-visible-only-in-tabbed-layout | Effective layout split | Pane toggle group does not render |
| split-view-007 | layout-preference-persists-across-viewport-changes | User selects split layout on wide viewport, then resize to narrow (<64rem), then resize back to wide (≥64rem) | Layout preference is "split" before narrow, remains "split" during narrow (though effective is "tabbed"), and effective becomes "split" again when widening |
| split-view-008 | effective-layout-demoted-on-narrow-viewport | Viewport narrower than 64rem, layout preference is "split" | Effective layout is "tabbed" |
| split-view-009 | edit-label-customizable | Render with `editLabel="Author"` | Edit toggle label reads "Author" instead of default "Edit" |
| split-view-010 | preview-label-customizable | Render with `previewLabel="Published"` | Preview toggle label reads "Published" instead of default "Preview" |
| split-view-011 | flex-row-layout | Render control in any state | Control renders as a flex row (`flex items-center gap-3`) with center vertical alignment and exactly 0.75rem (`gap-3`) horizontal spacing between children |
| split-view-012 | empty-toggle-selection-ignored | Layout toggle shows "split" selected; user clicks the "split" button again | Selection remains "split", no state change triggered |
| split-view-013 | layout-toggle-group-aria-label | Render with `subject="Editor"` | Layout toggle group has `aria-label="Editor layout"` |
| split-view-014 | pane-toggle-group-aria-label | Render with `subject="Document"` | Pane toggle group has `aria-label="Document pane"` |
| split-view-015 | pane-toggle-aria-controls-container | Render control | Each pane toggle item has `aria-controls` attribute matching the `panesId` from the view state |
| split-view-016 | layout-toggle-item-accessible-names | Render layout toggle on wide viewport | Tabbed toggle has `title="Single tabbed view"` and `aria-label="Single tabbed view"`; split toggle has `title="Side by side view"` and `aria-label="Side by side view"` |
| split-view-017 | tabbed-icon-is-square | Render layout toggle on wide viewport | Tabbed toggle item renders with Square icon |
| split-view-018 | split-icon-is-columns2 | Render layout toggle on wide viewport | Split toggle item renders with Columns2 icon |
| split-view-019 | edit-icon-is-pencil | Render pane toggle in tabbed mode | Edit toggle item renders with Pencil icon before label |
| split-view-020 | preview-icon-is-eye | Render pane toggle in tabbed mode | Preview toggle item renders with Eye icon before label |
| split-view-021 | layout-toggle-visible-on-wide-viewport | Viewport exactly 64rem (the `min-width: 64rem` boundary) | Layout toggle group renders (the ≥ threshold includes the boundary) |

