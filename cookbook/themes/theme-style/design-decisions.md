
**Decision**: Render the `style` element inline during render instead of appending it to `document.head` in an effect.
**Rationale**: The source comment states it puts the CSS in the SSR HTML and applies it on first paint, avoiding a flash of unstyled content; the test file records that a head-side-effect version once passed every gate unnoticed.
**Approved**: pending

**Decision**: Use one element id per scope (`adh-sdk-theme-scoped-<slug>`, plus a hash of the raw selector when the selector is not its own slug) instead of a shared scoped id.
**Rationale**: The source comment says a page can carry several scoped themes, and a shared id would be duplicate invalid HTML where `getElementById` silently returns the first.
**Approved**: pending

**Decision**: Rewrite the stylesheet text with ordered regular expressions into an `@scope` block instead of authoring scoped stylesheets.
**Rationale**: Inferred from the source: the same shipped theme stylesheets (the source comments count 41; the manifest lists 39 themes) serve both document-wide and scoped use. The cost, documented in the comments, is that an unrecognised anchor drops the whole palette with no error, which is why a test runs every shipped theme.
**Approved**: pending

**Decision**: Move document-state qualifiers (`[data-color-mode]`, `:not(.dark)`, `[data-contrast=...]`) onto an `html` ancestor of `:scope`.
**Rationale**: The source comment explains these qualifiers describe the document, not the scoped element; hanging them on the scoped element matches nothing, silently.
**Approved**: pending

**Decision**: Match the light anchor only when it is the whole selector of its own rule.
**Rationale**: The source comment states dark-always themes (charcoal, fishlamp) carry the same discriminator as one comma-list item, and rewriting it would hand them a light variant they do not have.
**Approved**: pending

**Decision**: For forced `light`, collapse the light block to `:scope` and leave the dark block in place, relying on source order.
**Rationale**: The source comment states the dark block is never removed; the light block wins because it is later. This ties correctness to the stylesheet order of full-palette themes.
**Approved**: pending

**Decision**: Allow only spaces and tabs before an anchor, not any whitespace.
**Rationale**: The source comment says `\s*` would eat newlines and let one match swallow a preceding blank line, while indented anchors inside media blocks do exist.
**Approved**: pending

**Decision**: Keep the legacy `:root`, `:root.dark` and `:root:not(.dark)` rewrites although no shipped theme uses them.
**Rationale**: The source test calls this a contract regression test: `buildScopedCss` is public and an external stylesheet may still use that shape.
**Approved**: pending

**Decision**: Return `null` for an unknown theme key rather than throw.
**Rationale**: The source comment: a throw would take down a whole page over a style tag.
**Approved**: pending

