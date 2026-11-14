
| State | Appearance change |
|-------|------------------|
| Default | Links in `--lp-ink-dim`, separators between them. |
| Sweeping | After the 2000 ms start delay the lens runs back and forth along the links without stopping, tinting glyphs near it from `--lp-ink-dim` toward `--lp-accent-bright` and scaling them up to 125%; it holds still (glyphs at rest) while the pointer is over a link, and does not run under reduced motion. |
| Hover | Link colour becomes `--lp-accent-bright`, animated by `transition: color 0.3s`. |
| Focused | Link colour becomes `--lp-accent-bright` and a 2px `--lp-accent` outline appears (`:focus-visible` only). |
| Phone width | Separators are removed and links are spaced by a 1.2rem column gap. |
| Pressed | Not applicable: `flow.css` has no `:active` rule for the links. |
| Disabled | Not applicable: the component has no disabled prop and renders only plain anchors. |
| Loading | Not applicable: rows are passed in synchronously and nothing is fetched. |

