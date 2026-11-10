
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; the component has no animation. |
| Increase Contrast | Not handled by the component; contrast comes from the host's `--lp-accent` / `--lp-ink-dim` tokens (see Compliance). |
| Differentiate Without Color | Satisfied: the `soon` state is marked by a distinct glyph (`○` vs `✓` via `--lp-checklist-mark-soon`), not by color or opacity alone (`packages/web/packages/landing/src/css/blocks.css`). |

