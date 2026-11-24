
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `preview.view-full` | "View full paper" | Label for public page link |
| `preview.by` | "by" | Preposition for author attribution |
| `preview.updated` | "Updated" | Prefix for update date (the "· " separator before it is part of the layout, not of this string) |
| `preview.summary` | "Summary:" | Label for summary section |
| `preview.untitled` | "Untitled" | Fallback title for missing title |

The source currently hardcodes each of these strings directly in the JSX rather than resolving them through a localization system — the table above describes the target localization contract, not the source's current implementation (see Compliance: string-externalization, no-hardcoded-strings). Date formatting is also not currently locale-aware: `formatDate` always uses the `en-US` locale (see Compliance: locale-aware-formatting).

