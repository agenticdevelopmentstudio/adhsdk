
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| rename-001 | display-when-open | `open={true}`, `node={categoryNode}` | Dialog is visible |
| rename-002 | render-nothing-before-first-node | `open={false}`, `node={null}`, never previously non-null | Component renders nothing |
| rename-003 | prefill-current-name | `open={true}`, `node={categoryNode}` where `node.name="Inventory"` | Input field displays "Inventory" |
| rename-004 | require-non-empty-name | User clears the input and presses Enter (Confirm is disabled while empty) | Error message: "A category needs a name." |
| rename-005 | reject-unchanged-name | Input shows original name "Inventory", user clicks Confirm | Dialog closes without calling `onRename` |
| rename-006 | validate-duplicate-names | Input: "Armory", `nodes` includes node with `name="Armory"` (different id) | Error: `There is already a category called “Armory”.` (curly quotes) |
| rename-007 | validate-extra-names | Input: "Taken", `extraNames=["Taken"]` | Error: `There is already a category called “Taken”.` (curly quotes) |
| rename-008 | accept-enter-key | Input focused with text "NewName", user presses Enter | `onRename` is called (validation passes) |
| rename-009 | show-loading-state | `onRename` is async and pending | Input is disabled; Cancel and Confirm are replaced by a `role="status"` loading indicator |
| rename-010 | clear-error-on-input | Error displayed, user types in input | Error message is cleared |
| rename-011 | call-onrename | User enters valid name "NewCategory" and submits | `onRename(node, "NewCategory")` is called |
| rename-012 | handle-async-rename | `onRename` returns rejected promise | Dialog remains open; error message displays rejection reason |
| rename-013 | call-onrenamed | Rename succeeds | `onRenamed(node, newName)` is called |
| rename-014 | call-onclose-after-success | Rename succeeds | `onClose()` is called |
| rename-015 | prevent-close-while-busy | User presses Escape while `busy={true}` | Dialog remains open |
| rename-016 | disable-confirm-when-empty | Input value is "" (`node.name=""`, or the user cleared the field) | Confirm button is disabled |
| rename-017 | show-error-text | Validation fails | Error text component displays error message |
| rename-018 | require-non-empty-name | Input is whitespace only ("   "), user presses Enter | Trimmed to ""; error message: "A category needs a name." |
| rename-019 | handle-async-rename | `onRename` rejects with a non-`Error` value (e.g., a plain string) | Error message: "Could not rename the category."; dialog remains open |
| rename-020 | prevent-close-while-busy | `busy={true}` | `DialogActions` renders only a loading spinner; Cancel and Confirm buttons are not present to click |
| rename-021 | prevent-close-while-busy | User clicks the dialog backdrop, both while `busy={false}` and while `busy={true}` | `onOpenChange` never fires from the backdrop press in either case (pointer-based outside dismissal is disabled unconditionally); `onClose()` is not called; dialog remains open |
| rename-022 | reject-unchanged-name | Input "INVENTORY" when `node.name` is "inventory" | `onRename(node, "INVENTORY")` is called — a case-only change is not treated as unchanged |
| rename-023 | prefill-current-name | Dialog closes with edited (unsaved) text present; host later reopens it with a different `node` | Input displays the new node's name, not the previous session's edited text |
| rename-024 | prevent-close-while-busy | User presses Escape while `busy={false}` | `onClose()` is called |
| rename-025 | call-onclose-after-success | User clicks Cancel while `busy={false}` | `onClose()` is called; `onRename` is not called |
| rename-026 | prefill-current-name | Dialog opens | The input has focus |
| rename-027 | validate-extra-names | `extraNames` contains the original name "Inventory"; input is "Inventory" | `onRename` is not called and no duplicate error shows; the dialog closes per **reject-unchanged-name** |
| rename-028 | clear-error-on-open | Dialog closes with an error showing, then reopens | No error message is shown after reopening |
| rename-029 | hold-node-while-closing | `node` reverts to `null` after having been non-null | The dialog keeps rendering the last node until the exit animation completes |
