
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| code-001 | render-as-preformatted | `text: "line1\nline2\n  indented"` | Output preserves newlines and leading spaces; renders as three lines with the third indented |
| code-002 | no-wrap | `text: "a very long command that exceeds container width"` | Computed `white-space: pre` on the `<pre>`; the line does not break into multiple lines |
| code-003 | accept-string-prop | `text: "$ echo hello"` | Component renders without error; text appears as `$ echo hello` |
| code-004 | no-markup-interpretation | `text: "# Heading\n**bold** <html>"` | Output renders literally as `# Heading\n**bold** <html>` with no markdown or HTML interpretation |
| code-005 | use-monospace-font | `text: "code"` | Computed `font-family` on the `<pre>` resolves to the mono token (`var(--lp-font-mono)`), distinct from the deck's body `font-family` |
| code-006 | render-as-preformatted (empty-string edge case) | `text: ""` | Renders `<pre><code></code></pre>` with no children; the source sets no `min-height` on `.lp-code` or `.lp-code code`, so the content box collapses to `0` height and only the block's own padding (`1.1rem` top and bottom) and `1px` border remain — visibly shorter than a populated one-line block (`1.48rem`, i.e. `0.8rem × 1.85`), so a layout shift occurs going from empty to non-empty text |
| code-007 | render-as-preformatted (whitespace-only edge case) | `text: "   \t\n  "` | All spaces, the tab, and the newline are preserved exactly; rendered text length and line count match the input |
| code-008 | no-wrap (tabs edge case) | `text: "a\tb\tc"` | Tab renders at the CSS default `tab-size: 8` (not overridden by `lp-code`); columns are not collapsed to a single space |
| code-009 | no-markup-interpretation (Unicode edge case) | `text: "café 日本語 🎉"` | All characters render literally and unmodified, including the emoji and non-Latin script; no transformation or substitution occurs |
| code-010 | no-wrap | `text: "a very long command that exceeds container width"` | Computed `overflow-x: auto` on the `<pre>`; `scrollWidth > clientWidth` once content exceeds the container |

