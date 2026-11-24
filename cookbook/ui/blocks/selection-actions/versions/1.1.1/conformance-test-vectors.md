
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| selection-actions-001 | render-action-buttons | actions=[{id:"a1", label:"Archive"}] | Button with text "Archive" is rendered |
| selection-actions-002 | pass-selected-ids-on-action | actions=[{id:"a1", label:"Archive", onClick}], selectedIds=["row1","row2"], user clicks Archive | onClick is called with ["row1","row2"] |
| selection-actions-003 | disable-selection-required-actions | actions=[{id:"a1", label:"Archive", requiresSelection:true}], selectedIds=[] | Archive button is disabled (disabled attribute set) |
| selection-actions-004 | keep-standalone-actions-enabled | actions=[{id:"a1", label:"New", requiresSelection:false}], selectedIds=[] | New button is enabled and clickable |
| selection-actions-005 | use-ghost-variant-by-default | actions=[{id:"a1", label:"Archive"}] | Archive button uses the `ghost` variant |
| selection-actions-006 | render-divider-before-action | actions=[{id:"a1", label:"Archive", onClick, dividerBefore:true}] | A vertical separator element with role="separator" is rendered before the Archive button |
| selection-actions-007 | render-delete-button-conditionally | onDelete undefined | Delete button is not rendered |
| selection-actions-008 | render-delete-button-conditionally | onDelete provided | Delete button is rendered |
| selection-actions-009 | disable-delete-when-no-selection | onDelete provided, selectedIds=[] | Delete button is disabled |
| selection-actions-010 | disable-delete-when-no-selection | onDelete provided, selectedIds=["row1"] | Delete button is enabled |
| selection-actions-011 | use-destructive-ghost-delete-variant | onDelete provided | Delete button uses destructive-ghost variant |
| selection-actions-012 | include-trash-icon-on-delete | onDelete provided | Delete button contains Trash2 icon and text "Delete" |
| selection-actions-013 | delete-requires-confirmation, confirm-modal-destructive-style | onDelete provided, user clicks Delete | AlertModal appears with `destructive` set to `true` |
| selection-actions-014 | use-default-delete-message | onDelete provided, deleteConfirm undefined, user clicks Delete | Modal title is "Delete selected?" |
| selection-actions-015 | use-custom-delete-message | onDelete provided, deleteConfirm={title:"Remove items?"}, user clicks Delete | Modal title is "Remove items?" |
| selection-actions-016 | call-ondelete-only-after-confirm | onDelete provided, selectedIds=["row1"], user clicks Delete then confirms | onDelete is called with ["row1"] |
| selection-actions-017 | close-modal-on-cancel | onDelete provided, user clicks Delete then clicks Cancel | Modal closes, onDelete is not called |
| selection-actions-018 | divider-separator-role | actions=[{id:"a1", label:"Archive", onClick, dividerBefore:true}] | Divider has role="separator" and aria-orientation="vertical" |
| selection-actions-019 | confirm-button-label | onDelete provided, user clicks Delete | Confirmation modal's confirm button label is "Delete" |
| selection-actions-020 | cancel-button-label | onDelete provided, user clicks Delete | Confirmation modal's cancel button label is "Cancel" |
| selection-actions-021 | close-modal-on-confirm | onDelete provided, selectedIds=["row1"], user clicks Delete then confirms | Modal is closed immediately after confirming |
| selection-actions-022 | ondelete-selection-argument | onDelete provided, selectedIds=["row1"], user clicks Delete, selectedIds prop changes to ["row1","row2"] while the modal is open, user confirms | onDelete is called with ["row1","row2"], not ["row1"] |
| selection-actions-023 | duplicate-action-ids | actions=[{id:"a1", label:"Archive", onClickA}, {id:"a1", label:"Rename", onClickB}] | Both "Archive" and "Rename" buttons render and each invokes its own onClick; the shared id is a caller error the component does not correct |

