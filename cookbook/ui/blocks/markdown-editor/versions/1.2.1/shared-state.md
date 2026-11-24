
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| markdown source | consumer (`value`) | Textarea | down | controlled `value` prop |
| edits | Textarea | consumer (`onChange`) | up | `onChange(next: string)` |
| uploaded file | upload control | consumer (`onUpload`) | up | `onUpload(text, fileName)` — caller sets body + title |
| textarea id | `useId()` (internal) | Label `htmlFor` ↔ Textarea `id` | internal | generated once per instance |
| popover open/closed | MarkdownQuickReference (internal) | — | internal | the shared Popover's own state |

