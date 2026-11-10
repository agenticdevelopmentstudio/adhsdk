
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mtpane-001 | initialize-with-editability | `MarkdownTextPane(editable: true)` | Pane is created and text editing is enabled |
| mtpane-002 | initialize-with-editability | `MarkdownTextPane(editable: false)` | Pane is created and text editing is disabled |
| mtpane-003 | provide-editability-property | Set `pane.isEditable = true` on a read-only pane | Text editing becomes enabled; user can edit |
| mtpane-004 | provide-editability-property | Set `pane.isEditable = false` on an editable pane | Text editing becomes disabled; user cannot edit |
| mtpane-005 | report-text-changes | User types "Hello" into an editable pane | `onTextChange` is called with "Hello" |
| mtpane-006 | silent-programmatic-set | Set `pane.text = "Programmatic"` directly | `onTextChange` is not called |
| mtpane-007 | provide-text-property | Set `pane.text = "Sample text"` then read `pane.text` | Returns "Sample text" exactly |
| mtpane-008 | provide-text-property | Create pane without setting text, read `pane.text` | Returns empty string "" (not nil) |
| mtpane-009 | support-attributed-text | Set `pane.setAttributedText(styled)` where styled includes bold/italic attributes | Read `pane.attributedText` returns the styled text with attributes preserved |
| mtpane-010 | support-focus | Call `pane.focus()` on an onscreen pane | Returns true; keyboard focus moves to text view; user keystrokes are received |
| mtpane-011 | support-focus | Call `pane.focus()` on a pane without a window | Returns false; no focus change occurs |
| mtpane-012 | support-theme | Call `applyTheme(palette)` with a palette defining windowBackground, primaryText, cursor, selection, selectionText, and code font | Text view background, text color, insertion point color, selection highlight colors, and font are updated |
| mtpane-013 | disable-smart-substitutions-ios | On iOS, user types a quote character | No smart quote substitution occurs |
| mtpane-014 | disable-smart-substitutions-ios | On iOS, user types two hyphens | No smart dash substitution occurs |
| mtpane-015 | disable-smart-substitutions-macos | On macOS, user types a quote character | No smart quote substitution occurs |
| mtpane-016 | allow-undo-macos | On macOS, user edits text then presses Cmd+Z | Text reverts to prior state; undo is available |
| mtpane-017 | use-plain-text-mode | Paste rich formatted text into the pane | Text is pasted as plain text; formatting is stripped |
| mtpane-018 | scroll-vertically | Pane contains content taller than its bounds | Vertical scrolling is available to reveal off-screen content |
| mtpane-019 | hide-scrollers-macos | On macOS, scroll a large document and then remain still | Scroll indicator appears momentarily and then auto-hides |
| mtpane-020 | bounce-vertically-ios | On iOS, scroll vertically past content end | Text view bounces back to content boundary |
| mtpane-021 | use-8pt-insets | Inspect `textView.textContainerInset` | Equals `NSSize(width: 8, height: 8)` on macOS and `UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)` on iOS |
| mtpane-022 | enable-find-bar-macos | On macOS, press Cmd+F while the pane is focused | The text view's find bar opens for in-pane search |
| mtpane-023 | preserve-default-undo-ios | On iOS, edit text then invoke the system undo (e.g. shake gesture, or Cmd+Z with a hardware keyboard) | Text reverts to the prior state; the pane does not intercept or disable the system `undoManager` |
| mtpane-024 | disable-smart-substitutions-macos | On macOS, user types two hyphens | No smart dash substitution occurs |
| mtpane-025 | disable-smart-substitutions-macos | On macOS, user types a misspelled word | No automatic spelling correction is applied |
| mtpane-026 | disable-smart-substitutions-macos | On macOS, user types a recognized text-replacement shortcut | No automatic text replacement occurs |

