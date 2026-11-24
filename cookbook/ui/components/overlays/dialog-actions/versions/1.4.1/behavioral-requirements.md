
- **render-confirm**: The component MUST always render a confirm button labeled with `confirmLabel` that invokes `onConfirm` when activated.
- **render-cancel-when-labeled**: The component MUST render a cancel button that invokes `onCancel` when `cancelLabel` is provided, and MUST omit the cancel button entirely when `cancelLabel` is absent.
- **equal-width-when-narrow**: In `auto` layout with two buttons, when the container is too narrow for both at their natural width, the component MUST give each button up to an equal share of the row, capped at its own natural width, with any share a button doesn't use falling to the other button.
- **natural-width-when-wide**: In `auto` layout with two buttons, when the container has room for both at their natural width, the component MUST hold each at that width and right-justify the row.
- **cap-growth-at-natural-width**: In `auto` layout, no button may be stretched past its own natural width; the space a button declines MUST fall to the other button if it needs it, and otherwise to the left of the row.
- **settle-before-interactive**: The component MUST present its final button geometry on the first frame it paints. It MUST NOT move or resize a button after mount as a result of deciding its own layout — a button that shifts while the dialog is already clickable can swallow the click that was aimed at it.
- **follow-the-container**: The layout MUST be derived from the container's own width, not the viewport's, and MUST re-resolve when the container's width changes.
- **honor-forced-layout**: When `layout` is `equal` or `natural`, the component MUST use that layout regardless of the container's width.
- **focus-initial-on-mount**: When `focusOnMount` is true, the component MUST move focus on mount to the button named by `initialFocus`.
- **default-focus-to-safe-button**: When `initialFocus` is unset, the component MUST default initial focus to the confirm button normally and to the cancel button when `destructive` is true.
- **suppress-focus-on-mount**: When `focusOnMount` is false, the component MUST NOT move focus on mount, leaving the host to place focus.
- **focus-fallback-to-other-button**: When the button named by `initialFocus` is disabled or absent at mount, the component MUST move initial focus to the other button instead; when both are disabled or absent, it MUST leave focus untouched rather than forcing it.
- **quiet-ring-for-destructive-cancel**: When `initialFocus` resolves to `"cancel"`, the cancel button's focus-visible ring MUST use the `--apt-text` token rather than the default accent ring.
- **style-confirm-destructive**: When `destructive` is true, the confirm button MUST render with the destructive variant.
- **show-busy-indicator**: When `busy` is true, the component MUST replace the buttons with a status spinner exposing an accessible working label, MUST ignore `confirmDisabled`, and MUST NOT invoke `onConfirm` or `onCancel`.
- **apply-confirm-disabled**: When `confirmDisabled` is true and `busy` is false, the confirm button MUST be disabled and MUST NOT invoke `onConfirm` when activated.

