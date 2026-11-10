
- **trigger-opens-surface**: Activating the trigger (click, Enter, or Space) MUST open the popover.
- **opens-with-field-focused**: On open, the filter/add field MUST receive focus so the user can type immediately.
- **type-narrows-list**: Typing in the field MUST narrow the list to items whose label contains the typed text as a case-insensitive substring.
- **arrow-roves-highlight**: ArrowDown / ArrowUp MUST move a roving highlight through the filtered list (and the create row when present). From no highlight, ArrowDown enters at the first row and ArrowUp enters at the last row; once a row is highlighted, ArrowUp at the first row and ArrowDown at the last row hold in place — no wrap between rows.
- **highlight-syncs-into-field**: While a list item is highlighted, the field MUST display that item's label (the highlight is previewed in the field); typing again replaces the preview with the typed text and clears the highlight.
- **enter-accepts-highlighted-item**: When a list item is highlighted, Enter MUST accept it via `onChange` with `isNew:false`, then close.
- **enter-accepts-typed-entry**: When nothing is highlighted, the trimmed text is non-empty and has no exact case-insensitive label match, and `allowCreate` is set, Enter MUST accept the trimmed text via `onChange` with `isNew:true`, then close.
- **typed-text-resolves-to-exact-item**: When nothing is highlighted and the trimmed text equals an item label (case-insensitive), accept MUST resolve to that item with `isNew:false`, never a new entry.
- **create-unavailable-when-disabled**: When `allowCreate` is false, text matching no item MUST NOT be acceptable — no create row, OK disabled, Enter a no-op.
- **escape-cancels**: Esc MUST close the surface without firing `onChange`.
- **ok-mirrors-enter**: The OK button MUST be equivalent to Enter and MUST be disabled whenever nothing is acceptable.
- **cancel-mirrors-escape**: The Cancel button MUST be equivalent to Esc.
- **pointer-click-commits**: A pointer click on a list row (or the create row) MUST accept it immediately and close.
- **focus-returns-on-close**: On any close, focus MUST return to the trigger.
- **empty-message-when-no-match**: When no item matches and creation is unavailable, the list MUST show the empty message.
- **shift-enter-dismiss-in-keep-open-mode**: When `keepOpenOnCommit` is true, Shift+Enter MUST close the popover; plain Enter still accepts and keeps the popup open.
- **focused-state-styling**: The trigger MUST show a visible focus indicator meeting WCAG 2.4.7 (Focus Visible) — a 2px focus ring distinct from the unfocused border — in addition to the platform-native focus ring where the host platform provides one.

