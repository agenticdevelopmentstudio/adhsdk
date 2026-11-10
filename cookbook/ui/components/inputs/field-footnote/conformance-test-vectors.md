
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| field-footnote-001 | error-shown-when-present | `error="This field is required"`, `hint={undefined}` | Renders a single element with the text "This field is required", using the error-foreground color and the monospace caption text size; no `id` attribute is present |
| field-footnote-002 | error-takes-precedence | `error="Error occurred"`, `hint="Hint text"` | Renders the error text only; the hint text is not present in the output |
| field-footnote-003 | hint-shown-without-error | `error={undefined}`, `hint="Type at least 8 characters"` | Renders a single element with the text "Type at least 8 characters", using the secondary-foreground color and the monospace caption text size; no `id` attribute is present |
| field-footnote-004 | renders-nothing-when-empty | `error={undefined}`, `hint={undefined}` | Returns null; nothing is rendered |
| field-footnote-005 | error-id-applied | `error="Error"`, `errorId="email-error"` | Renders the error element with `id="email-error"` |
| field-footnote-006 | error-id-only-on-error | `hint="Hint"`, `errorId="some-id"` | Renders the hint element with no `id` attribute present |
| field-footnote-007 | caller-class-name-merged | `error="Error"`, `className="custom-class"` | Renders the error element with the caller's `custom-class` present alongside the default classes |
| field-footnote-008 | supports-react-node-content | `error={<strong>Bold error</strong>}` | Renders the error element containing the bold element as a child |

