
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| search-dialog-connected-001 | forwarded-props | SearchDialogConnectedProps with `open: true`, a custom `onClose` handler and `placeholder: "Find"` | SearchDialog receives `open`, `onClose` and `placeholder` with the same values and the same function reference for `onClose` |
| search-dialog-connected-002 | search-state | Content context provides a searchIndex containing an entry titled "Install" and the user types "install" | The rendered SearchDialog lists the "Install" entry, showing its state comes from that index |
| search-dialog-connected-003 | section-labels | useSiteConfig returns nav with three sections: {key: 'guides', label: 'Guides'}, {key: 'api', label: 'API Reference'}, {key: 'examples', label: 'Examples'} | sectionLabels prop passed to SearchDialog contains {'guides': 'Guides', 'api': 'API Reference', 'examples': 'Examples'} |
| search-dialog-connected-004 | select-navigates | User selects entry with slug 'my-page' and component has onClose prop | navigate('my-page') is called, then onClose() is called in sequence |
| search-dialog-connected-005 | renders-dialog | Component invoked with any valid SearchDialogConnectedProps | The rendered output is exactly the SearchDialog (`role="dialog"` root when `open: true`), with the section labels and selection behavior of the other vectors applied |
| search-dialog-connected-006 | section-labels | useSiteConfig returns nav with an empty sections array | sectionLabels passed to SearchDialog is {} and SearchDialog renders without error |
| search-dialog-connected-007 | section-labels | `nav.sections` contains two sections with the same `key`, labelled "First" then "Second" | The label for that key passed to SearchDialog is "Second" (the last entry wins) |
| search-dialog-connected-008 | select-navigates | `navigate` throws when the user selects an entry | The exception propagates and `onClose()` is not called |
