
- **Rapid toggles**: If `toggleActive` is called multiple times in quick succession, each call MUST correctly flip the state and clear the selection; the final state MUST reflect the number of toggles applied.
- **resetKey as non-primitive**: If `resetKey` is an object or array (non-primitive) that is rebuilt each render, the selection MUST be cleared on every render even if the semantic value is unchanged, because `Object.is` compares reference identity, not deep equality.
- **selectedIds mutation**: If a caller mutates the returned `selectedIds` Set directly, the behavior is undefined. The contract requires that all updates go through `setSelectedIds`; direct mutation violates the contract.
- **Empty selection display**: When `selectedIds` is empty (size is 0), the button text and pressed state MUST still render correctly; there is no visual hiding or disabling of the button based on count.
- **Render-time reset vs effect**: The reset happens synchronously during render (not in an effect), so a commit with new `resetKey` will never execute pending actions with stale selection against new rows.

