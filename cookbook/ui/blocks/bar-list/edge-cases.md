
- **Empty items**: `items=[]` renders only the empty label (default "Nothing to show.") and no list; the component MUST NOT throw on the empty maximum. See bl-018.
- **All values zero or below**: When the largest value is 0 or less, every bar is 0% wide. See bl-013.
- **Negative value**: The source does not clamp or validate values. A negative value gets a negative percentage width string (its value divided by the largest value, times 100) and no minimum width, and its value text shows the formatted negative number; when the largest value is 0 or less every bar is 0% (see `bar-zero-maximum`). The values are counts per the `formatCount` comment in the trend chart block, so a negative value is outside what the component is given.
- **Large and small values**: The 2px floor applies only when the percentage width computes to less than 2px of the track, so where it starts depends on the track width, which the source does not fix (on a 300px track, below about 0.67% of the maximum); a value of exactly zero gets no floor. See bl-014 and bl-015.
- **Duplicate names**: Rows are keyed by `name` and selection is matched by `name`, so two items with the same name share a React key and are both pressed together. The component MUST NOT be given duplicate names; the source does nothing to prevent it.
- **Selected name not in the list**: A non-null `selected` that matches no item leaves every row dimmed at 55% and none pressed. The component does not clear or validate it.
- **`maxItems` boundaries**: Equal to the item count shows every row and no button; `Infinity` never shows a button (see bl-002); 0 shows no rows and a "Show all N" button while items exist; a negative value is passed to a slice from the start, so it hides that many rows from the end and still shows the button.
- **Expanded then shrunk**: If the list is expanded and `items` later shrinks to `maxItems` or fewer, the button disappears but the expanded flag stays true, so a later growth reopens already expanded. See bl-022.
- **Empty detail string**: `detail=""` is shown as an empty value, not replaced by the formatted value, because only null or undefined fall back. See bl-010.
- **Very long name**: Wraps, breaking inside a word if needed; never truncated. See bl-003.
- **Concurrent access**: Not applicable: the component is a synchronous render of props with one local boolean, and holds no shared mutable state.
- **Error states and offline**: Not applicable: the component makes no network or storage calls; data and any failure to obtain it belong to the host.
- **Repeated activation**: Each activation of a row calls `onSelect` once; there is no debounce and the component never toggles the selection off itself, so the host decides what a second activation means. See bl-024.

