
| State | Appearance change |
|-------|------------------|
| Default | Pretty-printed JSON in a coloured code block. |
| Pressed | Not applicable: the component has no interactive element. |
| Disabled | Not applicable: the component has no interactive element. |
| Focused | Not applicable: the component adds no focusable element of its own. |
| Loading | Below the limit, `MarkdownRenderer` shows a subtle "Rendering…" note (`aria-live="polite"`, `aria-busy="true"`) while its async pipeline runs. Above the limit there is no loading state; the output is synchronous. |
| Invalid text | The note "Not valid JSON — shown as written." followed by the unmodified content, uncoloured. |
| Large document | Plain `pre.shiki` block without syntax colours; the invalid note, if any, is a `p.adh-mv-json-note`. |
| Render error | Below the limit, `MarkdownRenderer` shows its alert pane "Failed to render document". Above the limit there is no error state. |

