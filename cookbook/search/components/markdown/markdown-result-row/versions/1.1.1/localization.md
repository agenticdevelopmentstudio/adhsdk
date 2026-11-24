
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `markdown-result-row.untitled` | Untitled | Fallback title when `hit.title` is null or empty |
| `markdown-result-row.author-prefix` | by | Prefix for author attribution |
| `markdown-result-row.updated-prefix` | · Updated | Separator + prefix before the formatted updated-at date |
| `markdown-result-row.view-paper-link` | View paper | Text label for the public link |

All other text (title, snippet, tags, category, author name) is sourced from the data object (`hit`) and not localized by the component. Localization of data content is the responsibility of the backend or indexing layer. The updated date's formatting locale (`en-US`) is currently hardcoded in `formatDate` rather than derived from the user's locale — see Compliance (`locale-aware-formatting`).

