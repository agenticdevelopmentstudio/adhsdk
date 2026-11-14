
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| field-footnote-001 | error-shown-when-present | `error="This field is required"`, `hint={undefined}` | Renders a single element with the text "This field is required", using the error-foreground color and the monospace caption text size; no `id` attribute is present |
| field-footnote-002 | error-takes-precedence | `error="Error occurred"`, `hint="Hint text"` | Renders the error text only; the hint text is not present in the output |
| field-footnote-003 | hint-shown-without-error | `error={undefined}`, `hint="Type at least 8 characters"` | Renders a single element with the text "Type at least 8 characters", using the secondary-foreground color and the monospace caption text size; no `id` attribute is present |
| field-footnote-004 | renders-nothing-when-empty | `error={undefined}`, `hint={undefined}` | Returns null; nothing is rendered |
| field-footnote-005 | error-id-applied | `error="Error"`, `errorId="email-error"` | Renders the error element with `id="email-error"` |
| field-footnote-006 | error-id-only-on-error | `hint="Hint"`, `errorId="some-id"` | Renders the hint element with no `id` attribute present |
| field-footnote-007 | caller-class-name-merged | `error="Error"`, `className="custom-class"` | Renders the error element with the caller's `custom-class` present alongside the default classes |
| field-footnote-008 | supports-rich-content | `error={<strong>Bold error</strong>}` | Renders the error element containing the bold element as a child |
| field-footnote-009 | caller-class-name-merged | `error="Error"`, `className="text-blue-500"` | The error element has `text-blue-500` and no longer carries the default error-foreground class (the caller's color wins) |
| field-footnote-010 | supports-rich-content, hint-shown-without-error | `error=""`, `hint="Hint"` | Renders the hint; the empty error is treated as absent |
| field-footnote-011 | supports-rich-content, renders-nothing-when-empty | `error={0}` | Returns null; nothing is rendered |
| field-footnote-012 | renders-nothing-when-empty | `hint=""` only | Returns null; nothing is rendered |
