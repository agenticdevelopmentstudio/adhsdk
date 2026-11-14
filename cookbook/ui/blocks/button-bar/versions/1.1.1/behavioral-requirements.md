
- **render-toolbar-role**: Component MUST render with `role="toolbar"`.
- **toolbar-aria-label**: Component MUST accept and render an `ariaLabel` prop; the default MUST be `"Editing actions"`.
- **children-slot**: Component MUST accept a `children` prop to render arbitrary custom content, which takes precedence over preset actions.
- **preset-actions-flow**: When `children` is not provided and `actions` is provided, the component MUST render the preset editing action flow.
- **create-button**: When rendering preset actions and `showCreate` is `true` and `actions.onCreate` is provided, the component MUST render a button with a leading add icon and a label (default `"New"`, or `actions.createLabel` if provided).
- **delete-button**: When rendering preset actions and `showDelete` is `true` and `actions.onDelete` is provided, the component MUST render a button in the Button component's `destructive-ghost` variant with a leading delete icon and the label `"Delete"`.
- **cancel-button**: When rendering preset actions and `actions` is provided, the component MUST render a button with a leading cancel icon and the label `"Cancel"`.
- **save-button**: When rendering preset actions and `actions` is provided, the component MUST render a button with a leading confirm icon and the label `"Save"` or `"Saving…"` when `actions.saving` is `true`.
- **disable-cancel-by-flag**: The Cancel button MUST be disabled when `actions.canCancel` is `false` or `actions.saving` is `true`. `canCancel` is a required field of `actions` (see Configuration); there is no omitted-value case for it.
- **disable-save-by-flag**: The Save button MUST be disabled when `actions.canSave` is `false` or `actions.saving` is `true`. `canSave` is a required field of `actions` (see Configuration); there is no omitted-value case for it.
- **disable-delete-by-flag**: The Delete button MUST be disabled when `actions.canDelete` is `false` or `actions.saving` is `true`.
- **create-not-disabled-while-saving**: Unlike Delete, Cancel, and Save, the Create button does not receive a `disabled` attribute when `actions.saving` is `true` — it stays enabled and clickable through a save.
- **save-disabled-styling**: When the Save button is disabled, the component MUST switch it to the Button component's `ghost` variant and apply the muted text token (`apt-text-muted`).
- **render-vertical-separator**: When rendering preset actions and a Create button is present, the component MUST render a vertical separator (visual divider, marked `aria-hidden`) between Create and Delete/Cancel buttons.
- **render-spacer**: When rendering preset actions, the component MUST render a flexible spacer between Delete and Save/Cancel groups that expands to fill available horizontal space.
- **leading-content**: Component MUST accept a `leading` prop to render content before the action buttons or children.
- **class-override**: Component MUST accept a `className` prop that is merged with the base styling.
- **invoke-callbacks**: The component MUST invoke `actions.onCreate()`, `actions.onCancel()`, `actions.onSave()`, or `actions.onDelete()` when the respective button is clicked, and MUST NOT invoke a callback while its button is disabled.

