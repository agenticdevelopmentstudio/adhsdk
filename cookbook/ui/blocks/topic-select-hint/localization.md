
TopicSelectHint does not provide localization infrastructure: the computed headline's English scaffolding is hardcoded in source and is not exposed as translatable resource strings. Only prop values (`noun`, `listTitle`, `children`) pass through unmodified from the caller — the surrounding English sentence structure does not.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `select-hint.prefix` | "Select" | Leads every computed headline |
| `select-hint.article` | "a" / "an" | Chosen by a naive first-letter rule, not true English grammar — see **compute-headline-from-noun** |
| `select-hint.list-fallback` | "an item from" | Used when `listTitle` is given and `noun` is not |
| `select-hint.generic-fallback` | "an item from the list" | Used when neither `noun` nor `listTitle` is given |
| `select-hint.edit-suffix` | " to view or edit it here." | Appended when no `children` are provided |

An application that needs a fully localized headline must override it entirely via the `title` prop with pre-translated text; there is no per-fragment translation hook.

