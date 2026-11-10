
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| toolbar-001 | mode-selector | availableModes = [.edit, .preview, .split] | Segmented control visible with three segments labeled "Edit", "Preview", "Split" |
| toolbar-002 | hide-mode-selector-single-mode | availableModes = [.split] | Segmented control hidden |
| toolbar-003 | empty-mode-list | availableModes = [] | Segmented control built with zero segments, hidden, no segment selected |
| toolbar-004 | help-button | No special config | Help button ("?") visible |
| toolbar-005 | help-button-visibility | showsHelpButton = false | Help button hidden |
| toolbar-006 | help-button-visibility | showsHelpButton toggled false then true | Help button hidden, then visible again |
| toolbar-007 | import-button | No special config | Import button ("Open…") visible |
| toolbar-008 | import-button-visibility | showsImportButton = false | Import button hidden |
| toolbar-009 | import-button-visibility | showsImportButton toggled false then true | Import button hidden, then visible again |
| toolbar-010 | mode-change-callback | User taps a mode segment other than the selected one | onModeChange callback fired with the new mode |
| toolbar-011 | mode-change-callback-scope | User taps the already-selected mode segment | onModeChange callback fires again with the same mode |
| toolbar-012 | mode-change-callback-scope | mode = .preview set programmatically | onModeChange callback does not fire |
| toolbar-013 | sync-selection | mode = .split (programmatically) | Segmented control's selected segment updates to match |
| toolbar-014 | sync-selection | mode set to a value not present in availableModes | Segmented control's selected segment becomes no-segment (iOS `UISegmentedControl.noSegment` / macOS -1); no segment appears selected |
| toolbar-015 | help-callback | User taps help button | onSyntaxHelpRequested callback fired |
| toolbar-016 | import-callback | User taps import button | onImport callback fired |
| toolbar-017 | theme-background | applyTheme(palette) called | Background color matches palette.elevatedSurface |
| toolbar-018 | theme-button-tint | applyTheme(palette) called (iOS) | Help and import button tint colors match palette.accent |
| toolbar-019 | mode-selector | macOS, default config | Mode control's accessibility label is "Editor Mode" and accessibility identifier is "markdown-editor.mode" |
| toolbar-020 | help-button | macOS, default config | Help button's accessibility label is "Markdown Syntax Help" and accessibility identifier is "markdown-editor.help" |
| toolbar-021 | import-button | macOS, default config | Import button's accessibility label is "Open Markdown File" and accessibility identifier is "markdown-editor.import" |
| toolbar-022 | sync-selection | User changes the mode control's selection | The new selection is announced to assistive technology |

