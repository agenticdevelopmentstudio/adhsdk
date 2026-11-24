
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `markdown-result-row.untitled` | Untitled | Fallback title when `hit.title` is null or empty |
| `markdown-result-row.author` | by {name} | Author attribution; `{name}` is the display name or `@slug` |
| `markdown-result-row.updated` | Updated {date} | Updated-at label; `{date}` is the formatted date, and the leading "· " separator is layout, not part of the string |
| `markdown-result-row.view-paper-link` | View paper | Text label for the public link |

The source currently concatenates "by ", the name, " · Updated " and the date as separate literals; the placeholder templates above are the proposed contract so a translation controls word order. All other text (title, snippet, tags, category, author name) is sourced from the data object (`hit`) and not localized by the component. Localization of data content is the responsibility of the backend or indexing layer. The updated date's formatting locale (`en-US`) is currently hardcoded in `formatDate` rather than derived from the user's locale — see Compliance (`locale-aware-formatting`).

