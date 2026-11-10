
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| search-dialog-connected-001 | forwarded-props | SearchDialogConnectedProps with custom onClose handler | Component renders SearchDialog with all forwarded props intact |
| search-dialog-connected-002 | search-state | Content context provides searchIndex | useSearchState is called with searchIndex and result is passed to SearchDialog as state prop |
| search-dialog-connected-003 | section-labels | useSiteConfig returns nav with three sections: {key: 'guides', label: 'Guides'}, {key: 'api', label: 'API Reference'}, {key: 'examples', label: 'Examples'} | sectionLabels prop passed to SearchDialog contains {'guides': 'Guides', 'api': 'API Reference', 'examples': 'Examples'} |
| search-dialog-connected-004 | select-navigates | User selects entry with slug 'my-page' and component has onClose prop | navigate('my-page') is called, then onClose() is called in sequence |
| search-dialog-connected-005 | renders-dialog | Component invoked with any valid SearchDialogConnectedProps | SearchDialog is the component's sole rendered output, receiving computed state, sectionLabels, and the selection handler together with the forwarded props |
| search-dialog-connected-006 | section-labels | useSiteConfig returns nav with an empty sections array | sectionLabels passed to SearchDialog is {} and SearchDialog renders without error |

