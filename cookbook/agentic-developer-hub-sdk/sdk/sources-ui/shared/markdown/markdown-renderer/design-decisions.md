
**Decision**: The Apple parser uses `failurePolicy: .returnPartiallyParsedIfPossible` to degrade incomplete or malformed markdown to plaintext, and a parse failure there is never fatal.
**Rationale**: This ensures that streaming edits and user input errors do not result in empty or corrupted output on Apple platforms. Web's `remark-parse` also does not throw on malformed markdown syntax, but a *pipeline* failure (e.g. Shiki) is deliberately not degraded on web — it surfaces as the error pane instead (see **emit-error-pane**), which is the intended web behavior, not an inconsistency with this Apple-only decision.
**Approved**: pending

**Decision**: Blockquote and table identities are tracked separately (via `PresentationIntent` component identity) to allow per-block styling (e.g. coloring an entire blockquote) without ambiguity when structures are adjacent.
**Rationale**: This is essential for correct rendering of complex nested and adjacent structures — see **quote-identity** and **table-identity**.
**Approved**: pending

**Decision**: Apple accepts syntax highlighting as an optional `CodeHighlighter` protocol supplied by the host application; web hard-wires Shiki internally with no injection point exposed.
**Rationale**: Apple avoids shipping a large grammar stack in a framework customers embed, and lets the host provide custom highlighting behavior. Web instead standardizes on Shiki so every consumer gets the same highlighting and dual-theme CSS variables without per-app wiring; the trade-off is that a web host cannot substitute its own highlighter.
**Approved**: pending

**Decision**: Apple produces `NSAttributedString` (native to UIKit/AppKit rendering); web produces HTML (native to DOM rendering).
**Rationale**: Both apply semantic palette styling, but the output format is optimized for the platform's native rendering pipeline.
**Approved**: pending

**Decision**: HTML output is always passed through `rehype-sanitize` (allowlist schema) before injection into the DOM, and `remark-rehype` never emits raw/dangerous HTML for it to sanitize around.
**Rationale**: The component never exposes unsanitized HTML to `dangerouslySetInnerHTML` — see **sanitize-html**.
**Approved**: pending

**Decision**: Headers level 1–2 use display roles (title and heading) from the palette; level 3 uses the heading role at its default weight; levels 4–6 use body font with bold weight.
**Rationale**: The palette has no smaller heading role, and inventing one would diverge from the toolkit's type scale.
**Approved**: pending

**Decision**: Code highlighting colors are emitted as CSS variables, allowing the reading theme to repaint via CSS without re-processing the markdown.
**Rationale**: This eliminates flashing or a "Rendering…" state on theme change.
**Approved**: pending

