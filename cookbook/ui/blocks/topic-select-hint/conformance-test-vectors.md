
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| topic-select-hint-001 | render-card, render-icon, use-test-hook, use-fallback-headline | No props (defaults) | Renders Card with mouse-pointer icon, data-htd-select-hint attribute present, default headline "Select an item from the list to view or edit it here." |
| topic-select-hint-002 | accept-custom-title | `title="Custom headline"` | Headline renders as "Custom headline" exactly |
| topic-select-hint-003 | compute-headline-from-noun | `noun="workspace"` | Headline renders as "Select a workspace to view or edit it here." |
| topic-select-hint-004 | compute-headline-from-noun | `noun="item"` | Headline renders as "Select an item to view or edit it here." |
| topic-select-hint-005 | compute-headline-from-list-title, append-edit-suffix | `listTitle="Workspaces"` | Headline renders as "Select an item from Workspaces to view or edit it here." (the edit suffix applies to the listTitle-derived headline too) |
| topic-select-hint-006 | compute-headline-from-noun, compute-headline-from-list-title | `noun="workspace"` `listTitle="Workspaces"` | Headline renders as "Select a workspace to view or edit it here." (noun takes precedence) |
| topic-select-hint-007 | accept-custom-title | `title="Select a group"` `noun="workspace"` | Headline renders as "Select a group" (title takes precedence) |
| topic-select-hint-008 | render-children | `children="Choose one to begin editing."` | Description text is rendered below headline |
| topic-select-hint-009 | append-edit-suffix | `noun="site"` (no children) | Headline ends with " to view or edit it here." |
| topic-select-hint-010 | append-edit-suffix | `noun="site"` `children="Some description"` | Headline does NOT end with " to view or edit it here." |
| topic-select-hint-011 | hide-headline-when-not-selectable | `selectable={false}` | Headline is not rendered, only children (if provided) are shown |
| topic-select-hint-012 | hide-headline-when-not-selectable | `selectable={false}` (no children) | Card is rendered but both headline and description sections are hidden |
| topic-select-hint-013 | hide-children-when-not-provided | `children={undefined}` | No description section is rendered |
| topic-select-hint-014 | center-content | `noun="workspace"` | The outer container computes to `display: flex; flex-direction: column; align-items: center; justify-content: center;`, centering the Card both horizontally and vertically within it |
| topic-select-hint-015 | accept-custom-title, hide-headline-when-not-selectable | `title="Confirm delete"` `selectable={false}` | Headline still renders as "Confirm delete" — an explicit `title` takes precedence over `selectable` |
| topic-select-hint-016 | use-fallback-headline | `noun=""` | Headline renders as "Select an item from the list to view or edit it here." — an empty string is falsy in JS, so `noun` is treated as not provided |
| topic-select-hint-017 | use-fallback-headline | `listTitle=""` | Headline renders as "Select an item from the list to view or edit it here." — an empty string is falsy in JS, so `listTitle` is treated as not provided |
| topic-select-hint-018 | compute-headline-from-noun | `noun="hour"` | Headline renders as "Select a hour to view or edit it here." — the article rule tests only the first letter, not English pronunciation, so this is a known grammatical miss |

