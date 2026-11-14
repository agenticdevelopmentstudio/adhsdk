
- **full-width-single-action**: With one button, the action button MUST be full width of the content area and gold (`Button variant="default"`).
- **equal-width-when-narrow**: With two buttons, when the row is too narrow for both buttons at their natural width, the underlying `DialogActions` default `auto` layout MUST give each button up to an equal share of the row, capped at its own natural width (`flex-1 max-w-max`), with any share a button doesn't use falling to the other button — yielding an equal-width `[ Cancel ][ OK ]` split, Cancel `ghost`/`outline` and OK gold, only when neither button's natural width exceeds that share.
- **natural-width-when-wide**: Once the row has room for both buttons at their natural width, the buttons MUST render at natural width and right-justify (`justify-end`), Cancel then OK; no button is ever stretched past its own natural width.
- **order-cancel-then-action**: The order MUST always be Cancel (left) then the action (right).
- **keyboard-default**: Under `keyboard:"default"`, Escape MUST dismiss via cancel if a cancel button exists (else via the single action), and Enter MUST activate the action.
- **keyboard-none**: Under `keyboard:"none"`, the modal MUST honor no keyboard shortcuts and be dismissable only by clicking a button (or the close affordance if shown).
- **keyboard-explicit-map**: Under an explicit key→action map, non-Escape keys MUST act only if listed, mapped to the named button (a key mapped to a button that is not present MUST be ignored). Escape MUST additionally always dismiss via cancel if a cancel button exists (else via the single action) whenever the keyboard policy is not `"none"`, regardless of whether Escape is listed in the map or mapped to a different action — see Edge Cases.
- **destructive-forces-none**: When `destructive` is true, the action button MUST render red (`apt-red`) and the keyboard policy MUST be forced to `"none"` regardless of `keyboard`.
- **block-dismissal-when-busy**: When `busy` is true, the component MUST block dismissal and replace the buttons with a spinner.
- **be-accessible-dialog**: The surface MUST be `role="dialog"` with `aria-modal`, labelled by the title and described by the body; initial focus MUST be the action button under `"default"` (the first field for composed form dialogs); focus MUST be trapped while open and restored to the opener on close.

