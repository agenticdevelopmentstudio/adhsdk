
| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `content` | string | Yes | — | Raw markdown string. A leading YAML frontmatter block (`---` at the very start of the string through the matching closing `---`) is stripped before processing; a `---` appearing later, after a blank line, is an ordinary thematic break and renders as `<hr>`. A leading `---` with no matching closing `---` is not frontmatter: nothing is stripped and the document renders as ordinary markdown (see **strip-frontmatter**, Edge Cases). |
| `className` | string | No | undefined | Additional CSS class(es) appended to the root `<div>` class list (see **accept-optional-class**). |
| `measure` | `'reading'` \| `'fill'` | No | `'reading'` | How wide the prose runs: `reading` is a ~72ch column and adds no class; `fill` runs as wide as the container and adds `adh-mv-prose--fill` to the root (see **apply-measure**). |
