
- **display-when-open**: Component MUST display a modal dialog when `open` is `true`.
- **render-nothing-when-closed**: Component MUST render `null` when the `node` prop is `null` and has never previously been non-null. Once a non-null `node` has been supplied, the component keeps rendering with the last-held value (via `useLastPresent`) even after `node` reverts to `null`, so the exit animation can complete before unmounting.
- **prefill-current-name**: Component MUST pre-fill the input field with the current node's name when the dialog opens (i.e., when `open` becomes `true` with a non-null `node`); the input is not re-seeded on any other `node` change.
- **require-non-empty-name**: Component MUST reject submission if the trimmed input is an empty string, displaying the error message: `A ${noun} needs a name.`
- **reject-unchanged-name**: Component MUST close without calling `onRename` if the trimmed input matches the original node name using a case-sensitive comparison after trim. A case-only change (e.g., "Inventory" → "INVENTORY") is not considered unchanged and proceeds to validation.
- **validate-duplicate-names**: Component MUST reject submission if the trimmed input name matches any existing node name (case-insensitive), excluding the node being renamed, displaying the error message: `There is already a ${noun} called "${name}".`
- **validate-extra-names**: Component MUST check the `extraNames` array for duplicates (case-insensitive) and reject submission if a match is found, excluding the original node's own name from the `extraNames` check (that exclusion is also compared case-insensitively).
- **accept-enter-key**: Component MUST trigger submission when the user presses Enter within the text input field.
- **show-loading-state**: Component MUST set `disabled={true}` on the input and show a loading state in the confirm button while `onRename` is executing.
- **clear-error-on-input**: Component MUST clear any error message when the user modifies the input text.
- **call-onrename**: Component MUST call `onRename(node, trimmedName)` with the trimmed input after all validation passes.
- **handle-async-rename**: Component MUST support async `onRename` (returns `Promise<void>`), display the error message if the promise rejects, and keep the dialog open on error.
- **call-onrenamed**: Component MUST call `onRenamed(node, trimmedName)` after a successful rename.
- **call-onclose-after-success**: Component MUST call `onClose()` after a successful rename.
- **prevent-close-while-busy**: Component MUST not close the dialog (via the close (`×`) affordance or the Escape key) if a rename operation is in progress (`busy === true`). A backdrop click never closes the dialog at all, regardless of `busy` — the shared `Dialog` primitive disables pointer-based outside dismissal unconditionally.
- **disable-confirm-when-empty**: Component MUST set `disabled={true}` on the confirm button when the trimmed input is an empty string; the confirm button is not otherwise disabled while a validation or operation error is showing.
- **show-error-text**: Component MUST display validation and operation error messages in an error text component.

