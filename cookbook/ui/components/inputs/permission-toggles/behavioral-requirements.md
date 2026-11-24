
- **render-four-buttons**: The component MUST render exactly four toggle buttons, one for each CRUD capability (Create, Read, Update, Delete).
- **enforce-parent-ceiling**: When a `parent` Crud value is provided, the component MUST prevent toggling any capability the parent disallows: the corresponding button MUST be rendered in a disabled state and MUST be visually suppressed (reduced opacity, `not-allowed` cursor), regardless of what `value` holds for that capability.
- **blocked-toggle-no-op**: Clicking a parent-blocked button MUST be a no-op: `onChange` MUST NOT be called for it and the capability MUST NOT be inverted.
- **pass-through-other-keys**: When a toggle emits, every capability other than the one toggled MUST pass through from `value` unchanged, even if it already violates `parent` (set before mount, or never corrected). The component does not retroactively clamp the rest of the object on every emit (see edge case "Value violates parent constraint before mount").
- **parent-optional**: When `parent` is omitted, every capability MUST be treated as unrestricted.
- **disabled-blocks-toggle**: When the `disabled` prop is true, toggling any button MUST have no effect and `onChange` MUST NOT be called.
- **toggle-on-click**: Clicking an enabled, unblocked button MUST invert the corresponding capability in the Crud value.
- **aria-pressed-reflects-on**: Each button MUST have an `aria-pressed` attribute that reflects the button's displayed `on` state (`value[key] && !blockedByParent`), not the raw `value[key]`. A capability blocked by the parent therefore reports `aria-pressed="false"` even when `value[key]` is `true`.
- **title-describes-action**: Each button MUST have a `title` attribute describing its action, built from the capability's raw key — `create`, `read`, `update`, or `delete` — never the single-letter label. When blocked by parent, the title MUST read "\<key\> is not permitted by the parent" (e.g. "create is not permitted by the parent"). When not blocked, the title MUST read "Enable \<key\>" or "Disable \<key\>" (e.g. "Enable create", "Disable read") based on current state.
- **group-role-and-label**: The container MUST have `role="group"` and `aria-label="CRUD permissions"` to announce the collection as a unified control group.
- **single-letter-labels**: Each button MUST display the single-letter label for its capability: C for Create, R for Read, U for Update, D for Delete.

