
| ID | Requirements | Input | Action | Expected |
|----|-------------|-------|--------|----------|
| error-text-001 | render-when-error-present, error-text-render-as-paragraph | `error="Username is required"`, variant: `ErrorText` | Render component | A `<p role="alert">` element appears with text "Username is required" |
| error-text-002 | render-nothing-when-error-absent | `error={null}` | Render component | Component returns `null`; no element is rendered |
| error-text-003 | render-nothing-when-error-absent | `error={undefined}` | Render component | Component returns `null`; no element is rendered |
| error-text-004 | render-nothing-when-error-absent | `error=""` | Render component | Component returns `null`; no element is rendered |
| error-text-005 | include-error-text-content | `error="Invalid email format"` | Render component; inspect text | Text content of the element is exactly "Invalid email format" |
| error-text-006 | apply-error-color, default-text-size | `error="Error message"` | Render component; inspect classList | The element includes both `text-sm` and `text-apt-red` classes in its class attribute |
| error-text-007 | render-when-error-present | `error="Error"` | Render component; inspect attributes | The element has `role="alert"` attribute |
| error-text-008 | support-classname-prop | `error="Error"`, `className="px-4"` | Render component; inspect classList | The element includes `px-4` in its class attribute, merged with the default classes via `cn()` |
| error-text-009 | dialog-error-text-render-as-span | `error="Error"`, variant: `DialogErrorText` | Render component; inspect element type | A `<span>` element is rendered, not `<p>` |
| error-text-010 | dialog-error-text-top-margin, dialog-error-text-render-as-span, apply-error-color, default-text-size | `error="Error"`, variant: `DialogErrorText` | Render component; inspect classList | The span includes `mt-2`, `block`, `text-sm`, and `text-apt-red` classes |
| error-text-011 | render-nothing-when-error-absent | `error={null}`, variant: `DialogErrorText` | Render component | Component returns `null`; no element is rendered |
| error-text-012 | support-classname-prop | `error="Error"`, `className="px-4"`, variant: `DialogErrorText` | Render component; inspect classList | The span includes `px-4` merged with the default classes (`mt-2`, `block`, `text-sm`, `text-apt-red`) via `cn()` |
| error-text-013 | default-text-size, apply-error-color | `error="Error"`, `className="text-xs"` | Render component; inspect classList | The element's class attribute includes `text-xs` in place of the default `text-sm` — `tailwind-merge` resolves the conflicting size utility in favor of the caller's class — while `text-apt-red` remains present and unaffected |
| error-text-014 | render-when-error-present | `error="Error"`, parent container `display: none` | Render component; inspect DOM | The `role="alert"` element is present in the DOM despite the hidden parent; this vector does not assert screen-reader announcement timing once the container becomes visible |

