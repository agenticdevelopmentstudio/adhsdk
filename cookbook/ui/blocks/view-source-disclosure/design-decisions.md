
**Decision**: Do not compose the toolkit's shared `Disclosure` component; keep this as a separate, self-contained disclosure.
**Rationale**: `Disclosure` renders a framed card — a rounded border, a raised surface, a `text-sm font-medium` title, and a ruled content box — for a host that wants that shape. Reaching this component's quiet inline look through `Disclosure` would mean cancelling nine of its visual decisions: the card chrome, the header padding, the chevron's size and colour, the title's family/size/weight/colour, and the content frame — to keep roughly 20 lines of open/close state. That is a standing coupling that would let a future `Disclosure` restyle silently break this component. The two disclosures encode different knowledge (a framed section vs. an inline text toggle), so duplicating the open/close mechanics is not a DRY violation.
**Approved**: pending

**Decision**: Keep the component uncontrolled — no `open`/`onOpenChange` props; state lives in an internal `useState`.
**Rationale**: Once opened, the reader owns the state. This reflects the component's role as a low-priority reader convenience, not a controlled UI element that a host form or flow needs to drive.
**Approved**: pending

**Decision**: Set `aria-controls` on the trigger only while the panel exists (open state).
**Rationale**: `aria-controls` is an IDREF; pointing it at a nonexistent element is an authoring error (axe: `aria-valid-attr-value`), not a harmless no-op. `aria-expanded` alone already announces the open/closed state to assistive technology, so nothing is lost by omitting `aria-controls` while the panel is absent.
**Approved**: pending

**Decision**: Render the source text as a plain text node — interpolated as a JSX child of `<pre>`, never assigned via `innerHTML`, `dangerouslySetInnerHTML`, or any other HTML-parsing API — with no markdown parsing or syntax highlighting.
**Rationale**: The rendering framework escapes text-node content automatically, so arbitrary source text (including strings that look like HTML or script tags) is always displayed literally and never interpreted as markup. The component is a raw-text viewer; the host owns syntax highlighting or transformation if it wants either.
**Approved**: pending

**Decision**: Use deliberately muted colors and small monospace type so the trigger reads as chrome, not content.
**Rationale**: A reader seeking the raw markdown will look for the disclosure; a reader who doesn't need it should not be visually drawn to notice it.
**Approved**: pending

