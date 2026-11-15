
| State | Appearance change |
|-------|------------------|
| Default | 16×16px circle, `apt-border` border, `apt-bg` background, no indicator |
| Checked | Border changes to `apt-gold`, inner `apt-gold` dot appears (8×8px) |
| Focused | Border and ring added with `apt-gold`, ring opacity set to 25% |
| Disabled | Dimmed (`disabled:opacity-50`, `disabled:cursor-not-allowed`, `disabled:pointer-events-none` match the native `disabled` attribute on the `<button>` root); also carries `aria-disabled="true"` and `data-disabled`; toggling is also blocked by Base UI's internal guards |
| Checked + Disabled | Checked appearance (border/dot) combined with the Disabled row's dimmed, `disabled`/`aria-disabled`/`data-disabled` state |

