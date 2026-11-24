
| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| id | string | yes | — | The key into the site's help copy. |
| children | ReactNode (text) | yes | — | The text or label that becomes the help trigger. It is text, not a control. |
| className | string | no | — | Applied to the root element in both variants, so the caller's layout survives a missing entry. |
| fallback | string | no | — | Help body shown as an `info` entry when the store has no entry for `id`. Suppresses the missing-entry warning. |
