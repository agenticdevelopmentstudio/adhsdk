
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| disclosure-001 | render-trigger-button, render-label | No props (defaults) | Trigger button renders with text "View source" |
| disclosure-002 | render-chevron-icon | No props | Chevron-right icon renders inside trigger |
| disclosure-003 | start-closed-by-default | No props | Disclosure starts closed; source panel is not in DOM |
| disclosure-004 | start-closed-by-default, render-source-in-pre-tag | `defaultOpen={true}` | Disclosure starts open; source panel is in DOM and visible |
| disclosure-005 | toggle-on-click, render-source-verbatim, not-parse-markdown | Click trigger when closed; `source="# Heading\n\n- List item"` | Panel appears showing raw text exactly as `"# Heading"` and `"- List item"`, not parsed as markdown |
| disclosure-006 | toggle-on-click | Click trigger when open | Panel closes and is removed from DOM |
| disclosure-007 | rotate-chevron-on-open | Click trigger to open | Chevron rotates to 90° with 150ms transition |
| disclosure-008 | rotate-chevron-on-open | Click trigger to close | Chevron rotates back to 0° with 150ms transition |
| disclosure-009 | wrap-text-not-truncate | `source="Short line\nVery long line that would exceed container width"` in narrow viewport | Long line wraps to multiple lines within container; does not overflow or truncate |
| disclosure-010 | scroll-horizontally-for-long-lines | `source="https://example.com/path/to/very/long/url/that/is/one/unbreakable/token"` in narrow viewport | Source area allows horizontal scroll; the URL does not wrap |
| disclosure-011 | accept-classname-prop | `className="custom-class"` | Custom class is applied to outer div alongside default classes |
| disclosure-012 | accept-html-attributes | `data-testid="source-disclosure"` | data attribute is present on outer div |
| disclosure-013 | set-aria-expanded | Click trigger to open, inspect button | `aria-expanded="true"` on button |
| disclosure-014 | set-aria-expanded | Click trigger to close, inspect button | `aria-expanded="false"` on button |
| disclosure-015 | conditionally-set-aria-controls | Trigger closed, inspect button | `aria-controls` attribute is absent |
| disclosure-016 | conditionally-set-aria-controls | Trigger open, inspect button and panel | `aria-controls` matches the panel's `id` |
| disclosure-017 | render-source-verbatim, not-parse-markdown | Click trigger to open; `source="<script>alert(1)</script>"` | Panel shows the literal text `<script>alert(1)</script>`; no `<script>` element is created and no code executes |
| disclosure-018 | source-selectable | Trigger open; select text within the source panel | Source text can be selected and copied via native text selection |

