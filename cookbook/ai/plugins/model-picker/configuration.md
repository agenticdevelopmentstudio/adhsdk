
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Anchor view | view | — (required) | The view the popover points at; the control passes its caret. |
| Chooser context | chooser context | — (required) | Plugin identifier, provider template, base URL, API key, current model, and warn and block thresholds (percent of RAM, defaulting to the fit policy's). |
| Choice callback | function from model id | — (required) | Called with each model chosen. |
| Label (control) | text | "AI Model" | The control's leading label. |
| Display name (control) | function returning optional text | — (required) | The name to show; none or empty shows "Choose a Model". |
| Context (control) | function returning an optional chooser context | — (required) | What the chooser lists; none disables the control. |
| On choose (control) | function from model id | — (required) | Receives each chosen model. |

