
- **Corner radius**: Not applicable: the component sets none of its own; below the limit the code block is styled by `MarkdownRenderer`, and above it by the `adh-mv-prose` styles for `pre.shiki`.
- **Padding**: Not applicable: none set by this component; it comes from the shared prose styles.
- **Font**: Monospace code, from the code-block styling shared with `MarkdownRenderer`. The invalid-text note below the limit is Markdown emphasis (italic) in the prose body font; above the limit the note is italic through `adh-mv-json-note`.
- **Background**: Below the limit, the shiki dual-theme code-block background shared with `MarkdownRenderer`. Above the limit, the `pre.shiki` background from the prose styles, without token colours.
- **Foreground/Text**: Below the limit, shiki token colours for valid JSON; invalid text has no language, so it has no token colours and renders as a bare `pre` without the `shiki` class. Above the limit, a single text colour. The plain-path note uses the muted text variable `--mdv-text-muted`.
- **Border**: Not applicable: none set by this component.
- **Shadow**: Not applicable: none set by this component.
- **Min/Max size**: Not applicable: no size constraint of its own. The root fills the width of its prose measure (`reading`, about 72ch). Long lines scroll sideways unless `wrap` is true.

