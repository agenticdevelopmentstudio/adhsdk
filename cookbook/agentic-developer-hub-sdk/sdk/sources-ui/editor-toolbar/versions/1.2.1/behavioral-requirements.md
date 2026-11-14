
- **mode-selector**: The component MUST render a segmented control displaying all modes in `availableModes`.
- **hide-mode-selector-single-mode**: The component MUST hide the segmented control when `availableModes` contains fewer than 2 entries.
- **empty-mode-list**: When `availableModes` is empty, the component MUST render the segmented control with zero segments and MUST hide it under **hide-mode-selector-single-mode**, with no segment selected. See Change History 1.1.0 for the source trace of this behavior.
- **help-button**: The component MUST render a help button labeled "?" by default.
- **help-button-visibility**: The component MUST respect the `showsHelpButton` property and hide the button when set to false.
- **import-button**: The component MUST render an import button labeled "Open…" by default.
- **import-button-visibility**: The component MUST respect the `showsImportButton` property and hide the button when set to false.
- **mode-change-callback**: The component MUST call `onModeChange` with the newly selected mode when the user taps a mode segment.
- **mode-change-callback-scope**: `onModeChange` MUST fire on any user tap that the platform control reports as its action — including a tap on the segment that is already selected, since the handler applies no equality check before firing — and MUST NOT fire when `mode` is set programmatically, since the `mode` property's `didSet` only re-syncs the control's selection (**sync-selection**) and never invokes the tap handler.
- **sync-selection**: The component MUST update the segmented control's selected segment when the `mode` property changes programmatically.
- **help-callback**: The component MUST call `onSyntaxHelpRequested` when the user taps the help button.
- **import-callback**: The component MUST call `onImport` when the user taps the import button.
- **theme-background**: The component MUST apply the `elevatedSurface` color from a `SemanticPalette` to its background when `applyTheme(_:)` is called.
- **theme-button-tint**: The component MUST apply the `accent` color from a `SemanticPalette` to the help and import buttons' tint color when `applyTheme(_:)` is called.

