
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | centered-modal | Open the dialog with `<DialogTrigger>` | Popup appears centered on screen with dimmed, blurred backdrop behind it |
| T2 | backdrop-dismissal-disabled (default) | Click the backdrop area while dialog is open | Dialog remains open |
| T3 | escape-closes (default) | Press Escape key while dialog is open and focused | Dialog closes |
| T4 | close-affordance (default) | Render `<DialogContent>` without `showClose` prop | Close button (×) is rendered in top-right corner |
| T5 | close-affordance (hidden) | Render `<DialogContent showClose={false}>` | Close button is not rendered |
| T6 | focus-trap | Tab through dialog, close it | Focus stays within dialog; on close, focus returns to the trigger element |
| T7 | dialog-labelling | Render with `<DialogTitle>` and `<DialogDescription>` | Assistive technology announces title and description |
| T8 | backdrop-dismissal-disabled (opt-in) | Set `disablePointerDismissal={false}` and click backdrop | Dialog closes on backdrop click |
| T9 | escape-closes (override) | Composing component passes its own `onOpenChange`, calling `eventDetails.cancel()` when the dismissal reason is Escape (or, with a controlled `open`, simply not setting it to `false`), then Escape is pressed while the dialog is open and focused | Dialog remains open — the composing component's override suppresses the default Escape-to-close behavior |
| T10 | dialog-labelling (missing title) | Render `<DialogContent>` with no `<DialogTitle>` child | Popup renders without an `aria-labelledby` attribute; assistive technology announces the dialog with no accessible name |

