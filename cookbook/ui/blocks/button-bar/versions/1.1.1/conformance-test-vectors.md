
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| button-bar-001 | render-toolbar-role | Render ButtonBar with default props | Element has `role="toolbar"` |
| button-bar-002 | toolbar-aria-label | Render ButtonBar with default props | Element has `aria-label="Editing actions"` |
| button-bar-003 | toolbar-aria-label | Render ButtonBar with `ariaLabel="Custom"` | Element has `aria-label="Custom"` |
| button-bar-004 | children-slot | Render with `children={<div>Custom</div>}` | Custom content appears inside toolbar; preset actions are not rendered |
| button-bar-005 | preset-actions-flow, create-button | Render with `actions={{ onCreate: fn, ... }}` and `showCreate={true}` and `actions.onCreate` is defined | Create button with a leading add icon and "New" label renders |
| button-bar-006 | create-button | Render with `actions={{ onCreate: fn, createLabel: "Add" }}` and `showCreate={true}` | Create button renders with label "Add" |
| button-bar-007 | create-button | Render with `showCreate={false}` | Create button does not render |
| button-bar-008 | delete-button | Render with `actions={{ onDelete: fn, ... }}` and `showDelete={true}` and `actions.onDelete` is defined | Delete button with a leading delete icon and "Delete" label renders in the Button component's `destructive-ghost` variant |
| button-bar-009 | delete-button | Render with `showDelete={false}` | Delete button does not render |
| button-bar-010 | cancel-button | Render with `actions={{ onCancel: fn, ... }}` | Cancel button with a leading cancel icon and "Cancel" label renders |
| button-bar-011 | save-button | Render with `actions={{ onSave: fn, ... }}` and `saving={false}` | Save button with a leading confirm icon and "Save" label renders |
| button-bar-012 | save-button | Render with `actions={{ onSave: fn, ... }}` and `saving={true}` | Save button with a leading confirm icon and "Saving…" label renders |
| button-bar-013 | disable-cancel-by-flag | Render with `actions={{ canCancel: false, ... }}` | Cancel button has `disabled` attribute |
| button-bar-014 | disable-cancel-by-flag | Render with `actions={{ canCancel: true, saving: true }}` | Cancel button has `disabled` attribute |
| button-bar-015 | disable-save-by-flag | Render with `actions={{ canSave: false, ... }}` | Save button has `disabled` attribute |
| button-bar-016 | disable-save-by-flag | Render with `actions={{ canSave: true, saving: true }}` | Save button has `disabled` attribute |
| button-bar-017 | disable-delete-by-flag | Render with `actions={{ canDelete: false, ... }}` | Delete button has `disabled` attribute |
| button-bar-018 | disable-delete-by-flag | Render with `actions={{ canDelete: true, saving: true }}` | Delete button has `disabled` attribute |
| button-bar-019 | create-not-disabled-while-saving | Render with `actions={{ onCreate: fn, saving: true }}` and `showCreate={true}` | Create button has no `disabled` attribute and remains clickable |
| button-bar-020 | save-disabled-styling | Render with `actions={{ canSave: false }}` | Save button renders in the Button component's `ghost` variant with the muted text token (`apt-text-muted`) applied |
| button-bar-021 | invoke-callbacks | User clicks Create button | `actions.onCreate()` is invoked |
| button-bar-022 | invoke-callbacks | User clicks Cancel button | `actions.onCancel()` is invoked |
| button-bar-023 | invoke-callbacks | User clicks Save button while `canSave={true}` and `saving={false}` | `actions.onSave()` is invoked |
| button-bar-024 | invoke-callbacks | User clicks Delete button | `actions.onDelete()` is invoked |
| button-bar-025 | invoke-callbacks | User clicks Save button while it is disabled (`canSave={false}`) | `actions.onSave()` is NOT invoked |
| button-bar-026 | leading-content | Render with `leading={<span>Title</span>}` | Leading content renders before action buttons |
| button-bar-027 | class-override | Render with `className="custom-class"` | Custom class is applied to the toolbar element alongside base classes |
| button-bar-028 | render-vertical-separator | Render with `actions={{ onCreate: fn, onDelete: fn, ... }}` and `showCreate={true}` | A vertical separator renders between the Create button and the Delete button |
| button-bar-029 | render-vertical-separator | Render with `showCreate={false}` (or `actions.onCreate` undefined) | No vertical separator renders |
| button-bar-030 | render-spacer | Render with `actions={{ onDelete: fn, ... }}` | A flexible spacer element renders between the Delete button and the Cancel/Save group and expands to fill available horizontal space |
| button-bar-031 | preset-actions-flow, children-slot | Render with neither `actions` nor `children` provided | Toolbar renders with `role="toolbar"` and no buttons or content, only its border/background/padding |

