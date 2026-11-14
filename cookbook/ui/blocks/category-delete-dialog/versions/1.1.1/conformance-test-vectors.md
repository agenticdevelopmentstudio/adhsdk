
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| category-delete-001 | renders-dialog-when-open | `open={true}`, `node={mockNode}` | Dialog modal appears on screen |
| category-delete-002 | renders-nothing-before-first-node | `open={true}`, `node={null}`, no prior non-null node | Component returns `null`; nothing rendered |
| category-delete-003 | shows-category-name-in-title | `node={{ name: "Projects" }}` | Dialog title shows `Delete "Projects"?` |
| category-delete-004 | shows-main-explanation | `itemNoun="notes"` | Description includes "This deletes the category only. Any notes filed under it are not deleted — they become uncategorized." |
| category-delete-005 | shows-orphaned-names-when-present | `orphanedNames={["Archived", "Draft"]}` | Description includes "Archived, Draft" as a bold string |
| category-delete-006 | pluralizes-orphaned-message | `orphanedNames={["Archive"]}` (length 1) | Message reads "This subcategory is filed nowhere else, so it is deleted too:" |
| category-delete-007 | pluralizes-orphaned-message | `orphanedNames={["Archive", "Draft"]}` (length > 1) | Message reads "These subcategories are filed nowhere else, so they are deleted too:" |
| category-delete-008 | shows-error-when-present | `error="Network error"` | Error text "Network error" appears in the description |
| category-delete-009 | disables-actions-while-busy | `busy={true}` | Delete and Cancel buttons are replaced by a loading indicator; the close affordance is hidden; Escape and a backdrop click never call `onConfirm`/`onCancel` (they don't dismiss regardless of `busy`) |
| category-delete-010 | calls-onconfirm-on-delete | User clicks "Delete" button | `onConfirm()` callback is invoked |
| category-delete-011 | calls-oncancel-on-cancel | User clicks "Cancel" button | `onCancel()` callback is invoked |
| category-delete-012 | retains-node-name-during-transition | Host sets `node={null}` after previously supplying a non-null node | Title and description still show the previous node's name |
| category-delete-013 | uses-error-tone-styling | Default render | Dialog renders with error-tone icon/accent |
| category-delete-014 | marks-as-destructive | Default render | Delete button renders with the destructive visual variant |
| category-delete-015 | role | Default render | Dialog element has `role="dialog"` and `aria-modal="true"` |
| category-delete-016 | shows-error-when-present | `error=""` (empty string) | No error text is rendered |
| category-delete-017 | shows-orphaned-names-when-present | `orphanedNames={[]}` (default) | No orphaned-names block is rendered |
| category-delete-018 | shows-orphaned-items-note | `orphanedNames={["Archive"]}`, `itemNoun="notes"` | Description includes "Their notes become uncategorized as well." |
| category-delete-019 | calls-oncancel-on-close-affordance | `busy={false}`, user clicks the close (`×`) affordance | `onCancel()` callback is invoked |
| category-delete-020 | ignores-escape-when-destructive | User presses Escape | Neither `onConfirm` nor `onCancel` is called; dialog remains open |
| category-delete-021 | bolds-destructive-emphasis | `orphanedNames={["Archive"]}` | "are not deleted" and "Archive" render inside bold elements |
| category-delete-022 | shows-error-when-present | `error={null}` (default) | No error text is rendered |
| category-delete-023 | shows-orphaned-names-when-present | `orphanedNames={["Archive", "Draft", "Notes"]}` | Description includes "Archive, Draft, Notes" with no truncation or ellipsis |
| category-delete-024 | retains-node-name-during-transition | Host sets `open={false}` while a node is retained | Component invokes neither `onConfirm` nor `onCancel`; retained node's name still shown during the dismissal transition |
| category-delete-025 | (edge case: very long names) | `node={{ name: "A".repeat(300) }}` | Full name is rendered unmodified; no truncation logic runs |

