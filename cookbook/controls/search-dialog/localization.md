
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| aria-label | `"Search"` | Accessible label for the input field. |
| placeholder | `"Search documentation..."` | Default placeholder text in input field; can be overridden by `placeholder` prop. |
| empty-state | `No results for “{query}”` | Message shown when user has typed a query but no results are found. Includes user-entered query string. |
| escape-hint | `"Esc"` | Text displayed in keyboard hint showing how to close the dialog. |

Each string value is hardcoded in the component. To support multiple languages, accept a `strings` (or `labels`) prop mapping each key above to its localized text at the call site, rather than forking the component.

