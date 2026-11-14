
| State | Appearance change |
|-------|------------------|
| Default | 16×16px circle, `apt-border` border, `apt-bg` background, no indicator |
| Checked | Border changes to `apt-gold`, inner `apt-gold` dot appears (8×8px) |
| Focused | Border and ring added with `apt-gold`, ring opacity set to 25% |
| Disabled | No visual dimming (the `disabled:opacity-50`/`disabled:cursor-not-allowed`/`disabled:pointer-events-none` utilities target a native `:disabled` state the rendered `<span role="radio">` never has); disabled state is `aria-disabled="true"`, `data-disabled`, and `tabindex="-1"`; toggling is still blocked by Base UI's internal guards |
| Checked + Disabled | Checked appearance (border/dot) combined with the Disabled row's `aria-disabled`/`data-disabled`/`tabindex="-1"` state; no additional dimming |

