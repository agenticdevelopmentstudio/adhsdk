
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| textarea-001 | textarea-root | Render component | Root node is an HTML `<textarea>` element |
| textarea-002 | custom-classname | `className="custom-class"` | Custom class is applied alongside default styles |
| textarea-003 | prop-forwarding | `value="text" placeholder="Enter text"` | Props are forwarded to textarea element and text/placeholder appear |
| textarea-004 | min-height | Render component, measure DOM | Minimum height is 64px or equivalent |
| textarea-005 | full-width | Render in a fixed-width container | Textarea fills 100% of container width |
| textarea-006 | focus-indicator | Focus textarea via keyboard or click | Border and ring color change to golden; ring opacity visible |
| textarea-007 | disabled-state | `disabled={true}` | Pointer events are disabled, cursor is not-allowed, opacity is 50% |
| textarea-008 | invalid-state | `aria-invalid="true"` | Border and ring color change to red; ring opacity visible |
| textarea-009 | autofill-suppression | Render component with no `autoComplete` prop, inspect DOM attributes | Rendered attributes include `autocomplete="off"`, `data-form-type="other"`, `data-1p-ignore="true"`, `data-lpignore="true"`, `data-bwignore="true"`, `data-protonpass-ignore="true"` |
| textarea-010 | data-slot | Render component, query `[data-slot="textarea"]` | Element is found via attribute selector |
| textarea-011 | autofill-suppression | `autoComplete="off"` | Same six suppression attributes as textarea-009 are present |
| textarea-012 | autocomplete-control, autofill-suppression | `autoComplete="email"` | Rendered attribute is `autocomplete="email"`; none of the five vendor ignore attributes (`data-form-type`, `data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore`) are present |
| textarea-013 | padding | Render component, measure computed style | Padding is 12px horizontal, 8px vertical |
| textarea-014 | font-size | Render component, measure computed style | Font size is 14px |
| textarea-015 | text-color | Render component, measure computed style | Text color matches the `apt-text` token value |
| textarea-016 | placeholder-styling | Render with `placeholder="Enter text"` and no value | Placeholder text renders in the `apt-text-dim` token color |
| textarea-017 | outline-removal | Focus the textarea | No native browser outline is rendered; only the component's own border/ring focus indicator is visible |
| textarea-018 | color-transition | Toggle `disabled`, `aria-invalid`, or focus state | The border/ring color change is animated via a CSS transition, not an instant snap |
| textarea-019 | custom-classname | `className="w-1/2"` (conflicts with the default `w-full`) | Rendered class list contains a single width utility (`w-1/2`); `tailwind-merge` removes the conflicting default rather than both classes coexisting |

